//
//  File.swift
//
//
//  Created by Evegeny Kalashnikov on 22.05.2024.
//

import SwiftUI

struct BottomSheetMenu<HContent: View, MContent: View, FContent: View>: ViewModifier {

    @Environment(\.orientation) var orientation

    let onDismiss: () -> Void
    let shadowAction: (() -> Void)?

    let headerContent: HContent
    let mainContent: (BottomSheetMenuScroller) -> MContent
    @ViewBuilder let footerContent: () -> FContent

    @State private var configuration: BottomSheetMenuConfiguration
    @Binding private var state: BottomSheetMenuDetentState

    @State private var isPresented: Bool
    @State private var translation: CGFloat = 0
    @State private var oldTranslation: CGFloat?
    @State private var startTime: DragGesture.Value?
    @State private var limits: BottomSheetDetent.Limits = (min: 0, max: 0)
    @State private var scroller: BottomSheetMenuScroller = BottomSheetMenuScroller()
    @State private var footerContentHeight: CGFloat = 0

    private let animation: Animation = .default
    private let dragIndicatorColor: Color = .init(red: 194/255.0, green: 199/255.0, blue: 208/255.0)

    init(configuration: BottomSheetMenuConfiguration,
         state: Binding<BottomSheetMenuDetentState>,
         onDismiss: @escaping () -> Void,
         shadowAction: (() -> Void)?,
         @ViewBuilder hcontent: () -> HContent,
         @ViewBuilder mcontent: @escaping (BottomSheetMenuScroller) -> MContent,
         @ViewBuilder fcontent: @escaping () -> FContent) {

        self.configuration = configuration
        _state = state

        self.onDismiss = onDismiss
        self.shadowAction = shadowAction

        headerContent = hcontent()
        mainContent = mcontent
        footerContent = fcontent

        isPresented = state.selectedDetent.wrappedValue != .notPresented
    }

    private func updateTranslation(_ yTranslation: CGFloat, yVelocity: Double, geometry: GeometryProxy) {
        if oldTranslation == nil { oldTranslation = translation }
        let oldTranslation = oldTranslation ?? translation

        let translation = min(oldTranslation - yTranslation, limits.max)

        // If translation less then min we add bounce effect.
        // 0.4 is optimal factor for bounce
        withAnimation(animation) {
            if translation < limits.min {
                let difference = limits.min - translation
                self.translation = limits.min - (difference * 0.4)
            } else {
                self.translation = translation
            }
        }

        let detent = state.detents.calculateDetent(
            translation: translation,
            yVelocity: yVelocity,
            geometry: geometry,
            bottomContentHeight: footerContentHeight
        )

        state.currentDetent = detent
        state.currentTranslation = translation
    }

    private func magnetize(yVelocity: Double, geometry: GeometryProxy) {
        let detent = state.detents.calculateDetent(
            translation: translation,
            yVelocity: yVelocity,
            geometry: geometry,
            bottomContentHeight: footerContentHeight
        )
        let translation = detent.size(in: geometry, bottomContentHeight: footerContentHeight)
        withAnimation(self.translation == translation ? .none : animation) {
            self.translation = translation
        }

        state.currentDetent = detent
        state.currentTranslation = translation
        state.selectedDetent = detent

        oldTranslation = nil
    }

    /// Calculate velocity based on pt/s so it matches the UIPanGesture
    private func velocity(for value: DragGesture.Value) -> CGFloat {
        guard let startTime else { return 0 }
        let distance = value.translation.height
        let time = value.time.timeIntervalSince(startTime.time)
        return -1 * ((distance / time) / 1000)
    }

