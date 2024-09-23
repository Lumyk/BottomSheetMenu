//
//  File.swift
//
//
//  Created by Evegeny Kalashnikov on 22.05.2024.
//

import SwiftUI

extension View {

    public func bottomSheetMenu<HContent: View, MContent: View, Background: View>(
        detents: BottomSheetDetent...,
        selectedDetent: Binding<BottomSheetDetent>,
        background: Background = Color(UIColor.systemBackground).cornerRadius(10),
        onDismiss: @escaping () -> Void = {},
        onDrag: @escaping (_ translation: CGFloat, _ detent: BottomSheetDetent) -> Void = { _, _ in },
        shadowAction: (() -> Void)? = nil,
        header: () -> HContent = { EmptyView() },
        main: @escaping (BottomSheetMenuScroller) -> MContent
    ) -> some View {
        modifier(
            BottomSheetMenu(
                detents: Set(detents),
                selectedDetent: selectedDetent,
                background: background,
                onDismiss: onDismiss,
                onDrag: onDrag, 
                shadowAction: shadowAction,
                hcontent: header,
                mcontent: main
            )
        )
    }
}
