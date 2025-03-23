//
//  BottomSheetMenuContent.swift
//  BottomSheetMenu
//
//  Created by Yevhenii Kalashnikov on 21.03.2025.
//

import Foundation
import SwiftUI

public struct BottomSheetMenuContent<C: View, ID: Equatable> {
    public let id: ID
    @ViewBuilder public var content: () -> C

    public init(id: ID, @ViewBuilder content: @escaping () -> C) {
        self.id = id
        self.content = content
    }
}

public struct BottomSheetMenuContentExtended<C: View, ID: Equatable, T> {
    public let id: ID
    @ViewBuilder public var content: (T) -> C

    public init(id: ID, @ViewBuilder content: @escaping (T) -> C) {
        self.id = id
        self.content = content
    }
}

public extension BottomSheetMenuContent {

    static var none: BottomSheetMenuContent<EmptyView, Int> {
        .init(id: 0, content: { EmptyView() })
    }
}
