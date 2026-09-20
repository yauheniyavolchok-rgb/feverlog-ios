import SwiftUI

extension View {
    /// Standard bottom-sheet presentation used across FeverLog (e.g. Quick
    /// Add). Always shows a drag indicator and defaults to medium/large
    /// detents so content remains reachable with one hand.
    func feverBottomSheet<Content: View>(
        isPresented: Binding<Bool>,
        detents: Set<PresentationDetent> = [.medium, .large],
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        sheet(isPresented: isPresented) {
            content()
                .presentationDetents(detents)
                .presentationDragIndicator(.visible)
        }
    }
}
