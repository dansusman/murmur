import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @StateObject private var transcriptionSession = TranscriptionSession()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Status section
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: statusIcon)
                        .foregroundColor(statusColor)
                    Text(transcriptionSession.state.displayText)
                        .font(.system(size: 13, weight: .medium))
                }
                
                if case .recording = transcriptionSession.state {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Duration: \(formatDuration(transcriptionSession.recordingDuration))")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        
                        if transcriptionSession.recordingMode == .meetingMode {
                            HStack {
                                Image(systemName: "mic.and.signal.meter")
                                    .font(.system(size: 9))
                                    .foregroundColor(.blue)
                                Text("Meeting Mode")
                                    .font(.system(size: 9))
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            
            Divider()
            
            // Recent transcriptions
            if !transcriptionSession.transcriptionHistory.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Recent Transcriptions")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                    
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 4) {
                            ForEach(transcriptionSession.getRecentTranscriptions(limit: 5), id: \.timestamp) { result in
                                TranscriptionHistoryRow(result: result)
                            }
                        }
                    }
                    .frame(maxHeight: 100)
                }
                
                Divider()
            }
            
            // Menu items
            VStack(alignment: .leading, spacing: 0) {
                MenuBarButton(title: "Settings...", action: openSettings)
                
                MenuBarButton(title: "Launch at Login", action: toggleLaunchAtLogin, isToggled: settingsManager.launchAtLogin)
                
                MenuBarButton(title: "Clear History", action: clearHistory, isEnabled: !transcriptionSession.transcriptionHistory.isEmpty)
                
                Divider()
                    .padding(.horizontal, 12)
                
                MenuBarButton(title: "Quit Murmur", action: quitApp, isDestructive: true)
            }
        }
        .frame(width: 280)
        .background(Color.clear)
    }
    
    private var statusIcon: String {
        switch transcriptionSession.state {
        case .idle:
            return "mic"
        case .recording:
            return "mic.fill"
        case .processing:
            return "waveform"
        case .completed:
            return "checkmark.circle"
        case .error:
            return "exclamationmark.triangle"
        }
    }
    
    private var statusColor: Color {
        switch transcriptionSession.state {
        case .idle:
            return .primary
        case .recording:
            return .red
        case .processing:
            return .blue
        case .completed:
            return .green
        case .error:
            return .red
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }
    
    private func toggleLaunchAtLogin() {
        settingsManager.launchAtLogin.toggle()
    }
    
    private func clearHistory() {
        transcriptionSession.clearHistory()
    }
    
    private func quitApp() {
        NSApp.terminate(nil)
    }
}

struct TranscriptionHistoryRow: View {
    let result: TranscriptionResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(result.text)
                .font(.system(size: 11))
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            Text(formatTimestamp(result.timestamp))
                .font(.system(size: 9))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.1))
        )
        .contentShape(Rectangle())
        .onTapGesture {
            // Copy transcription to clipboard
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(result.text, forType: .string)
        }
    }
    
    private func formatTimestamp(_ timestamp: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: timestamp)
    }
}

struct MenuBarButton: View {
    let title: String
    let action: () -> Void
    var isToggled: Bool = false
    var isEnabled: Bool = true
    var isDestructive: Bool = false
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 13))
                    .foregroundColor(isDestructive ? .red : .primary)
                
                Spacer()
                
                if isToggled {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11))
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.5)
        .background(
            Rectangle()
                .fill(Color.blue.opacity(0.1))
                .opacity(0)
        )
        .onHover { hovering in
            // Visual feedback on hover would be handled here
        }
    }
}

#Preview {
    MenuBarView()
        .environmentObject(SettingsManager())
}
