//
//  UpdateCheckResult.swift
//  YoloDL
//

enum UpdateCheckResult: Sendable {
    case available(UpdateResult)
    case upToDate
    case failed
}
