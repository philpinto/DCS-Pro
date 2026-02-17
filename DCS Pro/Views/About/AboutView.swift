//
//  AboutView.swift
//  DCS Pro
//
//  About screen with dedication to Delaney
//

import SwiftUI

/// About view showing app information and dedication
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    private let appVersion: String = {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }()
    
    var body: some View {
        VStack(spacing: 24) {
            // App icon
            appIcon
            
            // App name and version
            VStack(spacing: 4) {
                Text("DCS Pro")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Delaney's Cross Stitch Pro")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                
                Text("Version \(appVersion)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            
            Divider()
                .frame(width: 200)
            
            // Dedication
            dedication
            
            Divider()
                .frame(width: 200)
            
            // Features
            featuresList
            
            Spacer()
            
            // Close button
            Button("Close") {
                dismiss()
            }
            .keyboardShortcut(.escape)
            .buttonStyle(.borderedProminent)
        }
        .padding(32)
        .frame(width: 400, height: 550)
    }
    
    private var appIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22)
                .fill(
                    LinearGradient(
                        colors: [Color.pink.opacity(0.8), Color.purple.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 100, height: 100)
            
            // Cross stitch pattern icon
            VStack(spacing: 2) {
                ForEach(0..<3) { row in
                    HStack(spacing: 2) {
                        ForEach(0..<3) { col in
                            let colors: [[Color]] = [
                                [.white, .red, .white],
                                [.red, .white, .red],
                                [.white, .red, .white]
                            ]
                            RoundedRectangle(cornerRadius: 2)
                                .fill(colors[row][col])
                                .frame(width: 20, height: 20)
                        }
                    }
                }
            }
        }
        .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
    }
    
    private var dedication: some View {
        VStack(spacing: 12) {
            Text("For Delaney")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.pink, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            Text("Monkey Never Cramp")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var featuresList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Features")
                .font(.headline)
                .padding(.bottom, 4)
            
            FeatureRow(icon: "photo", text: "Convert photos to patterns")
            FeatureRow(icon: "paintpalette", text: "DMC thread color matching")
            FeatureRow(icon: "square.grid.3x3", text: "Zoomable pattern grid")
            FeatureRow(icon: "doc.richtext", text: "PDF export with thread list")
            FeatureRow(icon: "checkmark.circle", text: "Progress tracking")
            FeatureRow(icon: "paintbrush", text: "Pattern editing tools")
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .frame(width: 20)
                .foregroundStyle(.pink)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Preview

#Preview("About View") {
    AboutView()
}
