import SwiftUI

@main
struct TastyCompassApp: App {
    @StateObject private var toastManager = ToastManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .toastContainer(toastManager: toastManager)
                .environmentObject(toastManager)
        }
    }
}
