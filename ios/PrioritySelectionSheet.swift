import SwiftUI

struct PrioritySelectionSheet: View {
    let cards: [Card]
    let selectedCardIDs: Set<UUID>
    let onToggle: (Card) -> Void
    let onSelectAll: () -> Void
    let onRemoveAll: () -> Void
    let onClose: () -> Void

    private var priorityCards: [Card] {
        cards.filter { selectedCardIDs.contains($0.id) }
    }

    private var noteCards: [Card] {
        cards.filter { !selectedCardIDs.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Priority") {
                    ForEach(priorityCards) { card in
                        priorityRow(card, isPriority: true)
                    }
                }

                Section("Notes") {
                    ForEach(noteCards) { card in
                        priorityRow(card, isPriority: false)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .overlay {
                if cards.isEmpty {
                    Text("No recent tasks yet")
                        .font(AppFont.body)
                        .foregroundStyle(Material.Text.secondary)
                }
            }
            .navigationTitle("Choose Priorities")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .foregroundStyle(Material.Icon.action)
                    }
                    .accessibilityLabel("Close")
                    .accessibilityIdentifier("close-priority-selection-button")
                }

                ToolbarItemGroup(placement: .bottomBar) {
                    Button("Select All", action: onSelectAll)
                        .disabled(noteCards.isEmpty)
                        .accessibilityIdentifier("select-all-priorities-button")

                    Spacer()

                    Button("Remove All", action: onRemoveAll)
                        .disabled(priorityCards.isEmpty)
                        .accessibilityIdentifier("remove-all-priorities-button")
                }
            }
        }
        .background(Material.Surface.tertiary)
    }

    private func priorityRow(_ card: Card, isPriority: Bool) -> some View {
        Button { onToggle(card) } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isPriority ? Material.Control.fillPrimary : Material.Status.warning)

                    Image(systemName: isPriority ? "minus" : "lightbulb.fill")
                        .font(AppFont.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(isPriority ? Material.Icon.primary : Material.Text.onWarning)
                }
                .frame(width: 28, height: 28)
                .accessibilityHidden(true)

                Text(card.displayTitle)
                    .font(AppFont.body)
                    .foregroundStyle(Material.Text.primary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(card.displayTitle)
        .accessibilityValue(isPriority ? "Priority" : "Not a priority")
        .accessibilityHint(isPriority ? "Double tap to remove priority" : "Double tap to make priority")
        .accessibilityIdentifier("priority-selection-\(card.id.uuidString)")
        .cardSurface([Material.Surface.secondary], shadow: false, glass: false)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
    }
}
