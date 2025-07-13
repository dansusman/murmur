import Foundation
import AppKit

struct BorderSettings: Codable {
    var isEnabled: Bool = true
    var color: NSColor = .systemRed
    var thickness: CGFloat = 3.0
    
    private enum CodingKeys: String, CaseIterable, CodingKey {
        case isEnabled = "recording_border_enabled"
        case colorData = "recording_border_color"
        case thickness = "recording_border_thickness"
    }
    
    init(isEnabled: Bool = true, color: NSColor = .systemRed, thickness: CGFloat = 3.0) {
        self.isEnabled = isEnabled
        self.color = color
        self.thickness = thickness
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? true
        thickness = try container.decodeIfPresent(CGFloat.self, forKey: .thickness) ?? 3.0
        
        if let colorData = try container.decodeIfPresent(Data.self, forKey: .colorData) {
            color = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: colorData) ?? .systemRed
        } else {
            color = .systemRed
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(isEnabled, forKey: .isEnabled)
        try container.encode(thickness, forKey: .thickness)
        
        let colorData = try NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: true)
        try container.encode(colorData, forKey: .colorData)
    }
    
    static let presetColors: [NSColor] = [
        .systemRed,
        .systemBlue,
        .systemGreen,
        .systemOrange,
        .systemPurple,
        .controlAccentColor
    ]
    
    static let `default` = BorderSettings()
}