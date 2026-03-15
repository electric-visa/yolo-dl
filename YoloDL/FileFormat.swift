//
//  FileFormat.swift
//  YoloDL
//
//  Created on 15.3.2026.
//

enum FileFormat: String, CaseIterable {
    case mp4
    case mkv

    var label: String {
        switch self {
        case .mp4: "MP4"
        case .mkv: "MKV"
        }
    }
}
