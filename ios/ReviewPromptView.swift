import SwiftUI
import StoreKit

struct ReviewPromptView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.requestReview) private var requestReview

    @State private var step: Step = .sentiment
    @State private var showFeedback = false

    private enum Step { case sentiment, thankYou }

    var body: some View {
        VStack(spacing: 0) {
            if step == .sentiment {
                sentimentContent
                    .transition(.asymmetric(
                        insertion: .opacity,
                        removal: .opacity.combined(with: .move(edge: .leading))
                    ))
            } else {
                thankYouContent
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .trailing)),
                        removal: .opacity
                    ))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: step)
        .padding(.horizontal, 28)
        .padding(.vertical, 36)
        .frame(maxWidth: .infinity)
        .presentationDetents([.height(380)])
        .presentationDragIndicator(.visible)
        .presentationBackground(Material.Surface.secondary)
        .sheet(isPresented: $showFeedback, onDismiss: { dismiss() }) {
            FeedbackView()
                .presentationBackground(Material.Surface.secondary)
        }
    }

    // MARK: - Step 1: Sentiment

    private var sentimentContent: some View {
        VStack(spacing: 24) {
            Text("🐢")
                .font(.system(size: 52))

            VStack(spacing: 8) {
                Text("Are you enjoying the app?")
                    .font(AppFont.headline)
                    .foregroundColor(Material.Text.primary)
                    .multilineTextAlignment(.center)

                Text("Your feedback helps us improve.")
                    .font(AppFont.caption)
                    .foregroundColor(Material.Text.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                Button {
                    Analytics.shared.trackReviewSentimentPositive()
                    withAnimation { step = .thankYou }
                } label: {
                    Text("Yes, love it")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.solid)

                Button {
                    Analytics.shared.trackReviewSentimentNegative()
                    showFeedback = true
                } label: {
                    Text("Not really")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.ghost)
            }
        }
    }

    // MARK: - Step 2: Thank you → native review

    private var thankYouContent: some View {
        VStack(spacing: 24) {
            Text("🌟")
                .font(.system(size: 52))

            VStack(spacing: 8) {
                Text("Glad to hear it!")
                    .font(AppFont.headline)
                    .foregroundColor(Material.Text.primary)

                Text("A rating on the App Store helps others discover the app.")
                    .font(AppFont.body)
                    .foregroundColor(Material.Text.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                Button {
                    ReviewManager.shared.recordUserRated()
                    requestReview()
                    dismiss()
                } label: {
                    Text("Rate the App")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.solid)

                Button { dismiss() } label: {
                    Text("Maybe later")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.ghost)
            }
        }
    }
}

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            ReviewPromptView()
        }
}
