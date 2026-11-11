<template>
  <div v-if="c" style="max-width:960px">
    <router-link to="/competitions" class="small">← 競賽</router-link>
    <h1 style="margin-top:6px">{{ c.name }}</h1>
    <div class="sub">{{ c.organizer }}</div>
    <div class="grid grid-2" style="margin-top:16px">
      <div class="card">
        <div class="kv">
          <span>分類</span><span>{{ c.category }} · {{ labels.level[c.level] }}</span>
          <span>報名截止</span><span>{{ c.applyDeadline || '未公告' }} <span v-if="c.daysLeft !== null" class="pill" :class="c.daysLeft < 0 ? 'red' : c.daysLeft <= 14 ? 'orange' : 'green'">{{ c.daysLeft < 0 ? '已截止' : '剩 ' + c.daysLeft + ' 天' }}</span></span>
          <span>決賽／活動</span><span>{{ c.eventDate || '未公告' }}</span>
          <span>隊伍</span><span>{{ c.teamMax === 1 ? '個人賽' : (c.teamMin ?? '?') + '–' + (c.teamMax ?? '?') + ' 人' }} · 指導老師{{ c.advisorRequired === true ? '必填' : c.advisorRequired === false ? '非必要' : '未註明' }}</span>
          <span>資格</span><span>{{ c.eligibleDegrees.map(d => labels.degree[d]).join('、') }}<div class="sub small">{{ c.eligibilityNote }}</div></span>
          <span v-if="c.prize">獎勵</span><span v-if="c.prize">{{ c.prize }}</span>
          <span v-if="c.scheduleNote">時程</span><span v-if="c.scheduleNote" class="small">{{ c.scheduleNote }}</span>
        </div>
        <p style="margin:12px 0 8px">{{ c.description }}</p>
        <div class="row"><a v-if="c.url" :href="c.url" target="_blank" rel="noopener" class="btn secondary sm">官方網站 ↗</a>
          <span class="sub small">資料來源 <a :href="c.sourceUrl" target="_blank" rel="noopener">連結</a>，查證日 {{ c.checkedAt }}；日期與資格以官方公告為準。</span></div>
        <h3 style="margin-top:16px">所需技能</h3>
        <div class="row"><span v-for="s in c.skills" :key="s.skillId" class="chip">{{ s.name }} <span class="lv">{{ s.tier }}</span> <span :class="s.importance === 'CORE' ? 'tag-req' : 'tag-opt'">{{ labels.importance[s.importance] }}</span></span></div>
      </div>
      <div class="card" v-if="c.fit !== undefined">
        <div class="row between"><h3 style="margin:0"><span class="pill blue">競賽 Agent</span> 我的契合度</h3><span class="fit" style="font-size:26px" :style="c.eligible ? '' : 'color:var(--tertiary)'">{{ c.fit.toFixed(1) }}</span></div>
        <div class="sub small">涵蓋率 {{ Math.round(c.coverage * 100) }}% · 證據強度 {{ Math.round(c.depth * 100) }}% · 核心技能 {{ c.coreMet }}／{{ c.coreTotal }} 達標</div>
        <ul class="tight" v-if="c.blockedBy.length" style="color:var(--red)"><li v-for="b in c.blockedBy" :key="b">{{ b }}</li></ul>
        <div class="kv" style="margin-top:10px">
          <span>優點</span><span><span v-for="s in c.strengths" :key="s.skillId" class="chip" style="margin:0 4px 4px 0">{{ s.name }} <span class="lv">{{ s.mine }}</span> <span class="pill" :class="trustColor(s.trust)">{{ s.trust }}</span></span><span v-if="!c.strengths.length" class="muted">無</span></span>
          <span>弱項</span><span><span v-for="s in c.weaknesses" :key="s.skillId" class="chip" style="margin:0 4px 4px 0">{{ s.name }} <span class="muted">{{ s.mine }} → 需 {{ s.required }}</span></span><span v-if="!c.weaknesses.length" class="muted">無</span></span>
          <span>能力缺口</span><span><span v-for="s in c.gaps" :key="s.skillId" class="chip" style="margin:0 4px 4px 0;background:#ffe5e3">{{ s.name }}<span v-if="s.core" class="tag-req">核心</span></span><span v-if="!c.gaps.length" class="muted">無</span></span>
        </div>
        <ul class="tight" style="margin-top:8px"><li v-for="r in c.reasons" :key="r">{{ r }}</li></ul>
        <div v-if="c.myCases && c.myCases.length" style="margin-top:10px" class="small">我的隊伍：<router-link v-for="x in c.myCases" :key="x.id" :to="'/cases/' + x.id" style="margin-right:8px">{{ x.title }}（{{ labels.status[x.status] }}）</router-link></div>
        <div v-if="c.openTeams && c.openTeams.length" style="margin-top:6px" class="small">招募中的隊伍：<router-link v-for="x in c.openTeams" :key="x.id" :to="'/cases/' + x.id" style="margin-right:8px">{{ x.title }}（{{ x.ownerName }}，缺 {{ x.seats }} 人）</router-link></div>
      </div>
    </div>

    <template v-if="c.fit !== undefined && c.status !== 'CLOSED'">
      <div class="card" style="margin-top:16px">
        <div class="row between"><h3 style="margin:0"><span class="pill green">學生 Agent</span> 找技能互補的隊友</h3>
          <div class="row"><span class="sub small">每週</span><input v-model.number="hours" type="number" min="1" max="40" style="width:70px" /><span class="sub small">小時</span><button class="btn sm" :disabled="busy" @click="findTeam">{{ team ? '重新計算' : '找隊友' }}</button></div></div>
        <TeammatesCard v-if="team" :data="team" selectable v-model="invitees" :limit="8" style="margin-top:12px" />
        <p v-else class="sub small" style="margin:8px 0 0">依這個競賽的所需技能算出團隊缺口，推薦能補上缺口的同學；分數與案件推薦用同一顆排序引擎。</p>
      </div>
      <div class="card" style="margin-top:16px">
        <div class="row between"><h3 style="margin:0"><span class="pill purple">教師 Agent</span> 找指導老師</h3><button class="btn sm" :disabled="busy" @click="findTeachers">{{ teachers ? '重新計算' : '找老師' }}</button></div>
        <TeachersCard v-if="teachers" :data="teachers" selectable v-model="advisor" style="margin-top:12px" />
        <p v-else class="sub small" style="margin:8px 0 0">依所需技能、教師專長、研究方向與競賽指導經驗推薦，並列出需要你自己向老師確認的事項。</p>
      </div>
      <div class="card" style="margin-top:16px" v-if="team">
        <div class="row between"><h3 style="margin:0">組隊</h3>
          <button class="btn" :disabled="busy" @click="draft">{{ invitees.length ? '用勾選的 ' + invitees.length + ' 位起草組隊案件' : '起草公開招募的組隊案件' }}</button></div>
        <p class="sub small" style="margin:6px 0 0">先產生草稿給你檢查；按確認後才會建立並發布案件、送出邀請。{{ advisor ? '已選指導老師會寫入案件（老師不會收到通知）。' : '' }}</p>
        <ActionCard v-if="action" :key="action.id" :card="action" style="margin-top:12px" @changed="load" />
      </div>
    </template>
  </div>
