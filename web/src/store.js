import { reactive } from 'vue'
import { get, setToken, token } from './api'

// 極簡全域狀態：登入者、參考資料、通知未讀數、對話列表（訊息分頁的紅點由它算）
let reloadTimer = null
export const store = reactive({
  user: null, meta: null, unread: 0, toast: null,
  conversations: [], convLoaded: false, activeConversation: null,
  get unreadMessages() { return this.conversations.reduce((n, c) => n + (c.unread || 0), 0) },
  async loadMe() {
    if (!token()) { this.user = null; return null }
    try { this.user = await get('/me'); this.unread = this.user.unreadNotifications || 0 } catch { this.user = null }
    return this.user
  },
  async loadMeta() { if (!this.meta) this.meta = await get('/meta'); return this.meta },
  async loadConversations() {
    if (!this.user) return []
    try { this.conversations = await get('/conversations'); this.convLoaded = true } catch { /* 下一次事件或輪詢再試 */ }
    return this.conversations
  },
  /** 短時間內來好幾個事件時只重新載入一次 */
  loadConversationsSoon() { clearTimeout(reloadTimer); reloadTimer = setTimeout(() => this.loadConversations(), 150) },
  async refreshUnread() { try { this.unread = (await get('/me/notifications')).unread } catch { /* 不影響畫面 */ } },
  logout() { setToken(null); this.user = null; this.conversations = []; this.convLoaded = false; location.hash = '#/login' },
  notify(message, kind = 'info') { this.toast = { message, kind, id: Date.now() }; setTimeout(() => { if (this.toast && Date.now() - this.toast.id >= 3500) this.toast = null }, 3600) },

  /** WebSocket 推送（或輪詢備援）進來的事件 */
  onRealtime(ev) {
    if (!this.user) return
    if (ev.type === 'message.new') {
      const c = this.conversations.find(x => x.id === ev.conversationId), m = ev.message
      if (!c) return this.loadConversationsSoon()
      c.lastMessage = { id: m.id, kind: m.kind, body: String(m.body || '').replace(/\s+/g, ' ').slice(0, 60), senderId: m.senderId, senderName: m.senderName, createdAt: m.createdAt }
      c.lastMessageAt = m.createdAt
      if (m.senderId !== this.user.id && this.activeConversation !== c.id) c.unread = (c.unread || 0) + 1
      this.conversations = [c, ...this.conversations.filter(x => x !== c)]
    } else if (['conversation.updated', 'engagement.updated', 'team.updated', 'resync', 'poll'].includes(ev.type)) this.loadConversationsSoon()
    if (ev.type === 'notification.new') { this.unread = ev.unread; this.notify(ev.notification.title) }
    if (ev.type === 'resync' || ev.type === 'poll') this.refreshUnread()
  },
})

