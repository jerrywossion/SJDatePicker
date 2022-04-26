//
//  WeekdayHeader.swift
//
//
//  Created by Jie Weng on 2022/4/5.
//

import Cocoa

class WeekdayHeader: NSView {
    private let headerHeight: CGFloat = 25

    init() {
        super.init(frame: .zero)
        let symbols = Calendar.current.shortWeekdaySymbols
        var lastLabel: NSTextField?
        for i in 0 ..< 7 {
            let label = NSTextField()
            label.isBezeled = false
            label.isEditable = false
            label.backgroundColor = .clear
            label.alignment = .center
            label.font = .systemFont(ofSize: NSFont.systemFontSize, weight: .medium)
            label.stringValue = symbols[i]
            if i == 0 || (i == symbols.count - 1) {
                label.textColor = .secondaryLabelColor
            }
            addSubview(label)
            label.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.width.equalToSuperview().dividedBy(7)
                if let lastLabel = lastLabel {
                    make.leading.equalTo(lastLabel.snp.trailing)
                } else {
                    make.leading.equalToSuperview()
                }
            }
            lastLabel = label
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: 0, height: headerHeight)
    }
}
