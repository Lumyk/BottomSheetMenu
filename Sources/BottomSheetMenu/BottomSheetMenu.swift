//
//  File.swift
//  
//
//  Created by Evegeny Kalashnikov on 22.05.2024.
//

import SwiftUI

struct BottomSheetMenu<HContent: View, MContent: View, Background: View>: ViewModifier {

    let detents: Set<BottomSheetDetent>
    @Binding var selectedDetent: BottomSheetDetent
    let mainContent: MContent
    let headerContent: HContent
    let onDismiss: () -> Void
    let onDrag: (_ translation: CGFloat, _ detent: BottomSheetDetent) -> Void
    let background: Background

    @State private var isPresented: Bool = true
    @State private var translation: CGFloat = 0
    @State private var oldTranslation: CGFloat?
    @State private var startTime: DragGesture.Value?
    @State private var limits: BottomSheetDetent.Limits = (min: 0, max: 0)
    private let animation: Animation = .default
    private let dragIndicatorColor: Color = .init(red: 194/255.0, green: 199/255.0, blue: 208/255.0)

    init(detents: Set<BottomSheetDetent>,
         selectedDetent: Binding<BottomSheetDetent>,
         background: Background,
         onDismiss: @escaping () -> Void,
         onDrag: @escaping (_ translation: CGFloat, _ detent: BottomSheetDetent) -> Void,
         @ViewBuilder hcontent: () -> HContent,
         @ViewBuilder mcontent: () -> MContent) {

        self.detents = detents
        _selectedDetent = selectedDetent

        self.background = background
        self.onDismiss = onDismiss
        self.onDrag = onDrag

        self.headerContent = hcontent()
        self.mainContent = mcontent()

        self.isPresented = selectedDetent.wrappedValue != .notPresented
    }

    func updateTranslation(_ yTranslation: CGFloat, yVelocity: Double, geometry: GeometryProxy) {
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

        let detent = detents.calculateDetent(translation: translation, yVelocity: yVelocity, geometry: geometry)
        onDrag(translation, detent)
    }

    func magnetize(yVelocity: Double, geometry: GeometryProxy) {
        let detent = detents.calculateDetent(translation: translation, yVelocity: yVelocity, geometry: geometry)
        let translation = detent.size(in: geometry)
        withAnimation(self.translation == translation ? .none : animation) {
            self.translation = translation
        }
        onDrag(translation, detent)
        selectedDetent = detent
        oldTranslation = nil
    }

    /// Calculate velocity based on pt/s so it matches the UIPanGesture
    func velocity(for value: DragGesture.Value) -> CGFloat {
        guard let startTime else { return 0 }
        let distance = value.translation.height
        let time = value.time.timeIntervalSince(startTime.time)
        return -1 * ((distance / time) / 1000)
    }

    func body(content: Content) -> some View {
        GeometryReader { mainGeometry in
            ZStack {
                content
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
                                            geometry: geometry
                                        )
                                        if startTime == nil { startTime = value }
                                    }
                                    .onEnded { value in
                                        oldTranslation = nil
                                        let yVelocity = velocity(for: value)
                                        startTime = nil
                                        magnetize(yVelocity: yVelocity, geometry: geometry)
                                    }
                            )

                            ScrollViewWrapper(
                                translation: $translation,
                                onDragChange: { updateTranslation($0, yVelocity: 0, geometry: geometry) },
                                onDargFinished: { magnetize(yVelocity: 0, geometry: geometry) },
                                limits: limits
                            ) {
                                mainContent
                                    .frame(width: geometry.size.width)
                            }
                        }
                        .background(background)
                        .frame(height: limits.max)
                        .onDisappear {
                            onDismiss()
                        }
                        .offset(y: geometry.size.height - translation)
                    }
                    .edgesIgnoringSafeArea([.bottom])
                    .transition(.move(edge: .bottom))
                }
            }
            .onAppear {
                limits = detents.limits(for: mainGeometry)
                translation = selectedDetent.size(in: mainGeometry)
            }
            .onChange(of: mainGeometry.size, perform: { _ in
                limits = detents.limits(for: mainGeometry)
            })
            .onChange(of: selectedDetent, perform: { detent in
                if !isPresented && detent != .notPresented {
                    isPresented = true
                }
                let translation = detent.size(in: mainGeometry)
                if self.translation == translation {
                    isPresented = detent != .notPresented
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
            })
        }
    }
}

