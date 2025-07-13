import SwiftUI
import AppKit

struct HotkeyPickerView: View {
    @Binding var selectedKeyCode: UInt32
    let onComplete: () -> Void
    
    @State private var isListening = false
    @State private var currentKeyName = ""
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Hotkey Selection")
                .font(.headline)
            
            if isListening {
                Text("Press the key you want to use as a hotkey...")
                    .foregroundColor(.blue)
                    .font(.subheadline)
                
                Text("Current: \(currentKeyName)")
                    .font(.body.monospaced())
                    .foregroundColor(.secondary)
            } else {
                Text("Click 'Start Listening' and then press the key you want to use")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
            }
            
            HStack {
                Button(isListening ? "Stop Listening" : "Start Listening") {
                    if isListening {
                        stopListening()
                    } else {
                        startListening()
                    }
                }
                .buttonStyle(.borderedProminent)
                
                Button("Cancel") {
                    stopListening()
                    onComplete()
                }
                .buttonStyle(.bordered)
                
                if !currentKeyName.isEmpty {
                    Button("Use This Key") {
                        stopListening()
                        onComplete()
                    }
                    .buttonStyle(.bordered)
                }
            }
            
            // Common hotkey suggestions
            VStack(alignment: .leading, spacing: 4) {
                Text("Quick select:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                    ForEach(commonHotkeys, id: \.key) { hotkey in
                        Button(hotkey.name) {
                            selectedKeyCode = hotkey.key
                            currentKeyName = hotkey.name
                        }
                        .buttonStyle(.bordered)
                        .font(.caption)
                    }
                }
            }
        }
        .padding()
        .onAppear {
            currentKeyName = HotkeyManager.getKeyName(for: selectedKeyCode) ?? "Unknown"
        }
    }
    
    private func startListening() {
        isListening = true
        // Set up local event monitor
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if isListening {
                let keyCode = UInt32(event.keyCode)
                selectedKeyCode = keyCode
                currentKeyName = HotkeyManager.getKeyName(for: keyCode) ?? "Key \(keyCode)"
                return nil // Consume the event
            }
            return event
        }
    }
    
    private func stopListening() {
        isListening = false
        // Note: In a real implementation, you'd need to properly manage the event monitor
        // This is a simplified version
    }
}

private struct HotkeyOption {
    let name: String
    let key: UInt32
}

private let commonHotkeys: [HotkeyOption] = [
    HotkeyOption(name: "FN", key: 63),
    HotkeyOption(name: "F13", key: 105),
    HotkeyOption(name: "F14", key: 107),
    HotkeyOption(name: "F15", key: 113),
    HotkeyOption(name: "F16", key: 106),
    HotkeyOption(name: "F17", key: 64),
    HotkeyOption(name: "F18", key: 79),
    HotkeyOption(name: "F19", key: 80),
    HotkeyOption(name: "F20", key: 90),
    HotkeyOption(name: "Space", key: 49),
    HotkeyOption(name: "Tab", key: 48),
    HotkeyOption(name: "Return", key: 36)
]
