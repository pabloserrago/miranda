import SwiftUI

enum FeedbackCategory: String, CaseIterable {
    case feature = "Request Feature"
    case problem = "Report a Problem"
}

struct FeedbackView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedCategory: FeedbackCategory = .feature
    @State private var feedbackText: String = ""
    @State private var isSubmitting: Bool = false
    @State private var showError: Bool = false

    var onSuccess: (() -> Void)?

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }

    private var appLanguage: String {
        Locale.current.language.languageCode?.identifier ?? "en"
    }

    private var canSubmit: Bool {
        !feedbackText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSubmitting
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category")
                            .font(AppFont.label)
                            .foregroundColor(Material.Text.secondary)

                        Picker("Category", selection: $selectedCategory) {
                            ForEach(FeedbackCategory.allCases, id: \.self) { category in
                                Text(category.rawValue).tag(category)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Message")
                            .font(AppFont.label)
                            .foregroundColor(Material.Text.secondary)

                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $feedbackText)
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 120)
                                .padding(8)

                            if feedbackText.isEmpty {
                                Text("Describe your feedback...")
                                    .foregroundColor(Material.Text.secondary.opacity(0.5))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 16)
                                    .allowsHitTesting(false)
                            }
                        }
                        .background(Material.Control.fillTertiary)
                        .clipShape(RoundedRectangle(cornerRadius: Material.Shape.control))
                    }

                    Spacer()

                    Text("Reports are anonymous. Only app version (\(appVersion)) and language (\(appLanguage)) are included.")
                        .font(AppFont.caption)
                        .foregroundColor(Material.Text.secondary)
                        .padding(.bottom, 8)

                    Button(action: submitFeedback) {
                        HStack(spacing: 8) {
                            if isSubmitting {
                                ProgressView()
                                    .tint(Material.Text.inverse)
                            }
                            Text(isSubmitting ? "Sending..." : "Submit")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.solid)
                    .disabled(!canSubmit)
                    .opacity(canSubmit ? 1 : 0.4)
                }
                .padding(20)
            }
            .navigationTitle("Submit a Request")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Material.Text.secondary)
                    }
                }
            }
            .alert("Unable to Send", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Something went wrong. Please try again later.")
            }
        }
    }

    private func submitFeedback() {
        let trimmed = feedbackText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isSubmitting = true

        let url = URL(string: "\(Secrets.supabaseURL)/rest/v1/feedback")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Secrets.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(Secrets.supabaseAnonKey)", forHTTPHeaderField: "Authorization")

        let body: [String: String] = [
            "category": selectedCategory.rawValue,
            "message": trimmed,
            "app_version": appVersion,
            "language": appLanguage
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                isSubmitting = false
                if let httpResponse = response as? HTTPURLResponse,
                   (200...299).contains(httpResponse.statusCode) {
                    onSuccess?()
                    dismiss()
                } else {
                    showError = true
                }
            }
        }.resume()
    }
}

#Preview {
    FeedbackView()
}
