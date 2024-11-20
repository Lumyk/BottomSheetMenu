//
//  File.swift
//
//
//  Created by Evegeny Kalashnikov on 22.05.2024.
//

import SwiftUI

public enum BottomSheetDetent: Hashable {
    typealias Limits = (min: CGFloat, max: CGFloat)

    /// hidden — this is state when menu height == 0 but it still presented
    case hidden
    /// notPresented — this is state when all SwiftUI code not presented
    case notPresented
    case medium
    case large
    case bottom
    /// fullScreen — this is state when drag Indicator hides behind the screen area
    case fullScreen
    case fraction(CGFloat)
    case height(CGFloat)

    public func size(in geometry: GeometryProxy, bottomContentHeight: CGFloat = 0) -> CGFloat {
        let height = geometry.size.height + geometry.safeAreaInsets.bottom
        switch self {
        case .hidden, .notPresented:
            return 0
        case .medium:
            return height / 2
        case .large:
            return height
        case .fullScreen:
            return height + DragIndicator.height
        case .fraction(let fraction):
            return min(height * fraction, height)
        case .height(let h):
            return min(h, height)
        case .bottom:
            return geometry.safeAreaInsets.bottom + bottomContentHeight + DragIndicator.height + 6
        }
    }
}

extension Set where Element == BottomSheetDetent {

    func limits(for geometry: GeometryProxy, bottomContentHeight: CGFloat) -> BottomSheetDetent.Limits {
        let detentLimits: [CGFloat] = self
            .map { $0.size(in: geometry, bottomContentHeight: bottomContentHeight) }
            .sorted(by: <)

        return (min: detentLimits.first ?? 0, max: detentLimits.last ?? 0)
    }

    func calculateDetent(translation: CGFloat,
                         yVelocity: CGFloat,
                         geometry: GeometryProxy,
                         bottomContentHeight: CGFloat) -> BottomSheetDetent {

        let sortedDetents = self.sorted {
            $0.size(in: geometry, bottomContentHeight: bottomContentHeight) < $1.size(in: geometry, bottomContentHeight: bottomContentHeight)
        }
        guard let minDetent = sortedDetents.first else { return .notPresented }
        guard let maxDetent = sortedDetents.last else { return minDetent }

        if translation < minDetent.size(in: geometry, bottomContentHeight: bottomContentHeight) {
            return minDetent
        } else if translation > maxDetent.size(in: geometry, bottomContentHeight: bottomContentHeight) {
            return maxDetent
        }

        for (lower, upper) in zip(sortedDetents, sortedDetents.dropFirst()) {
            let lowerSize = lower.size(in: geometry, bottomContentHeight: bottomContentHeight)
            let upperSize = upper.size(in: geometry, bottomContentHeight: bottomContentHeight)
            let middle = lowerSize + (upperSize - lowerSize) / 2

            if lowerSize...upperSize ~= translation {
                if abs(yVelocity) > 1.8 {
                    return yVelocity > 0 ? upper : lower
                } else {
                    return translation > middle ? upper : lower
                }
            }
        }

        return minDetent
    }
}
