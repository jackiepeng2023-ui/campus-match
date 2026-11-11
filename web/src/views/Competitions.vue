<template>
  <div>
    <div class="row between"><div><h1>競賽</h1><p class="sub">競賽資料庫收錄官方簡章可查證的資訊與所需技能；日期與資格以官方公告為準。</p></div>
      <div class="segment"><button :class="{ on: tab === 'rec' }" @click="tab = 'rec'" v-if="!admin">推薦給我</button><button :class="{ on: tab === 'all' }" @click="tab = 'all'">全部競賽{{ loaded ? ' ' + all.length : '' }}</button></div></div>
    <div v-if="tab === 'rec' && rec" class="card">
      <h3><span class="pill blue">競賽 Agent</span> 依你的 Skill Profile 推薦 <span class="sub small">可報名 {{ rec.totalEligible }} 筆；已截止 {{ rec.skipped.closed }}、學制不符 {{ rec.skipped.ineligible }}、技能無交集 {{ rec.skipped.unrelated }}</span></h3>
      <p class="sub small">契合度 = 75% 涵蓋率（核心技能權重 2、輔助 1）+ 25% 證據強度；優點＝已達標、弱項＝有基礎未達需求、能力缺口＝完全沒有（可找隊友補）。</p>
      <CompetitionCard v-for="c in rec.recommended" :key="c.id" :c="c" />
      <div v-if="!rec.recommended.length" class="empty">目前沒有符合資格、與你的技能相關且還能報名的競賽；到「我的檔案」補上證據後再試。</div>
      <template v-if="rec.blocked.length"><h3 style="margin-top:16px">不建議或無法報名</h3><CompetitionCard v-for="c in rec.blocked" :key="c.id" :c="c" /></template>
      <AgentTrace :lines="rec.trace" />
    </div>
    <div v-if="tab === 'rec' && !rec && !admin" class="card"><div class="empty">競賽 Agent 計算中…</div></div>
    <div v-if="tab === 'all'" class="card">
      <div class="row"><input v-model="q" placeholder="搜尋名稱、主辦單位" style="max-width:260px" />
        <select v-model="category" style="max-width:160px"><option value="">全部分類</option><option v-for="c in categories" :key="c" :value="c">{{ c }}</option></select>
        <div class="segment"><button :class="{ on: status === 'open' }" @click="status = 'open'">可報名</button><button :class="{ on: status === 'all' }" @click="status = 'all'">全部</button></div>
        <span class="sub small">{{ shown.length }} 筆</span></div>
      <div style="margin-top:12px"><CompetitionCard v-for="c in shown" :key="c.id" :c="c" /></div>
      <div v-if="!shown.length" class="empty">{{ loaded ? '沒有符合條件的競賽' : '載入中…' }}</div>
    </div>
  </div>
</template>
<script setup>
import { ref, computed, onMounted } from 'vue'
import { get } from '../api'
import { store } from '../store'
import CompetitionCard from '../components/CompetitionCard.vue'
import AgentTrace from '../components/AgentTrace.vue'
const admin = store.user.role === 'ADMIN'
const tab = ref(admin ? 'all' : 'rec'), rec = ref(null), all = ref([]), loaded = ref(false), q = ref(''), category = ref(''), status = ref('open')
const categories = computed(() => [...new Set(all.value.map(c => c.category))])
const shown = computed(() => all.value.filter(c => (status.value === 'all' || c.status !== 'CLOSED') && (!category.value || c.category === category.value)
  && (!q.value || (c.name + c.shortName + c.organizer).toLowerCase().includes(q.value.toLowerCase()))))
onMounted(async () => { all.value = await get('/competitions'); loaded.value = true; if (!admin) rec.value = await get('/agents/competitions?limit=10') })
</script>
