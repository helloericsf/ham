import Cocoa
import SwiftUI

@MainActor
class SettingsWindowManager: ObservableObject {
    private var settingsWindow: NSWindow?

    func showSettings() {
        if settingsWindow == nil {
            let contentView = SettingsView()

            settingsWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 500, height: 250),
                styleMask: [.titled, .closable, .resizable],
                backing: .buffered,
                defer: false
            )

            settingsWindow?.contentView = NSHostingView(rootView: contentView)
            settingsWindow?.title = "Ham Settings"
            settingsWindow?.center()
            settingsWindow?.isReleasedWhenClosed = false

            // Enable standard Edit menu with Paste
            if NSApp.mainMenu == nil {
                let mainMenu = NSMenu()
                let editMenu = NSMenu(title: "Edit")
                editMenu.addItem(
                    NSMenuItem(
                        title: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v"))

                let editMenuItem = NSMenuItem(title: "Edit", action: nil, keyEquivalent: "")
                editMenuItem.submenu = editMenu
                mainMenu.addItem(editMenuItem)

                NSApp.mainMenu = mainMenu
            }
        }

        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        // Enable standard macOS menu bar when window is active
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NSApp.keyWindow?.makeFirstResponder(nil)
        }
    }

    func closeSettings() {
        settingsWindow?.close()
    }
}

struct SettingsView: View {
    @State private var openaiKey = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Ham - OpenAI Token Monitor")
                .font(.title2)
                .fontWeight(.bold)

            Text("Enter your OpenAI API key to monitor token usage.")
                .foregroundColor(.secondary)

            VStack(spacing: 15) {
                APIKeyField(
                    label: "OpenAI API Key",
                    key: $openaiKey
                )
            }

            HStack(spacing: 10) {
                Button("Save") {
                    saveAPIKey()
                }
                .buttonStyle(.borderedProminent)

                Button("Clear") {
                    clearAPIKey()
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Close") {
                    if let window = NSApp.keyWindow {
                        window.close()
                    }
                }
                .buttonStyle(.bordered)
            }

            Spacer()
        }
        .padding(30)
        .onAppear {
            loadAPIKey()
        }
        .alert("Settings", isPresented: $showingAlert) {
            Button("OK") {}
        } message: {
            Text(alertMessage)
        }
    }

    private func loadAPIKey() {
        openaiKey = KeychainManager.shared.getAPIKey() ?? ""
    }

    private func saveAPIKey() {
        if !openaiKey.isEmpty {
            if KeychainManager.shared.setAPIKey(openaiKey) {
                alertMessage = "OpenAI API key saved successfully!"
            } else {
                alertMessage = "Failed to save OpenAI API key."
            }
        } else {
            // Clearing the key is a valid action, so we handle it here.
            if KeychainManager.shared.deleteAPIKey() {
                alertMessage = "OpenAI API key cleared."
            } else {
                alertMessage = "Failed to clear OpenAI API key."
            }
        }

        showingAlert = true
    }

    private func clearAPIKey() {
        if KeychainManager.shared.deleteAPIKey() {
            openaiKey = ""
            alertMessage = "OpenAI API key cleared."
        } else {
            alertMessage = "Failed to clear OpenAI API key."
        }
        showingAlert = true
    }
}

struct APIKeyField: View {
    let label: String
    @Binding var key: String

    @State private var isSecure = true

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(label)
                    .font(.headline)
                Spacer()
                Button(action: { isSecure.toggle() }) {
                    Image(systemName: isSecure ? "eye.slash" : "eye")
                }
                .buttonStyle(.borderless)
            }

            NativeTextField(
                text: $key,
                isSecure: isSecure,
                placeholder: "Enter OpenAI API key"
            )
            .frame(height: 25)
        }
    }
}

struct NativeTextField: NSViewRepresentable {
    @Binding var text: String
    var isSecure: Bool
    var placeholder: String

    func makeNSView(context: Context) -> NSView {
        let containerView = NSView()
        let textField = createTextField(coordinator: context.coordinator)

        containerView.addSubview(textField)
        textField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textField.topAnchor.constraint(equalTo: containerView.topAnchor),
            textField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            textField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            textField.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
        ])

        context.coordinator.currentTextField = textField
        return containerView
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        let coordinator = context.coordinator

        // Check if we need to recreate the text field due to security change
        let needsRecreation =
            (isSecure && !(coordinator.currentTextField is NSSecureTextField))
            || (!isSecure && (coordinator.currentTextField is NSSecureTextField))

        if needsRecreation {
            // Remove old text field
            coordinator.currentTextField?.removeFromSuperview()

            // Create new text field
            let newTextField = createTextField(coordinator: coordinator)
            nsView.addSubview(newTextField)
            newTextField.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                newTextField.topAnchor.constraint(equalTo: nsView.topAnchor),
                newTextField.leadingAnchor.constraint(equalTo: nsView.leadingAnchor),
                newTextField.trailingAnchor.constraint(equalTo: nsView.trailingAnchor),
                newTextField.bottomAnchor.constraint(equalTo: nsView.bottomAnchor),
            ])

            coordinator.currentTextField = newTextField
        }

        // Update text if needed
        if coordinator.currentTextField?.stringValue != text {
            coordinator.currentTextField?.stringValue = text
        }
    }

    private func createTextField(coordinator: Coordinator) -> NSTextField {
        let textField: NSTextField
        if isSecure {
            textField = NSSecureTextField()
        } else {
            textField = NSTextField()
        }
        textField.stringValue = text
        textField.placeholderString = placeholder
        textField.delegate = coordinator
        textField.isBordered = true
        textField.bezelStyle = .roundedBezel

        return textField
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: NativeTextField
        var currentTextField: NSTextField?

        init(_ parent: NativeTextField) {
            self.parent = parent
        }

        func controlTextDidChange(_ obj: Notification) {
            guard let textField = obj.object as? NSTextField else { return }
            parent.text = textField.stringValue
        }
    }
}
