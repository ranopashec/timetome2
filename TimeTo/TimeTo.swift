import SwiftUI
import AppKit

@main
struct TimeTomeApp: App {
    @State private var store: AppStore
    private let statusController: StatusBarController

    init() {
        let store = AppStore()
        _store = State(initialValue: store)
        statusController = StatusBarController(store: store)
    }

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

private struct SettingsView: View {
    @Environment(AppStore.self) private var store
    let onImport: () -> Void
    let onExport: () -> Void
    let onRevealDataFile: () -> Void

    private var dataFileSummary: String {
        let components = DataStore.shared.fileURL.pathComponents.suffix(3)
        return components.joined(separator: "/")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Settings")
                    .font(.title2.weight(.semibold))

                Text("Manage backups and quickly jump to the app data location.")
                    .foregroundStyle(.secondary)
            }

            GroupBox {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Backups")
                            .font(.headline)
                        Text("Import or export the app's JSON backup file.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 12)

                    HStack(spacing: 10) {
                        Button("Import…", action: onImport)
                            .buttonStyle(.bordered)

                        Button("Export…", action: onExport)
                            .buttonStyle(.borderedProminent)
                    }
                }
                .padding(14)
            }

            GroupBox {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Data file")
                                .font(.headline)
                            Text(dataFileSummary)
                                .font(.callout.monospaced())
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .help(DataStore.shared.fileURL.path)
                        }

                        Spacer(minLength: 12)

                        Button("Reveal in Finder", action: onRevealDataFile)
                            .buttonStyle(.bordered)
                    }

                    Text("Full path: \(DataStore.shared.fileURL.path)")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(2)
                        .truncationMode(.middle)
                        .textSelection(.enabled)
                }
                .padding(14)
            }

            if let activeGoal = store.activeGoal {
                Label("Current goal: \(activeGoal.name)", systemImage: "timer")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(24)
        .frame(width: 520, height: 300, alignment: .topLeading)
    }
}

@MainActor
private final class StatusBarController: NSObject {
    private let store: AppStore
    private let statusItem: NSStatusItem
    private let popover = NSPopover()
    private let contextMenu = NSMenu()
    private let settingsWindowController: SettingsWindowController
    private var refreshTimer: Timer?

    init(store: AppStore) {
        self.store = store
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        settingsWindowController = SettingsWindowController(
            store: store,
            onImport: { },
            onExport: { },
            onRevealDataFile: { }
        )
        super.init()
        settingsWindowController.updateActions(
            onImport: { [weak self] in self?.importBackup() },
            onExport: { [weak self] in self?.exportBackup() },
            onRevealDataFile: { [weak self] in self?.revealDataFile() }
        )
        configureStatusItem()
        configurePopover()
        configureMenu()
        configureRefreshTimer()
        updateStatusItem()
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else { return }
        button.target = self
        button.action = #selector(handleStatusItemClick(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        let image = NSImage(systemSymbolName: "timer", accessibilityDescription: "TimeTo")
        image?.isTemplate = true
        button.image = image
        button.imagePosition = .imageLeading
    }

    private func configurePopover() {
        popover.behavior = .transient
        popover.animates = true
        popover.contentSize = NSSize(width: 360, height: 500)
        popover.contentViewController = NSHostingController(
            rootView: MenuBarContent()
                .environment(store)
        )
    }

    private func configureMenu() {
        let settingsItem = NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        contextMenu.addItem(settingsItem)

        contextMenu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        contextMenu.addItem(quitItem)
    }

    private func configureRefreshTimer() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.updateStatusItem()
            }
        }
    }

    private func updateStatusItem() {
        guard let button = statusItem.button else { return }
        let title = store.isTimerActive ? " \(formatTime(Swift.abs(store.remainingSeconds)))" : ""
        let color = store.remainingSeconds < 0 ? NSColor.systemRed : NSColor.labelColor
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: color,
            .font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium),
        ]

        button.title = ""
        button.attributedTitle = NSAttributedString(string: title, attributes: attributes)
    }

    @objc private func handleStatusItemClick(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else {
            togglePopover(sender)
            return
        }

        switch event.type {
        case .rightMouseUp:
            showContextMenu()
        default:
            togglePopover(sender)
        }
    }

    private func togglePopover(_ sender: NSStatusBarButton) {
        if popover.isShown {
            popover.performClose(sender)
            return
        }

        updateStatusItem()
        statusItem.menu = nil
        popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .maxY)
        popover.contentViewController?.view.window?.becomeKey()
    }

    private func showContextMenu() {
        popover.performClose(nil)

        guard let button = statusItem.button else { return }

        statusItem.menu = contextMenu
        button.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        settingsWindowController.show()
    }

    @objc private func exportBackup() {
        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = "TimeTo Backup.json"
        panel.allowedContentTypes = [.json]

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            try store.exportBackup(to: url)
        } catch {
            presentErrorAlert(title: "Export Failed", message: error.localizedDescription)
        }
    }

    @objc private func importBackup() {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.json]
        openPanel.allowsMultipleSelection = false

        guard openPanel.runModal() == .OK, let url = openPanel.url else { return }

        let confirm = NSAlert()
        confirm.messageText = "Replace current data?"
        confirm.informativeText = "Importing a backup will replace current goals, tasks, history, and timer state."
        confirm.alertStyle = .warning
        confirm.addButton(withTitle: "Import")
        confirm.addButton(withTitle: "Cancel")

        guard confirm.runModal() == .alertFirstButtonReturn else { return }

        do {
            try store.importBackup(from: url)
            updateStatusItem()
        } catch {
            presentErrorAlert(title: "Import Failed", message: error.localizedDescription)
        }
    }

    @objc private func revealDataFile() {
        NSWorkspace.shared.activateFileViewerSelecting([DataStore.shared.fileURL])
    }

    private func presentErrorAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}

@MainActor
private final class SettingsWindowController: NSWindowController, NSWindowDelegate {
    private let store: AppStore
    private var onImport: () -> Void
    private var onExport: () -> Void
    private var onRevealDataFile: () -> Void

    init(
        store: AppStore,
        onImport: @escaping () -> Void,
        onExport: @escaping () -> Void,
        onRevealDataFile: @escaping () -> Void
    ) {
        self.store = store
        self.onImport = onImport
        self.onExport = onExport
        self.onRevealDataFile = onRevealDataFile

        let hostingController = NSHostingController(
            rootView: AnyView(
                SettingsView(
                    onImport: onImport,
                    onExport: onExport,
                    onRevealDataFile: onRevealDataFile
                )
                    .environment(store)
            )
        )

        let window = NSWindow(contentViewController: hostingController)
        window.title = "Settings"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.isReleasedWhenClosed = false
        window.setContentSize(NSSize(width: 520, height: 300))
        window.center()

        super.init(window: window)
        window.delegate = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateActions(
        onImport: @escaping () -> Void,
        onExport: @escaping () -> Void,
        onRevealDataFile: @escaping () -> Void
    ) {
        self.onImport = onImport
        self.onExport = onExport
        self.onRevealDataFile = onRevealDataFile
        refreshRootView()
    }

    func show() {
        refreshRootView()
        if let window {
            window.orderFrontRegardless()
        }
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func windowWillClose(_ notification: Notification) {
        refreshRootView()
    }

    private func refreshRootView() {
        guard let hostingController = window?.contentViewController as? NSHostingController<AnyView> else {
            return
        }

        hostingController.rootView = AnyView(
            SettingsView(
                onImport: onImport,
                onExport: onExport,
                onRevealDataFile: onRevealDataFile
            )
            .environment(store)
        )
    }
}
