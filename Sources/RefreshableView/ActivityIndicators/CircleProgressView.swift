//
//  CircleProgressView.swift
//
//
//  Created by Dmitry.Marinin on 08.04.2023.
//

import SwiftUI

public struct CircleView: View {

    let lineWidth: CGFloat
    let color: Color

    public init(lineWidth: CGFloat, color: Color = Color.white) {
        self.lineWidth = lineWidth
        self.color = color
    }

    public var body: some View {
        Circle()
            .trim(from: .zero, to: 0.75)
            .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
            .foregroundColor(color)
    }
}

public struct CircleProgressView: View {

    let lineWidth: CGFloat
    let color: Color
    @State private var isAnimating = false

    public init(lineWidth: CGFloat, color: Color = Color.white, isAnimating: Bool = false) {
        self.lineWidth = lineWidth
        self.isAnimating = isAnimating
        self.color = color
    }

    public var body: some View {
        CircleView(lineWidth: lineWidth, color: color)
            .rotationEffect(Angle(degrees: self.isAnimating ? 360 : 0))
            .animation(Animation.linear(duration: 1).repeatForever(autoreverses: false))
            .onAppear { self.isAnimating = true }
            .onDisappear { self.isAnimating = false }
    }
}

#if DEBUG
struct CircleProgressView_Previews: PreviewProvider {
    static var previews: some View {
        CircleProgressView(lineWidth: 20)
    }
}
#endif
