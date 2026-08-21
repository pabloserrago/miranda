import Foundation
import Testing
import UIKit
@testable import ios

/// The widget background shifts with the clock: a warm sunrise, a neutral
/// working stretch and a cool sunset, each eight hours long.
struct DayPhaseTests {

    private func date(hour: Int, minute: Int = 0) -> Date {
        Calendar.current.date(from: DateComponents(
            year: 2026, month: 8, day: 18, hour: hour, minute: minute
        ))!
    }

    @Test func phaseBoundaries() {
        let expected: [(hour: Int, minute: Int, phase: DayPhase)] = [
            (0, 0, .sunset),
            (5, 59, .sunset),
            (6, 0, .sunrise),
            (13, 59, .sunrise),
            (14, 0, .working),
            (21, 59, .working),
            (22, 0, .sunset),
            (23, 59, .sunset),
        ]
        for expectation in expected {
            let when = date(hour: expectation.hour, minute: expectation.minute)
            #expect(DayPhase.phase(at: when) == expectation.phase,
                    "\(expectation.hour):\(expectation.minute) should be \(expectation.phase)")
        }
    }

    @Test func everyHourResolvesToAPhase() {
        // Each phase owns exactly 8 of the 24 hours.
        var counts: [DayPhase: Int] = [:]
        for hour in 0..<24 {
            counts[DayPhase.phase(at: date(hour: hour)), default: 0] += 1
        }
        #expect(counts[.sunrise] == 8)
        #expect(counts[.working] == 8)
        #expect(counts[.sunset] == 8)
    }

    // MARK: - Tint blending

    @Test func tintBlending() {
        let base = UIColor(red: 0.2, green: 0.4, blue: 0.6, alpha: 1)
        let tint = UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1)

        #expect(components(DayPhase.blend(base, toward: tint, amount: 0)).matches(components(base)))
        #expect(components(DayPhase.blend(base, toward: tint, amount: 1)).matches(components(tint)))

        let half = components(DayPhase.blend(base, toward: tint, amount: 0.5))
        #expect(abs(half.r - 0.6) < 0.001)
        #expect(abs(half.g - 0.6) < 0.001)
        #expect(abs(half.b - 0.3) < 0.001)
    }

    @Test func blendedChannelsStayInRange() {
        let base = UIColor(red: 0.05, green: 0.5, blue: 0.95, alpha: 1)
        let tint = UIColor(red: 0.9, green: 0.1, blue: 0.4, alpha: 1)
        for step in 0...10 {
            let c = components(DayPhase.blend(base, toward: tint, amount: CGFloat(step) / 10))
            #expect((0...1).contains(c.r) && (0...1).contains(c.g) && (0...1).contains(c.b))
        }
    }

    /// The working stretch is the untinted reference, so its stops must come
    /// back as the theme authored them.
    @Test func workingPhaseLeavesStopsUntinted() {
        let noon = date(hour: 18)  // working-phase anchor
        for theme in BackgroundTheme.allCases where theme != .standard {
            for (index, stop) in theme.cloudStops.enumerated() {
                let tinted = DayPhase.tinted(stop, at: noon)
                #expect(components(tinted.light).matches(components(stop.light)),
                        "\(theme) stop \(index) light should be untinted at the working anchor")
                #expect(components(tinted.dark).matches(components(stop.dark)),
                        "\(theme) stop \(index) dark should be untinted at the working anchor")
            }
        }
    }

    /// Sunrise and sunset pull in opposite directions, so their results must
    /// differ from each other and from the untinted stop.
    @Test func phasesProduceDistinctStops() {
        for theme in BackgroundTheme.allCases where theme != .standard {
            for stop in theme.cloudStops {
                let warm = components(DayPhase.tinted(stop, at: date(hour: 10)).light)
                let neutral = components(DayPhase.tinted(stop, at: date(hour: 18)).light)
                let cool = components(DayPhase.tinted(stop, at: date(hour: 2)).light)
                #expect(!warm.matches(neutral), "\(theme) sunrise should differ from working")
                #expect(!cool.matches(neutral), "\(theme) sunset should differ from working")
                #expect(!warm.matches(cool), "\(theme) sunrise should differ from sunset")
            }
        }
    }

    // MARK: - Per-theme stops

    @Test func phaseStopsPerTheme() {
        for hour in [2, 6, 10, 14, 18, 22] {
            let when = date(hour: hour)
            #expect(BackgroundTheme.standard.cloudStops.isEmpty)
            #expect(BackgroundTheme.standard.widgetMeshColors(at: when).isEmpty)
            for theme in BackgroundTheme.allCases where theme != .standard {
                #expect(theme.cloudStops.count == 3, "\(theme) must supply 3 raw stops")
                #expect(theme.cloudColors(at: when).count == 3,
                        "\(theme) must supply 3 stops at \(hour):00")
                #expect(theme.widgetMeshColors(at: when).count == 9,
                        "\(theme) must supply 9 mesh colors at \(hour):00")
            }
        }
    }

    /// The untinted `cloudColors` still drives the app's shader, so the raw
    /// pairs must stay in step with it.
    @Test func rawStopsMatchCloudColors() {
        for theme in BackgroundTheme.allCases {
            #expect(theme.cloudStops.count == theme.cloudColors.count)
        }
    }

    // MARK: - Timeline schedule

    @Test func entryDatesCoverADay() {
        let start = date(hour: 9, minute: 7)
        let dates = DayPhase.entryDates(from: start)

        #expect(dates.first == start)
        #expect(dates.count == 48, "30-minute steps across 24 hours")
        #expect(zip(dates, dates.dropFirst()).allSatisfy { $0 < $1 },
                "entry dates must strictly increase")

        let span = dates.last!.timeIntervalSince(start)
        #expect(span == 23.5 * 3600, "the last entry lands half an hour short of a full day")

        // The schedule has to be fine enough to catch every phase change.
        let phases = Set(dates.map { DayPhase.phase(at: $0) })
        #expect(phases.count == 3, "a day of entries should pass through all three phases")
    }
}

// MARK: - Helpers

private struct RGB {
    let r: CGFloat, g: CGFloat, b: CGFloat

    /// Channel-wise comparison with a tolerance, since blending is float math.
    func matches(_ other: RGB) -> Bool {
        abs(r - other.r) < 0.001 && abs(g - other.g) < 0.001 && abs(b - other.b) < 0.001
    }
}

private func components(_ color: UIColor) -> RGB {
    var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
    color.getRed(&r, green: &g, blue: &b, alpha: &a)
    return RGB(r: r, g: g, b: b)
}
