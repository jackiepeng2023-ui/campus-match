<template>
  <div>
    <div class="head">
      <div><h1>比賽</h1><p class="sub">先選一場比賽，再開隊或找隊。報名是在主辦單位的網站完成；日期與資格以官方公告為準。</p></div>
    </div>
    <div class="row" style="margin-bottom:16px">
      <label style="flex:1 1 280px;margin:0"><span class="sr">搜尋比賽名稱或主辦單位</span><input v-model="q" type="search" placeholder="搜尋比賽名稱、主辦單位…" /></label>
    </div>
    <div class="fpills" style="margin-bottom:22px">
      <button type="button" class="fpill" :class="{ on: !category }" :aria-pressed="!category" @click="category = ''">全部</button>
      <button v-for="c in categories" :key="c" type="button" class="fpill" :class="{ on: category === c }" :aria-pressed="category === c" @click="category = category === c ? '' : c">{{ c }}</button>
      <button type="button" class="fpill" :class="{ on: closed }" :aria-pressed="closed" @click="closed = !closed">已截止的也看</button>
    </div>
    <div class="sub small" style="margin-bottom:16px" role="status">{{ loaded ? `${shown.length} 場${closed ? '' : '還能報名的'}比賽，快截止的排前面` : '' }}</div>

    <div v-if="!loaded" class="empty">載入中…</div>
    <div v-else-if="!shown.length" class="card soft empty"><b>沒有符合條件的比賽</b>換個關鍵字，或把分類改回「全部」。</div>
    <div v-else class="cards few">
      <article v-for="c in shown" :key="c.id" class="card tcard">
        <div class="top-line">
          <span class="tags"><span class="tag yellow">{{ c.category }}</span><span class="tag">{{ labels.level[c.level] }}</span></span>
          <span v-if="c.applyDeadline">報名截止 {{ md(c.applyDeadline) }} · <span :class="{ urgent: c.daysLeft >= 0 && c.daysLeft <= 7 }">{{ leftText(c.daysLeft) }}</span></span>
          <span v-else>報名日期未公告</span>
        </div>
        <h3><router-link :to="'/competitions/' + c.id">{{ c.shortName || c.name }}</router-link></h3>
        <div class="meta">{{ c.organizer }}</div>
        <div class="tags">
          <span class="tag line">每隊 {{ teamSizeText(c.teamMin, c.teamMax) }}</span>
          <span v-if="c.advisorRequired" class="tag blue">需指導老師</span>
          <span v-for="s in c.skills.slice(0, 4)" :key="s.skillId" class="tag">{{ s.name }}</span>
        </div>
        <div class="foot">
          <div class="tags">
            <span v-if="mine[c.id]" class="tag peach">我的隊伍：{{ mine[c.id] }}</span>
            <b v-else-if="counts[c.id]">{{ counts[c.id] }} 隊正在找人</b>
            <span v-else class="why">{{ c.status === 'CLOSED' ? '報名已截止' : '還沒有隊伍，可以當第一隊' }}</span>
          </div>
          <router-link :to="'/competitions/' + c.id" class="btn sm">看這場比賽</router-link>
        </div>
      </article>
    </div>
  </div>
</template>
<script setup>
import { ref, computed, onMounted } from 'vue'
import { get } from '../api'
import { store, labels, md, leftText, teamSizeText } from '../store'

const all = ref([]), loaded = ref(false), q = ref(''), category = ref(''), closed = ref(false), counts = ref({}), mine = ref({})
const categories = computed(() => [...new Set(all.value.filter(c => closed.value || c.status !== 'CLOSED').map(c => c.category))])
const shown = computed(() => {
  const kw = q.value.trim().toLowerCase()
  return all.value.filter(c => (closed.value || c.status !== 'CLOSED') && (!category.value || c.category === category.value)
    && (!kw || (c.name + (c.shortName || '') + c.organizer).toLowerCase().includes(kw)))
    .sort((a, b) => (a.status === 'CLOSED') - (b.status === 'CLOSED') || (a.daysLeft ?? 9999) - (b.daysLeft ?? 9999))
})
onMounted(async () => {
  try {
    const [list, wall, my] = await Promise.all([get('/competitions'), get('/cases/wall'), store.user.role === 'ADMIN' ? [] : get('/cases/wall?mine=true')])
    all.value = list
    const n = {}; for (const t of wall) n[t.competition.id] = (n[t.competition.id] || 0) + 1
    counts.value = n
    mine.value = Object.fromEntries(my.map(t => [t.competition.id, t.title]))
  } catch (e) { store.notify(e.message, 'error') }
  loaded.value = true
})
</script>
