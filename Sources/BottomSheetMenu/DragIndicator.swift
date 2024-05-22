//
//  File.swift
//
//
//  Created by Evegeny Kalashnikov on 22.05.2024.
//

import SwiftUI

struct DragIndicator: View {
    static let height: CGFloat = 14
    let color: Color

    var body: some View {
        Rectangle()
            .fill(Color.clear)
            .frame(height: DragIndicator.height)
            .frame(maxWidth: .infinity)
            .overlay {
                Capsule()
                    .frame(width: 36, height: 5)
                    .foregroundStyle(color)
                    .padding(.top, 6)
            }
    }
}
