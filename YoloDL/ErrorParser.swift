//
//  ErrorParser.swift
//  YoloDL
//
//  Created by Visa Uotila on 9.3.2026.
//

struct ErrorParser {

    struct ErrorPattern {
        let pattern: String
        let message: String
    }

    let patterns = [
            ErrorPattern(pattern: "Unsupported URL", message: "The URL doesn't appear to be from Yle Areena or another supported Yle service. Check the URL and try again."),

            ErrorPattern(pattern: "No streams found", message: "yle-dl failed to find a stream in the provided URL. Try again or with a different URL."),

            ErrorPattern(pattern: "Failed to parse a playlist", message: "Failed to read the episode list. Try downloading from a single episode URL instead of using the series page."),

            ErrorPattern(pattern: "This clip is only available in Finland", message: "This clip is only available in Finland. yle-dl detected that your network location is outside Finland."),

            ErrorPattern(pattern: "This stream has expired", message: "This content is no longer available for download."),

            ErrorPattern(pattern: "Stream not yet available", message: "This stream is not available yet. Check the episode page for its release date."),

            ErrorPattern(pattern: "Media not found", message: "The media was not found. The content may have been removed or the URL may be incorrect."),

            ErrorPattern(pattern: "Failed to download program data", message: "Failed to fetch program information from Yle. Check your internet connection and try again."),

            ErrorPattern(pattern: "ffmpeg or ffprobe not found", message: "ffmpeg and ffprobe are required but were not found. Please report this error to the YOLO-dl developer."),

            ErrorPattern(pattern: "ffmpeg not found", message: "ffmpeg was not found. Please report this error to the YOLO-dl developer."),

            ErrorPattern(pattern: "does not exist. Use --create-dirs", message: "The selected download folder does not exist. Please choose a different folder."),

            ErrorPattern(pattern: "Stream probing timed out", message: "yle-dl timed out while analyzing the stream. Yle servers may be temporarily slow. Try again after a while."),

            ErrorPattern(pattern: "Stream probing failed", message: "yle-dl failed to analyze the stream. Try again."),

            ErrorPattern(pattern: "wget failed", message: "The download failed (wget error). Check your internet connection and try again."),

            ErrorPattern(pattern: "Problem with episode list", message: "Failed to read the full episode list. Some episodes may be missing. Try again or use individual episode URLs."),

            ErrorPattern(pattern: "Failed to check geo restrictions", message: "yle-dl could not check geographic restrictions. Your download may fail if the content is available in Finland only."),
        ]

    func parseErrors(_ text: String) -> String? {
        for entry in patterns {
            if text.contains(entry.pattern) { return entry.message }
        }
        return nil
    }
}
