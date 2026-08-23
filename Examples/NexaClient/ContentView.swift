//
//  ContentView.swift
//  NexaClient
//
//  Created by opfic on 6/13/26.
//

import SwiftUI

struct ContentView: View {
    private let preview = NexaIntegrationPreview()

    var body: some View {
        NavigationView {
            List {
                Section("Purpose") {
                    Text("Build-only integration host for Nexa maintainers.")
                    Text("This app is not distributed to package consumers.")
                }

                Section("Package Surface") {
                    Text(preview.clientDescription)
                    Text(preview.typedRequestDescription)
                    Text(preview.rawRequestDescription)
                }
            }
            .navigationTitle("NexaClient")
        }
    }
}

#Preview {
    ContentView()
}
