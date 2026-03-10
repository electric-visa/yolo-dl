//
//  EpisodeMetadata.swift
//  YoloDL
//
//  Created by Visa Uotila on 9.3.2026.
//

struct EpisodeMetadata: Codable {
    let durationSeconds: Int
    
    enum CodingKeys: String, CodingKey {
        case durationSeconds = "duration_seconds"
    }
}
