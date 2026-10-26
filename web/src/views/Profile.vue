<template>
  <div v-if="me">
    <div class="row between"><div><h1>我的檔案</h1><div class="sub">{{ me.studentNo }} · {{ me.college }}／{{ me.department }} · {{ labels.degree[me.degree] }}{{ me.year }}年級 · 預計畢業 {{ me.expectedGraduation }}</div></div>
      <router-link :to="'/users/' + me.id" class="btn secondary">別人看到的我</router-link></div>
    <div class="grid grid-2" style="margin-top:16px">
      <div class="stack">
        <div class="card">
          <h3>修課成績 <span class="sub small">只有你看得到；成績換算成技能預設等級（{{ me.degree === 'BACHELOR' ? '學士 90/80/70/60' : '碩博士 90/85/80/70' }}，D14）</span></h3>
          <table><tr><th>課程</th><th>學期</th><th>分數</th><th>對應技能</th><th></th></tr>
            <tr v-for="g in me.grades" :key="g.id"><td>{{ g.course }}</td><td class="small">{{ g.semester }}</td><td><strong>{{ g.score }}</strong></td><td class="sub small">{{ g.skills }}</td><td><button class="btn ghost sm" @click="run(() => del('/me/grades/' + g.id))">✕</button></td></tr></table>
          <form class="row" style="margin-top:10px" @submit.prevent="addGrade">
            <select v-model.number="ng.courseId" style="max-width:260px"><option v-for="co in courses" :key="co.id" :value="co.id">{{ co.name }}{{ co.skills ? '（' + co.skills + '）' : '' }}</option></select>
            <input v-model="ng.semester" placeholder="學期 115-1" style="max-width:110px" /><input v-model.number="ng.score" type="number" min="0" max="100" placeholder="分數" style="max-width:90px" /><button class="btn sm">新增</button>
          </form>
        </div>
        <div class="card">
          <h3>技能檔 <span class="sub small">預設等級來自成績；你可以調整，幅度會被記錄，由結案互評的「相符度」檢驗（D7、D10）</span></h3>
          <table><tr><th>技能</th><th>預設</th><th>目前等級</th><th>來源</th><th></th></tr>
            <tr v-for="s in me.skills" :key="s.skillId"><td>{{ s.name }} <span class="sub small">{{ s.category }}</span></td><td class="sub">{{ s.defaultLevel ?? '—' }}</td>
              <td><select :value="s.level" @change="setSkill(s.skillId, +$event.target.value)" style="max-width:80px"><option v-for="n in 5" :key="n" :value="n">{{ n }}</option></select></td>
              <td class="small"><span class="pill" :class="s.level !== s.defaultLevel && s.defaultLevel ? 'orange' : ''">{{ s.source === 'GRADE' ? (s.level !== s.defaultLevel ? '自評上調' : '成績') : '自填' }}</span></td>
              <td><button class="btn ghost sm" @click="run(() => del('/me/skills/' + s.skillId))">✕</button></td></tr></table>
          <form class="row" style="margin-top:10px" @submit.prevent="run(() => put('/me/skills', [ns]))">
            <select v-model.number="ns.skillId" style="max-width:260px"><option v-for="sk in store.meta?.skills" :key="sk.id" :value="sk.id">{{ sk.category }}｜{{ sk.name }}</option></select>
            <select v-model.number="ns.level" style="max-width:100px"><option v-for="n in 5" :key="n" :value="n">{{ n }} 級</option></select><button class="btn sm">自填技能</button>
          </form>
        </div>
      </div>
      <div class="stack">
        <div class="card">
          <h3>可投入時間 <span class="sub small">（時間閘門，D4）</span></h3>
          <form class="row" @submit.prevent="run(() => put('/me/availability', av))">
            <input v-model.number="av.hoursPerWeek" type="number" min="0" max="80" style="max-width:100px" /><span class="sub small">小時／週</span>
            <input v-model="av.availableFrom" type="date" style="max-width:160px" /><span class="sub small">～</span><input v-model="av.availableTo" type="date" style="max-width:160px" /><button class="btn sm">儲存</button>
          </form>
        </div>
        <div class="card">
          <h3>得獎紀錄 <span class="sub small">本身就是一種評價：R = 0.75×互評 + 0.25×得獎（D8、D41）</span></h3>
          <table><tr v-for="a in me.awards" :key="a.id"><td>{{ a.competition }}<div class="sub small">{{ a.skills }}</div></td><td class="small">{{ labels.level[a.level] }}・{{ labels.rank[a.rank] }} <span class="lv">+{{ a.score }}</span></td><td class="small">{{ a.awardDate }}</td><td><button class="btn ghost sm" @click="run(() => del('/me/awards/' + a.id))">✕</button></td></tr></table>
          <form class="grid grid-2" style="gap:8px;margin-top:10px" @submit.prevent="run(() => post('/me/awards', na))">
            <input v-model="na.competition" placeholder="競賽名稱" required />
            <input v-model="na.awardDate" type="date" required />
            <select v-model="na.level"><option v-for="(l, k) in labels.level" :key="k" :value="k">{{ l }}</option></select>
            <select v-model="na.rank"><option v-for="(l, k) in labels.rank" :key="k" :value="k">{{ l }}</option></select>
            <select v-model="na.skillIds" multiple style="grid-column:1/-1;height:80px"><option v-for="sk in store.meta?.skills" :key="sk.id" :value="sk.id">{{ sk.category }}｜{{ sk.name }}</option></select>
            <button class="btn sm" style="grid-column:1/-1">新增得獎</button>
          </form>
        </div>
        <div class="card">
          <h3>收到的評價</h3>
          <div v-if="reviews" class="sub small">累計：滿意度 {{ reviews.overall.satisfaction ?? '—' }} · 相符度 {{ reviews.overall.matchScore ?? '—' }} · 準時 {{ reviews.overall.onTime ?? '—' }} · 溝通 {{ reviews.overall.communication ?? '—' }}（{{ reviews.overall.n }} 筆）</div>
          <table v-if="reviews && reviews.cases.length" style="margin-top:8px"><tr v-for="r in reviews.cases" :key="r.caseId"><td>{{ r.title }}</td><td class="small" v-if="r.hidden"><span class="muted">{{ r.note }}</span></td><td class="small" v-else>滿意 {{ r.satisfaction }} · 相符 {{ r.matchScore }} · 準時 {{ r.onTime }} · 溝通 {{ r.communication }}<div class="sub" v-if="r.comments">「{{ r.comments }}」</div></td></tr></table>
        </div>
        <div class="card">
          <h3>畢業與資料保存 <span class="sub small">（D27–D29）</span></h3>
          <p class="sub small">畢業 3 個月後去識別化、6 個月後刪除本人資料；去識別化的案件與評價紀錄保留供統計。你也可以隨時刪除帳號。</p>
          <div class="row"><button class="btn secondary sm" @click="run(() => post('/me/graduation', { status: 'GRADUATED' }))">我已畢業</button><button class="btn danger sm" @click="deleteMe">刪除帳號</button></div>
        </div>
      </div>
    </div>
  </div>
