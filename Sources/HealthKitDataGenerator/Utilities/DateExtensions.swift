
import Foundation

// MARK: - Date Formatting Extensions

public enum DateFormat {
    case iso8601
}

extension Date {
    public func string(_ format: DateFormat) -> String {
        let formatter: DateFormatter
        switch format {
        case .iso8601:
            formatter = .iso8601
        }
        return formatter.string(from: self)
    }
}

extension String {
    public func date(_ format: DateFormat) throws -> Date {
        let formatter: DateFormatter
        switch format {
        case .iso8601:
            formatter = .iso8601
        }
        
        guard let date = formatter.date(from: self) else {
            throw NSError(domain: "DateFormattingError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid date format for string: \(self)"])
        }
        return date
    }
}

