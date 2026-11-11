// 型別檢查用的 SwiftUI 介面樁（stub）：只宣告 App 用到的型別與修飾器的「簽章」，沒有任何實作。
// 目的：在沒有 Xcode 的 Linux／CI 上，用 Swift 編譯器檢查 App 自己的程式（欄位名稱、參數標籤、Optional、async/await、型別）。
// 限制：簽章依 iOS 17 SDK 的公開介面手寫，不保證與 Apple 的 SwiftUI 完全一致；通過這裡的檢查不等於 Xcode 編譯通過。
@_exported import Foundation
@_exported import UIKit

// MARK: - View 與 ViewBuilder
public protocol View {
    associatedtype Body: View
    @ViewBuilder @MainActor var body: Self.Body { get }
}
extension Never: View { public typealias Body = Never; public var body: Never { fatalError() } }
public protocol _Primitive: View where Body == Never {}
public extension _Primitive { @MainActor var body: Never { fatalError() } }

@resultBuilder public enum ViewBuilder {
    public static func buildExpression<Content: View>(_ content: Content) -> Content { content }
    public static func buildBlock() -> EmptyView { EmptyView() }
    public static func buildBlock<Content: View>(_ content: Content) -> Content { content }
    public static func buildBlock<each Content: View>(_ content: repeat each Content) -> TupleView<(repeat each Content)> { TupleView((repeat each content)) }
    public static func buildIf<Content: View>(_ content: Content?) -> Content? { content }
    public static func buildEither<T: View, F: View>(first: T) -> _ConditionalContent<T, F> { _ConditionalContent() }
    public static func buildEither<T: View, F: View>(second: F) -> _ConditionalContent<T, F> { _ConditionalContent() }
    public static func buildLimitedAvailability<Content: View>(_ content: Content) -> AnyView { AnyView() }
}
public struct EmptyView: _Primitive { public init() {} }
public struct AnyView: _Primitive { public init() {}; public init<V: View>(_ view: V) {} }
public struct TupleView<T>: _Primitive { public init(_ value: T) {} }
public struct _ConditionalContent<T: View, F: View>: _Primitive { init() {} }
extension Optional: View where Wrapped: View { public typealias Body = Never; public var body: Never { fatalError() } }
public struct _Modified: _Primitive { init() {} }

// MARK: - 資料流
public protocol DynamicProperty {}
public protocol ObservableObject: AnyObject {}
@propertyWrapper public struct Published<Value> { public var wrappedValue: Value; public init(wrappedValue: Value) { self.wrappedValue = wrappedValue } }

@propertyWrapper @dynamicMemberLookup public struct Binding<Value>: DynamicProperty {
    public var wrappedValue: Value { get { fatalError() } nonmutating set {} }
    public var projectedValue: Binding<Value> { self }
    public init(get: @escaping () -> Value, set: @escaping (Value) -> Void) {}
    public static func constant(_ value: Value) -> Binding<Value> { fatalError() }
    public subscript<Subject>(dynamicMember keyPath: WritableKeyPath<Value, Subject>) -> Binding<Subject> { fatalError() }
}
@propertyWrapper public struct State<Value>: DynamicProperty {
    public init(wrappedValue value: Value) {}
    public init(initialValue value: Value) {}
    public var wrappedValue: Value { get { fatalError() } nonmutating set {} }
    public var projectedValue: Binding<Value> { fatalError() }
}
extension State where Value: ExpressibleByNilLiteral { public init() {} }
@propertyWrapper public struct EnvironmentObject<ObjectType: ObservableObject>: DynamicProperty {
    @dynamicMemberLookup public struct Wrapper { public subscript<Subject>(dynamicMember keyPath: ReferenceWritableKeyPath<ObjectType, Subject>) -> Binding<Subject> { fatalError() } }
    public init() {}
    @MainActor public var wrappedValue: ObjectType { fatalError() }
    @MainActor public var projectedValue: Wrapper { fatalError() }
}
@propertyWrapper public struct StateObject<ObjectType: ObservableObject>: DynamicProperty {
    public init(wrappedValue thunk: @autoclosure @escaping () -> ObjectType) {}
    @MainActor public var wrappedValue: ObjectType { fatalError() }
    @MainActor public var projectedValue: EnvironmentObject<ObjectType>.Wrapper { fatalError() }
}
public struct DismissAction { @MainActor public func callAsFunction() {} }
public struct EnvironmentValues { public var dismiss: DismissAction { DismissAction() } }
@propertyWrapper public struct Environment<Value>: DynamicProperty {
    public init(_ keyPath: KeyPath<EnvironmentValues, Value>) {}
    public var wrappedValue: Value { fatalError() }
}

