import SwiftUI
import UIKit

struct GrowthView: View {
    @EnvironmentObject var app: AppState
    @State private var g: Growth?
    @State private var goal = ""
    @State private var question = ""
    @State private var prompt: PromptResponse?
    @State private var copied = false

    var body: some View {
        NavigationStack {
            List {
                if let g = g {
                    Section {
                        KnowledgeGraphView().listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    } header: { Text("知識圖譜") } footer: { Text("證據（科目、證照與作品、得獎、結案案件）→ 技能 → 分類；可匯出成 Obsidian Vault 用 Graph view 檢視。") }
                    Section("技能雷達（各類別平均分數，0–100）") {
                        RadarChart(labels: g.radar.map { $0.category }, values: g.radar.map { $0.avgScore }, maxValue: 100)
                            .frame(height: 260).frame(maxWidth: .infinity)
                    }
                    Section {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                StatTile(title: "隊友評價", value: Fmt.opt(g.stats.avgRating))
                                StatTile(title: "相符度", value: Fmt.opt(g.stats.avgMatch))
                                StatTile(title: "可信度係數", value: String(format: "%.1f", g.stats.credibility))
                                StatTile(title: "回應率", value: Fmt.pct(g.stats.responseRate))
                                StatTile(title: "完成案件", value: "\(g.stats.closedCases)")
                            }.frame(minWidth: 560)
                        }.listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    }
                    Section {
                        TextField("成長目標，例：畢業後成為前端工程師", text: $goal)
                        TextField("想問的問題，例：下學期該補什麼？", text: $question)
                        Button("產生 Prompt") { Task { await gen() } }
                        if let p = prompt {
                            Text(p.notice).font(.caption).foregroundStyle(.orange)
                            Text(p.prompt).font(.caption.monospaced()).textSelection(.enabled)
                            Button(copied ? "已複製，貼到你選擇的 AI 即可" : "複製到剪貼簿") { UIPasteboard.general.string = p.prompt; copied = true }
                        }
                    } header: { Text("AI 成長建議") } footer: { Text("這裡不呼叫外部 AI：由系統從你的資料組出 Prompt（不含隊友姓名、評語原文與案件名稱），預覽後貼到你自己選的 AI。想讓平台直接規劃競賽與組隊，請用「AI 助理」分頁。") }
                    Section("成長時間軸") {
                        if g.timeline.isEmpty { Text("還沒有紀錄").foregroundStyle(.secondary) }
                        ForEach(g.timeline) { t in
                            HStack(alignment: .top, spacing: 10) {
                                Text(Fmt.time(t.ts)).font(.caption).foregroundStyle(.secondary).frame(width: 76, alignment: .leading)
                                Pill(text: kindLabel(t.kind), color: kindColor(t.kind))
                                Text(t.text).font(.subheadline)
                            }
                        }
                    }
                } else { ProgressView() }
            }
            .navigationTitle("成長")
            .refreshable { await load() }
            .task { await load() }
        }
    }

    func kindLabel(_ k: String) -> String { ["SKILL": "技能", "CASE_JOINED": "加入", "CASE_OWNED": "發起", "CASE_CLOSED": "結案", "AWARD": "得獎", "REVIEW": "評價"][k] ?? k }
    func kindColor(_ k: String) -> Color { ["SKILL": Color.blue, "CASE_CLOSED": .purple, "AWARD": .orange, "REVIEW": .green][k] ?? .secondary }
    func load() async { do { g = try await app.api.get("/me/growth", as: Growth.self) } catch { app.error = error.localizedDescription } }
    func gen() async {
        copied = false
        _ = await app.run { prompt = try await app.api.post("/me/growth-prompt", PromptBody(goal: goal, question: question), as: PromptResponse.self) }
    }
}

/// 雷達圖：以 Canvas 畫格線與多邊形
struct RadarChart: View {
    let labels: [String]; let values: [Double]; let maxValue: Double
    var body: some View {
        GeometryReader { geo in
            let n = max(labels.count, 3)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = min(geo.size.width, geo.size.height) / 2 - 28
            ZStack {
                Canvas { ctx, _ in
                    for ring in 1...5 {
                        var path = Path()
                        for i in 0..<n {
                            let pt = point(center, radius * CGFloat(ring) / 5, i, n)
                            if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
                        }
                        path.closeSubpath()
                        ctx.stroke(path, with: .color(Color(.systemGray4)), lineWidth: 0.8)
                    }
                    for i in 0..<n {
                        var axis = Path(); axis.move(to: center); axis.addLine(to: point(center, radius, i, n))
                        ctx.stroke(axis, with: .color(Color(.systemGray4)), lineWidth: 0.8)
                    }
                    var poly = Path()
                    for i in 0..<n {
                        let v = i < values.count ? values[i] : 0
                        let pt = point(center, radius * CGFloat(v / maxValue), i, n)
                        if i == 0 { poly.move(to: pt) } else { poly.addLine(to: pt) }
                    }
                    poly.closeSubpath()
                    ctx.fill(poly, with: .color(Color.accentColor.opacity(0.18)))
                    ctx.stroke(poly, with: .color(Color.accentColor), lineWidth: 2)
                }
                ForEach(0..<n, id: \.self) { i in
                    let pt = point(center, radius + 18, i, n)
                    Text(i < labels.count ? labels[i] : "").font(.caption).position(pt)
                }
            }
        }
    }
    func point(_ c: CGPoint, _ r: CGFloat, _ i: Int, _ n: Int) -> CGPoint {
        let angle = -Double.pi / 2 + Double(i) * 2 * Double.pi / Double(n)
        return CGPoint(x: c.x + r * CGFloat(cos(angle)), y: c.y + r * CGFloat(sin(angle)))
    }
}
