import Foundation
import SwiftData

@Model
final class GratitudeEntry {
    var date: Date
    var text: String
    
    init(date: Date, text: String) {
        self.date = date
        self.text = text
    }
}
