//
//  BottomSheetMenuDetentState.swift
//  BottomSheetMenu
//
//  Created by Yevhenii Kalashnikov on 05.11.2024.
//

import Foundation

public struct BottomSheetMenuDetentState: Equatable {
    public let detents: Set<BottomSheetDetent>
    public internal(set) var defaultDetent: BottomSheetDetent
    public var selectedDetent: BottomSheetDetent
    public internal(set) var currentDetent: BottomSheetDetent
    public internal(set) var currentTranslation: CGFloat

    public init(detents: BottomSheetDetent..., defaultDetent: BottomSheetDetent) {
        self.detents = Set(detents)
        self.defaultDetent = defaultDetent
        self.selectedDetent = defaultDetent
        self.currentDetent = defaultDetent
        self.currentTranslation = 0
    }
}
