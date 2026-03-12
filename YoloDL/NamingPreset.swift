//
//  NamingPreset.swift
//  YoloDL
//
//  Created by Visa Uotila on 11.3.2026.
//

enum NamingPreset: String, CaseIterable {
    case seriesDateTitle = "${series_separator}${episode_or_date} - ${title}"
    case seriesTitle = "${series_separator}${title}"
    case titleOnly = "${title}"
    case custom = ""
    
    var label: String {
        
        switch self {
        case .seriesDateTitle: "Series: date/episode - Title"
        case .seriesTitle: "Series: Title"
        case .titleOnly: "Title"
        case .custom: "Custom"
        }
    }
}
