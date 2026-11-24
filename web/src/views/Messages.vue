<template>
  <div class="msg-page" :class="{ open: !!currentId }">
    <div class="head" style="margin-bottom:18px"><div><h1>訊息</h1><p class="sub">申請、邀請和隊伍群組都在這裡，新訊息會即時出現。</p></div></div>

    <div class="im" :class="{ open: !!currentId }">
      <!-- 對話列表 -->
      <div class="im-list" aria-label="對話列表">
        <label style="margin:0"><span class="sr">搜尋對話或成員</span><input v-model="kw" type="search" placeholder="搜尋對話或成員" /></label>
        <div v-if="!store.convLoaded" class="empty">載入中…</div>
        <div v-else-if="!store.conversations.length" class="empty"><Squirrel pose="phone" :size="124" class="only-narrow" /><b>還沒有對話</b>申請加入一隊、開隊，或收到邀請之後，對話會出現在這裡。
          <div style="margin-top:12px"><router-link to="/" class="btn sm">去找隊友</router-link></div></div>
        <template v-for="g in groups" :key="g.key">
          <template v-if="g.items.length">
            <button v-if="g.key === 'ended'" type="button" class="im-item" style="align-items:center;margin-top:10px;border-top:1.5px solid var(--line);border-radius:0" :aria-expanded="showEnded" @click="showEnded = !showEnded">
              <span class="mid strong small">已結束的對話（{{ g.items.length }}）</span><Ico name="down" :size="18" :style="showEnded ? 'transform:rotate(180deg)' : ''" /></button>
            <h4 v-else>{{ g.label }}</h4>
            <template v-if="g.key !== 'ended' || showEnded">
              <button v-for="c in g.items" :key="c.id" type="button" class="im-item" :class="{ on: c.id === currentId }" @click="go(c.id)">
                <span v-if="c.kind === 'TEAM'" class="avatar team"><Ico name="team" :size="19" /></span><span v-else class="avatar ring">{{ initial(c.peer?.name) }}</span>
                <span class="mid"><span class="t">{{ c.kind === 'TEAM' ? c.team.title : c.peer?.name }}</span>
                  <span class="s" style="display:block">{{ subline(c) }}</span>
                  <span class="p" style="display:block">{{ previewOf(c) }}</span></span>
                <span class="end">{{ shortTime(c.lastMessageAt) }}<span v-if="c.unread" class="badge" style="border-color:#fff">{{ c.unread }}</span></span>
              </button>
            </template>
          </template>
        </template>
      </div>

      <!-- 對話內容 -->
      <div class="im-main">
        <div v-if="!currentId" class="empty" style="margin:auto"><Squirrel pose="phone" :size="156" />
          <template v-if="store.convLoaded && !store.conversations.length"><b>找到隊伍就能開始聊</b>申請、邀請和隊伍群組的訊息都會出現在這裡。</template>
          <template v-else><b>選一個對話</b>左邊是你的隊伍群組和洽談中的對話。</template></div>
        <div v-else-if="!conv" class="empty" style="margin:auto">載入中…</div>
        <template v-else>
          <div class="im-head">
            <div class="who">
              <button type="button" class="btn tiny white im-back" aria-label="回對話列表" @click="router.push('/messages')"><Ico name="back" :size="16" /></button>
              <template v-if="conv.kind === 'TEAM'">
                <span class="avatar team"><Ico name="team" :size="19" /></span><b>{{ conv.team.title }}</b>
                <span v-if="conv.competition" class="tag yellow">{{ conv.competition.name }}</span>
                <span v-if="team" class="tag" :class="statusTag(team.status)">{{ labels.status[team.status] }}{{ team.status === 'OPEN' ? ' · 還缺 ' + team.need + ' 人' : '' }}</span>
              </template>
              <template v-else>
                <span class="avatar ring">{{ initial(conv.peer?.name) }}</span><b>{{ conv.peer?.name }}</b>
                <span class="tag peach">{{ contextOf(conv) }}</span>
              </template>
            </div>
            <div class="row">
              <template v-if="conv.kind === 'TEAM'">
                <span class="row" style="gap:4px"><span v-for="m in conv.members.slice(0, 4)" :key="m.userId" class="avatar sm ring" :title="m.name">{{ initial(m.name) }}</span></span>
                <span class="small strong">{{ conv.members.length }}{{ team ? '／' + team.teamSize : '' }} 人</span>
                <router-link :to="'/teams/' + conv.team.id" class="btn sm white">成員與邀請</router-link>
              </template>
              <template v-else>
                <template v-if="conv.engagement.status === 'PENDING' && conv.engagement.role === 'RESPONDER'">
                  <button class="btn sm" :disabled="busy" @click="respond('accept')">接受</button>
                  <ConfirmButton question="婉拒後這個對話會改成唯讀。" yes="婉拒" :disabled="busy" @confirm="respond('decline')">婉拒</ConfirmButton>
                </template>
                <ConfirmButton v-else-if="conv.engagement.status === 'PENDING'" :question="conv.engagement.direction === 'INVITE' ? '要取消這筆邀請嗎？' : '要取消這筆申請嗎？'" :yes="conv.engagement.direction === 'INVITE' ? '取消邀請' : '取消申請'" :disabled="busy" @confirm="respond('withdraw')">{{ conv.engagement.direction === 'INVITE' ? '取消邀請' : '取消申請' }}</ConfirmButton>
                <router-link :to="'/teams/' + conv.team.id" class="btn sm white">看隊伍</router-link>
              </template>
            </div>
          </div>

          <RegistrationTrack v-if="conv.kind === 'TEAM' && team && ['OPEN', 'FORMED', 'IN_PROGRESS'].includes(team.status)" :team="team" @changed="(x) => team = x" />
          <div v-if="conv.kind === 'TALK' && conv.peer" class="im-strip">
            <span class="strong">{{ conv.peer.department }} {{ grade(conv.peer.degree, conv.peer.year) }}</span>
            <span v-for="s in (peer?.skills || []).slice(0, 4)" :key="s.skillId" class="tag line">{{ s.name }} {{ s.tier }}</span>
            <router-link :to="'/users/' + conv.peer.id" class="small strong" style="margin-left:auto">看完整檔案</router-link>
          </div>

          <div ref="bodyEl" class="im-body" role="log" aria-live="polite">
            <button v-if="hasMore" type="button" class="btn tiny white" style="align-self:center" :disabled="loadingOld" @click="loadOlder">看更早的訊息</button>
            <template v-for="m in rows" :key="m.key">
              <div v-if="m.day" class="im-sys">{{ m.day }}</div>
              <div v-else-if="m.kind === 'SYSTEM'" class="im-sys">{{ m.body }}<span class="t">{{ clock(m.createdAt) }}</span></div>
              <div v-else class="im-msg" :class="{ mine: m.senderId === store.user.id, sending: m.state === 'sending', failed: m.state === 'failed' }">
                <span class="by">{{ m.senderId === store.user.id ? '你' : m.senderName }} · {{ m.state === 'sending' ? '傳送中' : m.state === 'failed' ? '沒有送出' : clock(m.createdAt) }}</span>
                <p class="bubble">{{ m.deleted ? '（這則訊息已過保存期限）' : m.body }}</p>
                <span v-if="m.state === 'failed'" class="row small" style="gap:6px"><span class="urgent">{{ m.error }}</span><button type="button" class="btn tiny white" @click="resend(m)">再送一次</button><button type="button" class="btn tiny white" @click="drop(m)">刪掉</button></span>
              </div>
            </template>
            <div v-if="!rows.length" class="empty">還沒有訊息，打個招呼吧。</div>
          </div>

          <div v-if="noteText" class="im-note">{{ noteText }}</div>
          <form v-if="!conv.readOnly" class="im-foot" @submit.prevent="send">
            <label style="flex:1;margin:0"><span class="sr">輸入訊息</span>
              <textarea ref="inputEl" v-model="draft" rows="1" maxlength="2000" :placeholder="wide ? '輸入訊息…（Enter 傳送，Shift＋Enter 換行）' : '輸入訊息…'" @keydown.enter.exact="onEnter"></textarea></label>
            <button class="btn" :disabled="!draft.trim()">傳送</button>
          </form>
        </template>
      </div>
    </div>
  </div>
