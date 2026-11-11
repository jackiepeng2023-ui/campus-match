import SwiftUI

// 知識圖譜：資料型別 GraphData／GraphNode／GraphEdge 定義在 Models.swift

/// 力導向佈局（純 Swift，節點數 < 200 時每次 tick 約 1 ms）
final class GraphLayout: ObservableObject {
    struct P { var x: CGFloat; var y: CGFloat; var vx: CGFloat = 0; var vy: CGFloat = 0; var fixed = false }
    @Published var pos: [String: P] = [:]
    var nodes: [GraphNode] = []
    var edges: [(String, String, CGFloat)] = []
    private var typeOf: [String: String] = [:]

    func load(_ g: GraphData) {
        nodes = g.nodes; typeOf = Dictionary(uniqueKeysWithValues: g.nodes.map { ($0.id, $0.type) })
        let len: [String: CGFloat] = ["GRADE": 48, "CATEGORY": 78, "AWARD": 58, "CASE": 58]
        edges = g.edges.map { ($0.source, $0.target, len[$0.kind] ?? 60) }
        pos = [:]
        for (i, n) in g.nodes.enumerated() { let a = CGFloat(i) * 2.39996, r = 30 + sqrt(CGFloat(i)) * 22; pos[n.id] = P(x: cos(a) * r, y: sin(a) * r) }
        for i in 0..<260 { tick(alpha: 1 - CGFloat(i) / 280) }
    }

    func tick(alpha a: CGFloat, hidden: Set<String> = []) {
        var p = pos
        let ids = nodes.map(\.id).filter { !hidden.contains(typeOf[$0] ?? "") }
        for i in 0..<ids.count { for j in (i + 1)..<ids.count {
            guard var A = p[ids[i]], var B = p[ids[j]] else { continue }
            var dx = B.x - A.x, dy = B.y - A.y; var d2 = dx * dx + dy * dy
            if d2 < 1 { dx = CGFloat.random(in: -0.5...0.5); dy = CGFloat.random(in: -0.5...0.5); d2 = 1 }
            let f = 700 * a / d2, fx = dx * f, fy = dy * f
            if !A.fixed { A.vx -= fx; A.vy -= fy }; if !B.fixed { B.vx += fx; B.vy += fy }
            p[ids[i]] = A; p[ids[j]] = B
        } }
        for (s, t, L) in edges {
            guard var A = p[s], var B = p[t], !hidden.contains(typeOf[s] ?? ""), !hidden.contains(typeOf[t] ?? "") else { continue }
            let dx = B.x - A.x, dy = B.y - A.y, d = max(sqrt(dx * dx + dy * dy), 1), f = (d - L) * 0.09 * a
            let fx = dx / d * f, fy = dy / d * f
            if !A.fixed { A.vx += fx; A.vy += fy }; if !B.fixed { B.vx -= fx; B.vy -= fy }
            p[s] = A; p[t] = B
        }
        for id in ids {
            guard var n = p[id], !n.fixed else { continue }
            let g: CGFloat = typeOf[id] == "CATEGORY" ? 0.09 : 0.045
            n.vx -= n.x * g * a; n.vy -= n.y * g * a; n.vx *= 0.8; n.vy *= 0.8; n.x += n.vx; n.y += n.vy
            p[id] = n
        }
        pos = p
    }
}

