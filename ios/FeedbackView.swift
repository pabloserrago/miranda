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
        NavigationView {
            VStack(spacing: 0) {
                VStack(spacing: 20) {
                    // Category picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 10) {
                            ForEach(FeedbackCategory.allCases, id: \.self) { category in
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedCategory = category
                                    }
                                }) {
                                    Text(category.rawValue)
                                        .font(.system(size: 14, weight: .medium))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .frame(maxWidth: .infinity)
                                        .background(
                                            selectedCategory == category
                                                ? Color.primary
                                                : Color(uiColor: .tertiarySystemFill)
                                        )
                                        .foregroundColor(
                                            selectedCategory == category
                                                ? Color(uiColor: .systemBackground)
                                                : .primary
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    // Message field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Message")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        TextEditor(text: $feedbackText)
                            .frame(minHeight: 120)
                            .padding(8)
                            .background(Color(uiColor: .tertiarySystemFill))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                Group {
                                    if feedbackText.isEmpty {
                                        Text("Describe your feedback...")
                                            .foregroundColor(.secondary.opacity(0.5))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 16)
                                            .allowsHitTesting(false)
                                    }
                                },
                                alignment: .topLeading
                            )
                    }
                    
                    Spacer()
                    
                    // Privacy notice
                    Text("Reports are anonymous. Only app version (\(appVersion)) and language (\(appLanguage)) are included.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .padding(.bottom, 8)
                    
                    // Submit button
                    Button(action: submitFeedback) {
                        HStack(spacing: 8) {
                            if isSubmitting {
                                ProgressView()
                                    .tint(Color(uiColor: .systemBackground))
                            }
                            Text(isSubmitting ? "Sending..." : "Submit")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(canSubmit ? Color.primary : Color(uiColor: .tertiarySystemFill))
                        .foregroundColor(canSubmit ? Color(uiColor: .systemBackground) : .secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(!canSubmit)
                }
                .padding(20)
            }
            .navigationTitle("Submit a Request")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
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
        
        let url = URL(string: "https://umlqnctceqhcxkklpplc.supabase.co/rest/v1/feedback")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVtbHFuY3RjZXFoY3hra2xwcGxjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE4MDA1MTksImV4cCI6MjA4NzM3NjUxOX0.8HHTP7xQ2Aaf_LdsdoWEE0B8MKXr_St1kMx0z6CIBVw", forHTTPHeaderField: "apikey")
        request.setValue("Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVtbHFuY3RjZXFoY3hra2xwcGxjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE4MDA1MTksImV4cCI6MjA4NzM3NjUxOX0.8HHTP7xQ2Aaf_LdsdoWEE0B8MKXr_St1kMx0z6CIBVw", forHTTPHeaderField: "Authorization")
        
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
