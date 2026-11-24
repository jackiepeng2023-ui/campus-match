<template>
  <div>
    <div class="banner">
      <img :src="banner" :srcset="`${bannerSmall} 1024w, ${banner} 2048w`" sizes="(max-width: 1250px) 100vw, 1206px" width="2048" height="682"
           alt="Fomo鬆 橫幅：找到跨系夥伴，讓你的創意有人一起完成" fetchpriority="high" />
    </div>
    <div class="head">
      <div>
        <div class="title-row"><h1>找隊友</h1><router-link v-if="!admin" to="/competitions" class="btn">＋ 我要開隊</router-link></div>
        <p class="sub">這些隊伍正在找人。看到想加入的就申請，直接和隊長聊。</p>
        <div class="steps" aria-label="流程">
          <span>選比賽</span><i>→</i><span>開隊或找隊</span><i>→</i><span>申請或邀請</span><i>→</i><span>聊一聊</span><i>→</i><span>成隊</span><i>→</i><span>報名</span>
        </div>
      </div>
    </div>

    <form class="row" style="margin-bottom:16px" @submit.prevent="load">
      <label style="flex:1 1 280px;margin:0"><span class="sr">搜尋比賽、隊名或技能</span><input v-model="q" type="search" placeholder="搜尋比賽、隊名、技能…" /></label>
      <button class="btn">搜尋</button>
    </form>
    <div class="fpills" style="margin-bottom:22px">
      <button type="button" class="fpill" :class="{ on: !fit && !category && !mine }" :aria-pressed="!fit && !category && !mine" @click="reset">全部</button>
      <button v-if="!admin" type="button" class="fpill" :class="{ on: fit }" :aria-pressed="fit" @click="fit = !fit; mine = false; load()">適合我</button>
      <button v-if="!admin" type="button" class="fpill" :class="{ on: mine }" :aria-pressed="mine" @click="mine = !mine; fit = false; load()">我的隊伍</button>
      <button v-for="c in categories" :key="c" type="button" class="fpill" :class="{ on: category === c }" :aria-pressed="category === c" @click="category = category === c ? '' : c">{{ c }}</button>
    </div>

    <div class="sub small" style="margin-bottom:16px" role="status">{{ summary }}</div>

    <div v-if="!loaded" class="empty">載入中…</div>
    <div v-else-if="!shown.length" class="card soft empty">
      <Squirrel pose="stand" :size="132" />
      <b>{{ mine ? '你還沒有加入任何隊伍' : filtered ? '沒有符合條件的隊伍' : '目前沒有隊伍在找人' }}</b>
      {{ mine ? '到「比賽」選一場開隊，或在這裡找一隊申請。' : filtered ? '換個關鍵字，或清除篩選看看全部。' : '當第一個開隊的人：到「比賽」選一場，開隊只要填隊名和想找的技能。' }}
      <div class="row" style="justify-content:center;margin-top:14px">
        <button v-if="filtered || mine" class="btn sm white" @click="reset">看全部隊伍</button>
        <router-link v-if="!admin" to="/competitions" class="btn sm">去選比賽</router-link>
      </div>
    </div>
    <div v-else class="cards few">
      <article v-for="t in shown" :key="t.id" class="card tcard">
        <div class="top-line">
          <span class="tag yellow">{{ t.competition.category }}</span>
          <span>報名截止 {{ md(t.competition.applyDeadline) }} · <span :class="{ urgent: t.competition.daysLeft <= 7 }">{{ leftText(t.competition.daysLeft) }}</span></span>
        </div>
        <h3><router-link :to="'/competitions/' + t.competition.id">{{ t.competition.name }}</router-link></h3>
        <div class="meta">{{ t.title }} · 隊長 {{ t.owner.name }}（{{ t.owner.department }}）· 目前 {{ t.members }}／{{ t.teamSize }} 人</div>
        <p v-if="t.intro" class="intro">{{ t.intro }}</p>
        <div class="tags">
          <span v-for="s in skillsOf(t)" :key="s.skillId" class="tag" :title="s.required ? '一定要會' : '會的話加分'">{{ s.name }}<span v-if="s.required" class="tag-req">必</span></span>
          <span v-if="t.competition.advisorRequired" class="tag blue">需指導老師</span>
        </div>
        <div class="foot">
          <div class="tags">
            <b v-if="t.status === 'OPEN'">缺 {{ t.need }} 人</b><span v-else class="tag" :class="statusTag(t.status)">{{ labels.status[t.status] }}</span>
            <span v-if="t.my.isOwner" class="tag peach">我是隊長</span>
            <span v-else-if="t.my.isMember" class="tag peach">我的隊伍</span>
            <span v-else-if="t.my.pending" class="tag peach">{{ t.my.pending.direction === 'INVITE' ? '隊長邀請了你' : '已申請，等回覆' }}</span>
            <template v-else-if="t.fit && t.fit.passed"><span v-for="g in t.fit.tags" :key="g" class="tag green">{{ g }}</span></template>
            <span v-else-if="t.fit && t.fit.blocked.length" class="why">{{ t.fit.blocked[0] }}</span>
          </div>
          <router-link v-if="t.my.pending" :to="'/messages?e=' + t.my.pending.id" class="btn sm">去聊聊</router-link>
          <router-link v-else :to="'/teams/' + t.id" class="btn sm">看看這隊</router-link>
        </div>
      </article>
    </div>
  </div>
</template>
<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { get } from '../api'
import { store, labels, md, leftText, statusTag } from '../store'
import { onEvent } from '../realtime'
import Squirrel from '../components/Squirrel.vue'
import banner from '../assets/brand/banner-teammates.webp'
import bannerSmall from '../assets/brand/banner-teammates-1024.webp'

const admin = store.user.role === 'ADMIN'
const teams = ref([]), loaded = ref(false), q = ref(''), fit = ref(false), mine = ref(false), category = ref('')
const categories = computed(() => [...new Set(teams.value.map(t => t.competition.category))])
const filtered = computed(() => !!(q.value.trim() || fit.value || category.value))
// 「適合我」由後端依排序結果排好；其餘依報名截止日，快截止的排前面
const shown = computed(() => {
  const list = teams.value.filter(t => !category.value || t.competition.category === category.value)
  return fit.value ? list : [...list].sort((a, b) => (a.competition.daysLeft ?? 9999) - (b.competition.daysLeft ?? 9999) || b.id - a.id)
})
const summary = computed(() => !loaded.value ? '' : mine.value ? `我參加的隊伍 ${shown.value.length} 支` : fit.value ? `${shown.value.length} 隊適合你，最適合的排前面` : `${shown.value.length} 隊正在找人，依報名截止日排序`)
const skillsOf = (t) => t.roles.flatMap(r => r.skills).slice(0, 5)

async function load() {
  const p = new URLSearchParams()
  if (q.value.trim()) p.set('q', q.value.trim())
  if (fit.value) p.set('fit', 'true')
  if (mine.value) p.set('mine', 'true')
  try { teams.value = await get('/cases/wall' + (p.size ? '?' + p : '')) } catch (e) { store.notify(e.message, 'error') }
  loaded.value = true
  if (category.value && !categories.value.includes(category.value)) category.value = ''
}
function reset() { q.value = ''; fit.value = mine.value = false; category.value = ''; load() }
// 隊伍或申請有變動時（有人加入、成隊、被邀請）重新整理
const off = onEvent((ev) => { if (['team.updated', 'engagement.updated', 'resync'].includes(ev.type)) load() })
onMounted(load); onUnmounted(off)
</script>
