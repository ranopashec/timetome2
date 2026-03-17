import SwiftUI

@main
struct TimeTomeApp: App {
    @State private var store = AppStore()

    var body: some Scene {
        MenuBarExtra {
            MenuBarContent()
                .environment(store)
        } label: {
            // Access @Observable properties here so SwiftUI tracks changes in App.body
            HStack(spacing: 4) {
                Image(systemName: "timer")
                if store.isTimerActive {
                    Text(store.elapsedLabel)
                        .monospacedDigit()
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(store.elapsedSeconds > store.timerTargetSeconds && store.timerTargetSeconds > 0
                            ? Color.orange : Color.primary)
                }
            }
        }
        .menuBarExtraStyle(.window)
    }
}