</template>
<script setup>
import { ref, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { get, post } from '../api'
import { store, labels, trustColor } from '../store'
import TeammatesCard from '../components/TeammatesCard.vue'
import TeachersCard from '../components/TeachersCard.vue'
import ActionCard from '../components/ActionCard.vue'
const route = useRoute(), id = +route.params.id
const c = ref(null), team = ref(null), teachers = ref(null), invitees = ref([]), advisor = ref(null), action = ref(null), hours = ref(4), busy = ref(false)
async function load() { c.value = await get('/competitions/' + id) }
async function guard(fn) { busy.value = true; try { await fn() } catch (e) { store.notify(e.message, 'error') } finally { busy.value = false } }
const findTeam = () => guard(async () => { team.value = await post('/agents/teammates', { competitionId: id, hoursPerWeek: hours.value, limit: 12 }); invitees.value = team.value.suggestedTeam.picks.map(p => p.userId) })
const findTeachers = () => guard(async () => { teachers.value = await post('/agents/teachers', { competitionId: id, limit: 5 }) })
const draft = () => guard(async () => { action.value = await post('/assistant/actions/draft-team', { competitionId: id, inviteUserIds: invitees.value, advisorTeacherId: advisor.value, hoursPerWeek: hours.value }) })
onMounted(load)
</script>