</template>
<script setup>
import { ref, computed, watch, nextTick, onMounted, onUnmounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { get, post } from '../api'
import { store, labels, initial, grade, shortTime, clock, statusTag, hoursLeft } from '../store'
import { onEvent } from '../realtime'
import Ico from '../components/Ico.vue'
import ConfirmButton from '../components/ConfirmButton.vue'
import RegistrationTrack from '../components/RegistrationTrack.vue'
import Squirrel from '../components/Squirrel.vue'

const route = useRoute(), router = useRouter()
const currentId = computed(() => route.params.id ? +route.params.id : null)
const conv = ref(null), msgs = ref([]), team = ref(null), peer = ref(null), hasMore = ref(false), loadingOld = ref(false)
const draft = ref(''), busy = ref(false), kw = ref(''), showEnded = ref(false), bodyEl = ref(null), inputEl = ref(null)
const PAGE = 50, wide = window.innerWidth > 760

// ---------- 列表 ----------
const groups = computed(() => {
  const k = kw.value.trim().toLowerCase()
  const all = store.conversations.filter(c => !k || (c.team.title + (c.peer?.name || '') + (c.competition?.name || '')).toLowerCase().includes(k))
  return [
    { key: 'team', label: '我的隊伍', items: all.filter(c => c.kind === 'TEAM' && !c.readOnly) },
    { key: 'talk', label: '洽談中', items: all.filter(c => c.kind === 'TALK' && !c.readOnly) },
    { key: 'ended', label: '已結束的對話', items: all.filter(c => c.readOnly) },
  ]
})
function contextOf(c) {
  const e = c.engagement, team = c.team.title
  if (e.status === 'PENDING') return e.direction === 'APPLY' ? (c.isOwner ? `申請加入 ${team}` : `你申請加入 ${team}`) : (c.isOwner ? `你邀請加入 ${team}` : `邀請你加入 ${team}`)
  return `${labels.eng[e.status] || e.status} · ${team}`
}
const subline = (c) => c.kind === 'TEAM' ? `${c.competition?.name || ''} · ${c.memberCount} 人` : contextOf(c) + (c.engagement.status === 'PENDING' ? ' · 等回覆' : '')
function previewOf(c) {
  const m = c.lastMessage
  if (!m) return ''
  if (m.deleted) return '（訊息已過保存期限）'
  return m.kind === 'SYSTEM' ? m.body : `${m.senderId === store.user.id ? '你' : m.senderName}：${m.body}`
}
const go = (id) => router.push('/messages/' + id)

// ---------- 開啟對話 ----------
async function open(id) {
  store.activeConversation = id
  conv.value = null; msgs.value = []; team.value = null; peer.value = null; hasMore.value = false; draft.value = ''
  if (!id) return
  try {
    const [d, m] = await Promise.all([get('/conversations/' + id), get(`/conversations/${id}/messages?limit=${PAGE}`)])
    if (currentId.value !== id) return                                  // 載入途中已經切到別的對話
    conv.value = d; msgs.value = m; hasMore.value = m.length === PAGE
    toBottom(); markRead()
    if (d.kind === 'TEAM') team.value = await get('/cases/' + d.team.id)
    else if (d.peer) peer.value = await get('/users/' + d.peer.id).catch(() => null)
  } catch (e) { if (currentId.value === id) { store.notify(e.status === 404 ? '找不到這個對話，可能已經離開隊伍' : e.message, 'error'); router.replace('/messages') } }
}
async function refresh() {
  const id = currentId.value
  if (!id || !conv.value) return
  try {
    const d = await get('/conversations/' + id)
    if (currentId.value !== id) return
    conv.value = d
    if (d.kind === 'TEAM') team.value = await get('/cases/' + d.team.id)
  } catch (e) { if (e.status === 404 && currentId.value === id) { store.notify('你已經不在這個對話', 'error'); router.replace('/messages') } }
}
/** 斷線重連或輪詢時，用最後一則訊息的編號把漏掉的補回來 */
async function catchUp() {
  const id = currentId.value
  if (!id || !conv.value) return
  const last = lastId()
  try { for (const m of await get(`/conversations/${id}/messages?after=${last}&limit=200`)) if (currentId.value === id) add(m) } catch { /* 下一次再補 */ }
}
const lastId = () => msgs.value.reduce((n, m) => typeof m.id === 'number' && m.id > n ? m.id : n, 0)
async function loadOlder() {
  const first = msgs.value.find(m => typeof m.id === 'number'), el = bodyEl.value
  if (!first) return
  loadingOld.value = true
  try {
    const old = await get(`/conversations/${currentId.value}/messages?before=${first.id}&limit=${PAGE}`)
    const h = el.scrollHeight
    msgs.value = [...old, ...msgs.value]; hasMore.value = old.length === PAGE
    await nextTick(); el.scrollTop += el.scrollHeight - h                // 畫面停在原來那一則
  } catch (e) { store.notify(e.message, 'error') } finally { loadingOld.value = false }
}

// ---------- 訊息 ----------
const rows = computed(() => {
  const out = []; let day = ''
  for (const m of msgs.value) {
    const d = new Date(m.createdAt), label = `${d.getMonth() + 1} 月 ${d.getDate()} 日`
    if (label !== day) { day = label; out.push({ key: 'd' + label + m.id, day: label }) }
    out.push({ ...m, key: m.id })
  }
  return out
})
/** 加一則訊息：依編號去重；自己剛送出、還在等回應的那一則用 clientId 對上 */
function add(m) {
  if (msgs.value.some(x => x.id === m.id)) return
  const temp = m.clientId ? msgs.value.findIndex(x => x.state && x.clientId === m.clientId) : -1
  if (temp >= 0) msgs.value.splice(temp, 1)
  const list = [...msgs.value, m]
  list.sort((a, b) => (typeof a.id === 'number' ? a.id : Infinity) - (typeof b.id === 'number' ? b.id : Infinity))
  const near = nearBottom()
  msgs.value = list
  if (near || m.senderId === store.user.id) toBottom()
  if (m.senderId !== store.user.id) markRead()
}
const nearBottom = () => { const el = bodyEl.value; return !el || el.scrollHeight - el.scrollTop - el.clientHeight < 120 }
const toBottom = () => nextTick(() => { const el = bodyEl.value; if (el) el.scrollTop = el.scrollHeight })
async function markRead() {
  const id = currentId.value, last = lastId()
  if (!id || !last || document.hidden) return
  const item = store.conversations.find(c => c.id === id)
  if (item) item.unread = 0
  try { await post(`/conversations/${id}/read`, { messageId: last }) } catch { /* 下一則訊息進來時會再標一次 */ }
}
function onEnter(e) { if (e.isComposing) return; e.preventDefault(); send() }       // 注音選字時的 Enter 不送出
const newClientId = () => (crypto.randomUUID ? crypto.randomUUID() : Date.now().toString(36) + Math.random().toString(36).slice(2)).slice(0, 40)
function send() {
  const body = draft.value.trim()
  if (!body || !conv.value || conv.value.readOnly) return
  const temp = { id: 'tmp-' + newClientId(), kind: 'TEXT', body, senderId: store.user.id, senderName: store.user.name, createdAt: new Date().toISOString(), state: 'sending' }
  temp.clientId = temp.id.slice(4)
  msgs.value = [...msgs.value, temp]; draft.value = ''; toBottom()
  deliver(temp, conv.value.id)
}
async function deliver(temp, convId) {
  try { const saved = await post(`/conversations/${convId}/messages`, { body: temp.body, clientId: temp.clientId }); if (currentId.value === convId) add(saved) }
  catch (e) {
    const i = msgs.value.findIndex(x => x.id === temp.id)
    if (i >= 0) msgs.value.splice(i, 1, { ...temp, state: 'failed', error: e.message })
    if (e.code === 'READ_ONLY') refresh()
  }
}
function resend(m) {                                                                 // 用同一個 clientId 重送：伺服器已經收到的話不會變成兩則
  const i = msgs.value.findIndex(x => x.id === m.id), again = { ...m, state: 'sending', error: null }
  if (i >= 0) msgs.value.splice(i, 1, again)
  deliver(again, conv.value.id)
}
const drop = (m) => { msgs.value = msgs.value.filter(x => x.id !== m.id) }

// ---------- 申請與邀請的回覆 ----------
async function respond(what) {
  busy.value = true
  try { await post(`/engagements/${conv.value.engagement.id}/${what}`); store.notify({ accept: '成為隊友了，隊伍群組已經加好', decline: '已婉拒', withdraw: '已取消' }[what], 'success'); await refresh(); store.loadConversations() }
  catch (e) { store.notify(e.reasons?.length ? `${e.message}：${e.reasons.join('；')}` : e.message, 'error'); refresh() } finally { busy.value = false }
}
const noteText = computed(() => {
  const c = conv.value
  if (!c) return ''
  if (c.readOnly) return c.kind === 'TEAM' ? '隊伍已經結束，這個群組只能看、不能再傳訊息。' : '這個對話已經結束，不能再傳訊息。'
  if (c.kind !== 'TALK' || c.engagement.status !== 'PENDING') return ''
  return c.engagement.role === 'RESPONDER' ? `接受後，${c.isOwner ? c.peer?.name + ' 會' : '你會'}加入隊伍群組；婉拒後這個對話改成唯讀。還有 ${hoursLeft(c.engagement.dueAt)} 小時可以回覆。`
    : `對方還有 ${hoursLeft(c.engagement.dueAt)} 小時可以回覆，逾時會自動失效。`
})

// ---------- 即時事件 ----------
const off = onEvent((ev) => {
  const id = currentId.value
  if (ev.type === 'message.new' && ev.conversationId === id && conv.value) add(ev.message)
  else if (ev.type === 'conversation.updated' && ev.conversationId === id) refresh()
  else if (ev.type === 'engagement.updated' && ev.conversationId === id) refresh()
  else if (ev.type === 'team.updated' && conv.value?.kind === 'TEAM' && ev.caseId === conv.value.team.id) refresh()
  else if (ev.type === 'resync' || ev.type === 'poll') catchUp()
})
const onVisible = () => { if (!document.hidden) markRead() }

/** 從通知或隊伍頁帶著 ?e=申請編號 進來：找到那一筆的洽談對話 */
async function openByEngagement(e) {
  let c = store.conversations.find(x => x.kind === 'TALK' && x.engagement.id === e)
  if (!c) c = (await store.loadConversations()).find(x => x.kind === 'TALK' && x.engagement.id === e)
  if (c) router.replace('/messages/' + c.id)
  else { store.notify('找不到這個對話', 'error'); router.replace('/messages') }
}
watch(currentId, open)
watch(() => route.query.e, (e) => { if (e) openByEngagement(+e) })
onMounted(async () => {
  document.addEventListener('visibilitychange', onVisible)
  if (!store.convLoaded) await store.loadConversations()
  if (route.query.e) return openByEngagement(+route.query.e)
  if (currentId.value) return open(currentId.value)
  // 寬螢幕直接打開第一個有未讀的對話；手機先看列表
  const first = store.conversations.find(c => c.unread) || store.conversations.find(c => !c.readOnly)
  if (first && wide) router.replace('/messages/' + first.id)
})
onUnmounted(() => { off(); document.removeEventListener('visibilitychange', onVisible); store.activeConversation = null })
</script>
