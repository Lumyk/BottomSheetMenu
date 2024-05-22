//
//  File.swift
//  
//
//  Created by Evegeny Kalashnikov on 22.05.2024.
//

import SwiftUI

public enum BottomSheetDetent: Hashable {
    typealias Limits = (min: CGFloat, max: CGFloat)

    case hidden
    case medium
    case large
    /// fullScreen — this is mode when drag Indicator hides behind the screen area
    case fullScreen
    case fraction(CGFloat)
    case height(CGFloat)

    public func size(in geometry: GeometryProxy) -> CGFloat {
        let height = geometry.size.height + geometry.safeAreaInsets.bottom
        let bottom: CGFloat = 0
        switch self {
        case .hidden:
            return 0
        case .medium:
            return height / 2 + bottom
        case .large:
            return height + bottom
        case .fullScreen:
            return height + bottom + DragIndicator.height
        case .fraction(let fraction):
            return min(height * fraction + bottom, height + bottom)
        case .height(let h):
            return min(h, height + bottom)
        }
    }
}

extension Set where Element == BottomSheetDetent {

    func limits(for geometry: GeometryProxy) -> BottomSheetDetent.Limits {
        let detentLimits: [CGFloat] = self
            .map { $0.size(in: geometry) }
            .sorted(by: <)

        return (min: detentLimits.first ?? 0, max: detentLimits.last ?? 0)
    }

    func calculateDetent(translation: CGFloat, yVelocity: CGFloat, geometry: GeometryProxy) -> BottomSheetDetent {

        let sortedDetents = self.sorted { $0.size(in: geometry) < $1.size(in: geometry) }
        guard let minDetent = sortedDetents.first else { return .hidden }
        guard let maxDetent = sortedDetents.last else { return minDetent }

        if translation < minDetent.size(in: geometry) {
            return minDetent
        } else if translation > maxDetent.size(in: geometry) {
            return maxDetent
        }

        for (lower, upper) in zip(sortedDetents, sortedDetents.dropFirst()) {
            let lowerSize = lower.size(in: geometry)
            let upperSize = upper.size(in: geometry)
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
