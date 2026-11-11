import SwiftUI

/// AI 助理入口：說出目標 → 助理依序呼叫能力盤點模組與三個媒合 Agent（每一步都看得到）→ 要改資料時只準備草稿，由使用者按確認。
/// 助理在後端背景執行；這裡每 0.7 秒取一次進度，執行軌跡與卡片會逐步出現。
struct AssistantView: View {
    @EnvironmentObject var app: AppState
    @State private var status: AssistantStatus?
    @State private var sessionId: Int?
    @State private var messages: [AssistantMessage] = []
    @State private var text = ""
    @State private var busy = false
    private let starters = ["我想參加比賽，幫我規劃", "我的技能強弱項是什麼？", "幫我找互補的隊友", "誰可以指導？"]

    private var canSend: Bool { !busy && !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    private var stepCount: Int { messages.last?.stepList.count ?? 0 }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        if let st = status { StatusLine(status: st) }
                        if messages.isEmpty { intro }
                        ForEach(messages) { m in
                            if m.role == "user" { UserBubble(text: m.content) }
                            else { AssistantBubble(message: m, busy: busy, onChanged: { Task { await reload() } }, ask: { q in Task { await send(q) } }) }
                        }
                        Color.clear.frame(height: 1).id("bottom")
                    }.padding(16)
                }
                .onChange(of: stepCount) { _, _ in withAnimation { proxy.scrollTo("bottom", anchor: .bottom) } }
                .onChange(of: messages.count) { _, _ in withAnimation { proxy.scrollTo("bottom", anchor: .bottom) } }
            }
            .safeAreaInset(edge: .bottom) { inputBar }
            .navigationTitle("AI 助理")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("新對話") { sessionId = nil; messages = [] }.disabled(busy) } }
            .task { await loadStatus() }
        }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("說出你的目標，我來拆步驟").font(.title3.weight(.semibold))
            Text("我會依序呼叫能力盤點模組與競賽、學生、教師三個 Agent；要建立案件或邀請隊友時只會準備草稿，由你確認。").font(.subheadline).foregroundStyle(Color.secondary)
            ForEach(starters, id: \.self) { q in Button(q) { Task { await send(q) } }.buttonStyle(.bordered).controlSize(.small) }
        }
    }

    private var inputBar: some View {
        HStack {
            TextField("例如：我想參加比賽，幫我規劃", text: $text, axis: .vertical).lineLimit(1...3).textFieldStyle(.roundedBorder).disabled(busy)
            Button { Task { await send(text) } } label: { Image(systemName: busy ? "hourglass" : "arrow.up.circle.fill").font(.title2) }.disabled(!canSend)
        }.padding(.horizontal, 16).padding(.vertical, 8).background(.bar)
    }

    private func loadStatus() async { status = try? await app.api.get("/assistant/status", as: AssistantStatus.self) }

    private func send(_ raw: String) async {
        let q = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if q.isEmpty || busy { return }
        busy = true; text = ""
        var posted: AssistantPosted?
        let ok = await app.run { posted = try await app.api.post("/assistant/messages", MessageBody(sessionId: sessionId, text: q), as: AssistantPosted.self) }
        guard ok, let p = posted else { busy = false; return }
        sessionId = p.sessionId
        messages.append(AssistantMessage(id: p.userMessageId, role: "user", content: q, mode: nil, status: "DONE", notice: nil, stop: nil, durationMs: nil, toolCalls: nil, llmCalls: nil, steps: nil, cards: nil, checks: nil))
        messages.append(AssistantMessage(id: p.assistantMessageId, role: "assistant", content: "", mode: nil, status: "RUNNING", notice: nil, stop: nil, durationMs: nil, toolCalls: nil, llmCalls: nil, steps: [], cards: [], checks: nil))
        var failures = 0
        for _ in 0..<400 {                                   // 最多約 4.7 分鐘；後端自己有步數與逾時上限
            try? await Task.sleep(nanoseconds: 700_000_000)
            do {
                let m = try await app.api.get("/assistant/messages/\(p.assistantMessageId)", as: AssistantMessage.self)
                failures = 0
                if let i = messages.firstIndex(where: { $0.id == m.id }) { messages[i] = m }
                if !m.running { break }
            } catch {
                failures += 1
                if failures >= 5 { app.error = error.localizedDescription; break }
            }
        }
        busy = false
        await loadStatus()
    }

    private func reload() async {
        guard let sid = sessionId else { return }
        _ = await app.run { messages = try await app.api.get("/assistant/sessions/\(sid)", as: AssistantSession.self).messages }
    }
}

