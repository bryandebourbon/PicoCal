import SwiftUI

struct EventPlot: View {
    
    let dayOfMonth: Int
    let isBusyMorning: Bool
    let isBusyAfternoon: Bool
    let isBusyEvening: Bool
    
    var body: some View {
        let events = eventsForThisDay()
        VStack(spacing: 0) {
            GeometryReader { geometry in
                let lineHeight: CGFloat = 14 // Adjust this value based on your font size
                
                if geometry.size.height < lineHeight {
                    HStack(spacing: 0) {
                        ForEach(events) { event in
                            Rectangle()
                                .fill(event.calendarcolor)
                                .frame(minWidth: 4)
                        }
                    }
                } else {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(events) { event in
                            HStack(spacing: 0){
                                Rectangle()
                                  .fill(event.calendarcolor)
                                  .frame(maxWidth: 4)
                                Text(event.title)
                                    .font(.system(size: 10))
                                    .lineLimit(1)
                                    .frame(height: lineHeight)
                            }.frame(height: lineHeight)
                        }

                    }
                }

            }
        }
    }
    
    /// Helper to compute the Date for `dayOfMonth` in the *current* month,
    /// then filter events from `EventKitFetcher.eventDays`.
    private func eventsForThisDay() -> [EventWrapper] {
        let calendar = Calendar.current
        let today = Date()
        
        // 1) Find the first day of the current month.
        let startOfMonth = calendar.startOfMonth(for: today)
        
        // 2) Build a Date that corresponds to `dayOfMonth`.
        guard let targetDate = calendar.date(byAdding: .day, value: dayOfMonth - 1, to: startOfMonth) else {
            return []
        }
        
        // 3) Filter the global `eventDays` to those that fall on `targetDate`.
        return EventKitFetcher.eventDays.filter { eventWrapper in
            calendar.isDate(eventWrapper.startDate, inSameDayAs: targetDate)
        }
    }
}
