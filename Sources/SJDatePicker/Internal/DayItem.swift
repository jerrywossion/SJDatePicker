//
//  DayItem.swift
//
//
//  Created by Jie Weng on 2022/4/5.
//

import Cocoa

class DayItem: NSCollectionViewItem {
    enum BackgroundStyle {
        case selected
        case rangeLeftSelected
        case rangeRightSelected
        case rangeDoubleSelected
        case highlighted
        case normal
    }

    enum ForegroundStyle {
        case normal
        case today
        case notInThisMonth
    }

    private let label = NSTextField()
    private let leftBg = NSView()
    private let rightBg = NSView()
    private let rangeSelectCornerRadius: CGFloat = 6

    override var title: String? {
        didSet {
            label.stringValue = title ?? ""
        }
    }

    var isInRangeMode = false

    private(set) var isToday = false
    private(set) var isNotInThisMonth = false

    override var isSelected: Bool {
        didSet {
            if !isInRangeMode {
                updateBackgroundStyle(to: isSelected ? .selected : .normal)
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        label.stringValue = ""
        isInRangeMode = false
        isToday = false
        isNotInThisMonth = false
        updateBackgroundStyle(to: .normal)
        updateForegroundStyle(to: .normal)
    }

    override func loadView() {
        view = NSView()
        view.wantsLayer = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(leftBg)
        view.addSubview(rightBg)
        view.addSubview(label)

        label.isEditable = false
        label.isBezeled = false
        label.alignment = .center
        label.backgroundColor = .clear

        leftBg.snp.makeConstraints { make in
            make.left.top.height.equalToSuperview()
            make.right.equalToSuperview().offset(-rangeSelectCornerRadius)
        }
        rightBg.snp.makeConstraints { make in
            make.right.top.height.equalToSuperview()
            make.left.equalToSuperview().offset(rangeSelectCornerRadius)
        }
        label.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    override func viewDidLayout() {
        super.viewDidLayout()
    }

    func updateBackgroundStyle(to style: BackgroundStyle) {
        switch style {
        case .selected:
            let maskLayer = CAShapeLayer()
            let r = min(view.bounds.width, view.bounds.height)
            let rect = CGRect(origin: CGPoint(x: view.bounds.midX - r / 2, y: view.bounds.midY - r / 2), size: CGSize(width: r, height: r))
            maskLayer.path = CGPath(ellipseIn: rect, transform: nil)
            view.layer?.mask = maskLayer
            view.layer?.backgroundColor = NSColor.controlAccentColor.cgColor
            label.textColor = NSColor.highlightColor
        case .rangeLeftSelected:
            let maskLayer = CAShapeLayer()
            let viewBounds = view.bounds
            let rect = CGRect(origin: viewBounds.origin, size: CGSize(width: viewBounds.width - rangeSelectCornerRadius, height: viewBounds.height))
            maskLayer.path = CGPath(roundedRect: rect, cornerWidth: rangeSelectCornerRadius, cornerHeight: rangeSelectCornerRadius, transform: nil)
            leftBg.layer?.mask = maskLayer
            leftBg.layer?.backgroundColor = NSColor.controlAccentColor.cgColor
            rightBg.layer?.mask = nil
            rightBg.layer?.backgroundColor = NSColor.controlAccentColor.cgColor
            label.textColor = NSColor.highlightColor
        case .rangeRightSelected:
            let maskLayer = CAShapeLayer()
            let viewBounds = view.bounds
            let rect = CGRect(origin: viewBounds.origin, size: CGSize(width: viewBounds.width - rangeSelectCornerRadius, height: viewBounds.height))
            maskLayer.path = CGPath(roundedRect: rect, cornerWidth: rangeSelectCornerRadius, cornerHeight: rangeSelectCornerRadius, transform: nil)
            rightBg.layer?.mask = maskLayer
            rightBg.layer?.backgroundColor = NSColor.controlAccentColor.cgColor
            leftBg.layer?.mask = nil
            leftBg.layer?.backgroundColor = NSColor.controlAccentColor.cgColor
            label.textColor = NSColor.highlightColor
        case .rangeDoubleSelected:
            let maskLayer = CAShapeLayer()
            maskLayer.path = CGPath(roundedRect: view.bounds, cornerWidth: rangeSelectCornerRadius, cornerHeight: rangeSelectCornerRadius, transform: nil)
            view.layer?.mask = maskLayer
            view.layer?.backgroundColor = NSColor.controlAccentColor.cgColor
            label.textColor = NSColor.highlightColor
        case .highlighted:
            view.layer?.mask = nil
            view.layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.2).cgColor
        case .normal:
            view.layer?.mask = nil
            view.layer?.backgroundColor = .clear
            leftBg.layer?.mask = nil
            leftBg.layer?.backgroundColor = .clear
            rightBg.layer?.mask = nil
            rightBg.layer?.backgroundColor = .clear
            recoverForegroundStyle()
        }
    }

    private func recoverForegroundStyle() {
        updateForegroundStyle(to: .normal)
        if isToday {
            updateForegroundStyle(to: .today)
        }
        if isNotInThisMonth {
            updateForegroundStyle(to: .notInThisMonth)
        }
    }

    func updateForegroundStyle(to style: ForegroundStyle) {
        switch style {
        case .normal:
            label.textColor = .labelColor
        case .today:
            isToday = true
            label.textColor = .systemRed
        case .notInThisMonth:
            isNotInThisMonth = true
            if !isToday {
                label.textColor = .labelColor.withAlphaComponent(0.3)
            }
        }
    }
}
