<template>
  <div v-if="me">
    <div class="row between"><div><h1>我的檔案</h1><div class="sub">{{ me.studentNo }} · {{ me.college }}／{{ me.department }} · {{ labels.degree[me.degree] }}{{ me.year }}年級{{ me.entryYear ? '（' + me.entryYear + ' 學年度入學）' : '' }} · 預計畢業 {{ me.expectedGraduation }}</div></div>
      <router-link :to="'/users/' + me.id" class="btn secondary">別人看到的我</router-link></div>

    <div class="card" style="margin-top:16px">
      <div class="row between"><h3 style="margin:0">Skill Profile <span class="sub small">能力盤點模組把下面的證據彙整成「技能／等級／證據」；三個媒合 Agent 共用這一份</span></h3>
        <span class="sub small">等級：{{ bandsText(me.levelBands) }}</span></div>
      <p class="sub small" style="margin:6px 0 10px">同一技能有多筆證據時<strong>不疊加</strong>，取最高分，全部證據保留。分數只有你看得到；別人只看到階級與 <span class="pill green">已驗證</span> <span class="pill blue">修課成績</span> <span class="pill orange">自述</span>。</p>
      <div v-if="!me.skills.length" class="empty">還沒有任何證據。先在下方填修課成績，或新增證照、作品集。</div>
      <table v-else><tr><th>技能</th><th style="width:70px">分數</th><th style="width:80px">等級</th><th style="width:100px">可信狀態</th><th>證據（最高分在前）</th></tr>
        <template v-for="s in me.skills" :key="s.skillId">
          <tr><td>{{ s.name }} <span class="sub small">{{ s.category }}</span></td><td><strong>{{ s.score }}</strong></td>
            <td><span class="pill" :class="tierColor(s.tier)">{{ s.tier }}</span></td><td><span class="pill" :class="trustColor(s.trust)">{{ s.trustLabel }}</span></td>
            <td class="small"><a href="#" @click.prevent="open[s.skillId] = !open[s.skillId]">{{ s.evidenceCount }} 筆：{{ [...new Set(s.evidence.map(e => e.typeLabel))].join('、') }} {{ open[s.skillId] ? '▴' : '▾' }}</a></td></tr>
          <tr v-if="open[s.skillId]"><td colspan="5" style="background:var(--bg)">
            <div v-for="e in s.evidence" :key="e.id" class="row small" style="padding:3px 0"><span class="pill">{{ e.typeLabel }}</span><strong>{{ e.title }}</strong><span>{{ e.score }} 分（{{ e.tier }}）</span>
              <span class="pill" :class="e.verified ? 'green' : e.type === 'COURSE' ? 'blue' : 'orange'">{{ e.verified ? '已驗證' : e.type === 'COURSE' ? '成績自填' : '自述' }}</span>
              <span class="sub">{{ e.detail }}{{ e.occurredOn ? '・' + e.occurredOn : '' }}</span><a v-if="e.proofUrl" :href="e.proofUrl" target="_blank" rel="noopener">證明連結</a></div>
          </td></tr>
        </template></table>
    </div>

    <div class="grid grid-2" style="margin-top:16px">
      <div class="stack">
        <div class="card">
          <div class="row between"><h3 style="margin:0">修課成績 <span class="sub small">只有你看得到</span></h3>
            <button class="btn sm" :class="{ secondary: picker }" @click="picker = !picker">{{ picker ? '收起科目清單' : '從科目清單填分數' }}</button></div>
          <p class="sub small" style="margin:6px 0 0">科目清單來自學校公告的科目表。每門課由規則、課綱與 AI 對到 Skill 資料庫的 1–{{ max }} 個技能（管理員可調整）；{{ me.degree === 'BACHELOR' ? '學士成績直接作為證據分數' : '研究所成績先依研究所門檻換算到共同量尺' }}。</p>
          <CoursePicker v-if="picker" :me="me" @saved="load" style="margin-top:10px" />
          <table v-if="me.grades.length" style="margin-top:10px"><tr><th>科目</th><th>學期</th><th>分數</th><th>對應技能</th><th></th></tr>
            <tr v-for="g in me.grades" :key="g.id"><td>{{ g.course }} <span class="pill" :class="{ REQUIRED: 'blue', GENERAL: 'purple' }[g.requirement] || ''" v-if="g.requirement">{{ { REQUIRED: '必修', ELECTIVE: '選修', GENERAL: '通識' }[g.requirement] }}</span><div class="sub small" v-if="g.department && g.department !== me.department">{{ g.department }}</div></td>
              <td class="small">{{ g.semester }}</td><td><strong>{{ g.score }}</strong></td><td class="sub small">{{ g.skills }}<span class="muted" v-if="g.pendingSkills">（待核准：{{ g.pendingSkills }}）</span></td><td><button class="btn ghost sm" @click="run(() => del('/me/grades/' + g.id))">✕</button></td></tr></table>
          <p v-else class="sub small" style="margin-top:10px">尚未填任何成績。按「從科目清單填分數」開始。</p>
        </div>
        <div class="card">
          <h3>得獎紀錄 <span class="sub small">同一競賽不重複計分；每筆對應 1–{{ max }} 個技能，附證明連結可送審驗證</span></h3>
          <table v-if="me.awards.length"><tr v-for="a in me.awards" :key="a.id"><td>{{ a.competition }}<div class="sub small">{{ a.skills }}</div></td><td class="small">{{ labels.level[a.level] }}・{{ labels.rank[a.rank] }} <span class="pill" :class="a.verified ? 'green' : 'orange'">{{ a.verified ? '已驗證' : '自述' }}</span></td><td class="small">{{ a.awardDate }}</td><td><button class="btn ghost sm" @click="run(() => del('/me/awards/' + a.id))">✕</button></td></tr></table>
          <form class="grid grid-2" style="gap:8px;margin-top:10px" @submit.prevent="run(() => post('/me/awards', na)).then(ok => ok && (na = blankAward()))">
            <input v-model="na.competition" placeholder="競賽名稱" required />
            <input v-model="na.awardDate" type="date" required />
            <select v-model="na.level"><option v-for="(l, k) in labels.level" :key="k" :value="k">{{ l }}</option></select>
            <select v-model="na.rank"><option v-for="(l, k) in labels.rank" :key="k" :value="k">{{ l }}</option></select>
            <input v-model="na.proofUrl" placeholder="證明連結（選填，https://…）" style="grid-column:1/-1" />
            <SkillPicker v-model="na.skillIds" :max="max" style="grid-column:1/-1" />
            <button class="btn sm" style="grid-column:1/-1" :disabled="!na.skillIds.length">新增得獎</button>
          </form>
        </div>
      </div>
      <div class="stack">
        <div class="card">
          <h3>證照、作品集、自我評估 <span class="sub small">自己填的先標示「自述」；附上證明連結，管理員審核後變成「已驗證」</span></h3>
          <table v-if="me.credentials.length"><tr v-for="c in me.credentials" :key="c.id"><td><span class="pill">{{ labels.evidence[c.type] }}</span> {{ c.title }}<div class="sub small">{{ c.skills }}{{ c.issuer ? '・' + c.issuer : '' }}{{ c.obtainedOn ? '・' + c.obtainedOn : '' }}</div></td>
            <td class="small" style="white-space:nowrap">{{ c.score }} 分 <span class="pill" :class="c.verified ? 'green' : 'orange'">{{ c.verified ? '已驗證' : '自述' }}</span></td>
            <td class="small" style="white-space:nowrap"><a v-if="c.proofUrl" :href="c.proofUrl" target="_blank" rel="noopener">證明</a></td><td><button class="btn ghost sm" @click="run(() => del('/me/credentials/' + c.id))">✕</button></td></tr></table>
          <div class="segment" style="margin:12px 0 10px"><button v-for="(l, k) in { CERTIFICATE: '證照', PORTFOLIO: '作品集', SELF: '自我評估' }" :key="k" :class="{ on: nc.type === k }" @click="nc.type = k">{{ l }}</button></div>
          <form class="stack" style="gap:8px" @submit.prevent="addCredential">
            <template v-if="nc.type === 'CERTIFICATE'">
              <select v-model="nc.catalogId"><option :value="null">不在對照表內（自行填寫）</option><option v-for="c in store.meta?.certificateCatalog" :key="c.id" :value="c.id">{{ c.name }}｜{{ c.skills }}｜{{ c.score }} 分</option></select>
              <p class="sub small" v-if="nc.catalogId" style="margin:0">對照表內的證照：技能與分數由對照表決定（管理員維護），不需自選。</p>
            </template>
            <template v-if="nc.type !== 'SELF' && !(nc.type === 'CERTIFICATE' && nc.catalogId)">
              <input v-model="nc.title" :placeholder="nc.type === 'CERTIFICATE' ? '證照名稱' : '作品名稱，例如：社團活動報名前台（Vue 3）'" required />
              <input v-if="nc.type === 'CERTIFICATE'" v-model="nc.issuer" placeholder="發證單位（選填）" />
            </template>
            <template v-if="!(nc.type === 'CERTIFICATE' && nc.catalogId)">
              <div class="row"><span class="sub small">我認為達到</span><select v-model.number="nc.tier" style="max-width:120px"><option v-for="n in 3" :key="n" :value="n">{{ labels.tier[n] }}</option></select><span class="sub small">（以該階的代表分數計入）</span></div>
              <SkillPicker v-model="nc.skillIds" :max="nc.type === 'SELF' ? 1 : max" />
            </template>
            <div class="row" v-if="nc.type !== 'SELF'"><input v-model="nc.obtainedOn" type="date" style="max-width:170px" /><input v-model="nc.proofUrl" placeholder="證明連結（選填，https://…）" style="flex:1;min-width:200px" /></div>
            <button class="btn sm" :disabled="!(nc.type === 'CERTIFICATE' && nc.catalogId) && !nc.skillIds.length">新增{{ { CERTIFICATE: '證照', PORTFOLIO: '作品集', SELF: '自我評估' }[nc.type] }}</button>
          </form>
        </div>
        <div class="card">
          <h3>可投入時間 <span class="sub small">（時間閘門，D4）</span></h3>
          <form class="row" @submit.prevent="run(() => put('/me/availability', av))">
            <input v-model.number="av.hoursPerWeek" type="number" min="0" max="80" style="max-width:100px" /><span class="sub small">小時／週</span>
            <input v-model="av.availableFrom" type="date" style="max-width:160px" /><span class="sub small">～</span><input v-model="av.availableTo" type="date" style="max-width:160px" /><button class="btn sm">儲存</button>
          </form>
        </div>
        <div class="card">
          <h3>AI 助理的資料使用 <span class="pill" :class="me.aiConsent ? 'green' : ''">{{ me.aiConsent ? '已同意' : '未同意' }}</span></h3>
          <p class="sub small">同意後，你輸入給 AI 助理的訊息與你的技能檔（學制、系所、各技能的階級與可信狀態；<strong>不含姓名、學號、Email、原始成績與技能分數</strong>）會傳送到外部語言模型服務（Anthropic Claude API，由境外的服務商處理）；其他學生一律以代號表示。未同意時 AI 助理以規則模式運作，不傳送任何資料，其餘功能不受影響。</p>
          <button class="btn sm" :class="me.aiConsent ? 'secondary' : ''" @click="run(() => post('/me/consents/ai', { agree: !me.aiConsent }))">{{ me.aiConsent ? '撤回同意' : '同意使用 AI 助理' }}</button>
        </div>
        <div class="card">
          <h3>收到的評價</h3>
          <div v-if="reviews" class="sub small">累計：滿意度 {{ reviews.overall.satisfaction ?? '—' }} · 相符度 {{ reviews.overall.matchScore ?? '—' }} · 準時 {{ reviews.overall.onTime ?? '—' }} · 溝通 {{ reviews.overall.communication ?? '—' }}（{{ reviews.overall.n }} 筆）。結案時隊友評的「相符度」達門檻，角色技能會得到「已驗證」的結案證據。</div>
          <table v-if="reviews && reviews.cases.length" style="margin-top:8px"><tr v-for="r in reviews.cases" :key="r.caseId"><td>{{ r.title }}</td><td class="small" v-if="r.hidden"><span class="muted">{{ r.note }}</span></td><td class="small" v-else>滿意 {{ r.satisfaction }} · 相符 {{ r.matchScore }} · 準時 {{ r.onTime }} · 溝通 {{ r.communication }}<div class="sub" v-if="r.comments">「{{ r.comments }}」</div></td></tr></table>
        </div>
        <div class="card">
          <h3>畢業與資料保存 <span class="sub small">（D27–D29）</span></h3>
          <p class="sub small">畢業 3 個月後去識別化、6 個月後刪除本人資料（含證據與 AI 助理對話）；去識別化的案件與評價紀錄保留供統計。你也可以隨時刪除帳號。</p>
          <div class="row"><button class="btn secondary sm" @click="run(() => post('/me/graduation', { status: 'GRADUATED' }))">我已畢業</button><button class="btn danger sm" @click="deleteMe">刪除帳號</button></div>
        </div>
      </div>
    </div>
  </div>
