import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var showingHotkeyPicker = false
    @State private var showingApiKeyAlert = false
    @State private var tempApiKey = ""
    
    var body: some View {
        TabView {
            // General Settings
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
            
            // Hotkey Settings
            HotkeySettingsView()
                .tabItem {
                    Label("Hotkeys", systemImage: "keyboard")
                }
            
            // Whisper Settings
            WhisperSettingsView()
                .tabItem {
                    Label("Whisper", systemImage: "waveform")
                }
            
            // Advanced Settings
            AdvancedSettingsView()
                .tabItem {
                    Label("Advanced", systemImage: "slider.horizontal.3")
                }
        }
        .frame(width: 480, height: 360)
        .padding()
    }
}

struct GeneralSettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("General Settings")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                Toggle("Launch at login", isOn: $settingsManager.launchAtLogin)
                
                Toggle("Automatically insert transcribed text", isOn: $settingsManager.autoInsertText)
                    .help("When enabled, transcribed text will be automatically inserted into the active text field")
                
                Toggle("Show floating recording indicator", isOn: $settingsManager.showFloatingIndicator)
                    .help("Display a floating indicator when recording audio")
                
                HStack {
                    Text("Language:")
                    Picker("Language", selection: $settingsManager.language) {
                        Text("Auto-detect").tag("auto")
                        Text("English").tag("en")
                        Text("Spanish").tag("es")
                        Text("French").tag("fr")
                        Text("German").tag("de")
                        Text("Italian").tag("it")
                        Text("Portuguese").tag("pt")
                        Text("Japanese").tag("ja")
                        Text("Korean").tag("ko")
                        Text("Chinese").tag("zh")
                    }
                    .pickerStyle(MenuPickerStyle())
                }
            }
            
            Spacer()
            
            HStack {
                Spacer()
                Button("Reset to Defaults") {
                    settingsManager.resetToDefaults()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
    }
}

struct HotkeySettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var showingHotkeyPicker = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Hotkey Settings")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Press and hold the hotkey to start recording, release to stop and transcribe.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text("Current hotkey:")
                    Button(settingsManager.getHotkeyDisplayName()) {
                        showingHotkeyPicker = true
                    }
                    .buttonStyle(.bordered)
                    .font(.body.monospaced())
                }
                
                if showingHotkeyPicker {
                    HotkeyPickerView(selectedKeyCode: $settingsManager.hotkeyCode) {
                        showingHotkeyPicker = false
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recommended hotkeys:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• FN (Function) key - Default, doesn't interfere with other shortcuts")
                        Text("• F13-F20 - Function keys that are rarely used")
                        Text("• Avoid: Command, Option, Control - These interfere with other shortcuts")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding()
    }
}

struct WhisperSettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @StateObject private var whisperService = WhisperService()
    @State private var availableModels: [WhisperModel] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Whisper Settings")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Local Whisper Processing")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Model:")
                    Picker("Model", selection: $settingsManager.whisperModelType) {
                        ForEach(WhisperModelType.allCases, id: \.self) { model in
                            HStack {
                                Text(model.displayName)
                                if !whisperService.isModelAvailable(model) {
                                    Text("(Not Available)")
                                        .foregroundColor(.red)
                                        .font(.caption)
                                }
                            }
                            .tag(model)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    if let modelInfo = whisperService.getModelInfo(for: settingsManager.whisperModelType) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Model Details:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("• Size: \(modelInfo.size)")
                            Text("• Speed: \(settingsManager.whisperModelType.speed)")
                            Text("• File: \(modelInfo.filename)")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }
                
                GroupBox("Available Models") {
                    if availableModels.isEmpty {
                        Text("No models found. Please run the setup script to download models.")
                            .foregroundColor(.orange)
                            .font(.caption)
                    } else {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                            ForEach(availableModels, id: \.name) { model in
                                VStack {
                                    Text(model.name.capitalized)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                    Text(model.size)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(8)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.blue.opacity(0.1))
                                )
                            }
                        }
                    }
                }
                
                GroupBox("Performance Tips") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• Tiny model: Best for real-time transcription")
                        Text("• Base model: Good balance of speed and accuracy")
                        Text("• Larger models: Better accuracy but slower")
                        Text("• All processing happens locally (private)")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            availableModels = whisperService.getAvailableModels()
        }
    }
}

struct AdvancedSettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var showingExportAlert = false
    @State private var exportedSettings = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Advanced Settings")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                GroupBox("Permissions") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("This app requires the following permissions:")
                        Text("• Microphone access - for audio recording")
                        Text("• Accessibility permissions - for text insertion")
                        Text("• Input monitoring - for global hotkey detection")
                        
                        Button("Open System Settings") {
                            NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/System Settings.app"))
                        }
                        .buttonStyle(.bordered)
                    }
                    .font(.caption)
                }
                
                GroupBox("Settings Management") {
                    HStack {
                        Button("Export Settings") {
                            let settings = settingsManager.exportSettings()
                            do {
                                let data = try JSONSerialization.data(withJSONObject: settings, options: .prettyPrinted)
                                exportedSettings = String(data: data, encoding: .utf8) ?? ""
                                showingExportAlert = true
                            } catch {
                                Logger.settings.error("Failed to export settings: \(error)")
                            }
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Import Settings") {
                            let panel = NSOpenPanel()
                            panel.allowedContentTypes = [.json]
                            panel.allowsMultipleSelection = false
                            panel.canChooseDirectories = false
                            
                            if panel.runModal() == .OK, let url = panel.url {
                                do {
                                    let data = try Data(contentsOf: url)
                                    let settings = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                                    if let settings = settings {
                                        settingsManager.importSettings(settings)
                                    }
                                } catch {
                                    Logger.settings.error("Failed to import settings: \(error)")
                                }
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .alert("Export Settings", isPresented: $showingExportAlert) {
            Button("Copy to Clipboard") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(exportedSettings, forType: .string)
            }
            Button("Save to File") {
                let panel = NSSavePanel()
                panel.allowedContentTypes = [.json]
                panel.nameFieldStringValue = "murmur-settings.json"
                
                if panel.runModal() == .OK, let url = panel.url {
                    do {
                        try exportedSettings.write(to: url, atomically: true, encoding: .utf8)
                    } catch {
                        Logger.settings.error("Failed to save settings: \(error)")
                    }
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Settings exported successfully. You can copy to clipboard or save to a file.")
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(SettingsManager())
}
