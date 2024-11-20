//
//  File.swift
//
//
//  Created by Evegeny Kalashnikov on 22.05.2024.
//

import SwiftUI

extension View {

    public func bottomSheetMenu<HContent: View, MContent: View, FContent: View>(
        configuration: BottomSheetMenuConfiguration = .init(),
        state: Binding<BottomSheetMenuDetentState>,
        onDismiss: @escaping () -> Void = {},
        shadowAction: (() -> Void)? = nil,
        @ViewBuilder header: () -> HContent = { EmptyView() },
        @ViewBuilder footer: @escaping () -> FContent = { EmptyView() },
        @ViewBuilder main: @escaping (BottomSheetMenuScroller) -> MContent
    ) -> some View {
        modifier(
            BottomSheetMenu(
                configuration: configuration,
                state: state,
                onDismiss: onDismiss,
                shadowAction: shadowAction,
                hcontent: header,
                mcontent: main,
                fcontent: footer
            )
        )
    }
}
