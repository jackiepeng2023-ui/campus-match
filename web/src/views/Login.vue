<template>
  <div style="max-width:440px;margin:40px auto">
    <h1 style="text-align:center">跨系資源媒合平台</h1>
    <p class="sub" style="text-align:center;margin-bottom:24px">把分散的人才與合作需求，變成校園內可流動的資源</p>
    <div class="card">
      <div class="segment" style="margin-bottom:16px"><button :class="{on: mode==='login'}" @click="mode='login'">登入</button><button :class="{on: mode==='register'}" @click="mode='register'">註冊</button></div>
      <form v-if="mode==='login'" @submit.prevent="login">
        <div class="field"><label>Email 或學號</label><input v-model="account" placeholder="student001@example.edu" autofocus /></div>
        <div class="field"><label>密碼</label><input v-model="password" type="password" placeholder="demo1234" /></div>
        <button class="btn" style="width:100%" :disabled="busy">登入</button>
        <p class="sub small" style="margin-top:14px">示範帳號（密碼皆為 demo1234）：student001（企管，發案方）、student002（資工，前端）、student003（資工，後端）、student007（資工，作品集自述偏高）、student008（資工博士）、admin@example.edu（管理員）</p>
      </form>
      <form v-else @submit.prevent="register">
        <div class="grid grid-2" style="gap:12px">
          <div class="field"><label>學號</label><input v-model="r.studentNo" required /></div>
          <div class="field"><label>姓名</label><input v-model="r.name" required /></div>
          <div class="field"><label>Email</label><input v-model="r.email" type="email" required /></div>
          <div class="field"><label>密碼</label><input v-model="r.password" type="password" required /></div>
          <div class="field"><label>學制</label><select v-model="r.degree"><option value="BACHELOR">學士</option><option value="MASTER">碩士</option><option value="PHD">博士</option></select></div>
          <div class="field"><label>年級</label><input v-model.number="r.year" type="number" min="1" max="7" @input="syncEntryYear" /></div>
          <div class="field"><label>入學學年度 <span class="sub small">決定你的科目表</span></label><input v-model.number="r.entryYear" type="number" min="100" max="130" placeholder="例如 115" @input="entryTouched = true" /></div>
          <div class="field" style="grid-column:1/-1"><label>系所</label><select v-model.number="r.departmentId"><optgroup v-for="c in colleges" :key="c.id" :label="c.name"><option v-for="d in c.depts" :key="d.id" :value="d.id">{{ d.name }}</option></optgroup></select></div>
          <div class="field"><label>預計畢業年月（D29）</label><input v-model="r.expectedGraduation" type="date" required /></div>
          <div class="field"><label>每週可投入時數</label><input v-model.number="r.hoursPerWeek" type="number" min="0" max="80" /></div>
        </div>
        <div class="field" style="background:var(--bg);padding:12px;border-radius:10px">
          <label style="display:flex;gap:8px;align-items:flex-start;color:var(--text)"><input type="checkbox" v-model="r.consent" style="width:auto;margin-top:3px" />
            <span class="small"><strong>必要</strong>｜我同意平台為「媒合推薦」目的蒐集我的修課成績、證照、作品集、得獎與技能資料；原始成績與技能分數只有我本人可見，對外只顯示技能階級與「已驗證／自述」。資料於畢業 3 個月後去識別化、6 個月後刪除；我可以隨時申請刪除帳號。（個資法第 19、20 條、第 11 條第 3 項；條款 {{ meta?.termsVersion }}）</span></label>
          <label style="display:flex;gap:8px;align-items:flex-start;color:var(--text);margin-top:10px"><input type="checkbox" v-model="r.aiConsent" style="width:auto;margin-top:3px" />
            <span class="small"><strong>選填</strong>｜我同意使用「AI 助理」：我輸入的訊息與我的技能檔（學制、系所、各技能的階級與可信狀態，<u>不含姓名、學號、Email 與原始成績</u>）會傳送到外部語言模型服務（Anthropic Claude API，由境外的服務商處理）處理；其他學生以代號表示。不同意仍可使用全部功能，AI 助理改以規則模式運作、不傳送任何資料。之後可在「我的檔案」隨時撤回。</span></label>
        </div>
        <button class="btn" style="width:100%" :disabled="busy">建立帳號</button>
      </form>
      <p v-if="error" class="small" style="color:var(--red);margin:12px 0 0">{{ error }}</p>
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
const colleges = computed(() => { const m = {}; for (const d of meta.value?.departments || []) { (m[d.collegeId] ||= { id: d.collegeId, name: d.college, depts: [] }).depts.push(d) } return Object.values(m) })
function syncEntryYear() { if (!entryTouched.value && meta.value) r.value.entryYear = meta.value.currentAcademicYear - ((r.value.year || 1) - 1) }
onMounted(async () => { meta.value = await store.loadMeta(); r.value.departmentId = meta.value.departments[0]?.id || 1; syncEntryYear() })
async function login() {
  busy.value = true; error.value = ''
  try { const res = await post('/auth/login', { account: account.value, password: password.value }); setToken(res.token); store.user = res.user; store.unread = res.user.unreadNotifications; router.push('/') }
  catch (e) { error.value = e.message } finally { busy.value = false }
}
async function register() {
  busy.value = true; error.value = ''
  try { const res = await post('/auth/register', r.value); setToken(res.token); store.user = res.user; router.push('/profile') }
  catch (e) { error.value = e.message } finally { busy.value = false }
}
</script>
