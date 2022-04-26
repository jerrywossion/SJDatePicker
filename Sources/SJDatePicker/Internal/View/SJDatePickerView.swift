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

    // MARK: Views

    private let rangeToggle = NSButton()
    private let includesTimeToggle = NSButton()
    private let startCalendar: CalendarView
    private let endCalendar: CalendarView
    private let startTimePicker: TimePickerView
    private let endTimePicker: TimePickerView

    // MARK: States

    @Published var date: SJDatePicker.PickerDate
    @Published var mode: Mode

    /// - Single mode: Selected date
    /// - Range mode: Selected start date
    private var startDate: Date?
    /// - Single mode: Selected time
    /// - Range mode: Selected start time
    private var startTime: Date?
    /// - Single mode: N/A
    /// - Range mode: Selected end date
    private var endDate: Date?
    /// - Single mode: N/A
    /// - Range mode: Selected end time
    private var endTime: Date?

    /// State machine for range mode
    @Published private var rangeState: RangeState = .unselected
    private var includesTime: Bool {
        includesTimeToggle.state == .on
    }

    private var isStartCalendarDateSetByUs = false
    private var isStartTimeSetByUs = false
    private var isEndCalendarDateSetByUs = false
    private var isEndTimeSetByUs = false
    private var cancellableSet = Set<AnyCancellable>()

    // MARK: Layout constants

    private let toggleHPadding: CGFloat = 10
    private let toggleHeight: CGFloat = 20
    private let toggleCalendarSpacing: CGFloat = 10
    private let calendarHPadding: CGFloat = 10
    private let calendarSpacing: CGFloat = 10
    private let timePickerHeight: CGFloat = 24
    private let vPadding: CGFloat = 10

    init(date: SJDatePicker.PickerDate) {
        self.date = date
        switch date {
        case let .single(date):
            startCalendar = CalendarView(date: date)
            endCalendar = CalendarView(date: date)
            startTimePicker = TimePickerView(time: date)
            endTimePicker = TimePickerView(time: date)
            mode = .single
        case let .range(dateRange):
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

        setupSubviews()
        updateDateViewLayouts(with: mode)
        updateTimePickersVisibility()
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

    private func setupSubviews() {
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
            guard !self.isStartCalendarDateSetByUs else {
                self.isStartCalendarDateSetByUs = false
                return
            }
            switch self.mode {
            case .single:
                if let date = $0 {
                    self.startDate = date
                    self.updatePickerDateTime()
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
            guard !self.isEndCalendarDateSetByUs else {
                self.isEndCalendarDateSetByUs = false
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

        startTimePicker.$time.sink { [weak self] time in
            guard let self = self else {
                return
            }
            guard !self.isStartTimeSetByUs else {
                self.isStartTimeSetByUs = false
                return
            }
            self.startTime = time
            self.updatePickerDateTime()
        }.store(in: &cancellableSet)
        endTimePicker.$time.sink { [weak self] time in
            guard let self = self,
                  self.mode == .range
            else {
                return
            }
            guard !self.isEndTimeSetByUs else {
                self.isEndTimeSetByUs = false
                return
            }
            self.endTime = time
            self.updatePickerDateTime()
        }.store(in: &cancellableSet)
    }

    private func updateDateViewLayouts(with mode: Mode) {
        switch mode {
        case .single:
            endCalendar.isHidden = true
            endTimePicker.isHidden = true
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
            endTimePicker.isHidden = true
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
        var date: SJDatePicker.PickerDate?
        mode = sender.state == .on ? .range : .single
        switch mode {
        case .single:
            if case let .range(range) = self.date {
                date = .single(range.lowerBound)
            }
        case .range:
            if case let .single(single) = self.date {
                date = .range(single ... single)
            }
        }
        if let date = date {
            reset(date: date)
        }
    }

    private func updateTimePickersVisibility() {
        startTimePicker.isHidden = !includesTime
        endTimePicker.isHidden = !includesTime
    }

    @objc func onToggleIncludesTime(_ sender: NSButton) {
        updateTimePickersVisibility()
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

    func reset(date: SJDatePicker.PickerDate) {
        self.date = date
        switch date {
        case let .single(date):
            isStartCalendarDateSetByUs = true
            startCalendar.date = date
            isStartTimeSetByUs = true
            startTimePicker.time = date
            startDate = date
            startTime = date
            mode = .single
            startCalendar.isInRangeMode = false
            if rangeToggle.state != .off {
                rangeToggle.state = .off
            }
        case let .range(range):
            isStartCalendarDateSetByUs = true
            startCalendar.date = range.lowerBound
            isStartTimeSetByUs = true
            startTimePicker.time = range.lowerBound
            isEndCalendarDateSetByUs = true
            endCalendar.date = range.upperBound
            isEndTimeSetByUs = true
            endTimePicker.time = range.upperBound
            startDate = range.lowerBound
            startTime = range.lowerBound
            endDate = range.upperBound
            endTime = range.upperBound
            mode = .range
            if rangeToggle.state != .on {
                rangeToggle.state = .on
            }
            DispatchQueue.main.async { [weak self] in
                self?.rangeState = .endSelected
            }
        }
    }

    private func combineDateTime(date: Date, time: Date) -> Date? {
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

    private func updatePickerDateTime() {
        switch mode {
        case .single:
            guard let startDate = startDate else {
                return
            }
            if includesTime,
               let startTime = startTime,
               let combinedDate = combineDateTime(date: startDate, time: startTime) {
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
               let combinedEndDate = combineDateTime(date: endDate, time: endTime) {
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
                updatePickerDateTime()
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
            isStartCalendarDateSetByUs = true
            startCalendar.date = nil
            startCalendar.highlightedRange = nil
            isEndCalendarDateSetByUs = true
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
