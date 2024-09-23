//
//  File.swift
//  
//
//  Created by Evegeny Kalashnikov on 22.05.2024.
//

import SwiftUI
import UIKit

class UIScrollViewOverride: UIScrollView {
    @Binding var translation: CGFloat
    var limits: (min: CGFloat, max: CGFloat)

    init(translation: Binding<CGFloat>, limits: (min: CGFloat, max: CGFloat)) {
        _translation = translation
        self.limits = limits
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let velocity = panGestureRecognizer.velocity(in: self)

        // Disable scroll view pan recognizer when top and scrolling down
        // contentOffset.y can be < 0, because when scroll fast it can be negative for a moment,
        // and if we scroll down in this moment velocity.y == 0.
        // It help not wait until animation back contentOffset.y to 0
        if contentOffset.y <= 0 && velocity.y >= 0 {
            return false
        }

        // Disable scroll view pan recognizer when nemu not fully opened and scrolling up
        if translation != limits.max && velocity.y < 0 {
            return false
        }

        return super.gestureRecognizerShouldBegin(gestureRecognizer)
    }
}

struct ScrollViewWrapper<Content: View>: UIViewRepresentable {

    @Binding var translation: CGFloat
    let onDragChange: (_ yTranslation: CGFloat) -> Void
    let onDargFinished: () -> Void
    let limits: (min: CGFloat, max: CGFloat)
    let content: (UIScrollViewOverride) -> Content

    func makeUIView(context: Context) -> UIScrollViewOverride {
        let scrollView = UIScrollViewOverride(translation: $translation, limits: limits)
        let hostingController = context.coordinator.hostingController

        if #available(iOS 16.0, *) { // iOS 16 and later
            hostingController.sizingOptions = [.intrinsicContentSize]
        }

        scrollView.addSubview(hostingController.view)

        scrollView.contentInsetAdjustmentBehavior = .always
        scrollView.alwaysBounceVertical = true
        scrollView.delegate = context.coordinator

        let panRecognizer = UIPanGestureRecognizer(
            target: context.coordinator,
            action: #selector(context.coordinator.handlePan(_:))
        )
        panRecognizer.delegate = context.coordinator
        scrollView.addGestureRecognizer(panRecognizer)

        hostingController.view.translatesAutoresizingMaskIntoConstraints = false

        scrollView.addConstraints([
            hostingController.view.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: scrollView.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor)
        ])

        hostingController.view.backgroundColor = .clear
        scrollView.backgroundColor = .clear

        scrollView.layoutIfNeeded()

        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollViewOverride, context: Context) {
        scrollView.limits = limits

        context.coordinator.hostingController.rootView = self.content(scrollView)
        if #unavailable(iOS 16.0) { // Before iOS 16
            context.coordinator.hostingController.view.setNeedsUpdateConstraints()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            representable: self,
            hostingController: UIHostingController(rootView: content(UIScrollViewOverride(translation: $translation, limits: limits))),
            onDragChange: onDragChange,
            onDargFinished: onDargFinished
        )
    }

    class Coordinator: NSObject, UIScrollViewDelegate, UIGestureRecognizerDelegate {

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            return true
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            // Should be false for exclude buttons actions during pan over it
            return false
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            // This past enable to scroll when menu full opened
            if otherGestureRecognizer.view is UIScrollViewOverride {
                return true
            }
            return false
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return false
        }

        @objc func handlePan(_ panGestureRecognizer: UIPanGestureRecognizer) {
            guard let scrollView = panGestureRecognizer.view else { return }

            switch panGestureRecognizer.state {
            case .began, .changed:
                let yTranslation = panGestureRecognizer.translation(in: scrollView).y
                onDragChange(yTranslation)
            case .ended, .cancelled:
                onDargFinished()
            default:
                break
            }
        }

        private let representable: ScrollViewWrapper
        var hostingController: UIHostingController<Content>
        private let onDragChange: (_ yTranslation: CGFloat) -> Void
        private let onDargFinished: () -> Void

        init(representable: ScrollViewWrapper,
            hostingController: UIHostingController<Content>,
            onDragChange: @escaping (_ yTranslation: CGFloat) -> Void,
            onDargFinished: @escaping () -> Void) {

            self.hostingController = hostingController
            self.representable = representable
            self.onDragChange = onDragChange
            self.onDargFinished = onDargFinished
        }
    }
}
