//
//  ContentView.swift
//  StageTimePNW
//
//  Created by viradeth on 8/24/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink {
                    OpenMicMapView()
                } label: {
                    Label("Open Mic Map", systemImage: "map")
                }
            }
            .navigationTitle("StageTime PNW")
        }
    }
}

#Preview {
    ContentView()
}
