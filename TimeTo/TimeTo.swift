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
                    Text(formatTime(Swift.abs(store.remainingSeconds)))
                        .monospacedDigit()
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(store.remainingSeconds < 0 ? Color.red : Color.primary)
                }
            }
        }
        .menuBarExtraStyle(.window)
    }
}
