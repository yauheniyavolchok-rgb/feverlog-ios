import UIKit

/// The app is portrait-only everywhere except the Charts screen, which
/// toggles `OrientationManager.allowsLandscape` while it's on screen.
final class AppDelegate: NSObject, UIApplicationDelegate {
    @MainActor
    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        OrientationManager.allowsLandscape ? .allButUpsideDown : .portrait
    }
}
