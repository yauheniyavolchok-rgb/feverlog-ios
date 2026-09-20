import Foundation

/// Tracks whether the currently visible screen allows landscape. The rest of
/// the app is portrait-only per the spec ("landscape support for charts
/// only") — `ChartsScreen` flips this on `.onAppear`/`.onDisappear`, and
/// `AppDelegate.application(_:supportedInterfaceOrientationsFor:)` reads it.
@MainActor
enum OrientationManager {
    static var allowsLandscape = false
}
