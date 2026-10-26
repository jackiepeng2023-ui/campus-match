import SwiftUI

struct ReviewView: View {
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) var dismiss
    let caseId: Int
    @State private var p: PendingReviews?
    @State private var scores: [Int: [Int]] = [:]       // revieweeId → [滿意, 相符, 準時, 溝通]
    @State private var attribution: [Int: String] = [:]
    @State private var comments: [Int: String] = [:]

    var todo: [PendingReviews.Item] { (p?.items ?? []).filter { $0.submittedAt == nil && !$0.missed } }

    var body: some View {
        Form {
            if let p = p {
                Section { Text("四題各 1–5 分。「能力與檔案相符」會影響對方自填資料在推薦中的權重。評價匿名，雙方都送出才同時公開。").font(.caption).foregroundStyle(.secondary) }
                if todo.isEmpty { Text("你在本案的互評都已送出").foregroundStyle(.secondary) }
                ForEach(todo) { it in
                    Section(it.name + (it.isOwner ? "（發案方）" : "") + " · " + it.department) {
                        row("整體合作滿意度", it.revieweeId, 0)
                        row("實際能力與檔案相符嗎", it.revieweeId, 1)
                        row("是否準時完成分內工作", it.revieweeId, 2)
                        row("溝通與回應是否及時", it.revieweeId, 3)
                        if p.askAttribution && it.isOwner {
                            Picker("承諾的成果歸屬是否兌現", selection: Binding(get: { attribution[it.revieweeId] ?? "YES" }, set: { attribution[it.revieweeId] = $0 })) {
                                Text("是").tag("YES"); Text("部分").tag("PARTIAL"); Text("否").tag("NO")
                            }
                        }
                        TextField("評語（選填，只有對方看得到）", text: Binding(get: { comments[it.revieweeId] ?? "" }, set: { comments[it.revieweeId] = $0 }))
                    }
                }
                if !todo.isEmpty { Section { Button("送出評價") { Task { await submit() } }.frame(maxWidth: .infinity) } }
            } else { ProgressView() }
        }
        .navigationTitle("互評")
        .task { p = try? await app.api.get("/cases/\(caseId)/reviews/pending", as: PendingReviews.self) }
    }

    @ViewBuilder
    func row(_ title: String, _ uid: Int, _ idx: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.subheadline)
            Stars(value: Binding(get: { scores[uid]?[idx] ?? 0 }, set: { v in var a = scores[uid] ?? [0, 0, 0, 0]; a[idx] = v; scores[uid] = a }))
        }
    }

    func submit() async {
        guard let p = p else { return }
        var body: [ReviewSubmission] = []
        for it in todo {
            let a = scores[it.revieweeId] ?? [0, 0, 0, 0]
            if a.contains(0) { app.error = "請為 \(it.name) 的四題都評分"; return }
            body.append(ReviewSubmission(revieweeId: it.revieweeId, satisfaction: a[0], matchScore: a[1], onTime: a[2], communication: a[3],
                                         attributionKept: (p.askAttribution && it.isOwner) ? (attribution[it.revieweeId] ?? "YES") : nil,
                                         comment: (comments[it.revieweeId] ?? "").isEmpty ? nil : comments[it.revieweeId]))
        }
        if await app.run({ _ = try await app.api.post("/cases/\(caseId)/reviews", body, as: PendingReviews.self) }) { dismiss() }
    }
}
