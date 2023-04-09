//
//  ContentView.swift
//  Examples
//
//  Created by Dmitry.Marinin on 08.04.2023.
//

import SwiftUI
import RefreshableView

struct ContentView: View {
    @State var isActivePTR: Bool = false

    var body: some View {
        VStack {
            RefreshableScrollView(lineWidth: 2,
                                  color: Color.black,
                                  refreshing: $isActivePTR,
                                  activityView: AnyView(
                                    CircleProgressView(lineWidth: 2, color: Color.black)
                                  ),
                                  action: {
                print("Action")
                // add your code here
                // remmber to set the refresh to false
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.isActivePTR.toggle()
                }
            }) {
                ForEach(0..<20) { index in
                    Text("Item \(index)")
                }
            }
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
