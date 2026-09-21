import SwiftUI

struct ChildrenSettingsScreen: View {
    @Environment(ChildStore.self) private var childStore
    @Environment(\.feverPalette) private var palette

    @State private var showingAddChild = false
    @State private var editingChild: Child?
    @State private var pendingDeleteChild: Child?

    var body: some View {
        Group {
            if childStore.children.isEmpty {
                EmptyStateView(
                    systemImage: "person.2",
                    title: L10n.ChildrenSettings.emptyTitle,
                    message: L10n.ChildrenSettings.emptyMessage
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(palette.background)
            } else {
                List {
                    ForEach(childStore.children) { child in
                        childRow(child)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    pendingDeleteChild = child
                                } label: {
                                    Label(L10n.ChildProfile.deleteButton, systemImage: "trash")
                                }
                            }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle(L10n.ChildrenSettings.title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddChild = true
                } label: {
                    Image(systemName: Icon.add)
                }
                .accessibilityLabel(L10n.ChildrenSettings.addButton)
                .accessibilityIdentifier("childrenSettings.addButton")
            }
        }
        .navigationDestination(isPresented: $showingAddChild) {
            ChildFormScreen()
        }
        .navigationDestination(item: $editingChild) { child in
            ChildFormScreen(existingChild: child)
        }
        .confirmationDialog(
            L10n.ChildProfile.deleteConfirmTitle,
            isPresented: Binding(get: { pendingDeleteChild != nil }, set: { if !$0 { pendingDeleteChild = nil } }),
            titleVisibility: .visible
        ) {
            Button(L10n.ChildProfile.deleteConfirmConfirm, role: .destructive) {
                if let pendingDeleteChild {
                    try? childStore.softDelete(pendingDeleteChild)
                }
                pendingDeleteChild = nil
            }
            Button(L10n.ChildProfile.deleteConfirmCancel, role: .cancel) { pendingDeleteChild = nil }
        } message: {
            Text(L10n.ChildProfile.deleteConfirmMessage)
        }
    }

    private func childRow(_ child: Child) -> some View {
        HStack(spacing: Spacing.sm) {
            let avatarColor = ChildAvatarColorOption(rawValue: child.avatarColorIdentifier) ?? .mint
            Image(systemName: ChildAvatarOption(rawValue: child.avatarIdentifier)?.rawValue ?? "star.fill")
                .foregroundStyle(avatarColor.color(in: palette))
                .frame(width: Spacing.xl, height: Spacing.xl)
                .background(avatarColor.color(in: palette).opacity(0.3))
                .clipShape(Circle())
                .accessibilityHidden(true)
            Text(child.name)
                .font(Typography.body.weight(.semibold))
                .foregroundStyle(palette.primaryText)
            Spacer()
        }
        .padding(.vertical, Spacing.xs)
        .contentShape(Rectangle())
        .onTapGesture { editingChild = child }
        .accessibilityIdentifier("childrenSettings.row.\(child.id)")
    }
}

#Preview {
    NavigationStack { ChildrenSettingsScreen() }
        .environment(ChildStore())
        .feverThemed()
}
