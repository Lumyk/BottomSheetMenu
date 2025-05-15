//
//  File.swift
//
//
//  Created by Evegeny Kalashnikov on 22.05.2024.
//

import SwiftUI

struct MainContentView<Content: View, ID: Equatable>: View, Equatable {

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.content.id == rhs.content.id &&
        lhs.width == rhs.width &&
        lhs.footerContentHeight == rhs.footerContentHeight
    }

    let onDragChange: (_ yTranslation: CGFloat, _ yVelocity: CGFloat) -> Void
    let onDargFinished: (_ yVelocity: CGFloat) -> Void
    let dynamicParams: () -> (yTranslation: CGFloat, maxLimit: CGFloat)
    let width: CGFloat
    let footerContentHeight: CGFloat
    let scroller: BottomSheetMenuScroller
    let content: BottomSheetMenuContentExtended<Content, ID, BottomSheetMenuScroller>

    var body: some View {
        ScrollViewWrapper(
            onDragChange: onDragChange,
            onDargFinished: onDargFinished,
            dynamicParams: {
                let params = dynamicParams()
                return (params.yTranslation, params.maxLimit)
            }
        ) { scrollView in
            scroller.content(scrollView: scrollView) {
                VStack(spacing: 0) {
                    content.content(scroller)
                        .frame(width: width)
                    Color.clear
                        .frame(height: footerContentHeight)
                }
            }
        }
    }
}

struct FooterContentView<Content: View, ID: Equatable>: View, Equatable {

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.content.id == rhs.content.id
    }

    let configuration: BottomSheetMenuConfiguration
    @Binding var footerContentHeight: CGFloat
    let content: BottomSheetMenuContent<Content, ID>

    var body: some View {
        VStack {
            Spacer()

            VStack {
                content.content()
                    .background(
                        GeometryReader { geometry in
                            Color.clear
                                .onAppear {
                                    footerContentHeight = geometry.size.height
                                }
                                .onChange(of: geometry.size) {
                                    footerContentHeight = $0.height
                                }
                        }
                    )
                    .background(Color.clear)
            }
            .background(configuration.footerBackgroundColor)
            .edgesIgnoringSafeArea(.bottom)
        }
    }
}

struct HeaderContentView<Content: View, ID: Equatable>: View, Equatable {

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.content.id == rhs.content.id
    }

    private let dragIndicatorColor: Color = .init(red: 194/255.0, green: 199/255.0, blue: 208/255.0)

    let content: BottomSheetMenuContent<Content, ID>
    @Binding var contentHeight: CGFloat
    let onChanged: (DragGesture.Value) -> Void
    let onEnded: (DragGesture.Value) -> Void
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            DragIndicator(color: dragIndicatorColor)

            content.content()
                .background(
                    GeometryReader { geometry in
                        Color.clear
                            .onAppear {
                                contentHeight = geometry.size.height
                            }
                            .onChange(of: geometry.size) {
                                contentHeight = $0.height
                            }
                    }
                )
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(coordinateSpace: .global)
                .onChanged(onChanged)
                .onEnded(onEnded)
        )
        .onTapGesture(perform: onTap)
    }
}


