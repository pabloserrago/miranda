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
