import SwiftUI

struct LoginView: View {
    @EnvironmentObject var app: AppState
    @State private var account = "student002@example.edu"
    @State private var password = "demo1234"
    @State private var busy = false
    @State private var showSettings = false
    @State private var apiBase = APIClient.shared.baseURL

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                Spacer(minLength: 30)
                Image(systemName: "person.3.sequence.fill").font(.system(size: 54)).foregroundStyle(Color.accentColor)
                Text("跨系資源媒合平台").font(.title.weight(.bold))
                Text("把分散的人才與合作需求，變成校園內可流動的資源").font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
                VStack(spacing: 12) {
                    TextField("Email 或學號", text: $account).textInputAutocapitalization(.never).keyboardType(.emailAddress).autocorrectionDisabled()
                    SecureField("密碼", text: $password)
                }
                .textFieldStyle(.roundedBorder)
                Button(action: { Task { busy = true; _ = await app.login(account: account, password: password); busy = false } }) {
                    if busy { ProgressView().frame(maxWidth: .infinity) } else { Text("登入").frame(maxWidth: .infinity) }
                }
                .buttonStyle(.borderedProminent).controlSize(.large).disabled(busy)
                Text("示範帳號密碼皆為 demo1234：student002（資工，前端）、student005（創設，UI/UX）、student007（資工，自評上調）").font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
                Spacer()
                Button("API 伺服器設定") { showSettings = true }.font(.footnote)
            }
            .padding(24)
            .sheet(isPresented: $showSettings) {
                NavigationStack {
                    Form {
                        Section("API Base URL") {
                            TextField("http://localhost:8080", text: $apiBase).textInputAutocapitalization(.never).autocorrectionDisabled().keyboardType(.URL)
                            Text("模擬器用 http://localhost:8080；實機用 Mac 的區網 IP 或 Azure 網址").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .navigationTitle("設定")
                    .toolbar { ToolbarItem(placement: .confirmationAction) { Button("儲存") { APIClient.shared.baseURL = apiBase; showSettings = false } } }
                }
            }
        }
    }
}
