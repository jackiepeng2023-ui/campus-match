<template>
  <div style="max-width:470px;margin:0 auto;padding:44px 16px 60px">
    <div class="center" style="margin-bottom:22px">
      <div class="logo" style="font-size:44px">FOMO<b>鬆</b></div>
      <p class="strong" style="margin:6px 0 2px">找隊友打比賽</p>
      <p class="sub small">選比賽、開隊或找隊、聊一聊、成隊、報名。</p>
    </div>
    <div class="card">
      <div class="segment" style="margin-bottom:18px"><button type="button" :class="{ on: mode === 'login' }" @click="mode = 'login'">登入</button><button type="button" :class="{ on: mode === 'register' }" @click="mode = 'register'">註冊</button></div>
      <form v-if="mode === 'login'" @submit.prevent="login">
        <div class="field"><label for="acc">Email 或學號</label><input id="acc" v-model.trim="account" autocomplete="username" required autofocus /></div>
        <div class="field"><label for="pw">密碼</label><input id="pw" v-model="password" type="password" autocomplete="current-password" required /></div>
        <button class="btn block" :disabled="busy">登入</button>
        <div v-if="meta?.demo" style="margin-top:18px">
          <p class="small strong" style="margin-bottom:8px">示範帳號（點一下帶入帳號，密碼是部署時設定的示範密碼）</p>
          <div class="tags"><button v-for="d in demos" :key="d.account" type="button" class="fpill" style="min-height:40px;padding:6px 13px;font-size:13px" @click="account = d.account">{{ d.label }}</button></div>
          <p class="hint" style="margin-top:8px">示範資料裡的人名、隊名都是虛構的。</p>
        </div>
      </form>
      <form v-else @submit.prevent="register">
        <div class="grid grid-2" style="gap:12px">
          <div class="field" style="margin:0"><label for="r-no">學號</label><input id="r-no" v-model.trim="r.studentNo" required /></div>
          <div class="field" style="margin:0"><label for="r-name">姓名</label><input id="r-name" v-model.trim="r.name" required /></div>
          <div class="field" style="margin:0"><label for="r-mail">Email</label><input id="r-mail" v-model.trim="r.email" type="email" autocomplete="username" required /></div>
          <div class="field" style="margin:0"><label for="r-pw">密碼</label><input id="r-pw" v-model="r.password" type="password" autocomplete="new-password" required /></div>
          <div class="field" style="margin:0"><label for="r-deg">學制</label><select id="r-deg" v-model="r.degree"><option value="BACHELOR">學士</option><option value="MASTER">碩士</option><option value="PHD">博士</option></select></div>
          <div class="field" style="margin:0"><label for="r-year">年級</label><input id="r-year" v-model.number="r.year" type="number" min="1" max="7" @input="syncEntryYear" /></div>
          <div class="field" style="margin:0;grid-column:1/-1"><label for="r-dept">系所</label><select id="r-dept" v-model.number="r.departmentId"><optgroup v-for="c in colleges" :key="c.id" :label="c.name"><option v-for="d in c.depts" :key="d.id" :value="d.id">{{ d.name }}</option></optgroup></select></div>
          <div class="field" style="margin:0"><label for="r-entry">入學學年度</label><input id="r-entry" v-model.number="r.entryYear" type="number" min="100" max="130" placeholder="例如 115" @input="entryTouched = true" /><div class="hint">決定你的科目表</div></div>
          <div class="field" style="margin:0"><label for="r-grad">預計畢業年月</label><input id="r-grad" v-model="r.expectedGraduation" type="date" required /></div>
          <div class="field" style="margin:0;grid-column:1/-1"><label for="r-hours">每週可以投入幾小時</label><input id="r-hours" v-model.number="r.hoursPerWeek" type="number" min="0" max="80" /></div>
        </div>
        <div style="background:var(--bg);padding:14px;border-radius:14px;margin:14px 0">
          <label style="display:flex;gap:9px;align-items:flex-start;font-weight:400"><input type="checkbox" v-model="r.consent" style="margin-top:3px" />
            <span class="small"><strong>必要</strong>｜我同意平台為了「幫我找隊友」蒐集我的修課成績、證照、作品集、得獎與技能資料。原始成績與技能分數只有我本人看得到，別人只看到技能階級與「已驗證／自述」。資料在畢業 3 個月後去識別化、6 個月後刪除；我可以隨時刪除帳號。（個人資料保護法第 19、20 條、第 11 條第 3 項；條款 {{ meta?.termsVersion }}）</span></label>
          <label style="display:flex;gap:9px;align-items:flex-start;font-weight:400;margin-top:12px"><input type="checkbox" v-model="r.aiConsent" style="margin-top:3px" />
            <span class="small"><strong>選填</strong>｜我同意使用「AI 助理」：我輸入的訊息與我的技能檔（學制、系所、各技能的階級與可信狀態，<u>不含姓名、學號、Email 與原始成績</u>）會傳送到外部語言模型服務（Anthropic Claude API，由境外的服務商處理）；其他學生以代號表示。不同意仍可使用全部功能，AI 助理改以規則模式運作、不傳送任何資料。之後可以在個人頁隨時撤回。</span></label>
        </div>
        <button class="btn block" :disabled="busy">建立帳號</button>
      </form>
      <p v-if="error" class="small urgent" style="margin:12px 0 0" role="alert">{{ error }}</p>
    </div>
  </div>
</template>
<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { post, setToken } from '../api'
import { store } from '../store'
const router = useRouter()
const mode = ref('login'), account = ref(''), password = ref(''), busy = ref(false), error = ref(''), meta = ref(null)
const r = ref({ studentNo: '', name: '', email: '', password: '', degree: 'BACHELOR', year: 1, departmentId: 1, entryYear: null, expectedGraduation: '2030-06-30', hoursPerWeek: 8, consent: false, aiConsent: false })
const entryTouched = ref(false)
const demos = [{ account: 'student001@example.edu', label: '企管三・江筱涵' }, { account: 'student012@example.edu', label: '電機三・許詩涵（隊長）' }, { account: 'student005@example.edu', label: '創設二・王子軒（隊長）' },
  { account: 'student008@example.edu', label: '資工博三・蕭婉婷（隊長）' }, { account: 'student004@example.edu', label: '統計三・郭昱辰' }, { account: 'admin@example.edu', label: '管理員' }]
const colleges = computed(() => { const m = {}; for (const d of meta.value?.departments || []) { (m[d.collegeId] ||= { id: d.collegeId, name: d.college, depts: [] }).depts.push(d) } return Object.values(m) })
function syncEntryYear() { if (!entryTouched.value && meta.value) r.value.entryYear = meta.value.currentAcademicYear - ((r.value.year || 1) - 1) }
onMounted(async () => { meta.value = await store.loadMeta(); r.value.departmentId = meta.value.departments[0]?.id || 1; syncEntryYear() })
async function login() {
  busy.value = true; error.value = ''
  try { const res = await post('/auth/login', { account: account.value, password: password.value }); setToken(res.token); store.user = res.user; store.unread = res.user.unreadNotifications; router.push(res.user.role === 'ADMIN' ? '/admin' : '/') }
  catch (e) { error.value = e.message } finally { busy.value = false }
}
async function register() {
  busy.value = true; error.value = ''
  try { const res = await post('/auth/register', r.value); setToken(res.token); store.user = res.user; router.push('/profile') }
  catch (e) { error.value = e.message } finally { busy.value = false }
}
</script>
