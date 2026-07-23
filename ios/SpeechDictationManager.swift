//
//  SpeechDictationManager.swift
//  ios
//
//  Live, on-device speech-to-text for capturing notes by voice.
//

import Foundation
import Speech
import AVFoundation

/// Drives live dictation for the create-note sheet: requests the microphone +
/// speech-recognition permissions, runs an on-device `SFSpeechRecognizer`, and
/// publishes the running transcript. Audio never leaves the device
/// (`requiresOnDeviceRecognition`), matching the commitment in PRIVACY.md.
@MainActor
final class SpeechDictationManager: ObservableObject {

    enum Permission: Equatable {
        case granted
        case denied
    }

    @Published var transcript: String = ""
    @Published var isRecording: Bool = false
    @Published var permissionDenied: Bool = false

    private let recognizer = SFSpeechRecognizer(locale: Locale.current)
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    /// AVAudioSession activation can block; keep it off the main thread to
    /// avoid the "AVAudioSession Hang Risk" UI-unresponsiveness warning.
    private let sessionQueue = DispatchQueue(label: "miranda.dictation.session")

    // MARK: - Pure logic (unit-tested)

    /// Both the microphone and speech recognizer must be authorized to dictate.
    nonisolated static func resolvePermission(
        speech: SFSpeechRecognizerAuthorizationStatus,
        microphoneGranted: Bool
    ) -> Permission {
        guard microphoneGranted, speech == .authorized else { return .denied }
        return .granted
    }

    /// Combines any text the user already had with the live transcript so
    /// dictation extends—rather than clobbers—existing input.
    nonisolated static func compose(base: String, transcript: String) -> String {
        let trimmedBase = base.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedBase.isEmpty else { return transcript }
        guard !transcript.isEmpty else { return base }
        return trimmedBase + " " + transcript
    }

    // MARK: - Control

    func toggle() {
        if isRecording {
            stop()
        } else {
            requestAuthorizationAndStart()
        }
    }

    func requestAuthorizationAndStart() {
        SFSpeechRecognizer.requestAuthorization { [weak self] speechStatus in
            AVAudioApplication.requestRecordPermission { granted in
                Task { @MainActor in
                    guard let self else { return }
                    switch Self.resolvePermission(speech: speechStatus, microphoneGranted: granted) {
                    case .granted:
                        self.start()
                    case .denied:
                        self.permissionDenied = true
                    }
                }
            }
        }
    }

    func stop() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        request?.endAudio()
        request = nil
        task?.cancel()
        task = nil
        isRecording = false
        sessionQueue.async {
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
    }

    // MARK: - Private

    private func start() {
        guard let recognizer, recognizer.isAvailable else {
            permissionDenied = true
            return
        }

        // Reset any in-flight task before starting a fresh capture.
        task?.cancel()
        task = nil

        // Configure the session off-main (blocking call), then wire up the
        // engine + recognizer back on the main actor.
        sessionQueue.async { [weak self] in
            let session = AVAudioSession.sharedInstance()
            do {
                try session.setCategory(.record, mode: .measurement, options: .duckOthers)
                try session.setActive(true, options: .notifyOthersOnDeactivation)
            } catch {
                return
            }
            Task { @MainActor in
                self?.startEngineAndRecognition()
            }
        }
    }

    private func startEngineAndRecognition() {
        guard let recognizer else { return }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        if recognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
        }
        self.request = request

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            stop()
            return
        }

        isRecording = true

        task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                guard let self else { return }
                if let result {
                    self.transcript = result.bestTranscription.formattedString
                }
                if error != nil || (result?.isFinal ?? false) {
                    self.stop()
                }
            }
        }
    }
}
