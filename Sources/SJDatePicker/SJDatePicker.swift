//
//  SJDatePicker.swift
//  SJDatePicker
//
//  Created by Jie Weng on 2022/4/5.
//

import Cocoa
import Combine

open class SJDatePicker {
    public enum PickerDate {
        case single(Date)
        case range(ClosedRange<Date>)
    }

    private var modeCancellable: AnyCancellable?
    private var dateCancellable: AnyCancellable?
    private var datePickerVC: DatePickerViewController?
    public init() {}

    public func show(initDate: PickerDate, relativeTo positioningRect: NSRect, of positioningView: NSView, preferredEdge: NSRectEdge, onDateChanged: @escaping (PickerDate) -> Void) {
        let vc = DatePickerViewController(date: initDate)
        datePickerVC = vc
        let popover = NSPopover()
        popover.contentSize = vc.contentSize
        popover.contentViewController = vc
        popover.behavior = .transient
        popover.show(relativeTo: positioningRect, of: positioningView, preferredEdge: preferredEdge)
        modeCancellable = vc.mode.sink { [weak vc, weak popover] _ in
            if let vc = vc {
                popover?.contentSize = vc.contentSize
            }
        }
        dateCancellable = vc.date.sink { date in
            onDateChanged(date)
        }
    }
}