// MARK: - 樣式
public protocol ShapeStyle {}
public struct HierarchicalShapeStyle: ShapeStyle {}
public struct Material: ShapeStyle {}
public struct TintShapeStyle: ShapeStyle {}
public struct Color: ShapeStyle, View, Hashable, Sendable {
    public typealias Body = Never
    @MainActor public var body: Never { fatalError() }
    public init(_ color: UIColor) {}
    public init(red: Double, green: Double, blue: Double, opacity: Double = 1) {}
    public func opacity(_ opacity: Double) -> Color { self }
    public static let red = Color(.label), orange = Color(.label), yellow = Color(.label), green = Color(.label), mint = Color(.label), teal = Color(.label), cyan = Color(.label)
    public static let blue = Color(.label), indigo = Color(.label), purple = Color(.label), pink = Color(.label), brown = Color(.label)
    public static let white = Color(.label), gray = Color(.label), black = Color(.label), clear = Color(.label)
    public static let primary = Color(.label), secondary = Color(.label), accentColor = Color(.label)
    public static func == (a: Color, b: Color) -> Bool { true }
    public func hash(into hasher: inout Hasher) {}
}
public extension ShapeStyle where Self == Color {
    static var red: Color { Color.red }; static var orange: Color { Color.orange }; static var yellow: Color { Color.yellow }; static var green: Color { Color.green }
    static var mint: Color { Color.mint }; static var teal: Color { Color.teal }; static var cyan: Color { Color.cyan }; static var blue: Color { Color.blue }
    static var indigo: Color { Color.indigo }; static var purple: Color { Color.purple }; static var pink: Color { Color.pink }; static var brown: Color { Color.brown }
    static var white: Color { Color.white }; static var gray: Color { Color.gray }; static var black: Color { Color.black }; static var clear: Color { Color.clear }
}
public extension ShapeStyle where Self == HierarchicalShapeStyle {
    static var primary: HierarchicalShapeStyle { .init() }; static var secondary: HierarchicalShapeStyle { .init() }
    static var tertiary: HierarchicalShapeStyle { .init() }; static var quaternary: HierarchicalShapeStyle { .init() }
}
public extension ShapeStyle where Self == Material {
    static var bar: Material { .init() }; static var regularMaterial: Material { .init() }; static var thinMaterial: Material { .init() }; static var ultraThinMaterial: Material { .init() }
}
public extension ShapeStyle where Self == TintShapeStyle { static var tint: TintShapeStyle { .init() } }

