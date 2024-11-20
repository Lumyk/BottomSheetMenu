//
//  BottomSheetMenuConfiguration.swift
//  BottomSheetMenu
//
//  Created by Yevhenii Kalashnikov on 05.11.2024.
//

import SwiftUI

public struct BottomSheetMenuConfiguration {
    let background: AnyView
    var footerBackgroundColor: Color

    public init<Background: View>(background: Background = Color(UIColor.systemBackground).cornerRadius(10),
                                  footerBackgroundColor: Color = .white) {

        self.background = AnyView(background)
        self.footerBackgroundColor = footerBackgroundColor
    }
}
