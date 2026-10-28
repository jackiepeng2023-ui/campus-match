<template>
  <div class="picker">
    <div class="row" style="gap:8px;flex-wrap:wrap">
      <select v-model.number="sel.departmentId" style="max-width:300px" @change="reloadOptions">
        <optgroup v-for="c in colleges" :key="c.id" :label="c.name"><option v-for="d in c.depts" :key="d.id" :value="d.id">{{ d.name }}</option></optgroup>
      </select>
      <select v-model="sel.degree" style="max-width:110px" @change="reloadOptions"><option value="BACHELOR">學士</option><option value="MASTER">碩士</option><option value="PHD">博士</option></select>
      <select v-model.number="sel.entryYear" style="max-width:150px" @change="reload"><option v-for="y in options.years" :key="y" :value="y">{{ y }} 學年度入學</option></select>
      <div class="segment"><button v-for="t in tabs" :key="t.key" :class="{on: tab === t.key}" @click="tab = t.key; reload()">{{ t.label }}</button></div>
    </div>
    <p v-if="hint" class="sub small" style="margin:8px 0 0">{{ hint }}</p>
    <div v-if="tab === 'SEARCH'" class="row" style="margin-top:10px"><input v-model="q" placeholder="輸入科目名稱或課程編碼，搜尋全校四個年度的科目表（外系選修）" @keyup.enter="reload" /><button class="btn sm secondary" @click="reload">搜尋</button></div>
    <p v-if="!loading && !rows.length" class="sub small" style="margin-top:12px">{{ tab === 'SEARCH' ? '輸入關鍵字後按搜尋' : '此年度沒有這類科目（校共同必修與通識自 115 學年度起為全校共用清單；之前年度列在各系科目表內）' }}</p>
    <table v-if="rows.length" style="margin-top:10px">
      <tr><th style="width:84px;white-space:nowrap">年級／學期</th><th>科目</th><th style="width:48px">學分</th><th style="min-width:120px">對應技能</th><th style="width:96px">學期</th><th style="width:84px">分數</th></tr>
      <tr v-for="r in rows" :key="r.id" :class="{ filled: r.score !== '' && r.score !== null }">
        <td class="small muted">{{ r.gradeYear ? r.gradeYear + '年' + (r.term ? ' ' + r.term + '學期' : '') : '—' }}</td>
        <td>{{ r.name }} <span class="sub small" v-if="r.code">{{ r.code }}</span><span class="pill" style="margin-left:6px" :class="reqClass(r.requirement)">{{ reqLabel(r.requirement) }}</span>
          <span class="sub small" v-if="r.groupCode">（{{ r.groupCode }}）</span><div class="sub small" v-if="tab === 'SEARCH'">{{ r.department || '校共同／通識' }} · {{ r.entryYear }} 學年度 · {{ labelDegree(r.degree) }}</div></td>
        <td class="small muted">{{ r.credits ?? '—' }}</td>
        <td class="small">
          <span v-if="r.skills" class="sub">{{ r.skills }}</span>
          <span v-if="r.pendingSkills" class="sub muted">（待核准：{{ r.pendingSkills }}）</span>
          <select v-if="!r.skills" v-model.number="r.pickSkill" style="max-width:170px;padding:4px 8px;font-size:12px"><option :value="null">尚無對照，自填技能…</option><option v-for="sk in skills" :key="sk.id" :value="sk.id">{{ sk.category }}｜{{ sk.name }}</option></select>
        </td>
        <td><input v-model="r.semester" placeholder="自動" style="padding:6px 8px;font-size:13px;min-width:76px" /></td>
        <td><input v-model.number="r.score" type="number" min="0" max="100" placeholder="—" style="padding:6px 8px;font-size:13px;min-width:64px" /></td>
      </tr>
    </table>
    <div class="row between" style="margin-top:10px" v-if="rows.length">
      <span class="sub small">已填 {{ changed.length }} 筆未儲存{{ changed.length ? '：' + changed.map(r => r.name).slice(0, 4).join('、') + (changed.length > 4 ? '…' : '') : '' }}；分數只有你本人可見，自填的技能對照須經管理員核准後才計入排序</span>
      <button class="btn sm" :disabled="!changed.length || saving" @click="save">儲存 {{ changed.length }} 筆分數</button>
    </div>
  </div>