public struct Font: Hashable, Sendable {
    public enum Weight: Sendable { case ultraLight, thin, light, regular, medium, semibold, bold, heavy, black }
    public enum Design: Sendable { case `default`, serif, rounded, monospaced }
    public static let largeTitle = Font(), title = Font(), title2 = Font(), title3 = Font(), headline = Font(), subheadline = Font(), body = Font(), callout = Font(), footnote = Font(), caption = Font(), caption2 = Font()
    public static func system(size: CGFloat, weight: Weight? = nil, design: Design? = nil) -> Font { Font() }
    public func weight(_ weight: Weight) -> Font { self }
    public func bold() -> Font { self }
    public func italic() -> Font { self }
    public func monospaced() -> Font { self }
    public func monospacedDigit() -> Font { self }
}
public struct Alignment: Sendable { public static let center = Alignment(), leading = Alignment(), trailing = Alignment(), top = Alignment(), bottom = Alignment(), topLeading = Alignment(), topTrailing = Alignment(), bottomLeading = Alignment(), bottomTrailing = Alignment() }
public struct HorizontalAlignment: Sendable { public static let leading = HorizontalAlignment(), center = HorizontalAlignment(), trailing = HorizontalAlignment() }
public struct VerticalAlignment: Sendable { public static let top = VerticalAlignment(), center = VerticalAlignment(), bottom = VerticalAlignment(), firstTextBaseline = VerticalAlignment(), lastTextBaseline = VerticalAlignment() }
public struct UnitPoint: Sendable { public static let center = UnitPoint(), top = UnitPoint(), bottom = UnitPoint(), leading = UnitPoint(), trailing = UnitPoint(), topLeading = UnitPoint(), topTrailing = UnitPoint(), bottomLeading = UnitPoint(), bottomTrailing = UnitPoint() }
public enum Edge: Sendable { case top, leading, bottom, trailing
    public struct Set: OptionSet, Sendable { public let rawValue: Int; public init(rawValue: Int) { self.rawValue = rawValue }
        public static let top = Set(rawValue: 1), leading = Set(rawValue: 2), bottom = Set(rawValue: 4), trailing = Set(rawValue: 8)
        public static let horizontal: Set = [.leading, .trailing], vertical: Set = [.top, .bottom], all: Set = [.horizontal, .vertical] } }
public enum VerticalEdge: Sendable { case top, bottom }
public struct EdgeInsets: Sendable { public init(top: CGFloat, leading: CGFloat, bottom: CGFloat, trailing: CGFloat) {}; public init() {} }
public enum Axis: Sendable { case horizontal, vertical
    public struct Set: OptionSet, Sendable { public let rawValue: Int; public init(rawValue: Int) { self.rawValue = rawValue }; public static let horizontal = Set(rawValue: 1), vertical = Set(rawValue: 2) } }
public enum Visibility: Sendable { case automatic, visible, hidden }
public enum TextAlignment: Sendable { case leading, center, trailing }
public enum ControlSize: Sendable { case mini, small, regular, large, extraLarge }
public struct ButtonRole: Sendable { public static let destructive = ButtonRole(), cancel = ButtonRole() }
public struct TextInputAutocapitalization: Sendable { public static let never = TextInputAutocapitalization(), words = TextInputAutocapitalization(), sentences = TextInputAutocapitalization(), characters = TextInputAutocapitalization() }
public struct SubmitTriggers: OptionSet, Sendable { public let rawValue: Int; public init(rawValue: Int) { self.rawValue = rawValue }; public static let text = SubmitTriggers(rawValue: 1), search = SubmitTriggers(rawValue: 2) }
public struct Animation: Sendable { public static let `default` = Animation(), easeInOut = Animation(), spring = Animation() }
public func withAnimation<Result>(_ animation: Animation? = .default, _ body: () throws -> Result) rethrows -> Result { try body() }
public enum NavigationBarItem { public enum TitleDisplayMode: Sendable { case automatic, inline, large } }
public struct ToolbarItemPlacement: Sendable { public static let automatic = ToolbarItemPlacement(), principal = ToolbarItemPlacement(), cancellationAction = ToolbarItemPlacement(), confirmationAction = ToolbarItemPlacement(), topBarLeading = ToolbarItemPlacement(), topBarTrailing = ToolbarItemPlacement(), bottomBar = ToolbarItemPlacement(), navigationBarTrailing = ToolbarItemPlacement(), navigationBarLeading = ToolbarItemPlacement() }

