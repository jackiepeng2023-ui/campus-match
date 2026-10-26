import SwiftUI

struct CasesView: View {
    @EnvironmentObject var app: AppState
    @State private var items: [CaseSummary] = []
    @State private var query = ""
    @State private var type = ""
    @State private var scope = "all"

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("範圍", selection: $scope) { Text("全部").tag("all"); Text("我發起").tag("mine"); Text("我參與").tag("member") }.pickerStyle(.segmented)
                    Picker("類型", selection: $type) {
                        Text("所有類型").tag("")
                        ForEach(["PROJECT", "COMPETITION", "SHORT_TERM", "RESEARCH"], id: \.self) { Text(Labels.type[$0] ?? $0).tag($0) }
                    }
                }
                Section {
                    if items.isEmpty { Text("沒有符合的案件").foregroundStyle(.secondary) }
                    ForEach(items) { c in
                        NavigationLink(destination: CaseDetailView(caseId: c.id)) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack { Text(c.title).font(.headline); Spacer(); Pill(text: Labels.status[c.status] ?? c.status, color: statusColor(c.status)) }
                                Text("\(Labels.type[c.type] ?? c.type) · \(c.ownerName)（\(c.ownerCollege)） · 名額 \(c.filled)/\(c.headcount) · 截止 \(Fmt.day(c.applyDeadline))").font(.caption).foregroundStyle(.secondary)
                                if let s = c.skillNames { Text("需要：" + s).font(.caption).foregroundStyle(.secondary) }
                            }
                        }
                    }
                }
            }
            .navigationTitle("案件")
            .searchable(text: $query, prompt: "搜尋標題或描述")
            .onSubmit(of: .search) { Task { await load() } }
            .onChange(of: scope) { _, _ in Task { await load() } }
            .onChange(of: type) { _, _ in Task { await load() } }
            .refreshable { await load() }
            .task { await load() }
        }
    }

    func load() async {
        var q: [String] = []
        if !query.isEmpty, let e = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) { q.append("q=" + e) }
        if !type.isEmpty { q.append("type=" + type) }
        if scope == "mine" { q.append("mine=true") }
        if scope == "member" { q.append("member=true") }
        do { items = try await app.api.get("/cases" + (q.isEmpty ? "" : "?" + q.joined(separator: "&")), as: [CaseSummary].self) }
        catch { app.error = error.localizedDescription }
    }
}
