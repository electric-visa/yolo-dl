// Lightweight value type that carries everything needed to confirm and
// then start a download.

import Foundation

struct PendingDownload {
    var metadata: [EpisodeMetadata]
    var downloadLocation: String
    var fileNamingPattern: String
    var existingFilePath: String?
}
