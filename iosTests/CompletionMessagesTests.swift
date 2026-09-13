import Testing
@testable import ios

struct CompletionMessagesTests {
    @Test func messagesAdvanceThroughAllTwentyFivePositions() {
        #expect(CompletionMessages.count == 25)
        for completionCount in 1...25 {
            #expect(CompletionMessages.index(forCompletionCount: completionCount) == completionCount - 1)
        }
    }

    @Test func twentySixthCompletionStartsTheListOver() {
        #expect(CompletionMessages.index(forCompletionCount: 25) == 24)
        #expect(CompletionMessages.index(forCompletionCount: 26) == 0)
        #expect(CompletionMessages.index(forCompletionCount: 51) == 0)
    }
}
