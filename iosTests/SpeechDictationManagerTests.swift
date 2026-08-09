import Foundation
import Speech
import Testing
@testable import ios

// MARK: - Permission resolution

struct SpeechDictationPermissionTests {

    @Test func grantedRequiresBothMicAndSpeech() {
        let result = SpeechDictationManager.resolvePermission(
            speech: .authorized,
            microphoneGranted: true
        )
        #expect(result == .granted)
    }

    @Test func deniedWhenMicrophoneDenied() {
        let result = SpeechDictationManager.resolvePermission(
            speech: .authorized,
            microphoneGranted: false
        )
        #expect(result == .denied)
    }

    @Test func deniedWhenSpeechNotAuthorized() {
        for status: SFSpeechRecognizerAuthorizationStatus in [.denied, .restricted, .notDetermined] {
            let result = SpeechDictationManager.resolvePermission(
                speech: status,
                microphoneGranted: true
            )
            #expect(result == .denied)
        }
    }
}

// MARK: - On-device availability

struct SpeechDictationAvailabilityTests {

    @Test func availableWhenRecognizerReadyAndSupportsOnDevice() {
        let result = SpeechDictationManager.resolveAvailability(
            recognizerAvailable: true,
            supportsOnDeviceRecognition: true
        )
        #expect(result == .available)
    }

    @Test func unavailableWhenRecognizerNotAvailable() {
        let result = SpeechDictationManager.resolveAvailability(
            recognizerAvailable: false,
            supportsOnDeviceRecognition: true
        )
        #expect(result == .unavailable)
    }

    @Test func unavailableWhenOnDeviceRecognitionUnsupported() {
        // Privacy commitment: audio must never leave the device, so dictation
        // is refused entirely rather than falling back to cloud recognition.
        let result = SpeechDictationManager.resolveAvailability(
            recognizerAvailable: true,
            supportsOnDeviceRecognition: false
        )
        #expect(result == .unavailable)
    }

    @Test func unavailableWhenBothConditionsFail() {
        let result = SpeechDictationManager.resolveAvailability(
            recognizerAvailable: false,
            supportsOnDeviceRecognition: false
        )
        #expect(result == .unavailable)
    }
}

// MARK: - Transcript composition

struct SpeechDictationComposeTests {

    @Test func transcriptReplacesEmptyBase() {
        let result = SpeechDictationManager.compose(base: "", transcript: "buy milk")
        #expect(result == "buy milk")
    }

    @Test func transcriptReplacesWhitespaceOnlyBase() {
        let result = SpeechDictationManager.compose(base: "   \n ", transcript: "buy milk")
        #expect(result == "buy milk")
    }

    @Test func transcriptAppendsToExistingBaseWithSeparator() {
        let result = SpeechDictationManager.compose(base: "call mom", transcript: "and dad")
        #expect(result == "call mom and dad")
    }

    @Test func emptyTranscriptKeepsBaseUnchanged() {
        let result = SpeechDictationManager.compose(base: "call mom", transcript: "")
        #expect(result == "call mom")
    }
}

// MARK: - Segment accumulation (pause/reset workaround)

struct SpeechDictationAccumulateTests {

    @Test func growingPartialsReplaceCurrentPartial() {
        var segments: [String] = []
        var transcript = ""

        for partial in ["buy", "buy milk", "buy milk and"] {
            let folded = SpeechDictationManager.accumulate(
                finalizedSegments: segments,
                newText: partial,
                isFinalizedSegment: false
            )
            segments = folded.finalizedSegments
            transcript = folded.transcript
        }

        #expect(segments.isEmpty)
        #expect(transcript == "buy milk and")
    }

    @Test func finalizedSegmentIsCommittedAndNextUtteranceAppends() {
        // First utterance grows, then finalizes.
        var folded = SpeechDictationManager.accumulate(
            finalizedSegments: [],
            newText: "buy milk",
            isFinalizedSegment: false
        )
        folded = SpeechDictationManager.accumulate(
            finalizedSegments: folded.finalizedSegments,
            newText: "buy milk",
            isFinalizedSegment: true
        )
        #expect(folded.finalizedSegments == ["buy milk"])
        #expect(folded.transcript == "buy milk")

        // After a pause the recognizer resets bestTranscription to the new
        // utterance only — it must append, not overwrite (the reported bug).
        folded = SpeechDictationManager.accumulate(
            finalizedSegments: folded.finalizedSegments,
            newText: "and eggs",
            isFinalizedSegment: false
        )
        #expect(folded.transcript == "buy milk and eggs")

        folded = SpeechDictationManager.accumulate(
            finalizedSegments: folded.finalizedSegments,
            newText: "and eggs",
            isFinalizedSegment: true
        )
        #expect(folded.finalizedSegments == ["buy milk", "and eggs"])
        #expect(folded.transcript == "buy milk and eggs")
    }

    @Test func emptyFinalizedResultDoesNotDropCapturedText() {
        // Blank final callback (a known on-device quirk) must keep prior text.
        let folded = SpeechDictationManager.accumulate(
            finalizedSegments: ["buy milk"],
            newText: "",
            isFinalizedSegment: true
        )
        #expect(folded.finalizedSegments == ["buy milk"])
        #expect(folded.transcript == "buy milk")
    }
}
