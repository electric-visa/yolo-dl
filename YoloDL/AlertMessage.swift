//
//  AlertMessage.swift
//  YoloDL
//
// Identifiable wrapper used to drive SwiftUI's .alert(item:) modifier.
// Carries a title and descriptive text so that DownloadManager can
// publish a single optional AlertMessage? property for all generic alerts.

import Foundation

struct AlertMessage: Identifiable, Equatable, Sendable {
    
    let id = UUID()
    let title: String
    let text: String
}
