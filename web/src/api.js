// REST 客戶端：網頁與 iOS 共用同一套 API（/api/v1）
const BASE = (import.meta.env.VITE_API_BASE || '') + '/api/v1'

export function token() { return localStorage.getItem('token') }
export function setToken(t) { t ? localStorage.setItem('token', t) : localStorage.removeItem('token') }

export async function api(method, path, body) {
  const headers = { 'Content-Type': 'application/json' }
  const t = token()
  if (t) headers.Authorization = 'Bearer ' + t
  const res = await fetch(BASE + path, { method, headers, body: body === undefined ? undefined : JSON.stringify(body) })
  if (res.status === 204) return null
  const data = await res.json().catch(() => null)
  if (!res.ok) {
    if (res.status === 401 && !path.startsWith('/auth/')) { setToken(null); location.hash = '#/login' }
    const err = new Error((data && data.message) || `HTTP ${res.status}`)
    err.status = res.status; err.code = data && data.code; err.reasons = (data && data.reasons) || []
    throw err
  }
  return data
}
export const get = (p) => api('GET', p)
export const post = (p, b = {}) => api('POST', p, b)
export const put = (p, b) => api('PUT', p, b)
export const del = (p) => api('DELETE', p)
