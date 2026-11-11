<template>
  <div>
    <div class="row between" style="margin-bottom:18px">
      <div><h1>你好，{{ store.user.name }}</h1><div class="sub">{{ store.user.college }}／{{ store.user.department }} · {{ labels.degree[store.user.degree] }}{{ store.user.year }}年級</div></div>
      <router-link to="/cases/new" class="btn">＋ 發布需求</router-link>
    </div>
    <div class="stat-grid" style="margin-bottom:16px">
      <div class="stat"><div class="k">隊友評價</div><div class="v">{{ s.avgRating ?? '—' }}<span class="sub small"> /5</span></div></div>
      <div class="stat"><div class="k">檔案相符度</div><div class="v">{{ s.avgMatch ?? '—' }}<span class="sub small"> · 可信度 {{ s.credibility }}</span></div></div>
      <div class="stat"><div class="k">回應率</div><div class="v">{{ Math.round(s.responseRate * 100) }}%</div></div>
      <div class="stat"><div class="k">完成案件</div><div class="v">{{ s.closedCases }}</div></div>
      <div class="stat"><div class="k">進行中</div><div class="v">{{ s.activeCases }}</div></div>
    </div>
    <div class="grid grid-2">
      <div class="card">
        <h2>待我處理</h2>
        <div v-if="!pending.length" class="empty">{{ loaded ? '目前沒有待回覆的申請或邀請' : '載入中…' }}</div>
        <table v-else><tr v-for="e in pending" :key="e.id">
          <td><router-link :to="'/cases/' + e.caseId"><strong>{{ e.caseTitle }}</strong></router-link><div class="sub small">{{ e.direction === 'INVITE' ? '邀請你擔任' : e.direction === 'APPLY' ? '你申請' : '申請加入' }} {{ e.roleName }} · 發案方 {{ e.ownerName }}</div></td>
          <td style="text-align:right;white-space:nowrap"><span class="pill orange">{{ hoursLeft(e.dueAt) }} 小時內回覆</span>
            <div v-if="e.direction !== 'APPLY'" class="row" style="justify-content:flex-end;margin-top:6px"><button class="btn sm" @click="act(e, 'accept')">{{ e.direction === 'INVITE' ? '接受' : '核准' }}</button><button class="btn sm secondary" @click="act(e, 'decline')">拒絕</button></div>
            <div v-else class="row" style="justify-content:flex-end;margin-top:6px"><button class="btn sm secondary" @click="act(e, 'withdraw')">撤回</button></div></td>
        </tr></table>
        <div v-if="toReview.length" style="margin-top:14px">
          <h3>待互評</h3>
          <div v-for="c in toReview" :key="c.id" class="row between" style="padding:6px 0"><span>{{ c.title }}</span><router-link :to="'/cases/' + c.id + '/review'" class="btn sm">去評價</router-link></div>
        </div>
      </div>
      <div class="card">
        <h2>推薦給我的案件</h2>
        <p class="sub small" style="margin-top:-8px">與發案方看到的推薦用同一組閘門與公式，只是方向相反。</p>
        <div v-if="!recs.length" class="empty">{{ loaded ? '目前沒有通過閘門的招募中案件；補齊技能檔或可投入時間後再試' : '載入中…' }}</div>
        <div class="stack"><ScoreCard v-for="r in recs" :key="r.roleId" :item="r"><template #action><router-link :to="'/cases/' + r.caseId" class="btn sm secondary">查看</router-link></template></ScoreCard></div>
      </div>
    </div>
    <div class="card" style="margin-top:16px">
      <div class="row between"><h2 style="margin:0">我的案件</h2><router-link to="/cases" class="small">瀏覽全部 →</router-link></div>
      <div v-if="!mine.length" class="empty">{{ loaded ? '還沒有參與任何案件' : '載入中…' }}</div>
      <table v-else style="margin-top:10px"><tr><th>案件</th><th>類型</th><th>狀態</th><th>名額</th><th>截止</th></tr>
        <tr v-for="c in mine" :key="c.id"><td><router-link :to="'/cases/' + c.id">{{ c.title }}</router-link><div class="sub small">{{ c.ownerId === store.user.id ? '我發起' : '我是成員' }}<span v-if="c.pendingApplications && c.ownerId === store.user.id"> · {{ c.pendingApplications }} 筆申請待審</span></div></td>
          <td>{{ labels.type[c.type] }}</td><td><span class="pill" :class="statusColor(c.status)">{{ labels.status[c.status] }}</span></td><td>{{ c.filled }}/{{ c.headcount }}</td><td class="small">{{ fmtDate(c.applyDeadline) }}</td></tr></table>
    </div>
  </div>
</template>
<script setup>
import { ref, onMounted, computed } from 'vue'
import { get, post } from '../api'
import { store, labels, fmtDate, hoursLeft, statusColor } from '../store'
import ScoreCard from '../components/ScoreCard.vue'
const engs = ref([]), recs = ref([]), mine = ref([]), ownerPending = ref([]), toReview = ref([]), loaded = ref(false)
const s = computed(() => store.user.stats)
const pending = computed(() => [...engs.value.filter(e => e.status === 'PENDING'), ...ownerPending.value])
async function load() {
  await store.loadMe()
  const [e, r, m] = await Promise.all([get('/me/engagements'), get('/me/recommended-cases'), get('/cases?member=true')])
  engs.value = e; recs.value = r; mine.value = m; loaded.value = true
  // 我發起的案件裡待審核的申請（由案件詳情取得）
  const owned = m.filter(c => c.ownerId === store.user.id && c.pendingApplications > 0)
  const details = await Promise.all(owned.map(c => get('/cases/' + c.id)))
  ownerPending.value = details.flatMap(d => d.engagements.filter(x => x.status === 'PENDING' && x.direction === 'APPLY').map(x => ({ ...x, caseId: d.id, caseTitle: d.title, direction: 'APPLY_IN', ownerName: '你', roleName: x.roleName + '（' + x.name + ' 申請）' })))
  toReview.value = m.filter(c => c.status === 'CLOSED')
  const pend = await Promise.all(toReview.value.map(c => get('/cases/' + c.id).then(d => d.pendingReviews > 0 ? c : null)))
  toReview.value = pend.filter(Boolean)
}
async function act(e, what) {
  try {
    await post('/engagements/' + e.id + '/' + what)
    store.notify('已處理', 'success'); await load()
  } catch (err) { store.notify(err.message, 'error') }
}
onMounted(load)
</script>
