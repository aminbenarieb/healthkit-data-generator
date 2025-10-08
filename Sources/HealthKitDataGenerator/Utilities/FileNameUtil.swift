
import Foundation

/// Utility class for working with file names.
open class FileNameUtil {

    /// Removes the characters \ ? % * | . : , " < > from a string
    /// - Parameter userInput: a string that needs to be transformed to a filename
    /// - Returns: the string with all the characters mentioned above removed from the string.
    public static func normalizeName(_ userInput: String) -> String {
        let trimmedUserInput = userInput.trimmingCharacters(in: CharacterSet.whitespaces)

        let illegalFileNameCharacters = CharacterSet.init(charactersIn: "/\\?%*|.:, \"<>")

        return trimmedUserInput.components(separatedBy: illegalFileNameCharacters).joined(separator: "")
    }
}

