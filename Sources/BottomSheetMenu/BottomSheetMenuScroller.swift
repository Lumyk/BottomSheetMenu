//
//  BottomSheetMenuScroller.swift
//
//
//  Created by Yevhenii Kalashnikov on 20.09.2024.
//

import SwiftUI

public class BottomSheetMenuScroller {
    weak var scrollView: UIScrollViewOverride?
    private var indexes: [AnyHashable: CGRect] = [:]

    private var coordinateSpaceName: String { String(describing: self) }

    init(scrollView: UIScrollViewOverride? = nil) {
        self.scrollView = scrollView
    }

    func mark<T: Hashable, V: View>(item: T, @ViewBuilder view: () -> V) -> some View {
        view().background {
            GeometryReader { geometry -> Color in
                DispatchQueue.main.async {
                    self.indexes[.init(item)] = geometry.frame(in: .named(self.coordinateSpaceName))
                }
                return Color.clear
            }
        }
    }

    func content<V: View>(scrollView: UIScrollViewOverride, @ViewBuilder view: () -> V) -> some View {
        view()
            .coordinateSpace(name: coordinateSpaceName)
            .onAppear { [weak self, weak scrollView] in
                self?.scrollView = scrollView
            }
    }

    public func scrollTo<T: Hashable>(item: T, animated: Bool = false) {
        guard let scrollView else { return }
        DispatchQueue.main.async {
            guard let rect = self.indexes[.init(item)] else { return }
            scrollView.scrollRectToVisible(rect, animated: animated)
        }
    }
}

public extension View {
    func mark<T: Hashable>(item: T, scroller: BottomSheetMenuScroller) -> some View {
        scroller.mark(item: item) { self }
    }
}
