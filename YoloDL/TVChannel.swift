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
        case .tv1: "Yle TV1"
        case .tv2: "Yle TV2"
        case .teemaFem: "Yle Teema & Fem"
        }
    }

    var keyword: String {
        switch self {
        case .tv1: "tv1"
        case .tv2: "tv2"
        case .teemaFem: "teema"
        }
    }
}
