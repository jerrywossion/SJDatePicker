//
//  DatePickerViewController.swift
//
//
//  Created by Jie Weng on 2022/4/5.
//

import Cocoa
import Combine

class DatePickerViewController: NSViewController {
    private let datePickerView: SJDatePickerView
    private var cancellableSet = Set<AnyCancellable>()

    var date: AnyPublisher<SJDatePicker.PickerDate, Never> {
        datePickerView.$date.eraseToAnyPublisher()
    }

    var mode: AnyPublisher<SJDatePickerView.Mode, Never> {
        datePickerView.$mode.eraseToAnyPublisher()
    }

    var contentSize: NSSize {
        datePickerView.intrinsicContentSize
    }

    init(date: SJDatePicker.PickerDate) {
        datePickerView = SJDatePickerView(date: date)
        datePickerView.reset(date: date)

        super.init(nibName: nil, bundle: nil)
    }

    override func loadView() {
        view = datePickerView
    }

    required init?(coder: NSCoder) {
        preconditionFailure("init(coder:) has not been implemented")
    }
}
