//
//  File.swift
//
//
//  Created by Evegeny Kalashnikov on 22.05.2024.
//

import SwiftUI
import UIKit

class UIScrollViewOverride: UIScrollView {
    var dynamicSizeParams: () -> (yTranslation: CGFloat, maxLimit: CGFloat)

    init(dynamicSizeParams: @escaping () -> (yTranslation: CGFloat, maxLimit: CGFloat)) {
        self.dynamicSizeParams = dynamicSizeParams
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

        let params = dynamicSizeParams()
        // Disable scroll view pan recognizer when nemu not fully opened and scrolling up
        if params.yTranslation != params.maxLimit && velocity.y < 0 {
            return false
        }

        return super.gestureRecognizerShouldBegin(gestureRecognizer)
    }
}

struct ScrollViewWrapper<Content: View>: UIViewRepresentable {

    let onDragChange: (_ yTranslation: CGFloat, _ yVelocity: CGFloat) -> Void
    let onDargFinished: (_ yVelocity: CGFloat) -> Void
    let dynamicParams: () -> (yTranslation: CGFloat, maxLimit: CGFloat)
    let content: (UIScrollViewOverride) -> Content

    func makeUIView(context: Context) -> UIScrollViewOverride {
        let scrollView = UIScrollViewOverride(dynamicSizeParams: dynamicParams)
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
        scrollView.dynamicSizeParams = dynamicParams
        context.coordinator.hostingController.rootView = self.content(scrollView)
        if #unavailable(iOS 16.0) { // Before iOS 16
            context.coordinator.hostingController.view.setNeedsUpdateConstraints()
            // Fix for correct size calculation in iOS 15 and less
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                context.coordinator.hostingController.view.setNeedsUpdateConstraints()
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            representable: self,
            hostingController: UIHostingController(rootView: content(UIScrollViewOverride(dynamicSizeParams: dynamicParams))),
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

            let yVelocity = panGestureRecognizer.velocity(in: scrollView).y

            switch panGestureRecognizer.state {
            case .began, .changed:
                let yTranslation = panGestureRecognizer.translation(in: scrollView).y

                onDragChange(yTranslation, yVelocity)
            case .ended, .cancelled:
                onDargFinished(yVelocity)
            default:
                break
            }
        }

        private let representable: ScrollViewWrapper
        var hostingController: UIHostingController<Content>
        private let onDragChange: (_ yTranslation: CGFloat, _ yVelocity: CGFloat) -> Void
        private let onDargFinished: (_ yVelocity: CGFloat) -> Void

        init(representable: ScrollViewWrapper,
             hostingController: UIHostingController<Content>,
             onDragChange: @escaping (_ yTranslation: CGFloat, _ yVelocity: CGFloat) -> Void,
             onDargFinished: @escaping (_ yVelocity: CGFloat) -> Void) {

            self.hostingController = hostingController
            self.representable = representable
            self.onDragChange = onDragChange
            self.onDargFinished = onDargFinished
        }
    }
}
