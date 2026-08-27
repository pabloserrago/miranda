import Foundation
import Testing
@testable import ios

struct CalendarEventDraftTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    @Test func mapsFirstLineToTitleAndRemainingLinesToNotes() throws {
        let now = try #require(calendar.date(from: DateComponents(
            year: 2026, month: 8, day: 26, hour: 17, minute: 58
        )))

        let draft = CalendarEventDraft(
            noteText: "Project sync\nDiscuss milestones\n\nAssign owners",
            now: now,
            calendar: calendar
        )

        #expect(draft.title == "Project sync")
        #expect(draft.notes == "Discuss milestones\n\nAssign owners")
    }

    @Test func defaultsToNextFullHourForOneHour() throws {
        let now = try #require(calendar.date(from: DateComponents(
            year: 2026, month: 8, day: 26, hour: 17, minute: 58
        )))
        let expectedStart = try #require(calendar.date(from: DateComponents(
            year: 2026, month: 8, day: 26, hour: 18
        )))
        let expectedEnd = try #require(calendar.date(from: DateComponents(
            year: 2026, month: 8, day: 26, hour: 19
        )))

        let draft = CalendarEventDraft(noteText: "Project sync", now: now, calendar: calendar)

        #expect(draft.startDate == expectedStart)
        #expect(draft.endDate == expectedEnd)
        #expect(draft.notes == nil)
    }

    @Test func mapsFirstDetectedLinkToEventURL() {
        let draft = CalendarEventDraft(
            noteText: "Project sync\nAgenda: example.com/agenda\nBackup: https://example.org"
        )

        #expect(draft.url == URL(string: "http://example.com/agenda"))
    }
}
