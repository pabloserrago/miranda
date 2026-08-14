import Foundation

/// Hand-rolled PostgREST access — no SDK, no SPM dependency.
///
/// The app only ever inserts into two tables: `analytics` (anonymous event
/// upload) and `feedback` (user-submitted requests). Note content is never
/// sent anywhere. Every request funnels through `insertRequest`, which is the
/// single place the `Secrets.supabaseEnabled` master switch is honoured.
enum Supabase {

    static let requestTimeout: TimeInterval = 15

    /// Builds an insert request for `table`, or `nil` when the backend is
    /// disabled, the configuration is unusable, or `body` is not JSON.
    /// Callers treat `nil` as "do not send".
    static func insertRequest(
        table: String,
        body: [String: Any],
        enabled: Bool = Secrets.supabaseEnabled,
        baseURL: String = Secrets.supabaseURL,
        anonKey: String = Secrets.supabaseAnonKey
    ) -> URLRequest? {
        guard enabled, !anonKey.isEmpty else { return nil }

        let trimmedBase = baseURL.hasSuffix("/") ? String(baseURL.dropLast()) : baseURL
        guard let url = URL(string: "\(trimmedBase)/rest/v1/\(table)"),
              url.scheme != nil,
              url.host != nil else { return nil }

        guard JSONSerialization.isValidJSONObject(body),
              let data = try? JSONSerialization.data(withJSONObject: body) else { return nil }

        var request = URLRequest(url: url, timeoutInterval: requestTimeout)
        request.httpMethod = "POST"
        request.httpBody = data
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        // Suppress the echoed row: the anon role has insert-only access.
        request.setValue("return=minimal", forHTTPHeaderField: "Prefer")
        return request
    }
}