private struct StatusLine: View {
    let status: AssistantStatus
    var body: some View {
        HStack(spacing: 6) {
            Pill(text: status.label, color: status.isLLM ? Color.purple : Color.gray)
            Text(status.detail).font(.caption).foregroundStyle(Color.secondary)
        }
    }
}

private struct UserBubble: View {
    let text: String
    var body: some View {
        HStack {
            Spacer(minLength: 40)
            Text(text).padding(.horizontal, 12).padding(.vertical, 8).background(Color.accentColor).foregroundStyle(Color.white).clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}

/// 一則助理回覆：模式、執行軌跡、文字、卡片、待確認動作
struct AssistantBubble: View {
    let message: AssistantMessage
    let busy: Bool
    let onChanged: () -> Void
    let ask: (String) -> Void
    @State private var showSteps = true

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            if let n = message.notice { Text(n).font(.caption).foregroundStyle(Color.orange) }
            if message.running || !message.stepList.isEmpty { trace }
            if !message.content.isEmpty { Text(message.content).font(.subheadline).textSelection(.enabled) }
            ForEach(Array(message.cardList.enumerated()), id: \.offset) { _, card in
                AssistantCard(card: card, busy: busy, onChanged: onChanged, ask: ask)
            }
        }
        .padding(12).background(Color(.secondarySystemBackground)).clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var header: some View {
        HStack(spacing: 6) {
            Pill(text: message.modeLabel, color: message.isLLM ? Color.purple : Color.gray)
            if let c = message.checks, !message.running { Text(c.text).font(.caption2).foregroundStyle(c.ok ? Color.green : Color.red) }
            Spacer()
            if let t = message.meterText { Text(t).font(.caption2).foregroundStyle(Color.secondary) }
        }
    }

    private var trace: some View {
        DisclosureGroup(isExpanded: $showSteps) {
            ForEach(message.stepList) { s in StepRow(step: s) }
            if message.running {
                HStack(spacing: 6) { ProgressView().controlSize(.mini); Text(message.progressText).font(.caption).foregroundStyle(Color.secondary) }
            }
        } label: { Text("執行軌跡（\(message.stepList.count) 步）").font(.caption.weight(.semibold)) }
    }
}

private struct StepRow: View {
    let step: AssistantStep
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Image(systemName: step.ok ? "checkmark.circle.fill" : "xmark.circle.fill").foregroundStyle(step.ok ? Color.green : Color.red).font(.caption)
            VStack(alignment: .leading, spacing: 1) {
                Text(step.title).font(.caption.weight(.semibold))
                Text(step.summary).font(.caption).foregroundStyle(Color.secondary)
            }
            Spacer()
            Text("\(step.durationMs) ms").font(.caption2).foregroundStyle(Color.secondary)
        }
    }
}

/// 卡片由伺服器直接組成（不經過語言模型），名單與數字不會被改寫；這裡依 type 轉成具名型別後顯示重點
struct AssistantCard: View {
    let card: JSONValue
    let busy: Bool
    let onChanged: () -> Void
    let ask: (String) -> Void

    var body: some View {
        content.frame(maxWidth: .infinity, alignment: .leading).padding(10).background(Color(.systemBackground)).clipShape(RoundedRectangle(cornerRadius: 10))
    }