</template>
<script setup>
import { ref, computed, onMounted } from 'vue'
import { get, put, post, del } from '../api'
import { store, labels } from '../store'
const me = ref(null), reviews = ref(null)
const ng = ref({ courseId: null, semester: '115-1', score: null }), ns = ref({ skillId: 1, level: 3 })
const av = ref({ hoursPerWeek: 8, availableFrom: '', availableTo: '' }), na = ref({ competition: '', level: 'CAMPUS', rank: 'TOP3', awardDate: '', skillIds: [] })
const courses = computed(() => (store.meta?.courses || []).filter(c => c.departmentId === me.value.departmentId || c.departmentId === null || true))
async function load() { me.value = await get('/me'); store.user = me.value; reviews.value = await get('/me/reviews'); av.value = { ...me.value.availability }; if (!ng.value.courseId && courses.value.length) ng.value.courseId = courses.value[0].id }
async function run(fn) { try { await fn(); store.notify('已更新', 'success'); await load() } catch (e) { store.notify(e.message, 'error') } }
const addGrade = () => run(() => put('/me/grades', [ng.value]))
const setSkill = (skillId, level) => run(() => put('/me/skills', [{ skillId, level }]))
async function deleteMe() { if (!confirm('確定刪除帳號？本人資料將立即去識別化並刪除。')) return; await del('/me'); store.logout() }
onMounted(async () => { await store.loadMeta(); await load() })
</script>
