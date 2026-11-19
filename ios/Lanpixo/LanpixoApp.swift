import SwiftUI

@main struct LanpixoApp: App {
    @StateObject private var model = AppModel()
    @Environment(\.scenePhase) private var scenePhase
    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(model)
                .tint(Color(red: 1, green: 0.404, blue: 0.306))
                .preferredColorScheme(model.theme == "dark" ? .dark : model.theme == "light" ? .light : nil)
                .onChange(of: scenePhase) { _, phase in
                    if phase != .active { model.stop(); UIApplication.shared.isIdleTimerDisabled = false }
                }
                .onChange(of: model.busy) { _, active in UIApplication.shared.isIdleTimerDisabled = active }
        }
    }
}
