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
/// publishes the running transcript. Audio never leaves the device:
/// `requiresOnDeviceRecognition` is always set, and dictation is refused
/// entirely when on-device recognition is unsupported (no cloud fallback),
/// matching the commitment in PRIVACY.md.
@MainActor
final class SpeechDictationManager: ObservableObject {

    enum Permission: Equatable {
        case granted
        case denied
    }

    enum Availability: Equatable {
        case available
        case unavailable
    }

    @Published var transcript: String = ""
    @Published var isRecording: Bool = false
    @Published var permissionDenied: Bool = false
    /// True when dictation cannot run because on-device recognition is not
    /// supported for the current locale/device. Distinct from a permission
    /// denial: the user has nothing to grant, the capability is missing.
    @Published var onDeviceUnavailable: Bool = false

    private let recognizer = SFSpeechRecognizer(locale: Locale.current)
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    /// AVAudioSession activation can block; keep it off the main thread to
    /// avoid the "AVAudioSession Hang Risk" UI-unresponsiveness warning.
    private let sessionQueue = DispatchQueue(label: "miranda.dictation.session")

    /// Finalized utterances captured so far this session. iOS 18 on-device
    /// recognition resets `bestTranscription` after a pause, so we accumulate
    /// finalized segments ourselves instead of trusting it to stay cumulative.
    private var finalizedSegments: [String] = []
    /// The in-progress (not yet finalized) utterance.
    private var currentPartial: String = ""

    // MARK: - Pure logic (unit-tested)

    /// Both the microphone and speech recognizer must be authorized to dictate.
    nonisolated static func resolvePermission(
        speech: SFSpeechRecognizerAuthorizationStatus,
        microphoneGranted: Bool
    ) -> Permission {
        guard microphoneGranted, speech == .authorized else { return .denied }
        return .granted
    }

    /// Dictation only runs when the recognizer is usable AND supports
    /// on-device recognition. Anything less is refused outright so audio can
    /// never fall back to a cloud speech service.
    nonisolated static func resolveAvailability(
        recognizerAvailable: Bool,
        supportsOnDeviceRecognition: Bool
    ) -> Availability {
        guard recognizerAvailable, supportsOnDeviceRecognition else { return .unavailable }
        return .available
    }

    /// Folds a new recognition result into the running transcript. On-device
    /// recognition discards `bestTranscription` after pauses, so finalized
    /// segments are appended to an accumulator and the live partial is layered
    /// on top — new speech extends the transcript instead of overwriting it.
    nonisolated static func accumulate(
        finalizedSegments: [String],
        newText: String,
        isFinalizedSegment: Bool
    ) -> (finalizedSegments: [String], currentPartial: String, transcript: String) {
        var segments = finalizedSegments
        let partial: String
        if isFinalizedSegment {
            if !newText.isEmpty { segments.append(newText) }
            partial = ""
        } else {
            partial = newText
        }
        let transcript = (segments + [partial])
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        return (segments, partial, transcript)
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
        let availability = Self.resolveAvailability(
            recognizerAvailable: recognizer?.isAvailable ?? false,
            supportsOnDeviceRecognition: recognizer?.supportsOnDeviceRecognition ?? false
        )
        guard availability == .available else {
            onDeviceUnavailable = true
            return
        }

        // Reset any in-flight task before starting a fresh capture.
        task?.cancel()
        task = nil

        // Configure the session off-main (blocking call), then wire up the
        // engine + recognizer back on the main actor. Activation can transiently
        // fail right after a permission prompt dismisses or while the sheet is
        // still presenting, so retry a few times before giving up.
        sessionQueue.async { [weak self] in
            guard Self.activateRecordingSession() else { return }
            Task { @MainActor in
                self?.startEngineAndRecognition()
            }
        }
    }

    /// Activates the recording audio session, retrying briefly to ride out the
    /// transient failures seen immediately after a permission prompt or during
    /// sheet presentation. Runs off the main thread.
    private nonisolated static func activateRecordingSession(attempts: Int = 4) -> Bool {
        let session = AVAudioSession.sharedInstance()
        for attempt in 0..<attempts {
            do {
                try session.setCategory(.record, mode: .measurement, options: .duckOthers)
                try session.setActive(true, options: .notifyOthersOnDeactivation)
                return true
            } catch {
                if attempt < attempts - 1 {
                    Thread.sleep(forTimeInterval: 0.25)
                }
            }
        }
        return false
    }

    private func startEngineAndRecognition() {
        guard let recognizer else { return }

        // Fresh session: clear any accumulated text from a previous run.
        finalizedSegments = []
        currentPartial = ""
        transcript = ""

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        // Unconditional: start() already refused when on-device recognition is
        // unsupported, so audio can never be routed to a cloud speech service.
        request.requiresOnDeviceRecognition = true
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
                    // `isFinal` marks end-of-stream; per-utterance finalization is
                    // signalled by metadata / a non-zero segment confidence.
                    let isFinalized = result.isFinal
                        || result.speechRecognitionMetadata != nil
                        || (result.bestTranscription.segments.first?.confidence ?? 0) > 0
                    let folded = Self.accumulate(
                        finalizedSegments: self.finalizedSegments,
                        newText: result.bestTranscription.formattedString,
                        isFinalizedSegment: isFinalized
                    )
                    self.finalizedSegments = folded.finalizedSegments
                    self.currentPartial = folded.currentPartial
                    self.transcript = folded.transcript
                }
                if error != nil || (result?.isFinal ?? false) {
                    self.stop()
                }
            }
        }
    }
}
