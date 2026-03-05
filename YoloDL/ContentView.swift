//
//  ContentView.swift
//  YoloDL
//
//  Created by Visa Uotila on 5.3.2026.
//

import SwiftUI

struct ContentView: View {
    @State private var url: String = ""
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("YoloDL 0.01")
            TextField("Enter source URL", text: $url)
            Button("Download"){ print(url)
            }
            }
        .padding()
    }
}

#Preview {
    ContentView()
}
