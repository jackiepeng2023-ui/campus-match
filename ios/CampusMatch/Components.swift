import SwiftUI

struct Pill: View {
    let text: String; var color: Color = .secondary
    var body: some View {
        Text(text).font(.caption.weight(.semibold)).padding(.horizontal, 9).padding(.vertical, 3)
            .background(color.opacity(0.14)).foregroundStyle(color).clipShape(Capsule())
    }
}

func statusColor(_ s: String) -> Color {
    switch s {
    case "OPEN": return .blue
    case "FORMED", "IN_PROGRESS", "ACCEPTED": return .green
    case "CLOSING", "PENDING": return .orange
    case "CLOSED": return .purple
    case "CANCELLED", "EXPIRED", "DECLINED", "FULL": return .red
    default: return .secondary
    }
}

/// 五個分項的長條（S T R P C）
struct BreakdownView: View {
    let breakdown: [String: Double]
    var body: some View {
        HStack(spacing: 8) {
            ForEach(["S", "T", "R", "P", "C"], id: \.self) { k in
                VStack(alignment: .leading, spacing: 3) {
                    Text(Labels.factor[k] ?? k).font(.caption2).foregroundStyle(.secondary)
                    Text(String(format: "%.2f", breakdown[k] ?? 0)).font(.caption.weight(.semibold)).monospacedDigit()
                    GeometryReader { g in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color(.systemFill))
                            Capsule().fill(Color.accentColor).frame(width: g.size.width * CGFloat(min(1, max(0, breakdown[k] ?? 0))))
                        }
                    }.frame(height: 5)
                }
            }
        }
    }
}

/// 推薦卡：分數、分項、理由（學生端與發案方端共用）
struct ScoreCard<Action: View>: View {
    let title: String; let subtitle: String; let score: Double; let breakdown: [String: Double]; let reasons: [String]; var blockedBy: [String] = []
    @ViewBuilder let action: () -> Action
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline)
                    Text(subtitle).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Text(Fmt.score(score)).font(.title2.weight(.bold)).monospacedDigit().foregroundStyle(blockedBy.isEmpty ? Color.primary : Color.secondary)
                action()
            }
            BreakdownView(breakdown: breakdown)
            ForEach(blockedBy, id: \.self) { b in Label(b, systemImage: "xmark.octagon").font(.caption).foregroundStyle(.red) }
            ForEach(reasons.prefix(4), id: \.self) { r in Text("• " + r).font(.caption).foregroundStyle(.secondary) }
        }
        .padding(14).background(Color(.secondarySystemGroupedBackground)).clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct StatTile: View {
    let title: String; let value: String
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.title3.weight(.bold)).monospacedDigit()
        }.frame(maxWidth: .infinity, alignment: .leading).padding(12).background(Color(.secondarySystemGroupedBackground)).clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct Stars: View {
    @Binding var value: Int
    var body: some View {
        HStack(spacing: 6) {
            ForEach(1...5, id: \.self) { n in
                Button(action: { value = n }) {
                    Text("\(n)").font(.subheadline.weight(.semibold)).frame(width: 36, height: 36)
                        .background(value >= n ? Color.accentColor : Color(.systemFill))
                        .foregroundStyle(value >= n ? Color.white : Color.primary).clipShape(RoundedRectangle(cornerRadius: 8))
                }.buttonStyle(.plain)
            }
        }
    }
}

/// 技能 chip：level 為三階（1 初階／2 中階／3 進階）；trust 有值時顯示可信狀態（已驗證／修課成績／自述）
struct SkillChip: View {
    let name: String; let level: Int; var required: Bool? = nil; var trust: String? = nil; var atLeast: Bool = false
    var body: some View {
        HStack(spacing: 4) {
            Text(name).font(.caption)
            Text(Labels.tierName(level) + (atLeast ? "以上" : "")).font(.caption.weight(.bold)).foregroundStyle(Color.accentColor)
            if let t = trust { TrustBadge(label: t) }
            if let r = required { Text(r ? "必要" : "加分").font(.caption2).foregroundStyle(r ? Color.red : Color.secondary) }
        }.padding(.horizontal, 8).padding(.vertical, 4).background(Color(.systemFill)).clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct TrustBadge: View {
    let label: String
    var color: Color { label == "已驗證" ? .green : label == "自述" ? .orange : .blue }
    var body: some View { Text(label).font(.caption2.weight(.semibold)).foregroundStyle(color).padding(.horizontal, 6).padding(.vertical, 2).background(color.opacity(0.12)).clipShape(Capsule()) }
}

/// 簡單的流式排版（技能 chips 用）
struct FlowLayout: Layout {
    var spacing: CGFloat = 6
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 320
        var x: CGFloat = 0, y: CGFloat = 0, rowH: CGFloat = 0
        for s in subviews {
            let sz = s.sizeThatFits(.unspecified)
            if x + sz.width > width && x > 0 { x = 0; y += rowH + spacing; rowH = 0 }
            x += sz.width + spacing; rowH = max(rowH, sz.height)
        }
        return CGSize(width: width, height: y + rowH)
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowH: CGFloat = 0
        for s in subviews {
            let sz = s.sizeThatFits(.unspecified)
            if x + sz.width > bounds.maxX && x > bounds.minX { x = bounds.minX; y += rowH + spacing; rowH = 0 }
            s.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(sz))
            x += sz.width + spacing; rowH = max(rowH, sz.height)
        }
    }
}
