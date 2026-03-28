// Lightweight value type that carries everything needed to confirm and
// then start a download.

import Foundation

struct PendingDownload: Sendable {
    let metadata: [EpisodeMetadata]
    let downloadLocation: String
    let fileNamingPattern: String
    let existingFilePath: String?
}
