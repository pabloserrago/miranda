import Foundation

/// Short completion messages shown in a fixed, repeating order.
enum CompletionMessages {
    static let count = 25

    static func index(forCompletionCount completionCount: Int) -> Int {
        let zeroBasedCompletion = max(completionCount, 1) - 1
        return zeroBasedCompletion % count
    }

    static func message(forCompletionCount completionCount: Int) -> String {
        switch index(forCompletionCount: completionCount) {
        case 0:  return String(localized: "completion.message.01", defaultValue: "That’s one thing done.")
        case 1:  return String(localized: "completion.message.02", defaultValue: "Done. On to next.")
        case 2:  return String(localized: "completion.message.03", defaultValue: "One less thing today.")
        case 3:  return String(localized: "completion.message.04", defaultValue: "You finished the priority.")
        case 4:  return String(localized: "completion.message.05", defaultValue: "That’s taken care of.")
        case 5:  return String(localized: "completion.message.06", defaultValue: "Good. That one’s done.")
        case 6:  return String(localized: "completion.message.07", defaultValue: "One thing off your mind.")
        case 7:  return String(localized: "completion.message.08", defaultValue: "You got it done.")
        case 8:  return String(localized: "completion.message.09", defaultValue: "That can be closed.")
        case 9:  return String(localized: "completion.message.10", defaultValue: "It’s done for today.")
        case 10: return String(localized: "completion.message.11", defaultValue: "Nice. Keep moving forward.")
        case 11: return String(localized: "completion.message.12", defaultValue: "You followed that through.")
        case 12: return String(localized: "completion.message.13", defaultValue: "A solid piece of progress.")
        case 13: return String(localized: "completion.message.14", defaultValue: "That’s no longer pending.")
        case 14: return String(localized: "completion.message.15", defaultValue: "Finished and out of mind.")
        case 15: return String(localized: "completion.message.16", defaultValue: "One priority successfully completed.")
        case 16: return String(localized: "completion.message.17", defaultValue: "Another task behind you.")
        case 17: return String(localized: "completion.message.18", defaultValue: "You can let that go.")
        case 18: return String(localized: "completion.message.19", defaultValue: "That’s handled. Take a breath.")
        case 19: return String(localized: "completion.message.20", defaultValue: "Progress, one thing at a time.")
        case 20: return String(localized: "completion.message.21", defaultValue: "That one is complete.")
        case 21: return String(localized: "completion.message.22", defaultValue: "You stayed with it.")
        case 22: return String(localized: "completion.message.23", defaultValue: "All done. Carry on.")
        case 23: return String(localized: "completion.message.24", defaultValue: "Marked done and cleared.")
        default: return String(localized: "completion.message.25", defaultValue: "You moved things forward today.")
        }
    }
}
