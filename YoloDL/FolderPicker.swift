//
//  FolderPicker.swift
//  YoloDL
//
// Thin AppKit wrapper around NSOpenPanel.

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