struct KnowledgeGraphView: View {
    @EnvironmentObject var app: AppState
    @StateObject private var layout = GraphLayout()
    @State private var graph: GraphData?
    @State private var hidden: Set<String> = []
    @State private var selected: GraphNode?
    @State private var dragging: String?
    @State private var scale: CGFloat = 1
    @State private var exportURL: URL?
    @State private var exporting = false
    private let types: [(String, String, Color)] = [("COURSE", "科目", .blue), ("SKILL", "技能", .green), ("CATEGORY", "分類", .indigo), ("CREDENTIAL", "證照與作品", .teal), ("AWARD", "得獎", .orange), ("CASE", "案件", .gray)]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(types, id: \.0) { t in
                        let n = graph?.summary[t.0] ?? 0
                        Button { if hidden.contains(t.0) { hidden.remove(t.0) } else { hidden.insert(t.0) }; if let s = selected, hidden.contains(s.type) { selected = nil }; relax() } label: {
                            HStack(spacing: 4) { Circle().fill(t.2).frame(width: 8, height: 8); Text("\(t.1) \(n)").font(.caption) }
                                .padding(.horizontal, 8).padding(.vertical, 4).background(Color(.secondarySystemBackground)).clipShape(Capsule())
                                .opacity(hidden.contains(t.0) ? 0.4 : 1)
                        }.buttonStyle(.plain)
                    }
                }
            }
            GeometryReader { geo in
                let size = geo.size
                ZStack {
                    RoundedRectangle(cornerRadius: 14).fill(Color(red: 0.11, green: 0.11, blue: 0.12))
                    Canvas { ctx, sz in
                        let k = fitScale(size: sz) * scale, cx = sz.width / 2, cy = sz.height / 2
                        let nb = selected.map { neighborIds(of: $0.id) }
                        let pt: (String) -> CGPoint? = { id in layout.pos[id].map { CGPoint(x: cx + $0.x * k, y: cy + $0.y * k) } }   // 用閉包而不是區域函式：閉包沿用主執行緒隔離
                        for (s, t, _) in layout.edges {
                            guard let a = pt(s), let b = pt(t), !hidden.contains(typeOf(s)), !hidden.contains(typeOf(t)) else { continue }
                            let lit = nb == nil || (s == selected?.id || t == selected?.id)
                            var path = Path(); path.move(to: a); path.addLine(to: b)
                            ctx.stroke(path, with: .color(.white.opacity(lit ? (nb == nil ? 0.16 : 0.55) : 0.05)), lineWidth: lit && nb != nil ? 1.6 : 1)
                        }
                        for n in layout.nodes where !hidden.contains(n.type) {
                            guard let c = pt(n.id) else { continue }
                            let dim = nb != nil && !(nb!.contains(n.id) || n.id == selected?.id), r = radius(n)
                            let rect = CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r)
                            ctx.fill(Path(ellipseIn: rect), with: .color(color(n.type).opacity(dim ? 0.18 : 1)))
                            if n.id == selected?.id { ctx.stroke(Path(ellipseIn: rect), with: .color(.white), lineWidth: 2) }
                            let show = n.type == "CATEGORY" || n.type == "SKILL" || layout.nodes.count <= 60 || (nb?.contains(n.id) ?? false)
                            if show && !dim {
                                let label = n.label.count > 12 ? String(n.label.prefix(11)) + "…" : n.label
                                ctx.draw(Text(label).font(n.type == "CATEGORY" ? .caption.bold() : .caption2).foregroundColor(.white.opacity(n.type == "CATEGORY" ? 1 : 0.85)), at: CGPoint(x: c.x, y: c.y + r + 8))
                            }
                        }
                    }
                    .onTapGesture { p in                                   // 點一下聚焦；再點一次或點空白取消
                        let k = fitScale(size: size) * scale
                        if let id = hitTest(p, size: size, k: k) { selected = selected?.id == id ? nil : layout.nodes.first { $0.id == id } } else { selected = nil }
                    }
                    .gesture(DragGesture(minimumDistance: 12)              // 拖曳節點（垂直滑動仍交給清單捲動）
                        .onChanged { v in
                            let k = fitScale(size: size) * scale
                            if dragging == nil { dragging = hitTest(v.startLocation, size: size, k: k) ?? "" }
                            if let id = dragging, !id.isEmpty, var p = layout.pos[id] {
                                p.x = (v.location.x - size.width / 2) / k; p.y = (v.location.y - size.height / 2) / k; p.fixed = true; layout.pos[id] = p
                                layout.tick(alpha: 0.25, hidden: hidden)
                            }
                        }
                        .onEnded { _ in
                            if let id = dragging, !id.isEmpty, var p = layout.pos[id] { p.fixed = false; layout.pos[id] = p }
                            dragging = nil
                        })
                    .simultaneousGesture(MagnificationGesture().onChanged { scale = max(0.5, min(3, $0)) })
                    if graph != nil && layout.nodes.isEmpty {
                        Text("還沒有資料：先到「我的檔案」從科目清單填分數，技能等級與圖譜會自動生成。").font(.footnote).foregroundStyle(.white.opacity(0.7)).multilineTextAlignment(.center).padding()
                    }
                    if let s = selected {
                        VStack { Spacer()
                            VStack(alignment: .leading, spacing: 4) {
                                HStack { Text(typeLabel(s.type)).font(.caption.bold()).foregroundStyle(color(s.type)); Spacer(); Button { selected = nil } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary) } }
                                Text(s.label).font(.subheadline.bold())
                                Text(detail(s)).font(.caption).foregroundStyle(.secondary)
                                let names = neighborIds(of: s.id).compactMap { id in layout.nodes.first { $0.id == id }?.label }
                                if !names.isEmpty { Text("相連：" + names.joined(separator: "、")).font(.caption2).foregroundStyle(.secondary).lineLimit(2) }
                            }
                            .padding(10).background(.regularMaterial).clipShape(RoundedRectangle(cornerRadius: 10)).padding(8)
                        }
                    }
                }
            }
            .frame(height: 360)
            HStack {
                Button("重新排列") { if let g = graph { layout.load(g) }; scale = 1 }.buttonStyle(.bordered).controlSize(.small)
                Spacer()
                if let url = exportURL { ShareLink(item: url) { Label("分享 Vault", systemImage: "square.and.arrow.up") }.buttonStyle(.borderedProminent).controlSize(.small) }
                Button(exporting ? "匯出中…" : "匯出 Obsidian Vault") { Task { await export() } }.buttonStyle(.bordered).controlSize(.small).disabled(exporting)
            }
            Text("點一下聚焦、拖曳節點、兩指縮放。匯出的 zip 解壓後在 Obsidian 選「Open folder as vault」，Graph view 即為同一張圖（顏色已預設）。").font(.caption2).foregroundStyle(.secondary)
        }
        .task { await load() }
    }

    private func load() async {
        do { let g = try await app.api.get("/me/growth/graph", as: GraphData.self); graph = g; layout.load(g) }
        catch { app.error = error.localizedDescription }
    }
    private func relax() { for _ in 0..<40 { layout.tick(alpha: 0.4, hidden: hidden) } }
    private func typeOf(_ id: String) -> String { layout.nodes.first { $0.id == id }?.type ?? "" }
    private func color(_ t: String) -> Color { types.first { $0.0 == t }?.2 ?? .gray }
    private func typeLabel(_ t: String) -> String { types.first { $0.0 == t }?.1 ?? t }
    private func radius(_ n: GraphNode) -> CGFloat {
        switch n.type { case "CATEGORY": return 12; case "SKILL": return 5 + CGFloat(n.num("level") ?? 0) * 2.0; case "COURSE": return 3.5 + CGFloat(n.num("score") ?? 60) / 28; default: return 6.5 }
    }
    private func neighborIds(of id: String) -> Set<String> { Set(layout.edges.compactMap { $0.0 == id ? $0.1 : ($0.1 == id ? $0.0 : nil) }) }
    private func fitScale(size: CGSize) -> CGFloat {
        let ps = layout.nodes.filter { !hidden.contains($0.type) }.compactMap { layout.pos[$0.id] }
        guard let minX = ps.map(\.x).min(), let maxX = ps.map(\.x).max(), let minY = ps.map(\.y).min(), let maxY = ps.map(\.y).max() else { return 1 }
        return 0.85 * min(1.6, max(0.25, min(size.width / max(maxX - minX + 80, 1), size.height / max(maxY - minY + 60, 1))))
    }
    private func hitTest(_ p: CGPoint, size: CGSize, k: CGFloat) -> String? {
        var best: String? = nil, bd: CGFloat = 1e9
        for n in layout.nodes where !hidden.contains(n.type) {
            guard let q = layout.pos[n.id] else { continue }
            let c = CGPoint(x: size.width / 2 + q.x * k, y: size.height / 2 + q.y * k), d = hypot(c.x - p.x, c.y - p.y) - radius(n)
            if d < 14 && d < bd { bd = d; best = n.id }
        }
        return best
    }
    private func detail(_ n: GraphNode) -> String {
        switch n.type {
        case "COURSE": return "分數 \(n.str("score") ?? "—")　學期 \(n.str("semester") ?? "—")　\(Labels.requirement[n.str("requirement") ?? ""] ?? "")" + (n.str("department").map { "　" + $0 } ?? "")
        case "SKILL": return "\(n.str("tier") ?? "—")（\(n.str("score") ?? "—") 分・\(n.str("trustLabel") ?? "")）　最高分證據：\(n.str("source") ?? "—")，共 \(n.str("evidenceCount") ?? "0") 筆（不疊加）　分類 \(n.str("category") ?? "")"
        case "CATEGORY": return "平均 \(n.str("avgScore") ?? "—") 分　\(n.str("n") ?? "0") 項技能"
        case "CREDENTIAL": return "\(n.str("kind") ?? "")　\(n.str("tier") ?? "")（\(n.str("verified") == "true" ? "已驗證" : "自述，尚未驗證")）　\(n.str("issuer") ?? "") \(n.str("date") ?? "")"
        case "AWARD": return "\(Labels.level[n.str("level") ?? ""] ?? "")・\(Labels.rank[n.str("rank") ?? ""] ?? "")　\(n.str("date") ?? "")　得獎分 +\(n.str("score") ?? "")"
        default: return "角色 \(n.str("role") ?? "—")　\(n.str("result") == "COMPLETED" ? "完成" : "未完成")　結案 \(String((n.str("closedAt") ?? "").prefix(10)))"
        }
    }
    private func export() async {
        exporting = true; defer { exporting = false }
        do {
            let data = try await app.api.raw("GET", "/me/growth/obsidian")
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("成長儀表板-\(app.me?.name ?? "me").zip")
            try data.write(to: url, options: .atomic); exportURL = url
        } catch { app.error = error.localizedDescription }
    }
}
