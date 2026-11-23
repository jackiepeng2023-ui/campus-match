// 即時連線：WebSocket 只負責收推送，寫入一律走 REST（《軟體工程架構 3.1》第 9 節）。
// 連線後第一則訊息送登入憑證；每 25 秒 ping；斷線後自動重連（1、2、4…最長 30 秒），
// 重連期間改成每 10 秒輪詢。重連成功時送出 resync 事件，畫面用最後一則訊息的編號補漏。
import { reactive } from 'vue'
import { token, wsUrl } from './api'

export const rt = reactive({ state: 'idle' })          // idle 未連線｜connecting 連線中｜open 已連線｜polling 輪詢備援
const listeners = new Set()
let ws = null, pingTimer = null, pongTimer = null, retryTimer = null, pollTimer = null, retry = 0, wanted = false

/** 訂閱事件；回傳取消訂閱的函式 */
export function onEvent(fn) { listeners.add(fn); return () => listeners.delete(fn) }
function emit(ev) { for (const fn of [...listeners]) { try { fn(ev) } catch (e) { console.error(e) } } }

function startPolling() {
  if (pollTimer) return
  rt.state = 'polling'
  pollTimer = setInterval(() => emit({ type: 'poll' }), 10_000)
}
function stopPolling() { clearInterval(pollTimer); pollTimer = null }
function clearTimers() { clearInterval(pingTimer); clearTimeout(pongTimer); clearTimeout(retryTimer); pingTimer = pongTimer = retryTimer = null }

function open() {
  if (!wanted || !token()) return
  let sock
  try { sock = new WebSocket(wsUrl()) } catch { return scheduleRetry() }
  ws = sock
  if (rt.state !== 'polling') rt.state = 'connecting'
  sock.onopen = () => sock.send(JSON.stringify({ type: 'auth', token: token() }))
  sock.onmessage = (e) => {
    let ev
    try { ev = JSON.parse(e.data) } catch { return }
    if (ev.type === 'ready') {
      const again = retry > 0 || rt.state === 'polling'
      retry = 0; stopPolling(); rt.state = 'open'
      clearInterval(pingTimer)
      pingTimer = setInterval(() => {
        if (sock.readyState !== WebSocket.OPEN) return
        sock.send(JSON.stringify({ type: 'ping' }))
        clearTimeout(pongTimer); pongTimer = setTimeout(() => sock.close(), 10_000)      // 10 秒沒回 pong 就當成斷線
      }, 25_000)
      emit({ type: 'resync', again })
    } else if (ev.type === 'pong') clearTimeout(pongTimer)
    else if (ev.type === 'error' && ev.code === 'UNAUTHORIZED') { wanted = false }       // 憑證失效：不再重連，API 的 401 會帶回登入頁
    else emit(ev)
  }
  sock.onclose = () => { if (ws === sock) { ws = null; clearTimers(); if (wanted) scheduleRetry() } }
  sock.onerror = () => { try { sock.close() } catch { /* 已經關了 */ } }
}

function scheduleRetry() {
  startPolling()
  const wait = Math.min(30_000, 1000 * 2 ** retry++)
  clearTimeout(retryTimer); retryTimer = setTimeout(open, wait)
}

export function connect() { if (wanted) return; wanted = true; retry = 0; open() }
export function disconnect() {
  wanted = false; clearTimers(); stopPolling(); rt.state = 'idle'
  if (ws) { const s = ws; ws = null; try { s.close() } catch { /* 已經關了 */ } }
}
// 分頁回到前景時，如果連線已經斷了就立刻重連，不等倒數
if (typeof document !== 'undefined') document.addEventListener('visibilitychange', () => { if (!document.hidden && wanted && !ws) { clearTimeout(retryTimer); open() } })
