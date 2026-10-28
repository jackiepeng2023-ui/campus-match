<template>
  <div v-if="p">
    <h1>管理後台</h1>
    <p class="sub">權重、係數、參數都在資料表裡，改了立即生效，推薦名單可現場重排（D37、D38、D41）。</p>
    <div class="grid grid-2">
      <div class="card">
        <h3>排序權重（總和須為 1.0）</h3>
        <table><tr v-for="w in p.weights" :key="w.key"><td>{{ w.label }}（{{ w.key }}）</td><td><input v-model.number="weights[w.key]" type="number" step="0.05" min="0" max="1" style="max-width:100px" /></td></tr></table>
        <div class="row between" style="margin-top:8px"><span class="sub small">目前總和 {{ sum.toFixed(2) }}</span><button class="btn sm" @click="save">儲存權重</button></div>
        <h3 style="margin-top:16px">可信度係數（依相符度平均）</h3>
        <table><tr><th>相符度</th><th>係數</th></tr><tr v-for="c in p.credibility" :key="c.matchLevel"><td>{{ c.matchLevel === 0 ? '尚無互評' : c.matchLevel }}</td><td><input v-model.number="cred[c.matchLevel]" type="number" step="0.1" min="0" max="1" style="max-width:100px" /></td></tr></table>
        <h3 style="margin-top:16px">系統參數</h3>
        <table><tr v-for="s in p.params" :key="s.key"><td class="small">{{ s.label }}</td><td><input v-model.number="params[s.key]" type="number" style="max-width:100px" /></td></tr></table>
        <button class="btn sm" style="margin-top:8px" @click="save">儲存全部</button>
      </div>
      <div class="stack">
        <div class="card">
          <h3>Demo 時鐘 <span class="sub small">快轉後立即執行排程：提醒、逾時、結案確認、自動結案、互評公開、畢業生命週期</span></h3>
          <div class="row"><span class="pill blue">系統時間 {{ fmtTime(clock.now) }}（偏移 +{{ clock.offsetHours }}h）</span></div>
          <div class="row" style="margin-top:10px"><button class="btn secondary sm" @click="advance(24)">+24 小時</button><button class="btn secondary sm" @click="advance(49)">+49 小時</button><button class="btn secondary sm" @click="advance(73)">+73 小時</button><button class="btn secondary sm" @click="advance(24*8)">+8 天</button><button class="btn ghost sm" @click="resetClock">歸零</button></div>
          <pre v-if="jobs" class="prompt" style="max-height:140px;margin-top:10px">{{ jobs }}</pre>
        </div>
        <div class="card"><h3>媒合漏斗</h3><canvas ref="funnelEl" height="180"></canvas></div>
        <div class="card"><h3>推薦品質</h3><div class="stat-grid"><div class="stat"><div class="k">被核准人數</div><div class="v">{{ q.accepted }}</div></div><div class="stat"><div class="k">在推薦快照中</div><div class="v">{{ q.inSnapshot }}</div></div><div class="stat"><div class="k">平均名次</div><div class="v">{{ q.avgRank ?? '—' }}</div></div><div class="stat"><div class="k">前 5 名內</div><div class="v">{{ q.top5 }}</div></div></div><p class="sub small">快照只記錄發案方「查看推薦」後的名單；歷史種子案件未經推薦，因此不在快照中。</p></div>
      </div>
    </div>
    <div class="grid grid-2" style="margin-top:16px">
      <div class="card"><h3>技能供需缺口 <span class="sub small">供給 = 等級 ≥3 的人數；需求 = 招募中尚缺名額</span></h3><canvas ref="gapEl" height="300"></canvas></div>
      <div class="card"><h3>跨學院合作網絡 <span class="sub small">成案成員兩兩配對的學院組合（專題目的的直接證據）</span></h3>
        <table><tr><th>學院 A</th><th>學院 B</th><th>合作對數</th></tr><tr v-for="n in network" :key="n.a + n.b"><td>{{ n.a }}</td><td>{{ n.b }}</td><td><div class="row"><div class="bar" style="width:120px"><i :style="{ width: Math.round(n.n / network[0].n * 100) + '%' }"></i></div>{{ n.n }}</div></td></tr></table></div>
    </div>
    <div class="card" style="margin-top:16px" v-if="cs">
      <div class="row between"><h3 style="margin:0">科目表與科目→技能對照 <span class="sub small">科目表來自註冊課務組公告；對照由關鍵字規則建議、學生自填，須核准後才計入排序</span></h3>
        <div class="segment"><button :class="{on: csTab==='pending'}" @click="csTab='pending'">待核准 {{ cs.totals.pending }}</button><button :class="{on: csTab==='programs'}" @click="csTab='programs'">科目表 {{ cs.programs.length }} 份</button><button :class="{on: csTab==='add'}" @click="csTab='add'">補登科目</button></div></div>
      <div class="stat-grid" style="margin-top:10px"><div class="stat"><div class="k">科目</div><div class="v">{{ cs.totals.courses }}</div></div><div class="stat"><div class="k">系所</div><div class="v">{{ cs.totals.departments }}</div></div><div class="stat"><div class="k">已有技能對照</div><div class="v">{{ cs.totals.mapped }}</div></div><div class="stat"><div class="k">待核准對照</div><div class="v">{{ cs.totals.pending }}</div></div></div>
      <div v-if="csTab==='pending'" style="margin-top:10px">
        <div class="row"><input v-model="csQ" placeholder="搜尋科目或技能" style="max-width:260px" @keyup.enter="loadPending" /><button class="btn sm secondary" @click="loadPending">搜尋</button><span class="sub small">依填分數的學生數排序；核准後立即重算相關學生的技能預設等級</span></div>
        <p v-if="!pending.length" class="sub small" style="margin-top:10px">沒有待核准的對照。</p>
        <table v-else style="margin-top:8px"><tr><th>科目</th><th>系所／年度</th><th>技能</th><th>來源</th><th>學生數</th><th></th></tr>
          <tr v-for="m in pending" :key="m.courseId + '-' + m.skillId"><td>{{ m.course }} <span class="sub small">{{ m.code }}</span></td><td class="small">{{ m.department || '校共同／通識' }} · {{ m.entryYear }}</td><td>{{ m.skill }} <span class="sub small">{{ m.category }}</span></td>
            <td class="small"><span class="pill" :class="{ SELF: 'orange', LLM: 'purple', RULE: 'blue' }[m.source]">{{ { SELF: '學生自填', LLM: 'AI 建議', RULE: '規則', ADMIN: '管理員' }[m.source] }}</span> {{ m.confidence }}</td><td>{{ m.students }}</td>
            <td class="row"><button class="btn sm" @click="decide(m, true)">核准</button><button class="btn ghost sm" @click="decide(m, false)">退回</button></td></tr></table>
      </div>
      <div v-if="csTab==='programs'" style="margin-top:10px">
        <div class="row"><input v-model="progQ" placeholder="篩選系所" style="max-width:220px" /><span class="sub small">每份 = 一個系所 × 學制 × 入學學年度；「已對照」低的系所可用補登科目或等待學生自填</span></div>
        <div style="max-height:360px;overflow:auto;margin-top:8px"><table><tr><th>學院</th><th>系所</th><th>學制</th><th>入學年度</th><th>科目</th><th>必修</th><th>已對照</th></tr>
          <tr v-for="pr in cs.programs.filter(x => !progQ || x.department.includes(progQ) || x.college.includes(progQ))" :key="pr.departmentId + pr.degree + pr.entryYear"><td class="small">{{ pr.college }}</td><td>{{ pr.department }}</td><td class="small">{{ labels.degree[pr.degree] }}</td><td class="small">{{ pr.entryYear }}</td><td>{{ pr.courses }}</td><td class="small">{{ pr.required }}</td><td><div class="row"><div class="bar" style="width:80px"><i :style="{ width: Math.round(100 * pr.mapped / pr.courses) + '%' }"></i></div><span class="small">{{ pr.mapped }}</span></div></td></tr></table></div>
      </div>
      <form v-if="csTab==='add'" class="grid grid-2" style="gap:8px;margin-top:10px" @submit.prevent="addCourse">
        <select v-model.number="nc.departmentId"><option :value="null">校共同／通識（不分系）</option><option v-for="d in store.meta?.departments" :key="d.id" :value="d.id">{{ d.college }}／{{ d.name }}</option></select>
        <input v-model="nc.name" placeholder="科目名稱" required />
        <select v-model="nc.degree"><option value="BACHELOR">學士</option><option value="MASTER">碩士</option><option value="PHD">博士</option></select>
        <input v-model.number="nc.entryYear" type="number" placeholder="入學學年度，例如 115" required />
        <select v-model="nc.requirement"><option value="REQUIRED">必修</option><option value="ELECTIVE">選修</option><option value="GENERAL">校共同／通識</option></select>
        <div class="row"><input v-model.number="nc.gradeYear" type="number" min="1" max="7" placeholder="年級" /><input v-model.number="nc.term" type="number" min="1" max="2" placeholder="學期" /><input v-model.number="nc.credits" type="number" step="0.5" placeholder="學分" /></div>
        <select v-model="nc.skillIds" multiple style="grid-column:1/-1;height:70px"><option v-for="sk in store.meta?.skills" :key="sk.id" :value="sk.id">{{ sk.category }}｜{{ sk.name }}</option></select>
        <button class="btn sm" style="grid-column:1/-1">新增科目（直接核准所選技能對照）</button>
      </form>
    </div>
    <div class="card" style="margin-top:16px">
      <div class="row between"><h3 style="margin:0">事件紀錄（稽核）</h3><button class="btn danger sm" @click="reset">重置資料（彩排用）</button></div>
      <table style="margin-top:8px"><tr v-for="l in logs" :key="l.id"><td class="small muted">{{ fmtTime(l.createdAt) }}</td><td class="small">{{ l.actor || '系統' }}</td><td class="small">{{ l.entity }} #{{ l.entityId }} · {{ l.action }}</td><td class="small muted">{{ l.payload }}</td></tr></table>
    </div>
  </div>
