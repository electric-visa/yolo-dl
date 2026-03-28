// Lightweight value type that carries everything needed to confirm and
// then start a download.

struct PendingDownload: Sendable {
    let downloadLocation: String
    let fileNamingPattern: String
    let existingFilePath: String?
}
