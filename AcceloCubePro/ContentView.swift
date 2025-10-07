//
//  ContentView.swift
//  AcceloCubePro
//
//  Created by Roy Dimapilis on 10/6/25.
//

import SwiftUI

struct ContentView: View {
    @State private var motionVM = MotionVM()
    var body: some View {
        ZStack {
            Color.black.ignoressafeArea()
        
            VStack(spacing: 0) {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