</template>
<script setup>
import { ref, computed, onMounted, nextTick } from 'vue'
import { Chart, BarController, BarElement, CategoryScale, LinearScale, Tooltip, Legend } from 'chart.js'
import { get, put, post, del } from '../api'
import { store, labels, fmtTime } from '../store'
Chart.register(BarController, BarElement, CategoryScale, LinearScale, Tooltip, Legend)
const p = ref(null), weights = ref({}), cred = ref({}), params = ref({}), clock = ref({}), jobs = ref(''), q = ref({}), network = ref([]), logs = ref([])
const cs = ref(null), csTab = ref('pending'), csQ = ref(''), pending = ref([]), progQ = ref('')
const nc = ref({ departmentId: null, name: '', degree: 'BACHELOR', entryYear: null, requirement: 'ELECTIVE', gradeYear: null, term: null, credits: null, skillIds: [] })
async function loadCourses() { await store.loadMeta(); cs.value = await get('/admin/courses/summary'); if (!nc.value.entryYear) nc.value.entryYear = store.meta.currentAcademicYear; await loadPending() }
async function loadPending() { pending.value = await get('/admin/course-skills?approved=false' + (csQ.value ? '&q=' + encodeURIComponent(csQ.value) : '')) }
async function decide(m, ok) {
  try {
    if (ok) await put('/admin/course-skills', { courseId: m.courseId, skillId: m.skillId, approved: true, confidence: m.confidence })
    else await del(`/admin/course-skills/${m.courseId}/${m.skillId}`)
    store.notify(ok ? `已核准：${m.course} → ${m.skill}` : '已退回', 'success'); await loadCourses()
  } catch (e) { store.notify(e.message, 'error') }
}
async function addCourse() { try { await post('/admin/courses', nc.value); store.notify('已新增科目', 'success'); nc.value.name = ''; nc.value.skillIds = []; await loadCourses() } catch (e) { store.notify(e.message, 'error') } }
const funnelEl = ref(null), gapEl = ref(null)
let funnelChart, gapChart
const sum = computed(() => Object.values(weights.value).reduce((a, b) => a + (+b || 0), 0))
async function load() {
  p.value = await get('/admin/params')
  p.value.weights.forEach(w => weights.value[w.key] = +w.value); p.value.credibility.forEach(c => cred.value[c.matchLevel] = +c.coefficient); p.value.params.forEach(s => params.value[s.key] = s.value)
  clock.value = await get('/admin/clock'); q.value = await get('/analytics/recommendation-quality'); network.value = await get('/analytics/network'); logs.value = await get('/admin/event-logs?limit=40')
  const funnel = await get('/analytics/funnel'), gap = (await get('/analytics/skill-gap')).slice(0, 12)
  await nextTick()
  funnelChart?.destroy(); gapChart?.destroy()
  funnelChart = new Chart(funnelEl.value, { type: 'bar', data: { labels: funnel.map(f => f.stage), datasets: [{ label: '案件數', data: funnel.map(f => f.n), backgroundColor: '#0a84ff', borderRadius: 6 }] }, options: { plugins: { legend: { display: false } }, scales: { y: { beginAtZero: true, ticks: { precision: 0 } } } } })
  gapChart = new Chart(gapEl.value, { type: 'bar', data: { labels: gap.map(g => g.skill), datasets: [{ label: '供給（≥3 級人數）', data: gap.map(g => g.supply), backgroundColor: '#34c759', borderRadius: 6 }, { label: '需求（尚缺名額）', data: gap.map(g => g.demand), backgroundColor: '#ff9f0a', borderRadius: 6 }] }, options: { indexAxis: 'y', plugins: { legend: { position: 'bottom' } }, scales: { x: { beginAtZero: true, ticks: { precision: 0 } } } } })
}
async function save() { try { await put('/admin/params', { weights: weights.value, credibility: cred.value, params: params.value }); store.notify('已儲存，推薦名單重新查詢即套用', 'success'); await load() } catch (e) { store.notify(e.message, 'error') } }
async function advance(h) { try { const r = await post('/admin/clock', { hours: h }); jobs.value = JSON.stringify(r, null, 1); store.notify('時間已快轉 ' + h + ' 小時並執行排程', 'success'); await load() } catch (e) { store.notify(e.message, 'error') } }
async function resetClock() { await post('/admin/clock/reset'); jobs.value = ''; await load() }
async function reset() { if (!confirm('重建 schema 與 50 位示範學生？所有操作紀錄會清除。')) return; await post('/admin/reset'); store.notify('已重置', 'success'); await load() }
onMounted(async () => { await load(); await loadCourses() })
</script>
