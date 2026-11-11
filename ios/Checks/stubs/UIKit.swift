// 型別檢查用的 UIKit 介面樁：只宣告 App 用到的符號，沒有任何實作。
// 用途見 ios/Checks/README.md。這不是 UIKit，也不能用來執行 App。
@_exported import Foundation

public final class UIColor: @unchecked Sendable {
    public static let systemFill = UIColor(), secondarySystemFill = UIColor(), tertiarySystemFill = UIColor()
    public static let systemBackground = UIColor(), secondarySystemBackground = UIColor(), tertiarySystemBackground = UIColor()
    public static let systemGroupedBackground = UIColor(), secondarySystemGroupedBackground = UIColor()
    public static let systemGray = UIColor(), systemGray2 = UIColor(), systemGray3 = UIColor(), systemGray4 = UIColor(), systemGray5 = UIColor(), systemGray6 = UIColor()
    public static let label = UIColor(), secondaryLabel = UIColor(), separator = UIColor()
    public init() {}
}
public final class UIPasteboard { nonisolated(unsafe) public static let general = UIPasteboard(); public var string: String? }
public enum UIKeyboardType { case `default`, asciiCapable, numbersAndPunctuation, URL, numberPad, phonePad, emailAddress, decimalPad }
@MainActor public final class UIApplication { public static let shared = UIApplication(); public func registerForRemoteNotifications() {} }
