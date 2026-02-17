//
//  DCS_ProApp.swift
//  DCS Pro
//
//  Created by 906 on 2/16/26.
//

import SwiftUI

@main
struct DCS_ProApp: App {
    @State private var showingAbout = false
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            // Replace the default About menu item
            CommandGroup(replacing: .appInfo) {
                Button("About DCS Pro") {
                    NSApp.orderFrontStandardAboutPanel(
                        options: [
                            .applicationName: "DCS Pro",
                            .applicationVersion: "1.0",
                            .credits: NSAttributedString(
                                string: "Monkey Never Cramp\n\nDelaney's Cross Stitch Pro",
                                attributes: [
                                    .font: NSFont.systemFont(ofSize: 11),
                                    .foregroundColor: NSColor.secondaryLabelColor
                                ]
                            )
                        ]
                    )
                }
            }
            
            // Help menu
            CommandGroup(replacing: .help) {
                Link("DCS Pro Help", destination: URL(string: "https://github.com")!)
            }
        }
        
        // About window (custom, accessible via Window menu)
        Window("About DCS Pro", id: "about") {
            AboutView()
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }
}
