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
            ErrorPattern(pattern: "Unsupported URL", message: "The URL doesn't appear to be from Yle Areena or another supported Yle service. Check the link and try again."),
            ErrorPattern(pattern: "No streams found", message: "yle-dl failed to find a stream in the provided URL. Please try again or with a different URL."),
            ErrorPattern(pattern: "Failed to parse a playlist", message: "Failed to read the episode list. Try downloading from a single episode URL instead of using the series page."),
        ]
    
    func parseErrors(_ text: String) -> String? {
        for entry in patterns {
            if text.contains(entry.pattern) { return entry.message }
        }
        return nil
    }
}
