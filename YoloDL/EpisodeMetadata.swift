//
//  EpisodeMetadata.swift
//  YoloDL
//
//  Created by Visa Uotila on 9.3.2026.
//

import Foundation

struct EpisodeMetadata: Codable {
    let durationSeconds: Int?
    let title: String
    let episodeTitle: String
    let publishedTimestamp: String
    let flavors: [Flavor]
    
    var publishDate: String {
        String(publishedTimestamp.prefix(10))
    }
    
    var pureTitle: String {
        let parts = episodeTitle.components(separatedBy: ": ")
        return parts.last ?? episodeTitle
    }
    
    var seriesName: String? {
        let parts = episodeTitle.components(separatedBy: ": ")
        if parts.count > 1 {
            return parts.first
        } else {
            return nil
        }
    }
    
    var episodeCode: String? {
        let pattern = /(?:S\d{2})?E\d{2}/
        if let match = title.firstMatch(of: pattern) {
            return String(match.output)
        }
        return nil
    }
    
    func predictedFileStem(for preset: NamingPreset) -> String {
        switch preset {
        case .seriesTitle: return episodeTitle
        case .titleOnly: return pureTitle
        case .seriesDateTitle:
            var stem = ""
            if let series = seriesName { stem += series + ": "}
            stem += (episodeCode ?? publishDate) + " - " + pureTitle
            return stem
        case .custom: return ""
        }
    }
    
    struct Flavor: Codable {
        let url: String
    }
    
    enum ContentType {
        case vod
        case liveStream
        case tvChannel
    }

    var contentType: ContentType {
        let isLive = flavors.contains { $0.url.contains("/live/") }
        
        if !isLive { return .vod }
        return durationSeconds != nil ? .liveStream : .tvChannel
    }
    
    enum CodingKeys: String, CodingKey {
        case durationSeconds = "duration_seconds"
        case title = "title"
        case episodeTitle = "episode_title"
        case publishedTimestamp = "publish_timestamp"
        case flavors = "flavors"
    }
}
