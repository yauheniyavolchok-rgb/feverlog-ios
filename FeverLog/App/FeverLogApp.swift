import SwiftData
import SwiftUI

@main
struct FeverLogApp: App {
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
