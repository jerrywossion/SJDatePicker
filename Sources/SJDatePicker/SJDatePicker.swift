//
//  SJDatePicker.swift
//  SJDatePicker
//
//  Created by Jie Weng on 2022/4/5.
//

import Cocoa
import Combine

open class SJDatePicker {
    public enum DateType {
        case single(Date)
        case range(ClosedRange<Date>)
    }

    public var date: AnyPublisher<DateType, Never> {
        vc.date
    }
    private var cancellableSet = Set<AnyCancellable>()
    let vc: DatePickerViewController

    public init(date: DateType = .single(Date())) {
        self.vc = DatePickerViewController(date: date)
    }

    public func show(relativeTo positioningRect: NSRect, of positioningView: NSView, preferredEdge: NSRectEdge) {
        let popover = NSPopover()
        popover.contentSize = vc.contentSize
        popover.contentViewController = vc
        popover.behavior = .transient
        popover.show(relativeTo: positioningRect, of: positioningView, preferredEdge: preferredEdge)
        vc.mode.sink { [weak vc, weak popover] _ in
            if let vc = vc {
                popover?.contentSize = vc.contentSize
            }
        }.store(in: &cancellableSet)
    }
}
