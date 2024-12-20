//
//  Helpers.swift
//  Finacial Analysis
//
//  Created by Asher Antrim on 12/20/24.
//

import Foundation

func formatNumberShort(_ value: Double) -> String {
    let absValue = abs(value)
    let sign = value < 0 ? "-" : ""
    switch absValue {
    case 1_000_000_000...:
        return String(format: "\(sign)%.1fB", absValue / 1_000_000_000)
    case 1_000_000...:
        return String(format: "\(sign)%.1fM", absValue / 1_000_000)
    case 1_000...:
        return String(format: "\(sign)%.1fK", absValue / 1_000)
    default:
        return String(format: "\(sign)%.0f", absValue)
    }
}

func formatCurrency(_ value: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.maximumFractionDigits = 0
    if let formatted = formatter.string(from: NSNumber(value: value)) {
        return formatted
    }
    return "\(value)"
}

func formatPercentage(_ value: Double) -> String {
    return String(format: "%.2f%%", value)
}
