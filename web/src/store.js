import { reactive } from 'vue'
import { get, setToken, token } from './api'

// 極簡全域狀態：登入者、參考資料、通知未讀數
export const store = reactive({
  user: null, meta: null, unread: 0, toast: null,
  async loadMe() {
    if (!token()) { this.user = null; return null }
    try { this.user = await get('/me'); this.unread = this.user.unreadNotifications || 0 } catch { this.user = null }
    return this.user
  },
  async loadMeta() { if (!this.meta) this.meta = await get('/meta'); return this.meta },
  logout() { setToken(null); this.user = null; location.hash = '#/login' },
  notify(message, kind = 'info') { this.toast = { message, kind, id: Date.now() }; setTimeout(() => { if (this.toast && Date.now() - this.toast.id >= 3500) this.toast = null }, 3600) },
})

export const labels = {
  type: { PROJECT: '專題', COMPETITION: '競賽', SHORT_TERM: '短期支援', RESEARCH: '研究協作' },
  status: { DRAFT: '草稿', OPEN: '招募中', FORMED: '已成案', IN_PROGRESS: '執行中', CLOSING: '結案確認中', CLOSED: '已結案', CANCELLED: '已取消', EXPIRED: '截止未成案' },
  eng: { PENDING: '待回覆', ACCEPTED: '已成立', DECLINED: '已拒絕', WITHDRAWN: '已撤回', EXPIRED: '逾時放棄', FULL: '額滿' },
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
export const bandsText = (bands) => (bands || []).filter(b => !b.degreeGroup || b.degreeGroup === 'BACHELOR').map((b, i, a) => `${b.name} ${b.minScore}–${a[i + 1] ? a[i + 1].minScore - 1 : 100}`).join('、')
export const fmtDate = (s) => s ? String(s).slice(0, 10) : ''
export const fmtTime = (s) => s ? new Date(s).toLocaleString('zh-TW', { hour12: false, month: '2-digit', day: '2-digit', hour: '2-digit', minute: '2-digit' }) : ''
export const hoursLeft = (s) => s ? Math.max(0, Math.round((new Date(s) - Date.now()) / 36e5)) : 0
export const statusColor = (st) => ({ OPEN: 'blue', FORMED: 'green', IN_PROGRESS: 'green', CLOSING: 'orange', CLOSED: 'purple', CANCELLED: 'red', EXPIRED: 'red' }[st] || '')
