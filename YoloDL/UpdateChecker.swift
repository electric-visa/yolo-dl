//
//  UpdateChecker.swift
//  YoloDL
//

import Foundation

enum UpdateChecker {

    private static let versionURL = URL(
        string: "https://files.electric-visa.net/yolo-dl-version.json"
    )!

    static func checkForUpdate() async -> UpdateCheckResult {
        guard let (data, _) = try? await URLSession.shared.data(from: versionURL)
        else { return .failed }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: String],
              let version = json["version"],
              let urlString = json["url"],
              let url = URL(string: urlString)
        else { return .failed }

        let current = Bundle.main.appVersion

        if isNewer(version, than: current) {
            return .available(UpdateResult(version: version, url: url))
        } else {
            return .upToDate
        }
    }

    static func isNewer(_ remote: String, than local: String) -> Bool {
        let remoteParts = remote.split(separator: ".").compactMap { Int($0) }
        let localParts = local.split(separator: ".").compactMap { Int($0) }
        let count = max(remoteParts.count, localParts.count)

        for i in 0..<count {
            let r = i < remoteParts.count ? remoteParts[i] : 0
            let l = i < localParts.count ? localParts[i] : 0
            if r > l { return true }
            if r < l { return false }
        }
        return false
    }
}
