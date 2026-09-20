import SwiftData
import SwiftUI

@main
struct FeverLogApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    private let persistenceController: PersistenceController

    init() {
        #if DEBUG
        UITestSupport.resetStateIfRequested()
        #endif
        persistenceController = .production()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(persistenceController.container)
    }
}
