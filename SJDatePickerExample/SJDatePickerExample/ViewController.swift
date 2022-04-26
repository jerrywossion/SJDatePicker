//
//  ViewController.swift
//  SJDatePickerExample
//
//  Created by Jie Weng on 2022/4/5.
//

import Cocoa
import Combine
import SJDatePicker

class ViewController: NSViewController {
    @IBOutlet var singleButton: NSButton!
    @IBOutlet var rangeButton: NSButton!

    var datePicker = SJDatePicker()
    var cancellable: AnyCancellable?

    override func viewDidLoad() {
        super.viewDidLoad()

        singleButton.target = self
        singleButton.action = #selector(onSingle(_:))
        rangeButton.target = self
        rangeButton.action = #selector(onRange(_:))
    }

    private func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.setLocalizedDateFormatFromTemplate("MMM d yyyy HH mm ss")
        return formatter.string(from: date)
    }

    private func onDateChanged(_ date: SJDatePicker.PickerDate) {
        switch date {
        case .single(let date):
            print("[\(dateString(Date()))] \(dateString(date))")
        case .range(let range):
            print("[\(dateString(Date()))] \(dateString(range.lowerBound)) - \(dateString(range.upperBound))")
        }
    }

    @objc func onSingle(_ sender: NSButton) {
        let today = Date()
        let tomorrow = today.advanced(by: 24 * 60 * 60)
        datePicker.show(initDate: .single(tomorrow), relativeTo: sender.frame, of: view, preferredEdge: .minY) { [weak self] in
            self?.onDateChanged($0)
        }
    }

    @objc func onRange(_ sender: NSButton) {
        let today = Date()
        let tomorrow = today.advanced(by: 24 * 60 * 60)
        datePicker.show(initDate: .range(today ... tomorrow), relativeTo: sender.frame, of: view, preferredEdge: .minY) { [weak self] in
            self?.onDateChanged($0)
        }
    }
}
