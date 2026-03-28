//
//  StderrFields.swift
//  YoloDL
//
// Value type that parses a single ffmpeg stderr progress line intos tructured fields.
// Consumed by DownloadManager+Process to drive the progress bar.

struct StderrFields: Sendable {
    var progress: Double?
    var fileSize: String?
    var elapsed: String?
    var elapsedSeconds: Int?
    var speed: Double?
}
