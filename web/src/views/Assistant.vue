<template>
  <div class="chat">
    <div class="chat-side stack">
      <div class="card" style="padding:14px" v-if="st">
        <div class="row between"><strong>AI 助理</strong><span class="pill" :class="st.mode === 'LLM' ? 'purple' : ''">{{ st.mode === 'LLM' ? 'Claude' : '規則模式' }}</span></div>
        <p class="sub small" style="margin:6px 0 0">{{ st.mode === 'LLM' ? '由 ' + st.model + ' 規劃步驟、呼叫工具。' : st.notice }}</p>
        <p class="sub small" style="margin:6px 0 0" v-if="!st.aiConsent && st.llmEnabled"><router-link to="/profile">到「個人頁」同意後可改用 Claude</router-link></p>
        <div class="sub small" style="margin-top:8px">可用工具（白名單）：<div v-for="(names, agent) in toolGroups" :key="agent">· {{ agent }}</div></div>
        <div class="sub small" style="margin-top:8px">今日 {{ st.usedToday }}／{{ st.dailyLimit }} 則 · 單則最多 {{ st.maxSteps }} 輪工具呼叫</div>
      </div>
      <div class="card" style="padding:10px">
        <button class="btn secondary sm" style="width:100%" @click="newSession">＋ 新對話</button>
        <div v-for="s in sessions" :key="s.id" class="sess-row">
          <a class="sess" :class="{ on: s.id === sid }" @click="openSession(s.id)" :title="s.title">{{ s.title || '（未命名）' }}</a>
          <button class="sess-del" title="刪除這個對話（含執行軌跡）" :disabled="busy" @click="removeSession(s)">×</button>
        </div>
        <p v-if="sessions.length" class="sub small" style="margin:8px 4px 0">對話存在本系統；刪除後訊息與執行軌跡一併清除。</p>
      </div>
    </div>

    <div class="stack">
      <div class="card" v-if="!messages.length">
        <h2>說出你的目標，我來拆步驟</h2>
        <p class="sub">我會依序呼叫「能力盤點模組」與三個媒合 Agent（競賽、學生、教師），每一步都看得到；要開隊或邀請隊友時，我只會準備草稿，由你按確認。</p>
        <div class="suggest" style="margin-top:12px"><button v-for="q in starters" :key="q" @click="send(q)">{{ q }}</button></div>
      </div>
      <template v-for="m in messages" :key="m.id">
        <div v-if="m.role === 'user'" class="bubble">{{ m.content }}</div>
        <div v-else class="card">
          <div class="row between">
            <div class="row"><span class="pill" :class="m.mode === 'LLM' ? 'purple' : ''">{{ m.status === 'RUNNING' ? '執行中' : m.mode === 'LLM' ? 'Claude' : '規則模式' }}</span>
              <span v-if="m.status !== 'RUNNING' && m.stop && !['END_TURN', 'RULE'].includes(m.stop)" class="pill orange">{{ labels.stop[m.stop] }}</span>
              <span v-if="m.checks && m.status !== 'RUNNING'" class="pill" :class="m.checks.ok ? 'green' : 'red'" :title="'比對回覆中的分數、日期、學生代號是否都出現在工具結果'">輸出檢核{{ m.checks.ok ? '通過' : '：' + [...m.checks.unverified, ...m.checks.unknownTokens].join('、') + ' 無法對應工具結果' }}</span></div>
            <span class="sub small" v-if="m.status !== 'RUNNING'">{{ (m.durationMs / 1000).toFixed(1) }} 秒 · 工具 {{ m.toolCalls }} 次{{ m.toolErrors ? '（失敗 ' + m.toolErrors + '）' : '' }}{{ m.llmCalls ? ' · 模型 ' + m.llmCalls + ' 次 · ' + (m.inputTokens + m.outputTokens) + ' tokens' : '' }}</span>
          </div>
          <p v-if="m.notice" class="small" style="color:#b86a00;margin:8px 0 0">{{ m.notice }}</p>
          <div class="trace" style="margin-top:10px" v-if="m.steps && m.steps.length || m.status === 'RUNNING'">
            <div class="row between"><strong class="small">執行軌跡（{{ (m.steps || []).length }} 步）</strong><a href="#" class="small" @click.prevent="m._open = !m._open" v-if="m.status !== 'RUNNING'">{{ m._open === false ? '展開' : '收合' }}</a></div>
            <template v-if="m._open !== false">
              <div v-for="s in m.steps" :key="s.seq" class="st"><span>{{ s.ok ? '✓' : '✗' }}</span><span class="pill" :class="{ COMPETITION: 'blue', STUDENT: 'green', TEACHER: 'purple', ACTION: 'orange' }[s.agent] || ''">{{ labels.agent[s.agent] }}</span>
                <span><code>{{ s.tool }}({{ s.input === '{}' ? '' : s.input }})</code><br />{{ s.summary }}</span><span class="muted small">{{ s.durationMs }} ms</span></div>
              <div v-if="m.status === 'RUNNING'" class="st"><span class="spin"></span><span class="sub small" style="grid-column:2/-1">{{ (m.steps || []).length ? '依上一步的結果決定下一步…' : '理解目標、規劃步驟…' }}</span></div>
            </template>
          </div>
          <div class="answer" style="margin-top:12px" v-if="m.content">{{ m.content }}</div>
          <div style="margin-top:12px" v-if="m.cards && m.cards.length">
            <template v-for="(c, i) in m.cards" :key="i">
              <div v-if="c.type === 'profile'" class="acard"><h4><span class="pill">能力盤點</span>Skill Profile：{{ c.total }} 項技能
                <span class="sub small">{{ Object.entries(c.byTier).map(([k, v]) => k + ' ' + v).join('、') }}｜{{ Object.entries(c.byTrust).map(([k, v]) => k + ' ' + v).join('、') }}</span></h4>
                <div class="row"><span v-for="s in c.top" :key="s.name" class="chip">{{ s.name }} <span class="lv">{{ s.tier }}</span> <span class="pill" :class="trustColor(s.trust)">{{ s.trustLabel }}</span></span><router-link to="/profile" class="small">看全部與證據 →</router-link></div></div>
              <div v-else-if="c.type === 'competitions'" class="acard"><h4><span class="pill blue">競賽 Agent</span>推薦競賽 <span class="sub small">可報名 {{ c.totalEligible }} 筆（已截止 {{ c.skipped.closed }}、學制不符 {{ c.skipped.ineligible }}、技能無交集 {{ c.skipped.unrelated }}）</span></h4>
                <CompetitionCard v-for="x in c.recommended" :key="x.id" :c="x"><div class="suggest" style="margin-top:6px" v-if="i === lastCardIndex(m, 'competitions') && !busy"><button @click="send('幫我找「' + (x.shortName || x.name) + '」的隊友')">找這個競賽的隊友</button><button @click="send('「' + (x.shortName || x.name) + '」誰可以指導？')">找指導老師</button></div></CompetitionCard>
                <div v-if="!c.recommended.length" class="sub small">目前沒有符合資格、與你的技能相關且還能報名的競賽。</div><AgentTrace :lines="c.trace" /></div>
              <div v-else-if="c.type === 'competition'" class="acard"><h4><span class="pill blue">競賽 Agent</span>競賽評估</h4><CompetitionCard :c="c" show-reasons />
                <div class="sub small" style="margin-top:6px">資料查證日 {{ c.checkedAt }}，日期與資格以<a :href="c.url || c.sourceUrl" target="_blank" rel="noopener">官方公告</a>為準。</div></div>
              <div v-else-if="c.type === 'competition_list'" class="acard"><h4><span class="pill blue">競賽 Agent</span>搜尋「{{ c.keyword }}」：{{ c.items.length }} 筆</h4><CompetitionCard v-for="x in c.items" :key="x.id" :c="x" /></div>
              <div v-else-if="c.type === 'teammates'" class="acard"><h4><span class="pill green">學生 Agent</span>互補隊友 <span class="sub small">團隊缺口 {{ c.gaps.length }} 項 · 候選人 {{ c.totalCandidates }} 位</span></h4><TeammatesCard :data="c" :limit="4" /></div>
              <div v-else-if="c.type === 'teachers'" class="acard"><h4><span class="pill purple">教師 Agent</span>指導老師 <span class="sub small">專長相符 {{ c.totalMatched }} 位</span></h4><TeachersCard :data="c" /></div>
              <ActionCard v-else-if="c.type === 'action'" :card="c" @changed="loadSessions" />
            </template>
          </div>
          <div class="row between" style="margin-top:12px" v-if="m.status !== 'RUNNING'">
            <div class="row"><span class="sub small">這則回覆有幫助嗎？</span><button class="btn ghost sm" :style="m.feedback === 1 ? 'font-weight:800' : ''" @click="feedback(m, 1)">有幫助</button><button class="btn ghost sm" :style="m.feedback === -1 ? 'font-weight:800' : ''" @click="feedback(m, -1)">沒幫助</button></div>
            <a href="#" class="small" @click.prevent="downloadTrace">下載這個對話的操作軌跡（JSON）</a>
          </div>
        </div>
      </template>
      <div ref="bottom"></div>
      <form class="card row" style="position:sticky;bottom:12px;padding:12px;flex-wrap:nowrap" @submit.prevent="send(text)">
        <input v-model="text" :disabled="busy" placeholder="例如：我想參加比賽，幫我規劃；幫我找互補的隊友；誰可以指導？" maxlength="2000" />
        <button class="btn" :disabled="busy || !text.trim()" style="white-space:nowrap">{{ busy ? '執行中…' : '送出' }}</button>
      </form>
    </div>
  </div>
