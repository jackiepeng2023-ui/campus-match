<template>
  <div v-if="u" style="max-width:820px">
    <h1>{{ u.name }}</h1>
    <div class="sub">{{ u.college }}／{{ u.department }} · {{ labels.degree[u.degree] }}{{ u.year }}年級 · 每週可投入 {{ u.availability?.hoursPerWeek ?? '—' }} 小時（{{ u.availability?.availableFrom }} ～ {{ u.availability?.availableTo }}）</div>
    <div class="stat-grid" style="margin:16px 0">
      <div class="stat"><div class="k">隊友評價</div><div class="v">{{ u.stats.avgRating ?? '—' }}</div></div>
      <div class="stat"><div class="k">檔案相符度</div><div class="v">{{ u.stats.avgMatch ?? '—' }}</div></div>
      <div class="stat"><div class="k">可信度係數</div><div class="v">{{ u.stats.credibility }}</div></div>
      <div class="stat"><div class="k">回應率</div><div class="v">{{ Math.round(u.stats.responseRate * 100) }}%</div></div>
      <div class="stat"><div class="k">完成案件</div><div class="v">{{ u.stats.closedCases }}</div></div>
    </div>
    <div class="grid grid-2">
      <div class="card"><h3>技能等級 <span class="sub small">（只顯示等級，不顯示成績，D16）</span></h3>
        <div class="row"><span v-for="s in u.skills" :key="s.skillId" class="chip">{{ s.name }} <span class="lv">{{ s.level }}</span></span></div></div>
      <div class="card"><h3>得獎紀錄</h3>
        <div v-if="!u.awards.length" class="empty">無</div>
        <table v-else><tr v-for="a in u.awards" :key="a.id"><td>{{ a.competition }}<div class="sub small">{{ a.skills }}</div></td><td class="small">{{ labels.level[a.level] }}・{{ labels.rank[a.rank] }}</td><td class="small">{{ a.awardDate }}</td></tr></table></div>
    </div>
  </div>
</template>
<script setup>
import { ref, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { get } from '../api'
import { labels } from '../store'
const route = useRoute(), u = ref(null)
onMounted(async () => { u.value = await get('/users/' + route.params.id) })
</script>
