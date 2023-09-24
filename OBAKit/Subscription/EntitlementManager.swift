import SwiftUI

class EntitlementManager: ObservableObject {
    static let userDefaults = UserDefaults(suiteName: Bundle.main.appGroup!)!

    @AppStorage("adsFree", store: userDefaults)
    var adsFree: Bool = false
}
