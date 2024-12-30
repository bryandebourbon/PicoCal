//import SwiftUI
//import EventKit
//
//// MARK: - ContentViewEvents
//
//struct ContentViewEvents: View {
//    @StateObject private var viewModel = EventViewModel()
//    @State private var showAddEventSheet = false
//    @State private var showEditEventSheet = false
//    @State private var selectedEvent: EKEvent?
//    
//    var body: some View {
//        NavigationView {
//            List {
//                ForEach(viewModel.events, id: \.eventIdentifier) { event in
//                    Button(action: {
//                        selectedEvent = event
//                        showEditEventSheet.toggle()
//                    }) {
//                        VStack(alignment: .leading) {
//                            Text(event.title)
//                                .font(.headline)
//                            Text(event.startDate, style: .date)
//                                .font(.subheadline)
//                        }
//                    }
//                }
//                .onDelete(perform: viewModel.deleteEvent)
//            }
//            .navigationTitle("Events")
//            .toolbar {
//                ToolbarItem(placement: .navigationBarLeading) {
//                    Button("Refresh") {
//                        viewModel.refreshEvents()
//                    }
//                }
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    Button("Add Event") {
//                        showAddEventSheet.toggle()
//                    }
//                }
//            }
//            .sheet(isPresented: $showAddEventSheet) {
//                AddEventView(viewModel: viewModel)
//            }
//            .sheet(isPresented: $showEditEventSheet) {
//                if let event = selectedEvent {
//                    EditEventView(viewModel: viewModel, event: event)
//                }
//            }
//            .onAppear {
//                viewModel.requestAccess()
//            }
//        }
//    }
//}
//
//// MARK: - AddEventView
//
//struct AddEventView: View {
//    @Environment(\.presentationMode) var presentationMode
//    @ObservedObject var viewModel: EventViewModel
//    @State private var title = ""
//    @State private var startDate = Date()
//    @State private var endDate = Date().addingTimeInterval(3600)
//    @State private var notes = ""
//    
//    var body: some View {
//        Form {
//            TextField("Event Title", text: $title)
//            DatePicker("Start Date", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
//            DatePicker("End Date", selection: $endDate, displayedComponents: [.date, .hourAndMinute])
//            TextField("Notes", text: $notes)
//        }
//        .navigationTitle("Add Event")
//        .toolbar {
//            ToolbarItem(placement: .navigationBarLeading) {
//                Button("Cancel") {
//                    presentationMode.wrappedValue.dismiss()
//                }
//            }
//            ToolbarItem(placement: .navigationBarTrailing) {
//                Button("Save") {
//                    viewModel.createEvent(title: title, startDate: startDate, endDate: endDate, notes: notes)
//                    presentationMode.wrappedValue.dismiss()
//                }
//            }
//        }
//    }
//}
//
//// MARK: - EditEventView
//
//struct EditEventView: View {
//    @Environment(\.presentationMode) var presentationMode
//    @ObservedObject var viewModel: EventViewModel
//    @State private var title: String
//    @State private var startDate: Date
//    @State private var endDate: Date
//    @State private var notes: String
//    var event: EKEvent
//    
//    init(viewModel: EventViewModel, event: EKEvent) {
//        self.viewModel = viewModel
//        _title = State(initialValue: event.title)
//        _startDate = State(initialValue: event.startDate)
//        _endDate = State(initialValue: event.endDate)
//        _notes = State(initialValue: event.notes ?? "")
//        self.event = event
//    }
//    
//    var body: some View {
//        NavigationView {
//            Form {
//                TextField("Event Title", text: $title)
//                DatePicker("Start Date", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
//                DatePicker("End Date", selection: $endDate, displayedComponents: [.date, .hourAndMinute])
//                TextField("Notes", text: $notes)
//            }
//            .navigationTitle("Edit Event")
//            .toolbar {
//                ToolbarItem(placement: .navigationBarLeading) {
//                    Button("Cancel") {
//                        presentationMode.wrappedValue.dismiss()
//                    }
//                }
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    Button("Save") {
//                        viewModel.updateEvent(event: event, title: title, startDate: startDate, endDate: endDate, notes: notes)
//                        presentationMode.wrappedValue.dismiss()
//                    }
//                }
//            }
//        }
//    }
//}
//
//// MARK: - EventViewModel
//
//class EventViewModel: ObservableObject {
//    @Published var events: [EKEvent] = []
//    private let eventKitManager = EventKitManager()
//    
//    func requestAccess() {
//        eventKitManager.requestAccess { [weak self] granted, error in
//            if granted {
//                self?.refreshEvents()
//            } else {
//                print("Access denied: \(error?.localizedDescription ?? "Unknown error")")
//            }
//        }
//    }
//    
//    func refreshEvents() {
//        let startDate = Date()
//        let endDate = Date(timeIntervalSinceNow: 3600 * 24 * 365) // 1 year from now
//        eventKitManager.fetchEvents(startDate: startDate, endDate: endDate) { [weak self] events, error in
//            if let events = events {
//                DispatchQueue.main.async {
//                    self?.events = events
//                }
//            } else if let error = error {
//                print("Error fetching events: \(error.localizedDescription)")
//            }
//        }
//    }
//    
//    func createEvent(title: String, startDate: Date, endDate: Date, notes: String?) {
//        eventKitManager.createEvent(title: title, startDate: startDate, endDate: endDate, notes: notes) { [weak self] success, error in
//            if success {
//                self?.refreshEvents()
//            } else if let error = error {
//                print("Error creating event: \(error.localizedDescription)")
//            }
//        }
//    }
//    
//    func updateEvent(event: EKEvent, title: String, startDate: Date, endDate: Date, notes: String?) {
//        eventKitManager.updateEvent(event: event, title: title, startDate: startDate, endDate: endDate, notes: notes) { [weak self] success, error in
//            if success {
//                self?.refreshEvents()
//            } else if let error = error {
//                print("Error updating event: \(error.localizedDescription)")
//            }
//        }
//    }
//    
//    func deleteEvent(at offsets: IndexSet) {
//        for index in offsets {
//            let event = events[index]
//            eventKitManager.deleteEvent(event: event) { [weak self] success, error in
//                if success {
//                    self?.refreshEvents()
//                } else if let error = error {
//                    print("Error deleting event: \(error.localizedDescription)")
//                }
//            }
//        }
//    }
//}
//
//// MARK: - EventKitManager
//
//class EventKitManager {
//    private let eventStore = EKEventStore()
//    
//    func requestAccess(completion: @escaping (Bool, Error?) -> Void) {
//        eventStore.requestAccess(to: .event) { granted, error in
//            completion(granted, error)
//        }
//    }
//    
//    func fetchEvents(startDate: Date, endDate: Date, completion: @escaping ([EKEvent]?, Error?) -> Void) {
//        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
//        let events = eventStore.events(matching: predicate)
//        completion(events, nil)
//    }
//    
//    func createEvent(title: String, startDate: Date, endDate: Date, notes: String?, completion: @escaping (Bool, Error?) -> Void) {
//        let event = EKEvent(eventStore: eventStore)
//        event.title = title
//        event.startDate = startDate
//        event.endDate = endDate
//        event.notes = notes
//        event.calendar = eventStore.defaultCalendarForNewEvents
//        do {
//            try eventStore.save(event, span: .thisEvent)
//            completion(true, nil)
//        } catch {
//            completion(false, error)
//        }
//    }
//    
//    func updateEvent(event: EKEvent, title: String, startDate: Date, endDate: Date, notes: String?, completion: @escaping (Bool, Error?) -> Void) {
//        event.title = title
//        event.startDate = startDate
//        event.endDate = endDate
//        event.notes = notes
//        do {
//            try eventStore.save(event, span: .thisEvent)
//            completion(true, nil)
//        } catch {
//            completion(false, error)
//        }
//    }
//    
//    func deleteEvent(event: EKEvent, completion: @escaping (Bool, Error?) -> Void) {
//        do {
//            try eventStore.remove(event, span: .thisEvent)
//            completion(true, nil)
//        } catch {
//            completion(false, error)
//        }
//    }
//}
//
//// MARK: - CalendarManager
//
//class CalendarManager: ObservableObject {
//    private let eventStore = EKEventStore()
//    
//    func fetchEvents(for month: Int, year: Int, completion: @escaping ([Int: [EKEvent]]) -> Void) {
//        eventStore.requestAccess(to: .event) { [weak self] granted, error in
//            guard granted, let self = self else { return }
//            
//            let startDate = self.dateFor(month: month, day: 1, year: year)
//            let endDate = self.dateFor(month: month, day: self.daysInMonth(month: month, year: year), year: year)
//            
//            let predicate = self.eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
//            let events = self.eventStore.events(matching: predicate)
//            
//            var eventsDict: [Int: [EKEvent]] = [:]
//            for event in events {
//                let day = Calendar.current.component(.day, from: event.startDate)
//                if eventsDict[day] == nil {
//                    eventsDict[day] = []
//                }
//                eventsDict[day]?.append(event)
//            }
//            
//            DispatchQueue.main.async {
//                completion(eventsDict)
//            }
//        }
//    }
//    
//    private func dateFor(month: Int, day: Int, year: Int) -> Date {
//        var dateComponents = DateComponents()
//        dateComponents.month = month
//        dateComponents.day = day
//        dateComponents.year = year
//        return Calendar.current.date(from: dateComponents) ?? Date()
//    }
//    
//    private func daysInMonth(month: Int, year: Int) -> Int {
//        let dateComponents = DateComponents(year: year, month: month)
//        let calendar = Calendar.current
//        let date = calendar.date(from: dateComponents)!
//        let range = calendar.range(of: .day, in: .month, for: date)!
//        return range.count
//    }
//}
//
//// MARK: - Calendar Views (ContentView, MonthView, etc.)
//
//struct ContentView: View {
//    @StateObject private var calendarManager = CalendarManager()
//    let years = Array(arrayLiteral: 2024) // Add more years as needed
//    let months = [
//        "Jan", "Feb", "Mar", "Apr", "May", "Jun",
//        "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
//    ]
//    
//    let days = ["S", "M", "T", "W", "R", "F", "S2"]
//    
//    @State private var eventsByYearAndMonth: [String: [String: [Int: [EKEvent]]]] = [:]
//    @State private var selectedEvent: EKEvent?
//    @State private var showingEditEventSheet = false
//    
//    var body: some View {
//        GeometryReader { geometry in
//            ScrollView {
//                LazyVStack(spacing: 20) { // Adjust the spacing as needed
//                    ForEach(years, id: \.self) { year in
//                        VStack {
//                            Text("\(String(year))")
//                                .font(.title)
//                                .bold()
//                                .padding()
//                            
//                            ForEach(0..<4, id: \.self) { quarter in
//                                LazyVGrid(
//                                    columns: Array(repeating: GridItem(.flexible()), count: 3),
//                                    spacing: 16
//                                ) {
//                                    ForEach(quarter * 3..<min((quarter + 1) * 3, months.count), id: \.self) { monthIndex in
//                                        MonthView(
//                                            year: year,
//                                            month: months[monthIndex],
//                                            days: days,
//                                            events: eventsByYearAndMonth["\(year)"]?[months[monthIndex]] ?? [:],
//                                            monthIndex: monthIndex,
//                                            selectedEvent: $selectedEvent,
//                                            showingEditEventSheet: $showingEditEventSheet
//                                        )
//                                        .frame(
//                                            width: (geometry.size.width - 40) / 3, // Dynamically adjust width
//                                            height: geometry.size.height / 4  // Dynamically adjust height
//                                        )
//                                        
//                                        .onAppear {
//                                            calendarManager.fetchEvents(for: monthIndex + 1, year: year) { events in
//                                                var yearEvents = eventsByYearAndMonth["\(year)"] ?? [:]
//                                                yearEvents[months[monthIndex]] = events
//                                                eventsByYearAndMonth["\(year)"] = yearEvents
//                                            }
//                                        }
//                                    }
//                                }
//                            }
//                            .padding(.horizontal)
//                        }
//                    }
//                }
//            }
//        }
//        .sheet(isPresented: $showingEditEventSheet) {
//            if let event = selectedEvent {
//                EditEventView(viewModel: EventViewModel(), event: event)
//            }
//        }
//    }
//}
//
//struct MonthView: View {
//    let year: Int
//    let month: String
//    let days: [String]
//    let events: [Int: [EKEvent]]
//    let monthIndex: Int
//    
//    @Binding var selectedEvent: EKEvent?
//    @Binding var showingEditEventSheet: Bool
//    
//    private let currentDay: Int
//    private let currentMonth: Int
//    private let currentYear: Int
//    
//    @State private var selectedDay: Int? = nil
//    @State private var showingEventsPopup = false
//    
//    init(year: Int, month: String, days: [String], events: [Int: [EKEvent]], monthIndex: Int, selectedEvent: Binding<EKEvent?>, showingEditEventSheet: Binding<Bool>) {
//        self.year = year
//        self.month = month
//        self.days = days
//        self.events = events
//        self.monthIndex = monthIndex
//        _selectedEvent = selectedEvent
//        _showingEditEventSheet = showingEditEventSheet
//        
//        let currentDate = Date()
//        let calendar = Calendar.current
//        self.currentDay = calendar.component(.day, from: currentDate)
//        self.currentMonth = calendar.component(.month, from: currentDate)
//        self.currentYear = calendar.component(.year, from: currentDate)
//    }
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 8) {
//            Text(month)
//                .font(.caption)
//                .bold()
//            
//            WeekdayHeaderView(days: days)
//            
//            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
//                ForEach(getGridItems(), id: \.self) { item in
//                    if item.isEmpty {
//                        EmptyCellView()
//                    } else {
//                        DayCellView(
//                            day: item,
//                            events: events[Int(item)!],
//                            currentDay: currentDay,
//                            monthIndex: monthIndex,
//                            year: year,
//                            onDaySelected: { day in
//                                selectedDay = day
//                                showingEventsPopup = true
//                            }
//                        )
//                    }
//                }
//            }
//        }
//        .padding()
//        .background(isCurrentMonth() ? Color.red.opacity(0.1) : Color.clear)
//        .cornerRadius(8)
//        .sheet(isPresented: $showingEventsPopup) {
//            if let day = selectedDay, let dayEvents = events[day] {
//                EventsPopupView(
//                    day: day,
//                    month: month,
//                    year: year,
//                    events: dayEvents,
//                    onEventSelected: { event in
//                        selectedEvent = event
//                        showingEditEventSheet = true
//                    }
//                )
//            }
//        }
//    }
//    
//    private func getGridItems() -> [String] {
//        let emptyDays = getFirstDayOfMonth(year: year, monthIndex: monthIndex + 1)
//        let totalDays = daysInMonth(year: year, month: monthIndex + 1)
//        return Array(repeating: "", count: emptyDays) + (1...totalDays).map { String($0) }
//    }
//    
//    private func isCurrentDay(day: Int) -> Bool {
//        return day == currentDay && monthIndex + 1 == currentMonth && year == currentYear
//    }
//    
//    func isCurrentMonth() -> Bool {
//        return  monthIndex + 1 == currentMonth && year == currentYear
//    }
//    
//    private func getFirstDayOfMonth(year: Int, monthIndex: Int) -> Int {
//        var dateComponents = DateComponents()
//        dateComponents.year = year
//        dateComponents.month = monthIndex
//        dateComponents.day = 1
//        
//        let calendar = Calendar.current
//        let date = calendar.date(from: dateComponents)!
//        let weekday = calendar.component(.weekday, from: date)
//        
//        let firstWeekday = calendar.firstWeekday
//        let adjustedWeekday = (weekday - firstWeekday + 7) % 7
//        
//        return adjustedWeekday
//    }
//    
//    private func daysInMonth(year: Int, month: Int) -> Int {
//        let dateComponents = DateComponents(year: year, month: month)
//        let calendar = Calendar.current
//        let date = calendar.date(from: dateComponents)!
//        let range = calendar.range(of: .day, in: .month, for: date)!
//        return range.count
//    }
//}
//
//struct WeekdayHeaderView: View {
//    let days: [String]
//    
//    var body: some View {
//        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
//            ForEach(days, id: \.self) { day in
//                Text(day.prefix(1))
//                    .font(.system(size: 10))
//                    .bold()
//            }
//        }
//    }
//}
//
//struct EmptyCellView: View {
//    var body: some View {
//        Text("")  // Empty cell representation
//            .frame(minWidth: 0, maxWidth: .infinity)
//    }
//}
//
//struct DayCellView: View {
//    let day: String
//    let events: [EKEvent]?
//    let currentDay: Int
//    let monthIndex: Int
//    let year: Int
//    let onDaySelected: (Int) -> Void
//    
//    var body: some View {
//        VStack {
//            Text(day)
//                .font(.system(size: 10))
//                .frame(minWidth: 0, maxWidth: .infinity)
//                .background(isCurrentDay(day: Int(day)!) ? Color.red.opacity(1) : Color.clear)
//                .cornerRadius(4)
//            
//            if let events = events {
//                ForEach(events.prefix(5), id: \.eventIdentifier) { event in // Show up to 5 events
//                    Text(event.title)
//                        .font(.system(size: 8))
//                        .foregroundColor(.red)
//                        .multilineTextAlignment(.center)
//                        .lineLimit(1)
//                }
//            } else {
//                Text("")
//            }
//            Spacer()
//        }
//        .onTapGesture {
//            if let day = Int(day) {
//                onDaySelected(day)
//            }
//        }
//    }
//    
//    private func isCurrentDay(day: Int) -> Bool {
//        let calendar = Calendar.current
//        let components = calendar.dateComponents([.day, .month, .year], from: Date())
//        return day == components.day && monthIndex + 1 == components.month && year == components.year
//    }
//}
//
//// MARK: - EventsPopupView
//
//struct EventsPopupView: View {
//    let day: Int
//    let month: String
//    let year: Int
//    let events: [EKEvent]
//    let onEventSelected: (EKEvent) -> Void
//    @Environment(\.presentationMode) var presentationMode
//    @State private var showingAddEventSheet = false
//    
//    var body: some View {
//        NavigationView {
//            List {
//                ForEach(events, id: \.eventIdentifier) { event in
//                    Button(action: {
//                        presentationMode.wrappedValue.dismiss() // Dismiss the popup
//                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { // Delay to wait for dismissal
//                            onEventSelected(event) // Trigger the callback to show the edit sheet
//                        }
//                    }) {
//                        VStack(alignment: .leading) {
//                            Text(event.title)
//                                .font(.headline)
//                            Text(event.startDate, style: .time)
//                                .font(.subheadline)
//                        }
//                    }
//                }
//            }
//            .navigationTitle("Events for \(month) \(day), \(year)")
//            .toolbar {
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    Button("Add Event") {
//                        showingAddEventSheet = true
//                    }
//                }
//                ToolbarItem(placement: .navigationBarLeading) {
//                    Button("Close") {
//                        presentationMode.wrappedValue.dismiss()
//                    }
//                }
//            }
//            .sheet(isPresented: $showingAddEventSheet) {
//                AddEventView(viewModel: EventViewModel())
//                    .presentationDetents([.medium, .large]) // Allows the sheet to expand or collapse
//                    .presentationDragIndicator(.visible) // Shows a drag indicator to resize the sheet
//            }
//        }
//    }
//}
//
//// Helper View to Create an Event from the Popup
//struct AddEventViewWrapper: View {
//    @StateObject private var viewModel = EventViewModel()
//    @Environment(\.presentationMode) var presentationMode
//    
//    var body: some View {
//        AddEventView(viewModel: viewModel)
//            .toolbar {
//                ToolbarItem(placement: .navigationBarLeading) {
//                    Button("Cancel") {
//                        presentationMode.wrappedValue.dismiss()
//                    }
//                }
//            }
//    }
//}
//
//@main
//struct MyApp: App {
//    var body: some Scene {
//        WindowGroup {
//            ContentView()
//                .padding()
//        }
//    }
//}