struct BottomSheetMenu<HContent: View, HID: Equatable, MContent: View, MID: Equatable, FContent: View, FID: Equatable>: ViewModifier, Equatable {

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.headerContent.id == rhs.headerContent.id &&
        lhs.mainContent.id == rhs.mainContent.id &&
        lhs.footerContent.id == rhs.footerContent.id
    }

    @Environment(\.orientation) var orientation

    let configuration: BottomSheetMenuConfiguration
    let detents: Set<BottomSheetDetent>

    @Binding var currentDetent: BottomSheetDetent
    @Binding var selectedDetent: BottomSheetDetent
    @Binding var currentTranslation: CGFloat

    let onDismiss: () -> Void
    let shadowAction: (() -> Void)?

    let headerContent: BottomSheetMenuContent<HContent, HID>
    let mainContent: BottomSheetMenuContentExtended<MContent, MID, BottomSheetMenuScroller>
    let footerContent: BottomSheetMenuContent<FContent, FID>

    @State private var isPresented: Bool
    @State private var translation: CGFloat = 0
    @State private var oldTranslation: CGFloat?
    @State private var startTime: DragGesture.Value?
    @State private var limits: BottomSheetDetent.Limits = (min: 0, max: 0)
    @State private var scroller: BottomSheetMenuScroller = BottomSheetMenuScroller()
    @State private var headerContentHeight: CGFloat = 0
    @State private var footerContentHeight: CGFloat = 0

    private let defaultDetent: BottomSheetDetent?
    private let animation: Animation = .easeInOut(duration: 0.23)
    private let transaction = Transaction(animation: .easeInOut(duration: 0.23))

    init(configuration: BottomSheetMenuConfiguration,
         detents: Set<BottomSheetDetent>,
         currentDetent: Binding<BottomSheetDetent>,
         selectedDetent: Binding<BottomSheetDetent>,
         defaultDetent: BottomSheetDetent?,
         translation: Binding<CGFloat>,
         onDismiss: @escaping () -> Void,
         shadowAction: (() -> Void)?,
         header: BottomSheetMenuContent<HContent, HID>,
         main: BottomSheetMenuContentExtended<MContent, MID, BottomSheetMenuScroller>,
         footer: BottomSheetMenuContent<FContent, FID>) {

        self.configuration = configuration
        self.detents = detents

        _currentDetent = currentDetent
        _selectedDetent = selectedDetent
        _currentTranslation = translation

        self.defaultDetent = defaultDetent

        self.onDismiss = onDismiss
        self.shadowAction = shadowAction

        self.headerContent = header
        self.mainContent = main
        self.footerContent = footer

        isPresented = selectedDetent.wrappedValue != .notPresented
    }

    private func updateTranslation(_ yTranslation: CGFloat, yVelocity: Double, geometry: GeometryProxy) {

        if oldTranslation == nil { oldTranslation = translation }
        let oldTranslation = oldTranslation ?? translation

        let translation = min(oldTranslation - yTranslation, limits.max)
        let detent = detents.calculateDetent(
            translation: translation,
            yVelocity: yVelocity,
            geometry: geometry,
            bottomContentHeight: footerContentHeight
        )

        withAnimation(animation) {
            // If translation less then min we add bounce effect.
            // 0.4 is optimal factor for bounce
            if translation < limits.min {
                let difference = limits.min - translation
                currentTranslation = limits.min - (difference * 0.4)
                self.translation = limits.min - (difference * 0.4)
            } else {
                currentTranslation = translation
                self.translation = translation
            }

            currentDetent = detent
        }
    }

    private func magnetize(yVelocity: Double, geometry: GeometryProxy) {
        let detent = detents.calculateDetent(
            translation: translation,
            yVelocity: yVelocity,
            geometry: geometry,
            bottomContentHeight: footerContentHeight
        )
        let translation = detent.size(in: geometry, bottomContentHeight: footerContentHeight + headerContentHeight)

        withAnimation(animation) {
            currentTranslation = translation
            self.translation = translation

            currentDetent = detent
            selectedDetent = detent
        }

        oldTranslation = nil
    }

    /// Calculate velocity based on pt/s so it matches the UIPanGesture
    private func velocity(for value: DragGesture.Value) -> CGFloat {
        guard let startTime else { return 0 }
        let distance = value.translation.height
        let time = value.time.timeIntervalSince(startTime.time)
        return (distance / time)
    }

    private func onChange(detent: BottomSheetDetent, geometry: GeometryProxy, animated: Bool = true) {
        if !isPresented && detent != .notPresented {
            isPresented = true
        }
        let translation = detent.size(in: geometry, bottomContentHeight: footerContentHeight + headerContentHeight)
        if self.translation == translation {
            // 0.5 showld be enough to finish the animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isPresented = detent != .notPresented
            }
        } else {
            var transaction = Transaction(animation: animated ? animation : .none)
            if #available(iOS 17.0, *) {
                transaction.addAnimationCompletion {
                    isPresented = detent != .notPresented
                }
            } else {
                // 0.5 showld be enough to finish the animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isPresented = detent != .notPresented
                }
            }

            withTransaction(transaction) {
                currentTranslation = translation
                self.translation = translation
            }
        }
    }

    func body(content: Content) -> some View {

        GeometryReader { mainGeometry in
            ZStack {
                if configuration.hideMainContentInFullScreen && translation == BottomSheetDetent.fullScreen.size(in: mainGeometry) {
                    configuration.fullScreenContentOverlayColor
                } else {
                    content
                        .overlay {
                            if let shadowAction {
                                Color.black
                                    .opacity(isPresented ? 0.5 / mainGeometry.size.height * translation  : 0)
                                    .edgesIgnoringSafeArea([.top, .bottom])
                                    .onTapGesture { shadowAction() }
                            }
                        }
                }

                // If / else statement here breaks the animation from the bottom level
                // Might want to see if we can refactor the top level animation a bit
                if isPresented {
                    GeometryReader { geometry in
                        VStack(spacing: 0) {

                            // Header content
                            EquatableView(content: HeaderContentView(
                                content: headerContent,
                                contentHeight: $headerContentHeight
                            ) { value in
                                let yVelocity = velocity(for: value)
                                updateTranslation(
                                    value.translation.height,
                                    yVelocity: yVelocity,
                                    geometry: mainGeometry
                                )
                                if startTime == nil { startTime = value }
                            } onEnded: { value in
                                oldTranslation = nil
                                let yVelocity = velocity(for: value)
                                startTime = nil
                                magnetize(yVelocity: yVelocity, geometry: mainGeometry)
                            } onTap: {
                                if let defaultDetent, selectedDetent != defaultDetent {
                                    // Need to call onChange to update translation before changing detent
                                    onChange(detent: defaultDetent, geometry: mainGeometry)
                                    currentDetent = defaultDetent
                                    selectedDetent = defaultDetent
                                }
                            })

                            // Main content
                            EquatableView(content: MainContentView(
                                onDragChange: { updateTranslation($0, yVelocity: $1, geometry: mainGeometry) },
                                onDargFinished: { magnetize(yVelocity: $0, geometry: mainGeometry) },
                                dynamicParams: { (translation, limits.max) },
                                width: geometry.size.width,
                                footerContentHeight: footerContentHeight,
                                scroller: scroller,
                                content: mainContent
                            ))
                        }
                        .background(configuration.background)
                        .frame(height: limits.max)
                        .onDisappear { onDismiss() }
                        .offset(y: geometry.size.height - translation)
                    }
                    .edgesIgnoringSafeArea([.bottom])
                    .transition(.move(edge: .bottom))
                }

                // Footer content
                EquatableView(content: FooterContentView(
                    configuration: configuration,
                    footerContentHeight: $footerContentHeight,
                    content: footerContent
                ))
            }
            .onAppear {
                limits = detents.limits(for: mainGeometry, bottomContentHeight: footerContentHeight + headerContentHeight)
                onChange(detent: selectedDetent, geometry: mainGeometry, animated: false)
            }
            .onChange(of: mainGeometry.size) { _ in
                limits = detents.limits(for: mainGeometry, bottomContentHeight: footerContentHeight + headerContentHeight)
            }
            .onChange(of: selectedDetent) {
                onChange(detent: $0, geometry: mainGeometry)
            }
            .onChange(of: orientation.type) { _ in
                onChange(detent: selectedDetent, geometry: mainGeometry)
            }
        }
    }
}