public protocol PrimitiveButtonStyle {}
public struct PlainButtonStyle: PrimitiveButtonStyle {}; public struct BorderedButtonStyle: PrimitiveButtonStyle {}; public struct BorderedProminentButtonStyle: PrimitiveButtonStyle {}; public struct BorderlessButtonStyle: PrimitiveButtonStyle {}
public extension PrimitiveButtonStyle where Self == PlainButtonStyle { static var plain: PlainButtonStyle { .init() } }
public extension PrimitiveButtonStyle where Self == BorderedButtonStyle { static var bordered: BorderedButtonStyle { .init() } }
public extension PrimitiveButtonStyle where Self == BorderedProminentButtonStyle { static var borderedProminent: BorderedProminentButtonStyle { .init() } }
public extension PrimitiveButtonStyle where Self == BorderlessButtonStyle { static var borderless: BorderlessButtonStyle { .init() } }
public protocol PickerStyle {}
public struct SegmentedPickerStyle: PickerStyle {}; public struct MenuPickerStyle: PickerStyle {}; public struct InlinePickerStyle: PickerStyle {}; public struct WheelPickerStyle: PickerStyle {}; public struct NavigationLinkPickerStyle: PickerStyle {}
public extension PickerStyle where Self == SegmentedPickerStyle { static var segmented: SegmentedPickerStyle { .init() } }
public extension PickerStyle where Self == MenuPickerStyle { static var menu: MenuPickerStyle { .init() } }
public extension PickerStyle where Self == InlinePickerStyle { static var inline: InlinePickerStyle { .init() } }
public extension PickerStyle where Self == WheelPickerStyle { static var wheel: WheelPickerStyle { .init() } }
public extension PickerStyle where Self == NavigationLinkPickerStyle { static var navigationLink: NavigationLinkPickerStyle { .init() } }
public protocol TextFieldStyle {}
public struct RoundedBorderTextFieldStyle: TextFieldStyle {}; public struct PlainTextFieldStyle: TextFieldStyle {}
public extension TextFieldStyle where Self == RoundedBorderTextFieldStyle { static var roundedBorder: RoundedBorderTextFieldStyle { .init() } }
public extension TextFieldStyle where Self == PlainTextFieldStyle { static var plain: PlainTextFieldStyle { .init() } }
public protocol TextSelectability {}
public struct EnabledTextSelectability: TextSelectability {}; public struct DisabledTextSelectability: TextSelectability {}
public extension TextSelectability where Self == EnabledTextSelectability { static var enabled: EnabledTextSelectability { .init() } }
public extension TextSelectability where Self == DisabledTextSelectability { static var disabled: DisabledTextSelectability { .init() } }

// MARK: - 基本元件
public struct Text: _Primitive {
    public init<S: StringProtocol>(_ content: S) {}
    public init(verbatim content: String) {}
    public func font(_ font: Font?) -> Text { self }
    public func fontWeight(_ weight: Font.Weight?) -> Text { self }
    public func bold() -> Text { self }
    public func italic() -> Text { self }
    public func monospacedDigit() -> Text { self }
    public func foregroundColor(_ color: Color?) -> Text { self }
    public func foregroundStyle<S: ShapeStyle>(_ style: S) -> Text { self }
    public static func + (lhs: Text, rhs: Text) -> Text { lhs }
}
public struct Image: _Primitive { public init(systemName: String) {}; public init(_ name: String) {} }
public struct Spacer: _Primitive { public init(minLength: CGFloat? = nil) {} }
public struct Divider: _Primitive { public init() {} }
public struct ProgressView: _Primitive { public init() {}; public init<S: StringProtocol>(_ title: S) {} }
public struct Label<Title: View, Icon: View>: _Primitive { public init(@ViewBuilder title: () -> Title, @ViewBuilder icon: () -> Icon) {} }
public extension Label where Title == Text, Icon == Image { init<S: StringProtocol>(_ title: S, systemImage name: String) { self.init(title: { Text(title) }, icon: { Image(systemName: name) }) } }
public struct Button<Label: View>: _Primitive {
    public init(action: @escaping () -> Void, @ViewBuilder label: () -> Label) {}
    public init(role: ButtonRole?, action: @escaping () -> Void, @ViewBuilder label: () -> Label) {}
}
public extension Button where Label == Text {
    init<S: StringProtocol>(_ title: S, action: @escaping () -> Void) { self.init(action: action) { Text(title) } }
    init<S: StringProtocol>(_ title: S, role: ButtonRole?, action: @escaping () -> Void) { self.init(action: action) { Text(title) } }
}
public struct Link<Label: View>: _Primitive { public init(destination: URL, @ViewBuilder label: () -> Label) {} }
public extension Link where Label == Text { init<S: StringProtocol>(_ title: S, destination: URL) { self.init(destination: destination) { Text(title) } } }
public struct ShareLink<Label: View>: _Primitive { public init(item: URL, @ViewBuilder label: () -> Label) {} }
public struct TextField: _Primitive {
    public init<S: StringProtocol>(_ title: S, text: Binding<String>) {}
    public init<S: StringProtocol>(_ title: S, text: Binding<String>, axis: Axis) {}
}
public struct SecureField: _Primitive { public init<S: StringProtocol>(_ title: S, text: Binding<String>) {} }
public struct Toggle: _Primitive { public init<S: StringProtocol>(_ title: S, isOn: Binding<Bool>) {} }
public struct Stepper: _Primitive { public init<S: StringProtocol, V: Strideable>(_ title: S, value: Binding<V>, in bounds: ClosedRange<V>, step: V.Stride = 1) {} }
public struct Picker<SelectionValue: Hashable, Content: View>: _Primitive { public init<S: StringProtocol>(_ title: S, selection: Binding<SelectionValue>, @ViewBuilder content: () -> Content) {} }
public struct LabeledContent: _Primitive { public init<S1: StringProtocol, S2: StringProtocol>(_ title: S1, value: S2) {} }