</template>
<script setup>
import { ref, computed, onMounted } from 'vue'
import { get, put } from '../api'
import { store, labels } from '../store'
const props = defineProps({ me: { type: Object, required: true } })
const emit = defineEmits(['saved'])
const tabs = [{ key: 'REQUIRED', label: '必修' }, { key: 'ELECTIVE', label: '選修' }, { key: 'GENERAL', label: '校共同・通識' }, { key: 'SEARCH', label: '搜尋全校' }]
const sel = ref({ departmentId: props.me.departmentId, degree: props.me.degree, entryYear: null })
const options = ref({ years: [] }), tab = ref('REQUIRED'), q = ref(''), rows = ref([]), loading = ref(false), saving = ref(false)
const skills = computed(() => store.meta?.skills || [])
const colleges = computed(() => { const m = {}; for (const d of store.meta?.departments || []) { (m[d.collegeId] ||= { id: d.collegeId, name: d.college, depts: [] }).depts.push(d) } return Object.values(m) })
const hint = computed(() => {
  if (!options.value.years?.length) return '這個系所／學制尚無科目表，可用「搜尋全校」找科目，或請管理員補登'
  if (props.me.entryYear && !options.value.years.includes(props.me.entryYear) && sel.value.departmentId === props.me.departmentId) return `你的入學學年度 ${props.me.entryYear} 尚無科目表，顯示最接近的 ${options.value.nearestYear} 學年度；可切換其他年度`
  return ''
})
const changed = computed(() => rows.value.filter(r => r.score !== '' && r.score !== null && r.score !== undefined && (r.score !== r.myScore || (r.semester || '') !== (r.mySemester || '') || r.pickSkill)))
const reqLabel = (r) => ({ REQUIRED: '必修', ELECTIVE: '選修', GENERAL: '通識' }[r] || r), reqClass = (r) => ({ REQUIRED: 'blue', ELECTIVE: '', GENERAL: 'purple' }[r] || '')
const labelDegree = (d) => labels.degree[d] || d
function defaultSemester(r) { const base = props.me.entryYear || store.meta?.currentAcademicYear || 115; return r.gradeYear ? `${base + r.gradeYear - 1}-${r.term || 1}` : '' }
async function reloadOptions() { options.value = await get(`/courses/options?departmentId=${sel.value.departmentId}&degree=${sel.value.degree}`); sel.value.entryYear = options.value.nearestYear; await reload() }
async function reload() {
  loading.value = true
  try {
    const list = tab.value === 'SEARCH' ? (q.value.trim() ? await get(`/courses?q=${encodeURIComponent(q.value.trim())}`) : [])
      : sel.value.entryYear ? await get(`/courses?departmentId=${sel.value.departmentId}&degree=${sel.value.degree}&entryYear=${sel.value.entryYear}&requirement=${tab.value}`) : []
    rows.value = list.map(r => ({ ...r, score: r.myScore ?? '', semester: r.mySemester || defaultSemester(r), pickSkill: null }))
  } catch (e) { store.notify(e.message, 'error') } finally { loading.value = false }
}
async function save() {
  saving.value = true
  try {
    await put('/me/grades', changed.value.map(r => ({ courseId: r.id, score: r.score, semester: r.semester || null, skillIds: r.pickSkill ? [r.pickSkill] : [] })))
    store.notify(`已儲存 ${changed.value.length} 筆成績，技能預設等級已重算`, 'success'); emit('saved'); await reload()
  } catch (e) { store.notify(e.message, 'error') } finally { saving.value = false }
}
onMounted(async () => { await store.loadMeta(); await reloadOptions() })
</script>
<style scoped>
.picker { overflow-x: auto; }
.picker tr.filled td { background: #f3f9ff; }
.picker td { vertical-align: top; }
.picker input[type=number] { text-align: center; }
</style>
