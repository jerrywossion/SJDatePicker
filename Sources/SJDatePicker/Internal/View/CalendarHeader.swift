//
//  CalendarHeader.swift
//
//
//  Created by Jie Weng on 2022/4/5.
//

import Cocoa

class CalendarHeader: NSView {
    private let title = NSTextField()
    private lazy var prevButton = createButton(iconName: "chevron.left", action: #selector(onPrev(_:)))
    private lazy var nextButton = createButton(iconName: "chevron.right", action: #selector(onNext(_:)))

    private let headerHeight: CGFloat = 20

    var onPrev: (() -> Void)?
    var onNext: (() -> Void)?

    override var isFlipped: Bool { true }

    init() {
        super.init(frame: .zero)

        translatesAutoresizingMaskIntoConstraints = false

        addSubview(prevButton)
        addSubview(title)
        addSubview(nextButton)

        title.isEditable = false
        title.isBezeled = false
        title.backgroundColor = .clear
        title.font = .titleBarFont(ofSize: NSFont.systemFontSize)
        title.alignment = .center

        prevButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(5)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(16)
        }
        nextButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-5)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(16)
        }
        title.snp.makeConstraints { make in
            make.leading.equalTo(prevButton.snp.trailing).offset(5)
            make.trailing.equalTo(nextButton.snp.leading).offset(-5)
            make.centerY.equalToSuperview()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func createButton(iconName: String, action: Selector) -> NSButton {
        let button = NSButton()
        button.bezelStyle = .inline
        button.isBordered = false
        button.target = self
        button.action = action
        button.image = NSImage(systemSymbolName: iconName, accessibilityDescription: nil)
        return button
    }

    func update(with date: Date) {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("yyyy MM")
        title.stringValue = formatter.string(from: date)
    }

    @objc func onPrev(_ sender: NSButton) {
        onPrev?()
    }

    @objc func onNext(_ sender: NSButton) {
        onNext?()
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: 0, height: headerHeight)
    }
}
