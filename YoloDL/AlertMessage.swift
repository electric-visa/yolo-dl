//
//  AlertMessage.swift
//  YoloDL
//
//  Created by Visa Uotila on 9.3.2026.
//

import Foundation

struct AlertMessage: Identifiable {
    
    let id = UUID()
    let title: String
    let text: String
}
