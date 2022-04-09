//
//  TimePickerView.swift
//  
//
//  Created by Jie Weng on 2022/4/8.
//

import Cocoa
import Combine

class TimePickerView: NSView {
    private let datePicker = NSDatePicker()
    private var cancellable: AnyCancellable?

    @Published var time: Date

    init(time: Date) {
        self.time = time
        super.init(frame: .zero)

        datePicker.datePickerStyle = .textField
        datePicker.datePickerElements = .hourMinute
        datePicker.target = self
        datePicker.action = #selector(onTimeChanged(_:))
        datePicker.isBordered = false

        addSubview(datePicker)
        datePicker.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
        }

        cancellable = $time.sink { [weak self] in
            if self?.datePicker.dateValue != $0 {
                self?.datePicker.dateValue = $0
            }
        }
    }

    required init?(coder: NSCoder) {
        preconditionFailure("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: NSSize {
        return datePicker.sizeThatFits(.zero)
    }

    @objc func onTimeChanged(_ sender: NSDatePicker) {
        if time != sender.dateValue {
            time = sender.dateValue
        }
    }
}