</template>
<script setup>
import { ref, reactive, computed, onMounted } from 'vue'
import { get, put, post, del } from '../api'
import { store, labels, tierColor, trustColor, bandsText } from '../store'
import CoursePicker from '../components/CoursePicker.vue'
import SkillPicker from '../components/SkillPicker.vue'
const me = ref(null), reviews = ref(null), picker = ref(false), open = reactive({})
const max = computed(() => store.meta?.maxSkillsPerEvidence || 5)
const blankAward = () => ({ competition: '', level: 'CAMPUS', rank: 'TOP3', awardDate: '', proofUrl: '', skillIds: [] })
const blankCred = (type = 'CERTIFICATE') => ({ type, catalogId: null, title: '', issuer: '', tier: 2, obtainedOn: '', proofUrl: '', skillIds: [] })
const av = ref({ hoursPerWeek: 8, availableFrom: '', availableTo: '' }), na = ref(blankAward()), nc = ref(blankCred())
async function load() { me.value = await get('/me'); store.user = me.value; reviews.value = await get('/me/reviews'); av.value = { ...me.value.availability }; if (!me.value.grades.length) picker.value = true }
async function run(fn) { try { await fn(); store.notify('已更新，Skill Profile 已重新盤點', 'success'); await load(); return true } catch (e) { store.notify(e.message, 'error'); return false } }
async function addCredential() {
  const c = nc.value
  const body = c.type === 'SELF' ? null : { type: c.type, title: c.title, issuer: c.issuer, obtainedOn: c.obtainedOn, catalogId: c.type === 'CERTIFICATE' ? c.catalogId : null, tier: c.tier, proofUrl: c.proofUrl, skillIds: c.skillIds }
  const ok = await run(() => c.type === 'SELF' ? put('/me/skills', [{ skillId: c.skillIds[0], level: c.tier }]) : post('/me/credentials', body))
  if (ok) nc.value = blankCred(c.type)
}
async function deleteMe() { if (!confirm('確定刪除帳號？本人資料將立即去識別化並刪除。')) return; await del('/me'); store.logout() }
onMounted(async () => { await store.loadMeta(); await load() })
</script>
