//
//  ContentView.swift
//  Example
//
//  Created by Evegeny Kalashnikov on 22.05.2024.
//

import SwiftUI

struct ContentView: View {

    @State private var selectedDetent: BottomSheetDetent = .medium

    var body: some View {
        Rectangle()
            .foregroundColor(Color.teal)
            .ignoresSafeArea()
            .overlay(alignment: .top) {
                Button("Show/Hide BottomSheet") {
                    selectedDetent = selectedDetent == .medium ? .hidden : .medium
                }
                .padding(.top, 100)
            }
            .bottomSheetMenu(detents: .height(100), .medium, .large, selectedDetent: $selectedDetent) {
                ForEach(0..<10) { index in
                    Text("Hello, World!")
                        .padding()
                        .background(index % 2 == 0 ? Color.green : Color.cyan)
                        .cornerRadius(10)
                        .padding()
                }
            }
    }
}

#Preview {
    ContentView()
}
