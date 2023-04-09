//
//  RefreshableScrollSUI.swift
//
//
//  Created by Dmitry.Marinin on 07.04.2023.
//

import SwiftUI

public struct RefreshableScrollView<Content: View>: View {
    @State private var previousScrollOffset: CGFloat = 0
    @State private var scrollOffset: CGFloat = 0
    @State private var rotation: Angle = .degrees(0)

    var threshold: CGFloat = 80
    let lineWidth: CGFloat
    let color: Color
    @Binding var refreshing: Bool
    let content: Content
    let scrollType: ScrollType
    let activityView: AnyView
    public typealias Pull = (_ height: CGFloat, _ rotation: Angle, _ loading: Bool) -> AnyView
    var pullView: Pull!
    public typealias Action = ()->Void
    let action: Action?

    public init(
        lineWidth: CGFloat, color: Color,
        height: CGFloat = 80,
        refreshing: Binding<Bool>,
        scrollType: ScrollType = .scrollView,
        activityView: AnyView = AnyView(ActivityRep()),
        pullView: Pull? = nil,
        action: Action? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.threshold = height
        self.lineWidth = lineWidth
        self.color = color
        self._refreshing = refreshing
        self.content = content()
        self.scrollType = scrollType
        self.activityView = activityView
        self.pullView = pullView
        self.action = action

        if self.pullView == nil {
            self.pullView = defaultPullView(height:rotation:loading:)
        }
    }

    public func defaultPullView(height: CGFloat, rotation: Angle, loading: Bool) -> AnyView {
        let view = CircleView(lineWidth: lineWidth, color: color)
            .aspectRatio(contentMode: .fit)
            .frame(width: height * 0.25, height: height * 0.25).fixedSize()
            .padding(height * 0.375)
            .rotationEffect(rotation)
            .offset(y: -height + (loading ? +height : 0.0))

        return AnyView(view)
    }

    public var body: some View {
        return VStack {
            WrapperView(self.scrollType) {
                ZStack(alignment: .top) {
                    MovingView()

                    VStack { self.content }
                        .alignmentGuide(.top, computeValue: { d in
                            self.refreshing ? -self.threshold : 0.0
                        })

                    SymbolView(
                        height: self.threshold,
                        loading: self.refreshing,
                        rotation: self.rotation,
                        activityView: self.activityView,
                        pullView: self.pullView
                    )
                }
            }
            .background(FixedView())
            .onPreferenceChange(RefreshableKeyTypes.PrefKey.self) { values in
                self.refreshLogic(values: values)
            }
        }
    }

    func refreshLogic(values: [RefreshableKeyTypes.PrefData]) {
        DispatchQueue.main.async {
            // Calculate scroll offset
            let movingBounds = values.first { $0.vType == .movingView }?.bounds ?? .zero
            let fixedBounds = values.first { $0.vType == .fixedView }?.bounds ?? .zero

            self.scrollOffset  = movingBounds.minY - fixedBounds.minY

            self.rotation = self.symbolRotation(self.scrollOffset)

            // Crossing the threshold on the way down, we start the refresh process
            if !self.refreshing && (self.scrollOffset > self.threshold && self.previousScrollOffset <= self.threshold) {
                self.refreshing = true
                self.action?()
            }

            // Update last scroll offset
            self.previousScrollOffset = self.scrollOffset
        }
    }

    func symbolRotation(_ scrollOffset: CGFloat) -> Angle {

        // We will begin rotation, only after we have passed
        // 60% of the way of reaching the threshold.
        if scrollOffset < self.threshold * 0.60 {
            return .degrees(0)
        } else {
            // Calculate rotation, based on the amount of scroll offset
            let h = Double(self.threshold)
            let d = Double(scrollOffset)
            let v = max(min(d - (h * 0.6), h * 0.4), 0)
            return .degrees(180 * v / (h * 0.4))
        }
    }

    struct SymbolView: View {
        var height: CGFloat
        var loading: Bool
        var rotation: Angle
        var activityView: AnyView
        var pullView: Pull

        var body: some View {
            Group {
                if self.loading { // If loading, show the circule view
                    VStack {
                        Spacer()
                        self.activityView
                            .frame(width: height * 0.25, height: height * 0.25)
                            .fixedSize()
                        Spacer()
                    }
                    .frame(height: height).fixedSize()
                    .offset(y: -height + (self.loading ? height : 0.0))
                } else {
                    self.pullView(height, rotation, loading)
                }
            }
        }
    }

    struct MovingView: View {
        var body: some View {
            GeometryReader { proxy in
                Color.clear.preference(key: RefreshableKeyTypes.PrefKey.self, value: [RefreshableKeyTypes.PrefData(vType: .movingView, bounds: proxy.frame(in: .global))])
            }.frame(height: 0)
        }
    }

    struct FixedView: View {
        var body: some View {
            GeometryReader { proxy in
                Color
                    .clear
                    .preference(key: RefreshableKeyTypes.PrefKey.self, value: [RefreshableKeyTypes.PrefData(vType: .fixedView, bounds: proxy.frame(in: .global))])
            }
        }
    }

    public struct ActivityRep: UIViewRepresentable {
        public init() {}
        public func makeUIView(context: UIViewRepresentableContext<ActivityRep>) -> UIActivityIndicatorView {
            return UIActivityIndicatorView()
        }

        public func updateUIView(_ uiView: UIActivityIndicatorView, context: UIViewRepresentableContext<ActivityRep>) {
            uiView.startAnimating()
        }
    }

    public enum ScrollType {
        case scrollView
        case list
    }

    struct WrapperView <Content>: View where Content: View {
        let scrollType: ScrollType
        let content: Content

        init(_ scrollType: ScrollType, @ViewBuilder content: ()-> Content) {
            self.scrollType = scrollType
            self.content = content()
        }

        var body: some View {
            Group {
                if self.scrollType == .scrollView {
                    ScrollView { self.content }
                } else {
                    List { self.content }
                }
            }
        }
    }
}

struct RefreshableKeyTypes {
    enum ViewType: Int {
        case movingView
        case fixedView
    }

    struct PrefData: Equatable {
        let vType: ViewType
        let bounds: CGRect
    }

    struct PrefKey: PreferenceKey {
        static var defaultValue: [PrefData] = []

        static func reduce(value: inout [PrefData], nextValue: () -> [PrefData]) {
            value.append(contentsOf: nextValue())
        }

        typealias Value = [PrefData]
    }
}
