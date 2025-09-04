import Cocoa
import SwiftUI

@MainActor
class SettingsWindowManager: ObservableObject {
    private var settingsWindow: NSWindow?

    func showSettings() {
        if settingsWindow == nil {
            let contentView = SettingsView()

            settingsWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 500, height: 400),
                styleMask: [.titled, .closable, .resizable],
                backing: .buffered,
                defer: false
            )

            settingsWindow?.contentView = NSHostingView(rootView: contentView)
            settingsWindow?.title = "Ham Settings"
            settingsWindow?.center()
            settingsWindow?.isReleasedWhenClosed = false
        }

        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func closeSettings() {
        settingsWindow?.close()
    }
}

struct SettingsView: View {
    @State private var anthropicKey = ""
    @State private var openaiKey = ""
    @State private var googleaiKey = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Ham - LLM Token Monitor Settings")
                .font(.title2)
                .fontWeight(.bold)

            Text("Enter your API keys to monitor token usage")
                .foregroundColor(.secondary)

            VStack(spacing: 15) {
                APIKeyField(
                    label: "Anthropic Claude API Key",
                    key: $anthropicKey,
                    provider: .anthropic
                )

                APIKeyField(
                    label: "OpenAI API Key",
                    key: $openaiKey,
                    provider: .openai
                )

                APIKeyField(
                    label: "Google AI API Key",
                    key: $googleaiKey,
                    provider: .googleai
                )
            }

            HStack(spacing: 10) {
                Button("Save") {
                    saveAPIKeys()
                }
                .buttonStyle(.borderedProminent)

                Button("Clear All") {
                    clearAllAPIKeys()
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Close") {
                    // Close window
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
            loadAPIKeys()
        }
        .alert("Settings", isPresented: $showingAlert) {
            Button("OK") {}
        } message: {
            Text(alertMessage)
        }
    }

    private func loadAPIKeys() {
        anthropicKey = KeychainManager.shared.getAPIKey(for: .anthropic) ?? ""
        openaiKey = KeychainManager.shared.getAPIKey(for: .openai) ?? ""
        googleaiKey = KeychainManager.shared.getAPIKey(for: .googleai) ?? ""
    }

    private func saveAPIKeys() {
        var savedCount = 0
        var errors: [String] = []

        if !anthropicKey.isEmpty {
            if KeychainManager.shared.setAPIKey(anthropicKey, for: .anthropic) {
                savedCount += 1
            } else {
                errors.append("Anthropic")
            }
        }

        if !openaiKey.isEmpty {
            if KeychainManager.shared.setAPIKey(openaiKey, for: .openai) {
                savedCount += 1
            } else {
                errors.append("OpenAI")
            }
        }

        if !googleaiKey.isEmpty {
            if KeychainManager.shared.setAPIKey(googleaiKey, for: .googleai) {
                savedCount += 1
            } else {
                errors.append("Google AI")
            }
        }

        if errors.isEmpty {
            alertMessage = "Saved \(savedCount) API key(s) successfully!"
        } else {
            alertMessage =
                "Saved \(savedCount) keys. Failed to save: \(errors.joined(separator: ", "))"
        }

        showingAlert = true
    }

    private func clearAllAPIKeys() {
        _ = KeychainManager.shared.deleteAPIKey(for: .anthropic)
        _ = KeychainManager.shared.deleteAPIKey(for: .openai)
        _ = KeychainManager.shared.deleteAPIKey(for: .googleai)

        anthropicKey = ""
        openaiKey = ""
        googleaiKey = ""

        alertMessage = "All API keys cleared successfully!"
        showingAlert = true
    }
}

struct APIKeyField: View {
    let label: String
    @Binding var key: String
    let provider: APIProvider

    @State private var isSecure = true

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(label)
                    .font(.headline)
                Spacer()
                Button(action: { isSecure.toggle() }) {
                    Image(systemName: isSecure ? "eye" : "eye.slash")
                }
                .buttonStyle(.borderless)
            }

            HStack {
                if isSecure {
                    SecureField("Enter \(provider.displayName) API key", text: $key)
                } else {
                    TextField("Enter \(provider.displayName) API key", text: $key)
                }
            }
            .textFieldStyle(.roundedBorder)
        }
    }
}