export const labels = {
  type: { PROJECT: '專題', COMPETITION: '比賽', SHORT_TERM: '短期支援', RESEARCH: '研究協作' },
  status: { DRAFT: '草稿', OPEN: '招募中', FORMED: '已成隊', IN_PROGRESS: '已報名', CLOSING: '結束確認中', CLOSED: '已結束', CANCELLED: '已解散', EXPIRED: '截止未成隊' },
  eng: { PENDING: '等回覆', ACCEPTED: '已成為隊友', DECLINED: '已婉拒', WITHDRAWN: '已取消', EXPIRED: '逾時失效', FULL: '隊伍已成隊' },
  degree: { BACHELOR: '學士', MASTER: '碩士', PHD: '博士' },
  attribution: { AUTHORSHIP: '論文掛名', ACK: '致謝', NONE: '無' },
  level: { CAMPUS: '校內', NATIONAL: '全國', INTERNATIONAL: '國際' },
  rank: { FIRST: '第一名', TOP3: '前三名', HONORABLE: '佳作', FINALIST: '入圍' },
  factor: { S: '技能符合', T: '時間配合', R: '評價', P: '回應率', C: '跨系互補' },
  tier: ['未達初階', '初階', '中階', '進階'],                                   // D53 三階等級（門檻見 /meta 的 levelBands）
  trust: { VERIFIED: '已驗證', COURSE: '修課成績', SELF: '自述' },              // D54 可信狀態
  evidence: { COURSE: '課程', CERTIFICATE: '證照', PORTFOLIO: '作品集', COMPETITION: '競賽', CASE: '結案', SELF: '自評' },
  importance: { CORE: '核心', SUPPORT: '輔助' },
  agent: { PROFILE: '能力盤點', COMPETITION: '競賽 Agent', STUDENT: '學生 Agent', TEACHER: '教師 Agent', ACTION: '待確認動作', TOOL: '工具' },
  stop: { END_TURN: '完成', RULE: '完成', FALLBACK: 'API 失敗，改規則模式', MAX_STEPS: '達工具呼叫上限而中止', MAX_TOKENS: '回覆過長被截斷', REFUSAL: '模型拒答', ERROR: '錯誤' },
}
export const trustColor = (t) => ({ VERIFIED: 'green', COURSE: 'blue', SELF: 'orange', 已驗證: 'green', 修課成績: 'blue', 自述: 'orange' }[t] || '')
export const tierColor = (t) => ({ 3: 'purple', 2: 'blue', 1: '', 0: '', 進階: 'purple', 中階: 'blue' }[t] || '')
export const statusTag = (st) => ({ OPEN: 'peach', FORMED: 'green', IN_PROGRESS: 'green', CLOSED: 'grey', CANCELLED: 'grey', EXPIRED: 'grey' }[st] || '')
export const bandsText = (bands) => (bands || []).filter(b => !b.degreeGroup || b.degreeGroup === 'BACHELOR').map((b, i, a) => `${b.name} ${b.minScore}–${a[i + 1] ? a[i + 1].minScore - 1 : 100}`).join('、')
export const fmtDate = (s) => s ? String(s).slice(0, 10) : ''
export const fmtTime = (s) => s ? new Date(s).toLocaleString('zh-TW', { hour12: false, month: '2-digit', day: '2-digit', hour: '2-digit', minute: '2-digit' }) : ''
export const hoursLeft = (s) => s ? Math.max(0, Math.round((new Date(s) - Date.now()) / 36e5)) : 0
export const statusColor = (st) => ({ OPEN: 'blue', FORMED: 'green', IN_PROGRESS: 'green', CLOSING: 'orange', CLOSED: 'purple', CANCELLED: 'red', EXPIRED: 'red' }[st] || '')

// ---- 3.1 畫面用的小工具 ----
export const initial = (name) => (name || '?').trim().slice(0, 1)
/** 2026-11-30 → 11/30 */
export const md = (s) => { const m = /^\d{4}-(\d{2})-(\d{2})/.exec(String(s || '')); return m ? `${+m[1]}/${+m[2]}` : '' }
const WEEK = ['日', '一', '二', '三', '四', '五', '六']
export const mdw = (s) => { const m = /^(\d{4})-(\d{2})-(\d{2})/.exec(String(s || '')); return m ? `${+m[2]}/${+m[3]}（${WEEK[new Date(+m[1], +m[2] - 1, +m[3]).getDay()]}）` : '' }
export const leftText = (d) => d == null ? '' : d < 0 ? '已截止' : d === 0 ? '今天截止' : `剩 ${d} 天`
const NUM = ['', '一', '二', '三', '四', '五', '六', '七']
/** 學士三年級 → 三年級；碩士一年級 → 碩一；博士三年級 → 博三 */
export const grade = (degree, year) => degree === 'MASTER' ? '碩' + (NUM[year] || year) : degree === 'PHD' ? '博' + (NUM[year] || year) : (NUM[year] || year) + '年級'
/** 訊息列表右邊的時間：今天顯示時分，昨天顯示「昨天」，更早顯示月日 */
export const shortTime = (s) => {
  if (!s) return ''
  const d = new Date(s), now = new Date(), day = (x) => new Date(x.getFullYear(), x.getMonth(), x.getDate()).getTime()
  const diff = Math.round((day(now) - day(d)) / 864e5)
  if (diff === 0) return d.toLocaleTimeString('zh-TW', { hour12: false, hour: '2-digit', minute: '2-digit' })
  return diff === 1 ? '昨天' : `${d.getMonth() + 1}/${d.getDate()}`
}
export const clock = (s) => s ? new Date(s).toLocaleTimeString('zh-TW', { hour12: false, hour: '2-digit', minute: '2-digit' }) : ''
export const teamSizeText = (min, max) => max === 1 ? '個人賽' : min && max ? (min === max ? `${max} 人` : `${min}–${max} 人`) : max ? `最多 ${max} 人` : min ? `至少 ${min} 人` : '未公告'
