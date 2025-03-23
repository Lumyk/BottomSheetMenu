//
//  File.swift
//
//
//  Created by Evegeny Kalashnikov on 22.05.2024.
//

import SwiftUI

extension View {

    public func bottomSheetMenu<HContent: View, HID: Equatable, MContent: View, MID: Equatable, FContent: View, FID: Equatable>(
        configuration: BottomSheetMenuConfiguration = .init(),
        detents: BottomSheetDetent...,
        currentDetent: Binding<BottomSheetDetent> = .constant(.medium),
        selectedDetent: Binding<BottomSheetDetent>,
        translation: Binding<CGFloat> = .constant(0),
        onDismiss: @escaping () -> Void = {},
        shadowAction: (() -> Void)? = nil,
        header: BottomSheetMenuContent<HContent, HID> = .none,
        main: BottomSheetMenuContentExtended<MContent, MID, BottomSheetMenuScroller>,
        footer: BottomSheetMenuContent<FContent, FID> = .none
    ) -> some View {
        modifier(
            BottomSheetMenu(
                configuration: configuration,
                detents: Set(detents),
                currentDetent: currentDetent,
                selectedDetent: selectedDetent,
                translation: translation,
                onDismiss: onDismiss,
                shadowAction: shadowAction,
                header: header,
                main: main,
                footer: footer
            )
        )
    }
}
