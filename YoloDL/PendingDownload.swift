import Foundation

struct PendingDownload {
    var metadata: [EpisodeMetadata]
    var downloadLocation: String
    var fileNamingPattern: String
    var existingFilePath: String?
}
