import EventKit
import EventKitUI
import SwiftUI

/// The note fields and default timing used to seed Apple's event editor.
struct CalendarEventDraft: Equatable {
    let title: String
    let notes: String?
    let url: URL?
    let startDate: Date
    let endDate: Date

    init(noteText: String, now: Date = .now, calendar: Calendar = .current) {
        let content = NotePreviewContent(text: noteText)
        title = content.title
        notes = content.paragraphs.isEmpty ? nil : content.paragraphs.joined(separator: "\n\n")
        url = NoteTextStyler.linkMatches(in: noteText).first?.url

        let nextHour = calendar.dateInterval(of: .hour, for: now)?.end
            ?? calendar.date(byAdding: .hour, value: 1, to: now)
            ?? now
        startDate = nextHour
        endDate = calendar.date(byAdding: .hour, value: 1, to: nextHour) ?? nextHour
    }
}

/// Owns the event store that was authorized for this edit session.
struct CalendarEventEditRequest: Identifiable {
    let id = UUID()
    let eventStore: EKEventStore
    let draft: CalendarEventDraft
}

/// SwiftUI bridge for Apple's standard create-event screen.
struct CalendarEventComposer: UIViewControllerRepresentable {
    let request: CalendarEventEditRequest
    let onDismiss: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onDismiss: onDismiss)
    }

    func makeUIViewController(context: Context) -> EKEventEditViewController {
        let event = EKEvent(eventStore: request.eventStore)
        event.title = request.draft.title
        event.notes = request.draft.notes
        event.url = request.draft.url
        event.startDate = request.draft.startDate
        event.endDate = request.draft.endDate
        event.calendar = request.eventStore.defaultCalendarForNewEvents

        let controller = EKEventEditViewController()
        controller.eventStore = request.eventStore
        controller.event = event
        controller.editViewDelegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: EKEventEditViewController, context: Context) { }

    final class Coordinator: NSObject, EKEventEditViewDelegate {
        private let onDismiss: () -> Void

        init(onDismiss: @escaping () -> Void) {
            self.onDismiss = onDismiss
        }

        func eventEditViewController(
            _ controller: EKEventEditViewController,
            didCompleteWith action: EKEventEditViewAction
        ) {
            onDismiss()
        }
    }
}