// MARK: - 容器
public struct VStack<Content: View>: _Primitive { public init(alignment: HorizontalAlignment = .center, spacing: CGFloat? = nil, @ViewBuilder content: () -> Content) {} }
public struct HStack<Content: View>: _Primitive { public init(alignment: VerticalAlignment = .center, spacing: CGFloat? = nil, @ViewBuilder content: () -> Content) {} }
public struct ZStack<Content: View>: _Primitive { public init(alignment: Alignment = .center, @ViewBuilder content: () -> Content) {} }
public struct LazyVStack<Content: View>: _Primitive { public init(alignment: HorizontalAlignment = .center, spacing: CGFloat? = nil, @ViewBuilder content: () -> Content) {} }
public struct Group<Content: View>: _Primitive { public init(@ViewBuilder content: () -> Content) {} }
public struct Form<Content: View>: _Primitive { public init(@ViewBuilder content: () -> Content) {} }
public struct List<Content: View>: _Primitive { public init(@ViewBuilder content: () -> Content) {} }
public struct ScrollView<Content: View>: _Primitive { public init(_ axes: Axis.Set = .vertical, showsIndicators: Bool = true, @ViewBuilder content: () -> Content) {} }
public struct ScrollViewProxy { public func scrollTo<ID: Hashable>(_ id: ID, anchor: UnitPoint? = nil) {} }
public struct ScrollViewReader<Content: View>: _Primitive { public init(@ViewBuilder content: @escaping (ScrollViewProxy) -> Content) {} }
public struct GeometryProxy { public var size: CGSize { .zero } }
public struct GeometryReader<Content: View>: _Primitive { public init(@ViewBuilder content: @escaping (GeometryProxy) -> Content) {} }
public struct NavigationStack<Root: View>: _Primitive { public init(@ViewBuilder root: () -> Root) {} }
public struct NavigationLink<Label: View, Destination: View>: _Primitive {
    public init(@ViewBuilder destination: () -> Destination, @ViewBuilder label: () -> Label) {}
    public init(destination: Destination, @ViewBuilder label: () -> Label) {}
}
public extension NavigationLink where Label == Text {
    init<S: StringProtocol>(_ title: S, destination: Destination) { self.init(destination: destination) { Text(title) } }
    init<S: StringProtocol>(_ title: S, @ViewBuilder destination: () -> Destination) { self.init(destination: destination) { Text(title) } }
}
public struct TabView<Content: View>: _Primitive { public init(@ViewBuilder content: () -> Content) {} }
public struct DisclosureGroup<Label: View, Content: View>: _Primitive {
    public init(@ViewBuilder content: @escaping () -> Content, @ViewBuilder label: () -> Label) {}
    public init(isExpanded: Binding<Bool>, @ViewBuilder content: @escaping () -> Content, @ViewBuilder label: () -> Label) {}
}
public extension DisclosureGroup where Label == Text {
    init<S: StringProtocol>(_ label: S, @ViewBuilder content: @escaping () -> Content) { self.init(content: content) { Text(label) } }
    init<S: StringProtocol>(_ label: S, isExpanded: Binding<Bool>, @ViewBuilder content: @escaping () -> Content) { self.init(content: content) { Text(label) } }
}
public struct Section<Parent, Content, Footer> { init() {} }
extension Section: View where Parent: View, Content: View, Footer: View {
    public typealias Body = Never
    @MainActor public var body: Never { fatalError() }
    public init(@ViewBuilder content: () -> Content, @ViewBuilder header: () -> Parent, @ViewBuilder footer: () -> Footer) { self.init() }
}
public extension Section where Parent == EmptyView, Content: View, Footer: View { init(@ViewBuilder content: () -> Content, @ViewBuilder footer: () -> Footer) { self.init() } }
public extension Section where Parent: View, Content: View, Footer == EmptyView { init(@ViewBuilder content: () -> Content, @ViewBuilder header: () -> Parent) { self.init() } }
public extension Section where Parent == EmptyView, Content: View, Footer == EmptyView { init(@ViewBuilder content: () -> Content) { self.init() } }
public extension Section where Parent == Text, Content: View, Footer == EmptyView { init<S: StringProtocol>(_ title: S, @ViewBuilder content: () -> Content) { self.init() } }

