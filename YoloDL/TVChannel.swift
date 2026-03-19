//
//  TVChannel.swift
//  YoloDL
//
// Enum for the supported TV channel streams.
// Each case carries a display label and the keyword string passed to
// yle-dl to identify the live channel stream.

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
