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
        print("🎙️ [VoiceRecorder] Initializing VoiceRecorder...")
        print("🎙️ [VoiceRecorder] Speech recognizer available: \(speechRecognizer?.isAvailable ?? false)")
        print("🎙️ [VoiceRecorder] Speech recognizer locale: \(speechRecognizer?.locale.identifier ?? "unknown")")
        requestPermissions()
    }
    
    // MARK: - Permission Management
    func requestPermissions() {
        print("🎙️ [VoiceRecorder] Requesting permissions...")
        
        // Request speech recognition permission
        SFSpeechRecognizer.requestAuthorization { [weak self] speechStatus in
            print("🎙️ [VoiceRecorder] Speech recognition permission status: \(speechStatus.rawValue)")
            guard let self = self else { return }
            
            // Request microphone permission
                            AVAudioApplication.requestRecordPermission { [weak self] micStatus in
                print("🎙️ [VoiceRecorder] Microphone permission status: \(micStatus)")
                Task { @MainActor in
                    guard let self = self else { return }
                    
                    self.hasPermission = speechStatus == .authorized && micStatus
                    print("🎙️ [VoiceRecorder] Final permissions - hasPermission: \(self.hasPermission)")
                    
                    if !self.hasPermission {
                        let error = "Please enable microphone and speech recognition permissions in Settings to use voice features."
                        print("❌ [VoiceRecorder] Permission denied: \(error)")
                        self.errorMessage = error
                    }
                }
            }
        }
    }
    
    // MARK: - Recording Control
    func startRecording() {
        print("🎙️ [VoiceRecorder] Starting recording...")
        print("🎙️ [VoiceRecorder] Has permission: \(hasPermission)")
        print("🎙️ [VoiceRecorder] Currently recording: \(isRecording)")
        
        guard hasPermission else {
            let error = "Missing permissions for voice recording"
            print("❌ [VoiceRecorder] Permission check failed: \(error)")
            errorMessage = error
            return
        }
        
        // Prevent multiple simultaneous recordings
        if isRecording {
            print("⚠️ [VoiceRecorder] Already recording, ignoring start request")
            return
        }
        
        // Reset previous session
        if audioEngine.isRunning || recognitionTask != nil {
            print("🎙️ [VoiceRecorder] Cleaning up previous session...")
            stopRecording()
            // Wait a moment for cleanup to complete
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.performStartRecording()
            }
            return
        }
        
        performStartRecording()
    }
    
    private func performStartRecording() {
        print("🎙️ [VoiceRecorder] Performing actual recording start...")
        
        // Clear any previous error messages
        errorMessage = nil
        transcribedText = ""
        
        do {
            print("🎙️ [VoiceRecorder] Setting up audio session...")
            try setupAudioSession()
            
            print("🎙️ [VoiceRecorder] Starting speech recognition...")
            try startSpeechRecognition()
            
            isRecording = true
            errorMessage = nil
            print("✅ [VoiceRecorder] Recording started successfully")
        } catch {
            let errorMsg = "Failed to start recording: \(error.localizedDescription)"
            print("❌ [VoiceRecorder] Start recording failed: \(errorMsg)")
            errorMessage = errorMsg
        }
    }
    
    func stopRecording() {
        print("🎙️ [VoiceRecorder] Stopping recording...")
        print("🎙️ [VoiceRecorder] Audio engine running: \(audioEngine.isRunning)")
        print("🎙️ [VoiceRecorder] Current transcribed text: '\(transcribedText)'")
        
        // Set recording state to false first to prevent error handling during cleanup
        isRecording = false
        
        // Stop audio engine first
        if audioEngine.isRunning {
            print("🎙️ [VoiceRecorder] Stopping audio engine...")
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        
        // End recognition request gracefully
        if let request = recognitionRequest {
            print("🎙️ [VoiceRecorder] Ending recognition request...")
            request.endAudio()
            recognitionRequest = nil
        }
        
        // Cancel recognition task with a small delay to allow final results
        if let task = recognitionTask {
            print("🎙️ [VoiceRecorder] Canceling recognition task...")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                task.cancel()
            }
            recognitionTask = nil
        }
        
        // Clear audio levels
        audioLevels = Array(repeating: 0.0, count: 20)
        
        print("✅ [VoiceRecorder] Recording stopped successfully")
        print("🎙️ [VoiceRecorder] Final transcribed text: '\(transcribedText)'")
    }
    
    // MARK: - Audio Session Setup
    private func setupAudioSession() throws {
        print("🎙️ [VoiceRecorder] Setting up audio session...")
        print("🎙️ [VoiceRecorder] Current audio session category: \(audioSession.category)")
        
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        print("🎙️ [VoiceRecorder] Audio session category set to: \(audioSession.category)")
        
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        print("✅ [VoiceRecorder] Audio session activated successfully")
    }
    
    // MARK: - Speech Recognition
    private func startSpeechRecognition() throws {
        print("🎙️ [VoiceRecorder] Starting speech recognition...")
        
        let inputNode = audioEngine.inputNode
        print("🎙️ [VoiceRecorder] Audio input node: \(inputNode)")
        print("🎙️ [VoiceRecorder] Input format: \(inputNode.outputFormat(forBus: 0))")
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            print("❌ [VoiceRecorder] Failed to create recognition request")
            throw RecordingError.failedToCreateRequest
        }
        
        recognitionRequest.shouldReportPartialResults = true
        print("🎙️ [VoiceRecorder] Recognition request created with partial results enabled")
        
        // Start recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            Task { @MainActor in
                guard let self = self else { return }
                
                if let result = result {
                    let newText = result.bestTranscription.formattedString
                    let confidence = result.bestTranscription.segments.last?.confidence ?? 0.0
                    
                    print("🎙️ [VoiceRecorder] Speech recognition result: '\(newText)' (confidence: \(confidence))")
                    print("🎙️ [VoiceRecorder] Is final result: \(result.isFinal)")
                    
                    self.transcribedText = newText
                    
                    if result.isFinal {
                        print("✅ [VoiceRecorder] Final speech recognition result: '\(newText)'")
                    }
                }
                
                if let error = error {
                    let nsError = error as NSError
                    let errorCode = nsError.code
                    let errorDomain = nsError.domain
                    
                    print("❌ [VoiceRecorder] Speech recognition error - Domain: \(errorDomain), Code: \(errorCode)")
                    print("❌ [VoiceRecorder] Error details: \(error)")
                    
                    // Handle specific error codes
                    if errorDomain == "kLSRErrorDomain" && errorCode == 301 {
                        print("🎙️ [VoiceRecorder] Recognition was canceled (Code 301) - this is normal when stopping recording")
                        // Don't treat cancellation as an error if we're already stopping
                        if self.isRecording {
                            print("⚠️ [VoiceRecorder] Unexpected cancellation during recording - performing cleanup")
                            self.forceCleanup()
                            let errorMsg = "Speech recognition was interrupted. Please try again."
                            self.errorMessage = errorMsg
                        }
                    } else if errorDomain == "kLSRErrorDomain" && errorCode == 203 {
                        print("⚠️ [VoiceRecorder] Speech recognition unavailable - trying recovery")
                        self.forceCleanup()
                        let errorMsg = "Speech recognition temporarily unavailable. Please try again."
                        self.errorMessage = errorMsg
                    } else {
                        let errorMsg = "Speech recognition error: \(error.localizedDescription)"
                        self.errorMessage = errorMsg
                        self.stopRecording()
                    }
                }
            }
        }
        
        print("🎙️ [VoiceRecorder] Recognition task started")
        
        // Setup audio tap for waveform visualization and speech recognition
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        print("🎙️ [VoiceRecorder] Installing audio tap with buffer size: 1024")
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            // Send buffer to speech recognition
            recognitionRequest.append(buffer)
            
            // Process for waveform visualization
            Task { @MainActor in
                self?.processAudioBuffer(buffer)
            }
        }
        
        // Start audio engine
        print("🎙️ [VoiceRecorder] Preparing and starting audio engine...")
        audioEngine.prepare()
        try audioEngine.start()
        print("✅ [VoiceRecorder] Audio engine started successfully")
    }
    
    // MARK: - Audio Level Processing
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { 
            print("⚠️ [VoiceRecorder] No channel data in audio buffer")
            return 
        }
        
        let frameLength = Int(buffer.frameLength)
        let barsCount = audioLevels.count
        let samplesPerBar = frameLength / barsCount
        
        // Calculate overall audio level for debugging
        var totalSum: Float = 0.0
        for i in 0..<frameLength {
            totalSum += abs(channelData[i])
        }
        let overallLevel = totalSum / Float(frameLength)
        
        // Only log periodically to avoid spam (every ~30 buffers)
        if Int.random(in: 0..<30) == 0 {
            print("🎙️ [VoiceRecorder] Audio buffer - Frame length: \(frameLength), Overall level: \(String(format: "%.4f", overallLevel))")
        }
        
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
        
        // Log significant audio activity
        let maxLevel = newLevels.max() ?? 0.0
        if maxLevel > 0.3 && Int.random(in: 0..<20) == 0 {
            print("🎙️ [VoiceRecorder] High audio activity detected - Max level: \(String(format: "%.2f", maxLevel))")
        }
    }
    
    // MARK: - Cleanup
    private func forceCleanup() {
        print("🎙️ [VoiceRecorder] Force cleanup of all recording resources...")
        
        // Force stop all components
        isRecording = false
        
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        
        // Safely remove tap if it exists
        if audioEngine.inputNode.numberOfInputs > 0 {
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        recognitionTask?.cancel()
        recognitionTask = nil
        
        audioLevels = Array(repeating: 0.0, count: 20)
        
        print("✅ [VoiceRecorder] Force cleanup completed")
    }
    
    deinit {
        print("🎙️ [VoiceRecorder] Deinitializing VoiceRecorder...")
        
        if audioEngine.isRunning {
            print("🎙️ [VoiceRecorder] Cleaning up running audio engine...")
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
            recognitionRequest?.endAudio()
            recognitionTask?.cancel()
            print("✅ [VoiceRecorder] Cleanup completed")
        } else {
            print("🎙️ [VoiceRecorder] Audio engine not running, no cleanup needed")
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

// MARK: - Text-to-Speech Manager
import AVFoundation

@MainActor
class TextToSpeechManager: ObservableObject {
    private let synthesizer = AVSpeechSynthesizer()
    @Published var isSpeaking = false
    
    func speak(text: String, language: String = "ja-JP") {
        print("🔊 [TTS] Starting speech - Text: '\(text)', Language: '\(language)'")
        
        // Stop any current speech
        stop()
        
        let utterance = AVSpeechUtterance(string: text)
        
        // Set language based on destination
        let selectedLanguage: String
        switch language.lowercased() {
        case "japan", "japanese", "ja", "ja-jp":
            selectedLanguage = "ja-JP"
        case "germany", "german", "de", "de-de":
            selectedLanguage = "de-DE"
        case "china", "chinese", "zh", "zh-cn":
            selectedLanguage = "zh-CN"
        case "korea", "korean", "ko", "ko-kr":
            selectedLanguage = "ko-KR"
        default:
            selectedLanguage = "en-US"
        }
        
        // Try to get voice for selected language, fallback to default if not available
        if let voice = AVSpeechSynthesisVoice(language: selectedLanguage) {
            utterance.voice = voice
            print("🔊 [TTS] Selected voice language: \(selectedLanguage)")
            print("🔊 [TTS] Voice description: \(voice.name)")
        } else {
            // Fallback to default voice
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            print("⚠️ [TTS] Voice for \(selectedLanguage) not available, falling back to en-US")
        }
        
        utterance.rate = 0.5 // Slightly slower for learning
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        isSpeaking = true
        synthesizer.speak(utterance)
        
        // Monitor speech completion
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(text.count) * 0.1 + 2.0) {
            self.isSpeaking = false
        }
    }
    
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
    }
    
    // Extract local language text (second line) from bilingual name
    func extractLocalLanguageText(from bilingualText: String) -> String {
        let lines = bilingualText.components(separatedBy: "\n")
        // Return second line (local language), fallback to first if only one line
        return lines.count > 1 ? lines[1] : lines.first ?? bilingualText
    }
    
    // Determine language code from destination
    func getLanguageCode(for destination: String) -> String {
        switch destination.lowercased() {
        case "japan":
            return "ja-JP"
        case "germany":
            return "de-DE"
        case "china":
            return "zh-CN"
        case "korea":
            return "ko-KR"
        default:
            return "en-US"
        }
    }
} 