public struct ForEach<Data: RandomAccessCollection, ID: Hashable, Content> { init() {} }
extension ForEach: View where Content: View { public typealias Body = Never; @MainActor public var body: Never { fatalError() } }
public extension ForEach where ID == Data.Element.ID, Content: View, Data.Element: Identifiable { init(_ data: Data, @ViewBuilder content: @escaping (Data.Element) -> Content) { self.init() } }
public extension ForEach where Content: View { init(_ data: Data, id: KeyPath<Data.Element, ID>, @ViewBuilder content: @escaping (Data.Element) -> Content) { self.init() } }
public extension ForEach where Data == Range<Int>, ID == Int, Content: View { init(_ data: Range<Int>, @ViewBuilder content: @escaping (Int) -> Content) { self.init() } }
public extension ForEach where Content: View { func onDelete(perform action: ((IndexSet) -> Void)?) -> some View { _Modified() } }

public struct ToolbarItem<Content: View>: _Primitive { public init(placement: ToolbarItemPlacement = .automatic, @ViewBuilder content: () -> Content) {} }

// MARK: - 形狀、繪圖、手勢、Layout
public protocol Shape: View {}
public extension Shape {
    func fill<S: ShapeStyle>(_ style: S) -> some View { _Modified() }
    func stroke<S: ShapeStyle>(_ style: S, lineWidth: CGFloat = 1) -> some View { _Modified() }
}
public struct Capsule: Shape, _Primitive { public init() {} }
public struct Circle: Shape, _Primitive { public init() {} }
public struct Rectangle: Shape, _Primitive { public init() {} }
public struct RoundedRectangle: Shape, _Primitive { public init(cornerRadius: CGFloat) {} }
public struct Path {
    public init() {}
    public init(ellipseIn rect: CGRect) {}
    public init(_ rect: CGRect) {}
    public mutating func move(to point: CGPoint) {}
    public mutating func addLine(to point: CGPoint) {}
    public mutating func closeSubpath() {}
    public mutating func addEllipse(in rect: CGRect) {}
}
public struct GraphicsContext {
    public struct Shading { public static func color(_ color: Color) -> Shading { Shading() } }
    public func stroke(_ path: Path, with shading: Shading, lineWidth: CGFloat = 1) {}
    public func fill(_ path: Path, with shading: Shading) {}
    public func draw(_ text: Text, at point: CGPoint, anchor: UnitPoint = .center) {}
}
public struct Canvas: _Primitive { public init(opaque: Bool = false, rendersAsynchronously: Bool = false, renderer: @escaping (inout GraphicsContext, CGSize) -> Void) {} }
public enum CoordinateSpace: Sendable { case local, global }
public protocol Gesture { associatedtype Value }
public extension Gesture {
    func onChanged(_ action: @escaping (Value) -> Void) -> Self { self }
    func onEnded(_ action: @escaping (Value) -> Void) -> Self { self }
}
public struct DragGesture: Gesture {
    public struct Value { public var location: CGPoint { .zero }; public var startLocation: CGPoint { .zero }; public var translation: CGSize { .zero } }
    public init(minimumDistance: CGFloat = 10) {}
}
public struct MagnificationGesture: Gesture { public typealias Value = CGFloat; public init(minimumScaleDelta: CGFloat = 0.01) {} }
public struct ProposedViewSize: Sendable {
    public var width: CGFloat?, height: CGFloat?
    public static let unspecified = ProposedViewSize(width: nil, height: nil), zero = ProposedViewSize(width: 0, height: 0)
    public init(width: CGFloat?, height: CGFloat?) { self.width = width; self.height = height }
    public init(_ size: CGSize) { self.init(width: size.width, height: size.height) }
}
public struct LayoutSubview { public func sizeThatFits(_ proposal: ProposedViewSize) -> CGSize { .zero }; public func place(at position: CGPoint, anchor: UnitPoint = .topLeading, proposal: ProposedViewSize) {} }
public struct LayoutSubviews: RandomAccessCollection {
    public var startIndex: Int { 0 }; public var endIndex: Int { 0 }
    public subscript(index: Int) -> LayoutSubview { LayoutSubview() }
}
public protocol Layout {
    associatedtype Cache = Void
    typealias Subviews = LayoutSubviews
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) -> CGSize
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache)
}
public extension Layout { func callAsFunction<V: View>(@ViewBuilder _ content: () -> V) -> some View { _Modified() } }