    @ViewBuilder private var content: some View {
        switch card["type"].str ?? "" {
        case "profile": if let p = card.decode(ProfileCard.self) { ProfileCardView(card: p) }
        case "competitions": if let r = card.decode(CompetitionRecommendation.self) { CompetitionsCardView(result: r, busy: busy, ask: ask) }
        case "competition": if let c = card.decode(Competition.self) { CompetitionCardView(c: c) }
        case "competition_list": if let l = card.decode(CompetitionListCard.self) { CompetitionListCardView(list: l) }
        case "teammates": if let t = card.decode(TeammatesResult.self) { TeammatesCardView(result: t) }
        case "teachers": if let t = card.decode(TeachersResult.self) { TeachersCardView(result: t) }
        case "action": if let a = card.decode(ActionCard.self) { ActionCardView(actionId: a.actionId, title: a.title, status: a.status, payload: a.payload, result: a.result, onChanged: onChanged) }
        default: EmptyView()
        }
    }
}

private struct CardTitle: View {
    let text: String
    var body: some View { Text(text).font(.caption.weight(.semibold)) }
}

private struct ProfileCardView: View {
    let card: ProfileCard
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            CardTitle(text: card.title)
            FlowLayout { ForEach(Array(card.top.enumerated()), id: \.offset) { _, s in TierChip(name: s.name, tier: s.tier, trust: s.trustLabel) } }
        }
    }
}

private struct CompetitionsCardView: View {
    let result: CompetitionRecommendation
    let busy: Bool
    let ask: (String) -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            CardTitle(text: "競賽 Agent：可報名 \(result.totalEligible) 筆")
            if result.recommended.isEmpty { Text("目前沒有符合資格、與你的技能相關且還能報名的競賽。").font(.caption).foregroundStyle(Color.secondary) }
            ForEach(result.recommended.prefix(3)) { c in
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        NavigationLink(destination: CompetitionDetailView(id: c.id)) { Text(c.shortName).font(.subheadline.weight(.semibold)) }
                        Spacer()
                        Text(c.fitText).font(.subheadline.weight(.bold)).foregroundStyle(Color.accentColor)
                    }
                    Text(c.deadlineText + "・" + c.coreText).font(.caption).foregroundStyle(Color.secondary)
                    if let g = c.gapText { Text(g).font(.caption).foregroundStyle(Color.red) }
                    Button("找這個競賽的隊友") { ask("幫我找「\(c.shortName)」的隊友") }.font(.caption).buttonStyle(.bordered).controlSize(.mini).disabled(busy)
                }.padding(.vertical, 2)
            }
        }
    }
}

private struct CompetitionCardView: View {
    let c: Competition
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                NavigationLink(destination: CompetitionDetailView(id: c.id)) { Text(c.shortName).font(.subheadline.weight(.semibold)) }
                Spacer()
                Text(c.fitText).font(.subheadline.weight(.bold)).foregroundStyle(Color.accentColor)
            }
            Text(c.deadlineText + "・" + c.coreText).font(.caption).foregroundStyle(Color.secondary)
            if let s = c.strengthText { Text(s).font(.caption) }
            if let w = c.weaknessText { Text(w).font(.caption).foregroundStyle(Color.orange) }
            if let g = c.gapText { Text(g).font(.caption).foregroundStyle(Color.red) }
            ForEach(c.blockedBy ?? [], id: \.self) { b in Text(b).font(.caption).foregroundStyle(Color.red) }
        }
    }
}

private struct CompetitionListCardView: View {
    let list: CompetitionListCard
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            CardTitle(text: "競賽搜尋：\(list.items.count) 筆")
            ForEach(list.items) { c in
                NavigationLink(destination: CompetitionDetailView(id: c.id)) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(c.shortName).font(.subheadline.weight(.semibold))
                        Text(c.metaLine).font(.caption).foregroundStyle(Color.secondary)
                    }
                }
            }
        }
    }
}

