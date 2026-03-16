//
//  FolderPicker.swift
//  YoloDL
//
//  Created on 16.3.2026.
//

import AppKit

enum FolderPicker {
    static func chooseFolder() -> String? {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        return panel.runModal() == .OK ? panel.url?.path : nil
    }
}
