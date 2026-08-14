import Foundation
import Testing
@testable import ios

// MARK: - insertRequest

struct SupabaseInsertRequestTests {

    private let baseURL = "https://example.supabase.co"
    private let anonKey = "anon-key"

    @Test func insertRequestIsNilWhenDisabled() {
        let request = Supabase.insertRequest(
            table: "analytics",
            body: ["event": "app_opened"],
            enabled: false,
            baseURL: baseURL,
            anonKey: anonKey)

        #expect(request == nil)
    }

    @Test func insertRequestSetsHeadersAndPath() throws {
        let request = try #require(Supabase.insertRequest(
            table: "feedback",
            body: ["message": "hello"],
            enabled: true,
            baseURL: baseURL,
            anonKey: anonKey))

        #expect(request.url?.absoluteString == "https://example.supabase.co/rest/v1/feedback")
        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "apikey") == anonKey)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer \(anonKey)")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
        // Without return=minimal PostgREST echoes the inserted row, which the
        // anon role has no SELECT policy for.
        #expect(request.value(forHTTPHeaderField: "Prefer") == "return=minimal")
        #expect(request.timeoutInterval == Supabase.requestTimeout)
    }

    @Test func insertRequestEncodesBodyAsJSON() throws {
        let request = try #require(Supabase.insertRequest(
            table: "analytics",
            body: ["event": "card_created", "app_version": "1.0"],
            enabled: true,
            baseURL: baseURL,
            anonKey: anonKey))

        let data = try #require(request.httpBody)
        let decoded = try #require(
            JSONSerialization.jsonObject(with: data) as? [String: Any])

        #expect(decoded["event"] as? String == "card_created")
        #expect(decoded["app_version"] as? String == "1.0")
    }

    @Test func insertRequestTrimsTrailingSlashFromBaseURL() throws {
        let request = try #require(Supabase.insertRequest(
            table: "analytics",
            body: ["event": "app_opened"],
            enabled: true,
            baseURL: "https://example.supabase.co/",
            anonKey: anonKey))

        #expect(request.url?.absoluteString == "https://example.supabase.co/rest/v1/analytics")
    }

    @Test func insertRequestIsNilWhenBaseURLIsEmpty() {
        // ci_post_clone.sh emits empty strings when the CI secrets are unset.
        let request = Supabase.insertRequest(
            table: "analytics",
            body: ["event": "app_opened"],
            enabled: true,
            baseURL: "",
            anonKey: anonKey)

        #expect(request == nil)
    }

    @Test func insertRequestIsNilWhenBaseURLHasNoScheme() {
        let request = Supabase.insertRequest(
            table: "analytics",
            body: ["event": "app_opened"],
            enabled: true,
            baseURL: "example.supabase.co",
            anonKey: anonKey)

        #expect(request == nil)
    }

    @Test func insertRequestIsNilWhenAnonKeyIsEmpty() {
        let request = Supabase.insertRequest(
            table: "analytics",
            body: ["event": "app_opened"],
            enabled: true,
            baseURL: baseURL,
            anonKey: "")

        #expect(request == nil)
    }

    @Test func insertRequestIsNilWhenBodyIsNotSerializable() {
        let request = Supabase.insertRequest(
            table: "analytics",
            body: ["timestamp": Date()],
            enabled: true,
            baseURL: baseURL,
            anonKey: anonKey)

        #expect(request == nil)
    }
}

// MARK: - Analytics property coercion

struct AnalyticsJSONSafePropertiesTests {

    @Test func analyticsPropertiesAreJSONSafe() {
        let safe = Analytics.jsonSafeProperties([
            "has_emoji": true,
            "hour_of_day": 14,
            "ratio": 0.5,
            "day_of_week": "Friday",
        ])

        #expect(safe["has_emoji"] as? Bool == true)
        #expect(safe["hour_of_day"] as? Int == 14)
        #expect(safe["ratio"] as? Double == 0.5)
        #expect(safe["day_of_week"] as? String == "Friday")
        #expect(JSONSerialization.isValidJSONObject(safe))
    }

    @Test func unsupportedPropertyValuesAreStringified() {
        let safe = Analytics.jsonSafeProperties(["when": Date(timeIntervalSince1970: 0)])

        #expect(safe["when"] is String)
        #expect(JSONSerialization.isValidJSONObject(safe))
    }

    @Test func emptyPropertiesStayEmpty() {
        #expect(Analytics.jsonSafeProperties([:]).isEmpty)
    }
}
