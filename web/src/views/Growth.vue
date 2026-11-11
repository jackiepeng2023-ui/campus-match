<template>
  <div v-if="g">
    <h1>成長儀表板</h1>
    <p class="sub">成長只來自有紀錄的事：每一筆證據（課程成績、證照、作品集、競賽得獎、結案互評）出現時，技能分數與等級才會變動（D30、D53–D55）。等級：{{ bandsText(g.levelBands) }}。</p>
    <div class="card" style="margin-bottom:16px">
      <h3>知識圖譜 <span class="sub small">證據（科目、證照與作品、得獎、結案案件）→ 技能 → 分類；可匯出成 Obsidian Vault 用 Graph view 檢視</span></h3>
      <KnowledgeGraph />
    </div>
    <div class="grid grid-2">
      <div class="card"><h3>技能雷達（各類別平均分數與最高分，0–100）</h3><canvas ref="radar" height="260"></canvas></div>
      <div class="card"><h3>技能分數變化（每月各類別最高分；虛線為中階、進階門檻）</h3><canvas ref="line" height="260"></canvas></div>
    </div>
    <div class="grid grid-2" style="margin-top:16px">
      <div class="card">
        <h3>成長時間軸</h3>
        <ul class="timeline"><li v-for="(t, i) in g.timeline" :key="i"><span class="t">{{ fmtTime(t.ts) }}</span><span><span class="pill" :class="kindColor(t.kind)" style="margin-right:6px">{{ kindLabel(t.kind) }}</span>{{ t.text }}</span></li></ul>
        <div v-if="!g.timeline.length" class="empty">還沒有紀錄</div>
      </div>
      <div class="card">
        <h3>AI 成長建議 Prompt <span class="sub small">由系統從你的資料組出 Prompt，預覽、刪改後貼到你自己選的 AI；想讓平台直接規劃競賽與組隊，請用上方選單的「AI 助理」（D31–D33、D56）</span></h3>
        <div class="field"><label>成長目標</label><input v-model="goal" placeholder="例：畢業後成為前端工程師" /></div>
        <div class="field"><label>我想問的問題</label><input v-model="question" placeholder="例：下學期該補什麼、該參加哪種比賽？" /></div>
        <button class="btn" @click="gen">產生 Prompt</button>
        <div v-if="prompt" style="margin-top:12px">
          <p class="small" style="color:var(--orange)">{{ notice }}</p>
          <textarea v-model="prompt" rows="16" style="font-family:ui-monospace,Menlo,monospace;font-size:12.5px"></textarea>
          <div class="row" style="margin-top:8px"><button class="btn secondary" @click="copy">複製到剪貼簿</button>
            <a class="btn ghost sm" href="https://claude.ai/new" target="_blank">Claude</a><a class="btn ghost sm" href="https://chatgpt.com/" target="_blank">ChatGPT</a><a class="btn ghost sm" href="https://gemini.google.com/" target="_blank">Gemini</a><a class="btn ghost sm" href="https://grok.com/" target="_blank">Grok</a><a class="btn ghost sm" href="https://www.perplexity.ai/" target="_blank">Perplexity</a></div>
        </div>
      </div>
    </div>
  </div>
</template>
<script setup>
import { ref, onMounted, nextTick } from 'vue'
import { Chart, RadarController, LineController, RadialLinearScale, LinearScale, CategoryScale, PointElement, LineElement, Filler, Tooltip, Legend } from 'chart.js'
import { get, post } from '../api'
import { store, fmtTime, bandsText } from '../store'
import KnowledgeGraph from '../components/KnowledgeGraph.vue'
Chart.register(RadarController, LineController, RadialLinearScale, LinearScale, CategoryScale, PointElement, LineElement, Filler, Tooltip, Legend)
const g = ref(null), radar = ref(null), line = ref(null), goal = ref(''), question = ref(''), prompt = ref(''), notice = ref('')
const kindLabel = (k) => ({ SKILL: '技能', CASE_JOINED: '加入', CASE_OWNED: '發起', CASE_CLOSED: '結案', AWARD: '得獎', REVIEW: '評價' }[k] || k)
const kindColor = (k) => ({ SKILL: 'blue', CASE_JOINED: '', CASE_OWNED: '', CASE_CLOSED: 'purple', AWARD: 'orange', REVIEW: 'green' }[k] || '')
onMounted(async () => {
  g.value = await get('/me/growth'); await nextTick()
  new Chart(radar.value, { type: 'radar', data: { labels: g.value.radar.map(r => r.category), datasets: [{ label: '平均分數', data: g.value.radar.map(r => +r.avgScore), fill: true, backgroundColor: 'rgba(10,132,255,.15)', borderColor: '#0a84ff', pointBackgroundColor: '#0a84ff' }, { label: '最高分', data: g.value.radar.map(r => +r.maxScore), borderColor: '#5e5ce6', borderDash: [4, 4], pointBackgroundColor: '#5e5ce6', fill: false }] }, options: { scales: { r: { min: 0, max: 100, ticks: { stepSize: 20 } } }, plugins: { legend: { position: 'bottom' } } } })
  const months = [...new Set(g.value.semesters.map(s => s.month))].sort(), cats = [...new Set(g.value.semesters.map(s => s.category))]
  const colors = ['#0a84ff', '#34c759', '#ff9f0a', '#5e5ce6', '#ff3b30', '#64d2ff']
  new Chart(line.value, { type: 'line', data: { labels: months, datasets: cats.map((c, i) => { let last = null; return { label: c, borderColor: colors[i % colors.length], tension: .3, spanGaps: true, data: months.map(m => { const hit = g.value.semesters.find(s => s.month === m && s.category === c); if (hit) last = Math.max(last ?? 0, +hit.score); return last }) } }).concat(g.value.levelBands.filter(b => b.tier >= 2).map(b => ({ label: b.name + '門檻', data: months.map(() => b.minScore), borderColor: '#aeaeb2', borderDash: [5, 5], pointRadius: 0, borderWidth: 1 }))) }, options: { scales: { y: { min: 40, max: 100, ticks: { stepSize: 10 } } }, plugins: { legend: { position: 'bottom' } } } })
})
async function gen() { try { const r = await post('/me/growth-prompt', { goal: goal.value, question: question.value }); prompt.value = r.prompt; notice.value = r.notice } catch (e) { store.notify(e.message, 'error') } }
async function copy() { await navigator.clipboard.writeText(prompt.value); store.notify('已複製，貼到你選擇的 AI 即可', 'success') }
</script>