</template>
<script setup>
import { ref, computed, onMounted, onBeforeUnmount, nextTick } from 'vue'
import { get, post, del } from '../api'
import { store, labels, trustColor } from '../store'
import CompetitionCard from '../components/CompetitionCard.vue'
import TeammatesCard from '../components/TeammatesCard.vue'
import TeachersCard from '../components/TeachersCard.vue'
import ActionCard from '../components/ActionCard.vue'
import AgentTrace from '../components/AgentTrace.vue'
const st = ref(null), sessions = ref([]), sid = ref(null), messages = ref([]), text = ref(''), busy = ref(false), bottom = ref(null)
const starters = ['我想參加比賽，幫我規劃', '我的技能強弱項是什麼？', '推薦我可以參加的比賽', '幫我找互補的隊友', '誰可以指導？']
const toolGroups = computed(() => { const g = {}; for (const t of st.value?.tools || []) (g[t.agent] ||= []).push(t.name); return g })
const lastCardIndex = (m, type) => m.cards.map(c => c.type).lastIndexOf(type)
let timer = null, alive = true
const scroll = () => nextTick(() => bottom.value?.scrollIntoView({ behavior: 'smooth', block: 'end' }))
async function loadSessions() { sessions.value = await get('/assistant/sessions'); st.value = await get('/assistant/status') }
async function openSession(id) { sid.value = id; messages.value = (await get('/assistant/sessions/' + id)).messages; scroll(); const run = messages.value.find(m => m.status === 'RUNNING'); if (run) { busy.value = true; poll(run.id) } }
function newSession() { sid.value = null; messages.value = [] }
async function removeSession(s) {
  if (!confirm(`刪除對話「${s.title || '未命名'}」？訊息與執行軌跡會一併刪除，無法復原。`)) return
  try { await del('/assistant/sessions/' + s.id); if (sid.value === s.id) newSession(); sessions.value = await get('/assistant/sessions') } catch (e) { store.notify(e.message, 'error') }
}
async function send(q) {
  q = (q || '').trim(); if (!q || busy.value) return
  busy.value = true; text.value = ''
  try {
    const r = await post('/assistant/messages', { sessionId: sid.value, text: q })
    sid.value = r.sessionId
    messages.value.push({ id: r.userMessageId, role: 'user', content: q }, { id: r.assistantMessageId, role: 'assistant', status: 'RUNNING', steps: [], cards: [], content: '' })
    scroll(); poll(r.assistantMessageId)
  } catch (e) { store.notify(e.message, 'error'); busy.value = false }
}
// 助理在背景執行：每 0.6 秒取一次進度，工具呼叫軌跡與卡片會逐步出現
function poll(id) {
  clearTimeout(timer)
  timer = setTimeout(async () => {
    if (!alive) return
    try {
      const m = await get('/assistant/messages/' + id), i = messages.value.findIndex(x => x.id === id)
      const grew = i >= 0 && ((m.steps || []).length !== (messages.value[i].steps || []).length || m.status !== messages.value[i].status)
      if (i >= 0) messages.value[i] = { ...m, _open: m.status === 'RUNNING' ? true : (m.steps || []).length <= 6 }
      if (grew) scroll()
      if (m.status === 'RUNNING') poll(id); else { busy.value = false; loadSessions() }
    } catch (e) { busy.value = false; store.notify(e.message, 'error') }
  }, 600)
}
async function feedback(m, v) { try { await post(`/assistant/messages/${m.id}/feedback`, { value: v }); m.feedback = v; store.notify('已記錄，謝謝', 'success') } catch (e) { store.notify(e.message, 'error') } }
async function downloadTrace() {
  const t = await get(`/assistant/sessions/${sid.value}/trace`)
  const a = document.createElement('a'); a.href = URL.createObjectURL(new Blob([JSON.stringify(t, null, 2)], { type: 'application/json' })); a.download = `agent-trace-${sid.value}.json`; a.click()
}
onMounted(async () => { await store.loadMeta(); await loadSessions() })
onBeforeUnmount(() => { alive = false; clearTimeout(timer) })
</script>
