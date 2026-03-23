//
//  IndefiniteRecordingAlert.swift
//  YoloDL
//
// NSAlert confirmation shown before starting an indefinite recording.
// Includes a suppression checkbox; once suppressed the alert is skipped.

import AppKit

enum IndefiniteRecordingAlert {

    static func confirm() -> Bool {
        if UserDefaults.standard.bool(forKey: StorageKeys.hasAcceptedIndefiniteRecording) {
            return true
        }

        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "Indefinite recording"
        alert.informativeText = "The recording will continue until you press Stop. This could produce a large file."
        alert.addButton(withTitle: "Record")
        alert.addButton(withTitle: "Cancel")
        alert.showsSuppressionButton = true

        let response = alert.runModal()

        guard response == .alertFirstButtonReturn else { return false }

        if alert.suppressionButton?.state == .on {
            UserDefaults.standard.set(true, forKey: StorageKeys.hasAcceptedIndefiniteRecording)
        }
        return true
    }
}
