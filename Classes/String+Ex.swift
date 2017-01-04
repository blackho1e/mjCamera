
extension String {
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    
    func localizedWithOption(tableName tableName: String? = nil, bundle: Bundle = Bundle.main, value: String = "") -> String {
        return NSLocalizedString(self, tableName: tableName, bundle: bundle, value: value, comment: "")
    }
}
