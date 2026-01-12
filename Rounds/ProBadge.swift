//
//  ProBadge.swift
//  Rounds
//
//  Created by Ali Mirza on 1/11/26.
//

import SwiftUI

/// A visual badge indicating Pro features
struct ProBadge: View {
    var size: BadgeSize = .medium
    
    enum BadgeSize {
        case small, medium, large
        
        var fontSize: CGFloat {
            switch self {
            case .small: return 10
            case .medium: return 12
            case .large: return 14
            }
        }
        
        var padding: CGFloat {
            switch self {
            case .small: return 4
            case .medium: return 6
            case .large: return 8
            }
        }
        
        var iconSize: CGFloat {
            switch self {
            case .small: return 10
            case .medium: return 12
            case .large: return 14
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "crown.fill")
                .font(.system(size: size.iconSize))
            Text("PRO")
                .font(.system(size: size.fontSize, weight: .bold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, size.padding * 1.5)
        .padding(.vertical, size.padding)
        .background(
            LinearGradient(
                colors: [.yellow, .orange],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(size.padding)
    }
}

/// An inline Pro badge for use in text
struct InlineProBadge: View {
    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "crown.fill")
                .font(.system(size: 8))
            Text("PRO")
                .font(.system(size: 8, weight: .bold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(Color.yellow)
        .cornerRadius(3)
    }
}

#Preview("Pro Badge - Small") {
    ProBadge(size: .small)
}

#Preview("Pro Badge - Medium") {
    ProBadge(size: .medium)
}

#Preview("Pro Badge - Large") {
    ProBadge(size: .large)
}

#Preview("Inline Pro Badge") {
    InlineProBadge()
}
