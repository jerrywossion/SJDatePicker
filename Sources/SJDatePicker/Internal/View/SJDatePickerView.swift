//
//  SJDatePickerView.swift
//
//
//  Created by Jie Weng on 2022/4/5.
//

import Cocoa
import Combine

class SJDatePickerView: NSView {
    enum Mode {
        case single
        case range
    }

    enum RangeState {
        case unselected
        case startSelected
        case endSelected
    }

    private let rangeToggle = NSButton()
    private let includesTimeToggle = NSButton()
    private let startCalendar: CalendarView
    private let endCalendar: CalendarView
    private let startTimePicker: TimePickerView
    private let endTimePicker: TimePickerView

    @Published var date: SJDatePicker.DateType
    @Published var mode: Mode

    private var startDate: Date?
    private var startTime: Date?
    private var endDate: Date?
    private var endTime: Date?
    @Published private var rangeState: RangeState = .unselected
    @Published private var includesTime = false
    private var isStartDateViewDateSetByUs = false
    private var isEndDateViewDateSetByUs = false
    private var cancellableSet = Set<AnyCancellable>()

    private let toggleHPadding: CGFloat = 10
    private let toggleHeight: CGFloat = 20
    private let toggleCalendarSpacing: CGFloat = 10
    private let calendarHPadding: CGFloat = 10
    private let calendarSpacing: CGFloat = 10
    private let timePickerHeight: CGFloat = 24
    private let vPadding: CGFloat = 10

