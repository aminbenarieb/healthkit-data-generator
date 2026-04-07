import Foundation

enum DateRangeType: String, CaseIterable {
    case lastDays = "last_days"
    case thisWeek = "this_week"
    case thisMonth = "this_month"
    case weekdaysOnly = "weekdays_only"
    case weekendsOnly = "weekends_only"
    case specificDates = "specific_dates"
    
    var displayName: String {
        switch self {
        case .lastDays: return "Last N Days"
        case .thisWeek: return "This Week"
        case .thisMonth: return "This Month"
        case .weekdaysOnly: return "Weekdays"
        case .weekendsOnly: return "Weekends"
        case .specificDates: return "Specific"
        }
    }
}
