//
//  NamingPreset.swift
//  YoloDL
//
// Enum for file-naming strategies stored in AppStorage.
// Each case maps to the yle-dl --output template string it represents.

enum NamingPreset: String, CaseIterable {
    case seriesDateTitle = "${series_separator}${episode_or_date} - ${title}"
    case seriesTitle = "${series_separator}${title}"
    case titleOnly = "${title}"
    case custom = ""
    
    func resolvedPattern(custom: String) -> String {
        self == .custom ? custom : self.rawValue
    }

    var label: String {
        
        switch self {
        case .seriesDateTitle: "Series: date/episode - Title"
        case .seriesTitle: "Series: Title"
        case .titleOnly: "Title"
        case .custom: "Custom"
        }
    }
}
