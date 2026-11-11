<template>
  <div class="kg">
    <div class="row between" style="flex-wrap:wrap;gap:8px">
      <div class="row" style="gap:10px;flex-wrap:wrap">
        <label v-for="t in TYPES" :key="t.key" class="kg-legend" :class="{ off: hidden.has(t.key) }" @click.prevent="toggle(t.key)">
          <i :style="{ background: t.color }"></i>{{ t.label }} <span class="muted">{{ counts[t.key] || 0 }}</span></label>
      </div>
      <div class="row" style="gap:6px">
        <button class="btn ghost sm" @click="layout(true)">重新排列</button>
        <button class="btn secondary sm" :disabled="exporting" @click="exportVault">{{ exporting ? '匯出中…' : '匯出 Obsidian Vault' }}</button>
      </div>
    </div>
    <div class="kg-stage" ref="stage">
      <canvas ref="canvas" @pointerdown="onDown" @pointermove="onMove" @pointerup="onUp" @pointercancel="onUp" @pointerleave="hover = null; draw()" @wheel.prevent="onWheel" @dblclick="selected = null; draw()"></canvas>
      <div v-if="!nodes.length && loaded" class="kg-empty">還沒有資料：先到「我的檔案」從科目清單填分數，技能等級與圖譜會自動生成。</div>
      <div v-if="selected" class="kg-panel">
        <div class="row between"><strong :style="{ color: colorOf(selected.type) }">{{ typeLabel(selected.type) }}</strong><button class="btn ghost sm" @click="selected = null; draw()">✕</button></div>
        <h3 style="margin:4px 0 6px">{{ selected.label }}</h3>
        <div class="small" v-html="detail(selected)"></div>
        <div class="small sub" style="margin-top:8px">相連：{{ neighborsOf(selected).map(n => n.label).join('、') || '—' }}</div>
      </div>
    </div>
    <p class="sub small" style="margin:8px 0 0">科目（藍）換算成技能（綠），技能歸入分類（紫）；得獎（橘）與結案案件（灰）連到它們驗證過的技能。拖曳節點、滾輪縮放、點一下聚焦、雙擊取消；匯出的 Vault 在 Obsidian 以「Open folder as vault」開啟，Graph view 即為同一張圖。</p>
  </div>
</template>
<script setup>
import { ref, computed, onMounted, onBeforeUnmount } from 'vue'
import { get, download } from '../api'
import { store } from '../store'
const TYPES = [
  { key: 'COURSE', label: '科目', color: '#0a84ff' }, { key: 'SKILL', label: '技能', color: '#34c759' }, { key: 'CATEGORY', label: '分類', color: '#5e5ce6' },
  { key: 'CREDENTIAL', label: '證照與作品', color: '#30b0c7' }, { key: 'AWARD', label: '得獎', color: '#ff9f0a' }, { key: 'CASE', label: '結案案件', color: '#8e8e93' }]
