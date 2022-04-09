//
//  CalendarView.swift
//
//
//  Created by Jie Weng on 2022/4/5.
//

import Cocoa
import Combine
import SnapKit

class CalendarView: NSView {
    private let header = CalendarHeader()
    private let weekdayHeader = WeekdayHeader()
    private let scrollView = NSScrollView()
    private let collectionView = CalendarCollectionView()

    private var dates: [Date] = []
    private var firstDayInMonthIndex = -1
    private var lastDayInMonthIndex = -1
    private var cancellableSet = Set<AnyCancellable>()

    private let rows = 6
    private let columns = 7
    private let itemSize = CGSize(width: 36, height: 26)
    private let headerHeight: CGFloat = 20

    /// 当前选中的日期值
    @Published var date: Date?

    var isInRangeMode = false {
        didSet {
            reloadData()
        }
    }

    var highlightedRange: (start: Date, end: Date?)? {
        didSet {
            updateHighlight()
        }
    }

    /// 用作当前日历视图展示的参考日期
    private var displayingDate: Date {
        didSet {
            reloadData()
        }
    }

    init(date: Date) {
        self.displayingDate = date
        self.date = date

        super.init(frame: .zero)

        setupSubViews()
        setupLayouts()

        header.onPrev = { [weak self] in
            if let self = self,
               let date = Calendar.current.date(byAdding: .month, value: -1, to: self.displayingDate)
            {
                self.displayingDate = date
            }
        }
        header.onNext = { [weak self] in
            if let self = self,
               let date = Calendar.current.date(byAdding: .month, value: 1, to: self.displayingDate)
            {
                self.displayingDate = date
            }
        }

        reloadData()
    }

    required init?(coder: NSCoder) {
        preconditionFailure("init(coder:) has not been implemented")
    }

    private func setupSubViews() {
        wantsLayer = true
        translatesAutoresizingMaskIntoConstraints = false

        addSubview(header)
        addSubview(weekdayHeader)
        addSubview(scrollView)

        scrollView.autohidesScrollers = true
        scrollView.hasVerticalScroller = false
        scrollView.documentView = collectionView
        scrollView.backgroundColor = .clear

        collectionView.collectionViewLayout = createLayout()
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.isSelectable = true
        collectionView.backgroundColors = [.clear]
    }

    private func setupLayouts() {
        header.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }
        weekdayHeader.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(header.snp.bottom)
        }
        scrollView.snp.makeConstraints { make in
            make.leading.bottom.trailing.equalToSuperview()
            make.top.equalTo(weekdayHeader.snp.bottom)
        }
    }

    override var intrinsicContentSize: NSSize {
        let width = itemSize.width * CGFloat(columns)
        var height: CGFloat = 0
        height += header.intrinsicContentSize.height
        height += weekdayHeader.intrinsicContentSize.height
        height += itemSize.height * CGFloat(rows)
        return NSSize(width: width, height: height)
    }

    private func createLayout() -> NSCollectionViewGridLayout {
        let layout = NSCollectionViewGridLayout()
        layout.maximumNumberOfRows = rows
        layout.maximumNumberOfColumns = columns
        layout.minimumLineSpacing = 2
        return layout
    }

    private func reloadData() {
        header.update(with: displayingDate)
        dates.removeAll()
        let calendar = Calendar.current
        let dateDc = calendar.dateComponents([.month, .year, .day], from: displayingDate)
        var firstDateInMonthDc = dateDc
        firstDateInMonthDc.day = 1
        let firstDateInMonth = calendar.date(from: firstDateInMonthDc)
        guard let firstDateInMonth = firstDateInMonth else {
            return
        }
        firstDateInMonthDc = calendar.dateComponents([.year, .month, .day, .weekday], from: firstDateInMonth)
        guard var weekday = firstDateInMonthDc.weekday else {
            return
        }
        weekday -= 1
        if let daysInMonth = calendar.range(of: .day, in: .month, for: displayingDate)?.count {
            firstDayInMonthIndex = weekday
            lastDayInMonthIndex = firstDayInMonthIndex + daysInMonth - 1
        } else {
            firstDayInMonthIndex = -1
            lastDayInMonthIndex = -1
        }
        let count = rows * columns
        for i in 0 ..< count {
            if let date = calendar.date(byAdding: .day, value: i - weekday, to: firstDateInMonth) {
                dates.append(date)
            }
        }
        collectionView.reloadData()
        if let date = date,
           let item = dates.firstIndex(where: { Calendar.current.isDate(date, inSameDayAs: $0) })
        {
            DispatchQueue.main.async {
                self.collectionView.selectItems(at: [IndexPath(item: item, section: 0)], scrollPosition: .top)
            }
        }
    }

    private func updateHighlight() {
        let calendar = Calendar.current
        for (i, date) in dates.enumerated() {
            guard let item = collectionView.item(at: i) as? DayItem
            else {
                continue
            }

            guard let highlightedRange = highlightedRange else {
                item.updateBackgroundStyle(to: .normal)
                continue
            }

            let start = highlightedRange.start
            guard let end = highlightedRange.end else {
                if calendar.isDate(start, inSameDayAs: date) {
                    item.updateBackgroundStyle(to: .rangeLeftSelected)
                } else {
                    item.updateBackgroundStyle(to: .normal)
                }
                continue
            }

            if item.isNotInThisMonth {
                item.updateBackgroundStyle(to: .normal)
                continue
            }

            if calendar.isDate(start, inSameDayAs: end),
               calendar.isDate(start, inSameDayAs: date)
            {
                item.updateBackgroundStyle(to: .rangeDoubleSelected)
                continue
            }

            if calendar.isDate(start, inSameDayAs: date) {
                item.updateBackgroundStyle(to: .rangeLeftSelected)
            } else if calendar.isDate(end, inSameDayAs: date) {
                item.updateBackgroundStyle(to: .rangeRightSelected)
            } else if start < date, end > date {
                item.updateBackgroundStyle(to: .highlighted)
            } else {
                item.updateBackgroundStyle(to: .normal)
            }
        }
    }
}

extension CalendarView: NSCollectionViewDataSource {
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        dates.count
    }

    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = DayItem()
        if indexPath.item < dates.count {
            let calendar = Calendar.current
            let dc = calendar.dateComponents([.day, .weekday], from: dates[indexPath.item])
            if let day = dc.day {
                item.title = "\(day)"
            }
            if !(firstDayInMonthIndex ... lastDayInMonthIndex ~= indexPath.item) {
                item.updateForegroundStyle(to: .notInThisMonth)
            }
            if Calendar.current.isDateInToday(dates[indexPath.item]) {
                item.updateForegroundStyle(to: .today)
            }
            item.isInRangeMode = isInRangeMode
        }
        return item
    }
}

extension CalendarView: NSCollectionViewDelegate {
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        guard let indexPath = indexPaths.first,
              indexPath.item > -1,
              indexPath.item < dates.count
        else {
            return
        }
        date = dates[indexPath.item]
    }
}

class CalendarCollectionView: NSCollectionView {
    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        let point = convert(event.locationInWindow, from: nil)
        if let indexPath = indexPathForItem(at: point),
           let item = item(at: indexPath) as? DayItem,
           item.isSelected
        {
            deselectItems(at: [indexPath])
            selectItems(at: [indexPath], scrollPosition: .top)
            delegate?.collectionView?(self, didSelectItemsAt: [indexPath])
        }
    }
}