    private func onChange(detent: BottomSheetDetent, geometry: GeometryProxy) {
        if !isPresented && detent != .notPresented {
            isPresented = true
        }
        let translation = detent.size(in: geometry, bottomContentHeight: footerContentHeight)
        if self.translation == translation {
            // 0.5 showld be enough to finish the animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isPresented = detent != .notPresented
            }
        } else {
            var transaction = Transaction(animation: animation)
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
                self.translation = translation
            }
        }
    }

    func body(content: Content) -> some View {
        GeometryReader { mainGeometry in
            ZStack {
                content
                    .overlay {
                        if let shadowAction {
                            Color.black.opacity(isPresented ? 0.5 / mainGeometry.size.height * translation  : 0)
                                .edgesIgnoringSafeArea([.top, .bottom])
                                .onTapGesture { shadowAction() }
                        }
                    }
                if isPresented {
                    GeometryReader { geometry in
                        VStack(spacing: 0) {
                            // If / else statement here breaks the animation from the bottom level
                            // Might want to see if we can refactor the top level animation a bit
                            VStack(spacing: 0) {
                                DragIndicator(color: dragIndicatorColor)

                                headerContent
                                    .contentShape(Rectangle())
                            }
                            .frame(maxWidth: .infinity)
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(coordinateSpace: .global)
                                    .onChanged { value in
                                        let yVelocity = velocity(for: value)
                                        updateTranslation(
                                            value.translation.height,
                                            yVelocity: yVelocity,
                                            geometry: mainGeometry
                                        )
                                        if startTime == nil { startTime = value }
                                    }
                                    .onEnded { value in
                                        oldTranslation = nil
                                        let yVelocity = velocity(for: value)
                                        startTime = nil
                                        magnetize(yVelocity: yVelocity, geometry: mainGeometry)
                                    }
                            )
                            .onTapGesture {
                                if state.selectedDetent != state.defaultDetent {
                                    // Need to call onChange to update translation before changing detent
                                    onChange(detent: state.defaultDetent, geometry: mainGeometry)
                                    state.currentDetent = state.defaultDetent
                                    state.selectedDetent = state.defaultDetent
                                }
                            }

                            ScrollViewWrapper(
                                translation: $translation,
                                onDragChange: { updateTranslation($0, yVelocity: 0, geometry: mainGeometry) },
                                onDargFinished: { magnetize(yVelocity: 0, geometry: mainGeometry) },
                                limits: limits
                            ) { scrollView in
                                scroller.content(scrollView: scrollView) {
                                    VStack(spacing: 0) {
                                        mainContent(scroller)
                                            .frame(width: geometry.size.width)
                                        Color.clear
                                            .frame(height: footerContentHeight)
                                    }
                                }
                            }
                        }
                        .background(configuration.background)
                        .frame(height: limits.max)
                        .onDisappear {
                            onDismiss()
                        }
                        .offset(y: geometry.size.height - translation)
                    }
                    .edgesIgnoringSafeArea([.bottom])
                    .transition(.move(edge: .bottom))
                }

                VStack {
                    Spacer()

                    VStack {
                        footerContent()
                            .background(
                                GeometryReader { geometry in
                                    Color.clear
                                        .onAppear {
                                            footerContentHeight = geometry.size.height
                                        }
                                }
                            )
                            .background(Color.clear)
                    }
                    .background(configuration.footerBackgroundColor)
                    .edgesIgnoringSafeArea(.bottom)
                }
            }
            .onAppear {
                limits = state.detents.limits(for: mainGeometry, bottomContentHeight: footerContentHeight)
                translation = state.selectedDetent.size(in: mainGeometry, bottomContentHeight: footerContentHeight)
            }
            .onChange(of: translation, perform: {
                state.currentTranslation = $0
            })
            .onChange(of: mainGeometry.size, perform: { _ in
                limits = state.detents.limits(for: mainGeometry, bottomContentHeight: footerContentHeight)
            })
            .onChange(of: state.selectedDetent, perform: {
                onChange(detent: $0, geometry: mainGeometry)
            })
            .onChange(of: orientation.type, perform: { _ in
                onChange(detent: state.selectedDetent, geometry: mainGeometry)
            })
        }
    }
}
