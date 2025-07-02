//
//  VoiceRecorder.swift
//  CoC
//
//  Created by Sean Song on 7/2/25.
//

import Foundation
import Speech
import AVFoundation
import Combine

@MainActor
class VoiceRecorder: ObservableObject {
    @Published var isRecording = false
    @Published var transcribedText = ""
    @Published var audioLevels: [Float] = Array(repeating: 0.0, count: 20)
    @Published var hasPermission = false
    @Published var errorMessage: String?
    
    private var audioEngine = AVAudioEngine()
    private var speechRecognizer = SFSpeechRecognizer()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioSession = AVAudioSession.sharedInstance()
    
    init() {
        requestPermissions()
    }
    
    // MARK: - Permission Management
    func requestPermissions() {
        // Request speech recognition permission
        SFSpeechRecognizer.requestAuthorization { [weak self] speechStatus in
            guard let self = self else { return }
            
            // Request microphone permission
            self.audioSession.requestRecordPermission { [weak self] micStatus in
                Task { @MainActor in
                    guard let self = self else { return }
                    
                    self.hasPermission = speechStatus == .authorized && micStatus
                    if !self.hasPermission {
                        self.errorMessage = "Please enable microphone and speech recognition permissions in Settings to use voice features."
                    }
                }
            }
        }
    }
    
    // MARK: - Recording Control
    func startRecording() {
        guard hasPermission else {
            errorMessage = "Missing permissions for voice recording"
            return
        }
        
        // Reset previous session
        if audioEngine.isRunning {
            stopRecording()
        }
        
        do {
            try setupAudioSession()
            try startSpeechRecognition()
            isRecording = true
            errorMessage = nil
        } catch {
            errorMessage = "Failed to start recording: \(error.localizedDescription)"
        }
    }
    
    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        
        isRecording = false
        
        // Clear audio levels
        audioLevels = Array(repeating: 0.0, count: 20)
    }
    
    // MARK: - Audio Session Setup
    private func setupAudioSession() throws {
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    }
    
    // MARK: - Speech Recognition
    private func startSpeechRecognition() throws {
        let inputNode = audioEngine.inputNode
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw RecordingError.failedToCreateRequest
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Start recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            Task { @MainActor in
                guard let self = self else { return }
                
                if let result = result {
                    self.transcribedText = result.bestTranscription.formattedString
                }
                
                if let error = error {
                    self.errorMessage = "Speech recognition error: \(error.localizedDescription)"
                    self.stopRecording()
                }
            }
        }
        
        // Setup audio tap for waveform visualization and speech recognition
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            // Send buffer to speech recognition
            recognitionRequest.append(buffer)
            
            // Process for waveform visualization
            Task { @MainActor in
                self?.processAudioBuffer(buffer)
            }
        }
        
        // Start audio engine
        audioEngine.prepare()
        try audioEngine.start()
    }
    
    // MARK: - Audio Level Processing
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        
        let frameLength = Int(buffer.frameLength)
        let barsCount = audioLevels.count
        let samplesPerBar = frameLength / barsCount
        
        var newLevels: [Float] = []
        
        for i in 0..<barsCount {
            let startIndex = i * samplesPerBar
            let endIndex = min(startIndex + samplesPerBar, frameLength)
            
            var sum: Float = 0.0
            for j in startIndex..<endIndex {
                sum += abs(channelData[j])
            }
            
            let average = sum / Float(endIndex - startIndex)
            let normalizedLevel = min(max(average * 10, 0.0), 1.0) // Normalize and scale
            newLevels.append(normalizedLevel)
        }
        
        audioLevels = newLevels
    }
    
    // MARK: - Cleanup
    deinit {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
            recognitionRequest?.endAudio()
            recognitionTask?.cancel()
        }
    }
}

// MARK: - Recording Errors
enum RecordingError: LocalizedError {
    case failedToCreateRequest
    case permissionDenied
    case audioEngineFailure
    
    var errorDescription: String? {
        switch self {
        case .failedToCreateRequest:
            return "Failed to create speech recognition request"
        case .permissionDenied:
            return "Microphone or speech recognition permission denied"
        case .audioEngineFailure:
            return "Audio engine failed to start"
        }
    }
} 