import Foundation
import Testing
@testable import ios

struct RecentNotesSectionTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private var now: Date {
        calendar.date(from: DateComponents(year: 2026, month: 8, day: 26, hour: 12))!
    }

    private func daysAgo(_ days: Int) -> Date {
        calendar.date(byAdding: .day, value: -days, to: now)!
    }

    @Test func ageBandsUseElapsedCalendarDays() {
        #expect(RecentNotesSection.section(for: daysAgo(0), relativeTo: now, calendar: calendar) == .first30Days)
        #expect(RecentNotesSection.section(for: daysAgo(29), relativeTo: now, calendar: calendar) == .first30Days)
        #expect(RecentNotesSection.section(for: daysAgo(30), relativeTo: now, calendar: calendar) == .previous30Days)
        #expect(RecentNotesSection.section(for: daysAgo(89), relativeTo: now, calendar: calendar) == .previous30Days)
        #expect(RecentNotesSection.section(for: daysAgo(90), relativeTo: now, calendar: calendar) == .previous3Months)
        #expect(RecentNotesSection.section(for: daysAgo(364), relativeTo: now, calendar: calendar) == .previous3Months)
        #expect(RecentNotesSection.section(for: daysAgo(365), relativeTo: now, calendar: calendar) == .previousYears)
    }

    @Test func futureClockSkewStaysInNewestBand() {
        #expect(RecentNotesSection.section(for: daysAgo(-1), relativeTo: now, calendar: calendar) == .first30Days)
    }
}