private struct TeammatesCardView: View {
    let result: TeammatesResult
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            CardTitle(text: "學生 Agent：團隊缺口 \(result.gaps.count) 項")
            if let g = result.gapText { Text(g).font(.caption).foregroundStyle(Color.red) }
            if let s = result.suggestionText { Text(s).font(.caption) }
            ForEach(result.candidates.prefix(3)) { c in
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 1) {
                        NavigationLink(destination: PublicProfileView(userId: c.userId)) { Text(c.headline).font(.caption.weight(.semibold)) }
                        Text(c.why).font(.caption2).foregroundStyle(Color.secondary)
                    }
                    Spacer()
                    Text(Fmt.score(c.score)).font(.caption.weight(.semibold))
                }
            }
        }
    }
}

private struct TeachersCardView: View {
    let result: TeachersResult
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            CardTitle(text: "教師 Agent：專長相符 \(result.totalMatched) 位")
            ForEach(result.teachers.prefix(3)) { t in
                VStack(alignment: .leading, spacing: 1) {
                    HStack { Text(t.headline).font(.caption.weight(.semibold)); Spacer(); Text(Fmt.score(t.fit)).font(.caption.weight(.bold)).foregroundStyle(Color.accentColor) }
                    Text(t.why).font(.caption2).foregroundStyle(Color.secondary)
                    if let c = t.confirmText { Text(c).font(.caption2).foregroundStyle(Color.orange) }
                }
            }
            Text("教師資料來自系所公開網頁；平台不會替你聯絡老師，請自行聯絡並確認。").font(.caption2).foregroundStyle(Color.secondary)
        }
    }
}

/// 待確認動作：按下確認才會建立並發布案件、送出邀請（對話與競賽頁共用）
struct ActionCardView: View {
    @EnvironmentObject var app: AppState
    let actionId: Int
    let title: String
    let status: String
    let payload: ActionPayload
    let result: ActionResult?
    let onChanged: () -> Void
    @State private var acting = false

    private var statusColor: Color { status == "PENDING" ? Color.orange : (status == "DONE" ? Color.green : Color.secondary) }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(ActionStatus.label(status)).font(.caption2.weight(.bold)).foregroundStyle(statusColor)
            Text(title).font(.subheadline.weight(.semibold))
            Text(payload.summary).font(.caption).foregroundStyle(Color.secondary)
            ForEach(Array(payload.roles.enumerated()), id: \.offset) { _, r in Text(r.text).font(.caption) }
            if let a = payload.advisorText { Text(a).font(.caption) }
            if status == "PENDING" { pending } else { outcome }
        }
    }

    private var pending: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("按下確認後才會建立並發布案件、送出邀請；不確認就不會有任何變動。").font(.caption2).foregroundStyle(Color.orange)
            HStack {
                Button("確認") { Task { await decide("confirm") } }.buttonStyle(.borderedProminent).controlSize(.small)
                Button("取消") { Task { await decide("cancel") } }.buttonStyle(.bordered).controlSize(.small)
            }.disabled(acting)
        }
    }

    @ViewBuilder private var outcome: some View {
        if let r = result {
            if let cid = r.caseId { NavigationLink("查看案件", destination: CaseDetailView(caseId: cid)).font(.caption) }
            if let t = r.invitedText { Text(t).font(.caption).foregroundStyle(Color.secondary) }
            if let t = r.failedText { Text(t).font(.caption).foregroundStyle(Color.orange) }
            if let e = r.error { Text(e).font(.caption).foregroundStyle(Color.red) }
        }
    }

    private func decide(_ what: String) async {
        acting = true
        let ok = await app.run { _ = try await app.api.post("/assistant/actions/\(actionId)/\(what)", as: AssistantAction.self) }
        acting = false
        if ok { onChanged() }
    }
}

/// 技能 chip（階級以文字表示）：能力盤點卡片用
struct TierChip: View {
    let name: String
    let tier: String
    let trust: String?
    var body: some View {
        HStack(spacing: 4) {
            Text(name).font(.caption)
            Text(tier).font(.caption.weight(.bold)).foregroundStyle(Color.accentColor)
            if let t = trust { TrustBadge(label: t) }
        }.padding(.horizontal, 8).padding(.vertical, 4).background(Color(.systemFill)).clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
