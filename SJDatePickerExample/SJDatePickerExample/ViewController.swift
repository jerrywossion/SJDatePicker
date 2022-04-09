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
    @IBOutlet weak var singleButton: NSButton!
    @IBOutlet weak var rangeButton: NSButton!

    var datePicker = SJDatePicker()
    var cancellable: AnyCancellable?

    override func viewDidLoad() {
        super.viewDidLoad()

        singleButton.target = self
        singleButton.action = #selector(onSingle(_:))
        rangeButton.target = self
        rangeButton.action = #selector(onRange(_:))
    }

    @objc func onSingle(_ sender: NSButton) {
        datePicker.show(relativeTo: sender.frame, of: view, preferredEdge: .minY)
        cancellable = datePicker.date.sink {
            print($0)
        }
    }

    @objc func onRange(_ sender: NSButton) {
        datePicker.show(relativeTo: sender.frame, of: view, preferredEdge: .minY)
        cancellable = datePicker.date.sink {
            print($0)
        }
    }
}

