//
//  TVChannel.swift
//  YoloDL 0.1
//
//  Created on 13.3.2026.
//

enum TVChannel: String, CaseIterable {
    case tv1
    case tv2
    case teemaFem
    
    var label: String {
        switch self {
        case .tv1:
            return "Yle TV1"
        case .tv2:
            return "Yle TV2"
        case .teemaFem:
            return "Yle Teema & Fem"
        }
    }
    
    var keyword: String {
        switch self {
        case .tv1:
            return "tv1"
        case .tv2:
            return "tv2"
        case .teemaFem:
            return "teema"
        }
    }
}