// MARK: - 修飾器
public extension View {
    func font(_ font: Font?) -> some View { _Modified() }
    func fontWeight(_ weight: Font.Weight?) -> some View { _Modified() }
    func bold() -> some View { _Modified() }
    func monospacedDigit() -> some View { _Modified() }
    func foregroundStyle<S: ShapeStyle>(_ style: S) -> some View { _Modified() }
    func foregroundColor(_ color: Color?) -> some View { _Modified() }
    func tint(_ color: Color?) -> some View { _Modified() }
    func padding(_ length: CGFloat) -> some View { _Modified() }
    func padding(_ edges: Edge.Set = .all, _ length: CGFloat? = nil) -> some View { _Modified() }
    func frame(width: CGFloat? = nil, height: CGFloat? = nil, alignment: Alignment = .center) -> some View { _Modified() }
    func frame(minWidth: CGFloat? = nil, idealWidth: CGFloat? = nil, maxWidth: CGFloat? = nil, minHeight: CGFloat? = nil, idealHeight: CGFloat? = nil, maxHeight: CGFloat? = nil, alignment: Alignment = .center) -> some View { _Modified() }
    func background<S: ShapeStyle>(_ style: S) -> some View { _Modified() }
    func clipShape<S: Shape>(_ shape: S) -> some View { _Modified() }
    func opacity(_ opacity: Double) -> some View { _Modified() }
    func position(_ position: CGPoint) -> some View { _Modified() }
    func position(x: CGFloat = 0, y: CGFloat = 0) -> some View { _Modified() }
    func disabled(_ disabled: Bool) -> some View { _Modified() }
    func id<ID: Hashable>(_ id: ID) -> some View { _Modified() }
    func tag<V: Hashable>(_ tag: V) -> some View { _Modified() }
    func buttonStyle<S: PrimitiveButtonStyle>(_ style: S) -> some View { _Modified() }
    func pickerStyle<S: PickerStyle>(_ style: S) -> some View { _Modified() }
    func textFieldStyle<S: TextFieldStyle>(_ style: S) -> some View { _Modified() }
    func controlSize(_ size: ControlSize) -> some View { _Modified() }
    func labelsHidden() -> some View { _Modified() }
    func lineLimit(_ number: Int?) -> some View { _Modified() }
    func lineLimit(_ limit: ClosedRange<Int>) -> some View { _Modified() }
    func multilineTextAlignment(_ alignment: TextAlignment) -> some View { _Modified() }
    func textSelection<S: TextSelectability>(_ selectability: S) -> some View { _Modified() }
    func keyboardType(_ type: UIKeyboardType) -> some View { _Modified() }
    func textInputAutocapitalization(_ autocapitalization: TextInputAutocapitalization?) -> some View { _Modified() }
    func autocorrectionDisabled(_ disable: Bool = true) -> some View { _Modified() }
    func listRowInsets(_ insets: EdgeInsets?) -> some View { _Modified() }
    func listRowBackground<V: View>(_ view: V?) -> some View { _Modified() }
    func navigationTitle<S: StringProtocol>(_ title: S) -> some View { _Modified() }
    func navigationBarTitleDisplayMode(_ displayMode: NavigationBarItem.TitleDisplayMode) -> some View { _Modified() }
    func toolbar<Content: View>(@ViewBuilder content: () -> Content) -> some View { _Modified() }
    func tabItem<V: View>(@ViewBuilder _ label: () -> V) -> some View { _Modified() }
    func badge(_ count: Int) -> some View { _Modified() }
    func searchable<S: StringProtocol>(text: Binding<String>, prompt: S) -> some View { _Modified() }
    func onSubmit(of triggers: SubmitTriggers = .text, _ action: @escaping () -> Void) -> some View { _Modified() }
    func onAppear(perform action: (() -> Void)? = nil) -> some View { _Modified() }
    func onDisappear(perform action: (() -> Void)? = nil) -> some View { _Modified() }
    func task(priority: TaskPriority = .userInitiated, @_inheritActorContext _ action: @escaping @Sendable () async -> Void) -> some View { _Modified() }
    func refreshable(@_inheritActorContext action: @escaping @Sendable () async -> Void) -> some View { _Modified() }
    func onChange<V: Equatable>(of value: V, initial: Bool = false, _ action: @escaping (_ oldValue: V, _ newValue: V) -> Void) -> some View { _Modified() }
    func onChange<V: Equatable>(of value: V, initial: Bool = false, _ action: @escaping () -> Void) -> some View { _Modified() }
    @available(*, deprecated, message: "iOS 17 起改用兩個參數或沒有參數的 onChange")
    func onChange<V: Equatable>(of value: V, perform action: @escaping (_ newValue: V) -> Void) -> some View { _Modified() }
    func sheet<Content: View>(isPresented: Binding<Bool>, onDismiss: (() -> Void)? = nil, @ViewBuilder content: @escaping () -> Content) -> some View { _Modified() }
    func alert<S: StringProtocol, A: View, M: View>(_ title: S, isPresented: Binding<Bool>, @ViewBuilder actions: () -> A, @ViewBuilder message: () -> M) -> some View { _Modified() }
    func alert<S: StringProtocol, A: View>(_ title: S, isPresented: Binding<Bool>, @ViewBuilder actions: () -> A) -> some View { _Modified() }
    func confirmationDialog<S: StringProtocol, A: View>(_ title: S, isPresented: Binding<Bool>, titleVisibility: Visibility = .automatic, @ViewBuilder actions: () -> A) -> some View { _Modified() }
    func safeAreaInset<V: View>(edge: VerticalEdge, alignment: HorizontalAlignment = .center, spacing: CGFloat? = nil, @ViewBuilder content: () -> V) -> some View { _Modified() }
    func onTapGesture(count: Int = 1, perform action: @escaping () -> Void) -> some View { _Modified() }
    func onTapGesture(count: Int = 1, coordinateSpace: CoordinateSpace = .local, perform action: @escaping (CGPoint) -> Void) -> some View { _Modified() }
    func gesture<T: Gesture>(_ gesture: T) -> some View { _Modified() }
    func simultaneousGesture<T: Gesture>(_ gesture: T) -> some View { _Modified() }
    func environmentObject<T: ObservableObject>(_ object: T) -> some View { _Modified() }
}