    init(date: SJDatePicker.DateType) {
        self.date = date
        switch date {
        case .single(let date):
            startCalendar = CalendarView(date: date)
            endCalendar = CalendarView(date: date)
            startTimePicker = TimePickerView(time: date)
            endTimePicker = TimePickerView(time: date)
            mode = .single
        case .range(let dateRange):
            startCalendar = CalendarView(date: dateRange.lowerBound)
            endCalendar = CalendarView(date: dateRange.upperBound)
            startCalendar.highlightedRange = (dateRange.lowerBound, dateRange.upperBound)
            endCalendar.highlightedRange = (dateRange.lowerBound, dateRange.upperBound)
            startTimePicker = TimePickerView(time: dateRange.lowerBound)
            endTimePicker = TimePickerView(time: dateRange.upperBound)
            startDate = dateRange.lowerBound
            endDate = dateRange.upperBound
            mode = .range
            rangeState = .endSelected
        }
        super.init(frame: .zero)

        wantsLayer = true

        setupToggle(rangeToggle, title: "Choose range of date", action: #selector(onToggleDateRange(_:)))
        setupToggle(includesTimeToggle, title: "Includes time", action: #selector(onToggleIncludesTime(_:)))

        addSubview(rangeToggle)
        addSubview(includesTimeToggle)
        addSubview(startCalendar)
        addSubview(endCalendar)
        addSubview(startTimePicker)
        addSubview(endTimePicker)

        rangeToggle.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(vPadding)
            make.leading.equalToSuperview().offset(toggleHPadding)
            make.height.equalTo(toggleHeight)
        }
        includesTimeToggle.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(toggleHPadding)
            make.height.equalTo(toggleHeight)
            make.top.equalTo(rangeToggle.snp.bottom)
        }
        updateDateViewLayouts(with: mode)

        setupStateSubscribers()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateLayer() {
        super.updateLayer()
        layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
    }

    private func setupToggle(_ button: NSButton, title: String, action: Selector) {
        button.setButtonType(.switch)
        button.title = title
        button.isBordered = false
        button.bezelStyle = .inline
        button.target = self
        button.action = action
    }

    private func setupStateSubscribers() {
        startCalendar.$date.sink { [weak self] in
            guard let self = self else { return }
            guard !self.isStartDateViewDateSetByUs else {
                self.isStartDateViewDateSetByUs = false
                return
            }
            switch self.mode {
            case .single:
                if let date = $0 {
                    self.startDate = date
                    self.updateDate()
                }
            case .range:
                if let date = $0 {
                    self.onRangeSelect(date: date)
                }
            }
        }.store(in: &cancellableSet)

        endCalendar.$date.sink { [weak self] in
            guard let self = self,
                  self.mode == .range else { return }
            guard !self.isEndDateViewDateSetByUs else {
                self.isEndDateViewDateSetByUs = false
                return
            }
            if let date = $0 {
                self.onRangeSelect(date: date)
            }
        }.store(in: &cancellableSet)

        $mode.sink { [weak self] mode in
            self?.startCalendar.isInRangeMode = mode == .range
            self?.endCalendar.isInRangeMode = mode == .range
            self?.updateDateViewLayouts(with: mode)
        }.store(in: &cancellableSet)

        $rangeState.sink { [weak self] state in
            guard let self = self,
                  self.mode == .range else { return }
            self.onRangeStateChange(to: state)
        }.store(in: &cancellableSet)

        $includesTime.sink { [weak self] includesTime in
            guard let self = self else { return }
            self.startTimePicker.isHidden = !includesTime
            self.endTimePicker.isHidden = !includesTime
        }.store(in: &cancellableSet)

        startTimePicker.$time.sink { [weak self] time in
            self?.startTime = time
        }.store(in: &cancellableSet)
        endTimePicker.$time.sink { [weak self] time in
            self?.endTime = time
        }.store(in: &cancellableSet)
    }

    private func updateDateViewLayouts(with mode: Mode) {
        switch mode {
        case .single:
            endCalendar.isHidden = true
            startCalendar.snp.remakeConstraints { make in
                make.centerX.equalToSuperview()
                make.top.equalTo(includesTimeToggle.snp.bottom).offset(toggleCalendarSpacing)
            }
            startTimePicker.snp.remakeConstraints { make in
                make.bottom.equalToSuperview().offset(-vPadding)
                make.centerX.equalTo(startCalendar)
            }
        case .range:
            endCalendar.isHidden = false
            startCalendar.snp.remakeConstraints { make in
                make.leading.equalToSuperview().offset(calendarHPadding)
                make.top.equalTo(includesTimeToggle.snp.bottom).offset(toggleCalendarSpacing)
            }
            startTimePicker.snp.remakeConstraints { make in
                make.bottom.equalToSuperview().offset(-vPadding)
                make.centerX.equalTo(startCalendar)
            }
            endCalendar.snp.remakeConstraints { make in
                make.trailing.equalToSuperview().offset(-calendarHPadding)
                make.top.equalTo(includesTimeToggle.snp.bottom).offset(toggleCalendarSpacing)
            }
            endTimePicker.snp.remakeConstraints { make in
                make.bottom.equalToSuperview().offset(-vPadding)
                make.centerX.equalTo(endCalendar)
            }
        }
    }

    @objc func onToggleDateRange(_ sender: NSButton) {
        if sender.state == .on {
            if case .single(let singleDate) = date {
                startDate = singleDate
                endDate = singleDate
            }
            rangeState = .endSelected
        } else {
            rangeState = .unselected
        }
        setup(date: date)
        mode = sender.state == .on ? .range : .single
    }

    @objc func onToggleIncludesTime(_ sender: NSButton) {
        includesTime = sender.state == .on
    }

    override var intrinsicContentSize: NSSize {
        let calendarSize = startCalendar.intrinsicContentSize
        let calendarWidth = calendarSize.width
        let width: CGFloat
        if rangeToggle.state == .off {
            width = calendarWidth + 2 * calendarHPadding
        } else {
            width = 2 * (calendarWidth + calendarHPadding) + calendarSpacing
        }
        let height = vPadding + 2 * toggleHeight + toggleCalendarSpacing + calendarSize.height + timePickerHeight + vPadding
        return NSSize(width: width, height: height)
    }

    // MARK: - Date & Time Operations

    func setup(date: SJDatePicker.DateType) {
        self.date = date
        switch date {
        case .single(let date):
            startCalendar.date = date
            startTimePicker.time = date
        case .range(let range):
            startCalendar.date = range.lowerBound
            endCalendar.date = range.upperBound
        }
    }

    func combineDateTime(date: Date, time: Date) -> Date? {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        var resComponents = DateComponents()
        guard let year = dateComponents.year,
              let month = dateComponents.month,
              let day = dateComponents.day,
              let hour = timeComponents.hour,
              let minute = timeComponents.minute
        else {
            return nil
        }
        resComponents.year = year
        resComponents.month = month
        resComponents.day = day
        resComponents.hour = hour
        resComponents.minute = minute
        guard let resDate = calendar.date(from: resComponents) else {
            return nil
        }
        return resDate
    }

    func updateDate() {
        switch mode {
        case .single:
            guard let startDate = startDate else {
                return
            }
            if includesTime,
               let startTime = startTime,
               let combinedDate = combineDateTime(date: startDate, time: startTime)
            {
                date = .single(combinedDate)
            } else {
                date = .single(startDate)
            }
        case .range:
            guard rangeState == .endSelected,
                  let startDate = startDate,
                  let endDate = endDate
            else {
                return
            }
            if includesTime,
               let startTime = startTime,
               let endTime = endTime,
               let combinedStartDate = combineDateTime(date: startDate, time: startTime),
               let combinedEndDate = combineDateTime(date: endDate, time: endTime)
            {
                date = .range(combinedStartDate ... combinedEndDate)
            } else {
                date = .range(startDate ... endDate)
            }
        }
    }

    private func onRangeSelect(date: Date) {
        switch rangeState {
        case .unselected:
            startDate = date
            rangeState = .startSelected
        case .startSelected:
            guard let startDate = startDate else {
                return
            }
            if startDate <= date {
                endDate = date
                rangeState = .endSelected
                updateDate()
            } else {
                self.startDate = date
                rangeState = .startSelected
            }
        case .endSelected:
            startDate = date
            endDate = nil
            rangeState = .startSelected
        }
    }

    private func onRangeStateChange(to state: RangeState) {
        switch state {
        case .unselected:
            isStartDateViewDateSetByUs = true
            startCalendar.date = nil
            startCalendar.highlightedRange = nil
            isEndDateViewDateSetByUs = true
            endCalendar.date = nil
            endCalendar.highlightedRange = nil
        case .startSelected:
            guard let startDate = startDate else {
                return
            }
            startCalendar.highlightedRange = (startDate, nil)
            endCalendar.highlightedRange = (startDate, nil)
        case .endSelected:
            guard let startDate = startDate,
                  let endDate = endDate
            else {
                return
            }
            startCalendar.highlightedRange = (startDate, endDate)
            endCalendar.highlightedRange = (startDate, endDate)
        }
    }
}