const LEN = { GRADE: 60, CATEGORY: 95, AWARD: 70, CASE: 70, CREDENTIAL: 65 }
const stage = ref(null), canvas = ref(null)
const nodes = ref([]), edges = ref([]), hidden = ref(new Set()), hover = ref(null), selected = ref(null), loaded = ref(false), exporting = ref(false)
const counts = computed(() => { const c = {}; for (const n of nodes.value) c[n.type] = (c[n.type] || 0) + 1; return c })
let ctx, W = 0, H = 0, dpr = 1, view = { k: 1, tx: 0, ty: 0 }, drag = null, raf = 0, alpha = 0, ro
const colorOf = (t) => TYPES.find(x => x.key === t)?.color || '#999'
const typeLabel = (t) => TYPES.find(x => x.key === t)?.label || t
const visible = () => nodes.value.filter(n => !hidden.value.has(n.type))
const visEdges = () => edges.value.filter(e => !hidden.value.has(e.s.type) && !hidden.value.has(e.t.type))
function radius(n) {
  if (n.type === 'CATEGORY') return 15
  if (n.type === 'SKILL') return 6 + (n.data.level || 0) * 2.4
  if (n.type === 'COURSE') return 4 + (n.data.score || 60) / 22
  return 8
}
function neighborsOf(n) { const out = []; for (const e of edges.value) { if (e.s === n) out.push(e.t); else if (e.t === n) out.push(e.s) } return out }
function detail(n) {
  const d = n.data, esc = (s) => String(s ?? '—').replace(/</g, '&lt;')
  if (n.type === 'COURSE') return `分數 <b>${esc(d.score)}</b>　學期 ${esc(d.semester)}　${{ REQUIRED: '必修', ELECTIVE: '選修', GENERAL: '通識' }[d.requirement] || ''}${d.department ? '　' + esc(d.department) : ''}${d.code ? '　' + esc(d.code) : ''}`
  if (n.type === 'SKILL') return `<b>${esc(d.tier)}</b>（${esc(d.score)} 分・${esc(d.trustLabel)}）　最高分證據：${esc(d.source)}，共 ${esc(d.evidenceCount)} 筆（不疊加）　分類 ${esc(d.category)}`
  if (n.type === 'CATEGORY') return `平均 <b>${esc(d.avgScore)}</b> 分　${esc(d.n)} 項技能`
  if (n.type === 'CREDENTIAL') return `${esc(d.kind)}　${esc(d.tier)}（${d.verified ? '已驗證' : '自述，尚未驗證'}）　${esc(d.issuer || '')} ${esc(d.date || '')}`
  if (n.type === 'AWARD') return `${{ CAMPUS: '校內', NATIONAL: '全國', INTERNATIONAL: '國際' }[d.level] || ''}・${{ FIRST: '第一名', TOP3: '前三名', HONORABLE: '佳作', FINALIST: '入圍' }[d.rank] || ''}　${esc(d.date)}　得獎分 +${esc(d.score)}`
  return `角色 ${esc(d.role)}　${d.result === 'COMPLETED' ? '完成' : '未完成'}　結案 ${esc((d.closedAt || '').slice(0, 10))}`
}
async function load() {
  const g = await get('/me/growth/graph')
  const byId = {}
  nodes.value = g.nodes.map((n, i) => { const a = i * 2.39996; const r = 40 + Math.sqrt(i) * 28; return (byId[n.id] = { ...n, x: Math.cos(a) * r, y: Math.sin(a) * r, vx: 0, vy: 0, fixed: false }) })
  edges.value = g.edges.map(e => ({ s: byId[e.source], t: byId[e.target], kind: e.kind, w: e.weight, len: LEN[e.kind] || 80 })).filter(e => e.s && e.t)
  loaded.value = true
  layout(false)
}
function tick(a) {
  const ns = visible(), es = visEdges()
  for (let i = 0; i < ns.length; i++) for (let j = i + 1; j < ns.length; j++) {
    const p = ns[i], q = ns[j]; let dx = q.x - p.x, dy = q.y - p.y; let d2 = dx * dx + dy * dy; if (d2 < 1) { dx = (Math.random() - .5); dy = (Math.random() - .5); d2 = 1 }
    const f = (1100 * a) / d2; const fx = dx * f, fy = dy * f
    if (!p.fixed) { p.vx -= fx; p.vy -= fy } if (!q.fixed) { q.vx += fx; q.vy += fy }
  }
  for (const e of es) {
    const dx = e.t.x - e.s.x, dy = e.t.y - e.s.y, d = Math.sqrt(dx * dx + dy * dy) || 1, f = (d - e.len) * 0.09 * a; const fx = dx / d * f, fy = dy / d * f
    if (!e.s.fixed) { e.s.vx += fx; e.s.vy += fy } if (!e.t.fixed) { e.t.vx -= fx; e.t.vy -= fy }
  }
  for (const n of ns) {
    if (n.fixed) continue
    const g = n.type === 'CATEGORY' ? 0.09 : 0.045
    n.vx -= n.x * g * a; n.vy -= n.y * g * a
    n.vx *= 0.8; n.vy *= 0.8; n.x += n.vx; n.y += n.vy
  }
}
function layout(reset) {
  if (reset) nodes.value.forEach((n, i) => { const a = i * 2.39996; const r = 40 + Math.sqrt(i) * 28; n.x = Math.cos(a) * r; n.y = Math.sin(a) * r; n.vx = n.vy = 0; n.fixed = false })
  for (let i = 0; i < 320; i++) tick(1 - i / 340)
  fit(); draw()
}
function fit() {
  const ns = visible(); if (!ns.length || !W) return
  const xs = ns.map(n => n.x), ys = ns.map(n => n.y), minX = Math.min(...xs) - 60, maxX = Math.max(...xs) + 60, minY = Math.min(...ys) - 40, maxY = Math.max(...ys) + 40
  view.k = 0.88 * Math.min(1.6, Math.max(0.25, Math.min(W / (maxX - minX), H / (maxY - minY)))); view.tx = W / 2 - (minX + maxX) / 2 * view.k; view.ty = H / 2 - (minY + maxY) / 2 * view.k
}
function draw() {
  if (!ctx) return
  ctx.setTransform(dpr, 0, 0, dpr, 0, 0); ctx.clearRect(0, 0, W, H)
  ctx.translate(view.tx, view.ty); ctx.scale(view.k, view.k)
  const focus = selected.value || hover.value, nb = focus ? new Set([focus, ...neighborsOf(focus)]) : null, few = visible().length <= 70
  for (const e of visEdges()) {
    const lit = !nb || (nb.has(e.s) && nb.has(e.t) && (e.s === focus || e.t === focus))
    ctx.strokeStyle = lit ? (nb ? 'rgba(255,255,255,.55)' : 'rgba(255,255,255,.16)') : 'rgba(255,255,255,.05)'; ctx.lineWidth = (lit && nb ? 1.6 : 1) / view.k
    ctx.beginPath(); ctx.moveTo(e.s.x, e.s.y); ctx.lineTo(e.t.x, e.t.y); ctx.stroke()
  }
  for (const n of visible()) {
    const dim = nb && !nb.has(n), r = radius(n) / view.k
    ctx.globalAlpha = dim ? 0.18 : 1
    ctx.beginPath(); ctx.arc(n.x, n.y, r, 0, Math.PI * 2); ctx.fillStyle = colorOf(n.type); ctx.fill()
    if (n === focus) { ctx.strokeStyle = '#fff'; ctx.lineWidth = 2 / view.k; ctx.stroke() }
    const showLabel = n.type === 'CATEGORY' || n.type === 'SKILL' || few || view.k >= 1.1 || (nb && nb.has(n))
    if (showLabel && !dim) {
      const fs = (n.type === 'CATEGORY' ? 13 : n.type === 'SKILL' ? 12 : 11) / view.k
      ctx.font = `${n.type === 'CATEGORY' ? 'bold ' : ''}${fs}px -apple-system, "PingFang TC", "Noto Sans TC", sans-serif`
      ctx.fillStyle = n.type === 'CATEGORY' ? '#fff' : 'rgba(255,255,255,.85)'; ctx.textAlign = 'center'; ctx.textBaseline = 'top'
      ctx.fillText(n.label.length > 14 ? n.label.slice(0, 13) + '…' : n.label, n.x, n.y + r + 3 / view.k)
    }
    ctx.globalAlpha = 1
  }
}
function toWorld(ev) { const b = canvas.value.getBoundingClientRect(); return { x: (ev.clientX - b.left - view.tx) / view.k, y: (ev.clientY - b.top - view.ty) / view.k } }
function hit(p) { let best = null, bd = 1e9; for (const n of visible()) { const d = Math.hypot(n.x - p.x, n.y - p.y) - radius(n) / view.k; if (d < 8 / view.k && d < bd) { bd = d; best = n } } return best }
function onDown(ev) { const p = toWorld(ev), n = hit(p); drag = { n, sx: ev.clientX, sy: ev.clientY, tx: view.tx, ty: view.ty, moved: false }; if (n) { n.fixed = true } canvas.value.setPointerCapture(ev.pointerId) }
function onMove(ev) {
  if (drag) {
    if (Math.hypot(ev.clientX - drag.sx, ev.clientY - drag.sy) > 3) drag.moved = true
    if (drag.n) { const p = toWorld(ev); drag.n.x = p.x; drag.n.y = p.y; kick(0.25) } else { view.tx = drag.tx + ev.clientX - drag.sx; view.ty = drag.ty + ev.clientY - drag.sy; draw() }
  } else { const n = hit(toWorld(ev)); if (n !== hover.value) { hover.value = n; canvas.value.style.cursor = n ? 'pointer' : 'grab'; draw() } }
}
function onUp(ev) {
  if (!drag) return
  if (drag.n) { drag.n.fixed = false; if (!drag.moved) { selected.value = selected.value === drag.n ? null : drag.n } }
  drag = null; draw()
}
function onWheel(ev) { const b = canvas.value.getBoundingClientRect(), mx = ev.clientX - b.left, my = ev.clientY - b.top, f = ev.deltaY < 0 ? 1.12 : 1 / 1.12, k = Math.max(0.3, Math.min(4, view.k * f)); view.tx = mx - (mx - view.tx) * k / view.k; view.ty = my - (my - view.ty) * k / view.k; view.k = k; draw() }
function kick(a) { alpha = Math.max(alpha, a); if (!raf) raf = requestAnimationFrame(step) }
function step() { raf = 0; tick(alpha); draw(); alpha *= 0.94; if (alpha > 0.01) raf = requestAnimationFrame(step) }
function toggle(t) { const s = new Set(hidden.value); s.has(t) ? s.delete(t) : s.add(t); hidden.value = s; if (selected.value && s.has(selected.value.type)) selected.value = null; kick(0.6) }
function resize() { if (!stage.value) return; W = stage.value.clientWidth; H = Math.max(380, Math.min(560, Math.round(W * 0.55))); dpr = window.devicePixelRatio || 1; canvas.value.width = W * dpr; canvas.value.height = H * dpr; canvas.value.style.width = W + 'px'; canvas.value.style.height = H + 'px'; ctx = canvas.value.getContext('2d'); fit(); draw() }
async function exportVault() { exporting.value = true; try { await download('/me/growth/obsidian', 'growth-vault.zip'); store.notify('已下載 Obsidian Vault（zip）：解壓後在 Obsidian 選 Open folder as vault', 'success') } catch (e) { store.notify(e.message, 'error') } finally { exporting.value = false } }
onMounted(async () => { resize(); ro = new ResizeObserver(resize); ro.observe(stage.value); try { await load() } catch (e) { store.notify(e.message, 'error') } })
onBeforeUnmount(() => { ro?.disconnect(); if (raf) cancelAnimationFrame(raf) })
</script>
<style scoped>
.kg-stage { position: relative; margin-top: 10px; border-radius: 14px; overflow: hidden; background: #1c1c1e; }
.kg-stage canvas { display: block; touch-action: none; cursor: grab; }
.kg-legend { display: inline-flex; align-items: center; gap: 6px; font-size: 13px; cursor: pointer; user-select: none; padding: 3px 8px; border-radius: 8px; background: var(--bg); }
.kg-legend.off { opacity: .4; text-decoration: line-through; }
.kg-legend i { width: 10px; height: 10px; border-radius: 50%; display: inline-block; }
.kg-panel { position: absolute; right: 12px; top: 12px; width: min(300px, 70%); background: rgba(255,255,255,.96); border-radius: 12px; padding: 12px 14px; box-shadow: 0 6px 24px rgba(0,0,0,.25); }
.kg-empty { position: absolute; inset: 0; display: flex; align-items: center; justify-content: center; color: rgba(255,255,255,.7); font-size: 14px; padding: 24px; text-align: center; }
</style>
