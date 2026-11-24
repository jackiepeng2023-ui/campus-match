<template>
  <section class="track" :class="{ plain, folded: !open }" aria-label="報名追蹤">
    <template v-if="open">
      <div class="with-art">
        <Squirrel v-if="team.registeredAt" pose="cheer" :size="68" />
        <div>
          <div class="small strong">報名追蹤</div>
          <div class="big">{{ headline }}</div>
          <div class="sub small">報名截止 {{ mdw(team.competitionDeadline) }}</div>
        </div>
      </div>
      <ul class="checks">
        <li :class="sizeOk ? 'ok' : 'todo'"><span class="mark">{{ sizeOk ? '✓' : '' }}</span><span>隊伍 {{ team.members.length }} 人，{{ sizeRule }}</span></li>
        <li :class="team.competitionAdvisorRequired === false ? 'ok' : ''"><span class="mark">{{ team.competitionAdvisorRequired === false ? '✓' : '' }}</span>
          <span>{{ team.competitionAdvisorRequired === true ? '這場需要指導老師，記得先找好' : team.competitionAdvisorRequired === false ? '這場不需要指導老師' : '指導老師：簡章沒有註明，請看官方公告' }}</span></li>
        <li :class="team.registeredAt ? 'ok' : 'todo'"><span class="mark">{{ team.registeredAt ? '✓' : '' }}</span>
          <span>{{ team.registeredAt ? `官方報名已完成（隊長在 ${md(String(team.registeredAt).slice(0, 10))} 標記）` : '官方報名還沒完成' }}</span></li>
      </ul>
      <div class="acts">
        <a v-if="team.competitionUrl" :href="team.competitionUrl" target="_blank" rel="noopener" class="btn sm white">到官方網站報名 <Ico name="out" :size="15" /></a>
        <template v-if="team.isOwner">
          <ConfirmButton v-if="!team.registeredAt && ['OPEN', 'FORMED'].includes(team.status)" variant="" :disabled="busy || !sizeOk" :title="sizeOk ? '' : '人數還不符合這場比賽的規定'"
                         question="已經在官方網站報好了？標記後名單會鎖定。" yes="標記已報名" @confirm="mark">標記已報名</ConfirmButton>
          <ConfirmButton v-else-if="team.registeredAt && team.status === 'IN_PROGRESS'" :disabled="busy" question="取消標記後名單可以再調整。" yes="取消標記" @confirm="unmark">按錯了，取消標記</ConfirmButton>
        </template>
      </div>
      <div class="foot">{{ team.registeredAt ? '名單已鎖定，不能再加人或退出。' : '截止前 7、3、1 天會提醒全隊。報名是在比賽官網做的；只有隊長能標記，標記後名單鎖定。' }}
        <button v-if="!plain" type="button" class="btn tiny white toggle" style="margin-top:8px" @click="open = false">收起來</button></div>
    </template>
    <template v-else>
      <span class="small strong">報名追蹤</span><span class="small" :class="{ urgent: !team.registeredAt && team.daysLeft <= 7 }">{{ headline }}{{ team.registeredAt ? '' : '，還沒標記報名' }}</span>
      <button type="button" class="btn tiny white toggle" :aria-expanded="false" @click="open = true">展開</button>
    </template>
  </section>
</template>
<script setup>
// 報名追蹤：隊伍頁與隊伍群組共用。報名本身在主辦單位網站完成，這裡只記錄隊長說「報好了」。
// 手機上的隊伍群組先收成一行，留位置給訊息；隊伍頁（plain）一律展開。
import { ref, computed } from 'vue'
import { post, del } from '../api'
import { store, md, mdw, leftText } from '../store'
import Ico from './Ico.vue'
import ConfirmButton from './ConfirmButton.vue'
import Squirrel from './Squirrel.vue'
const props = defineProps({ team: { type: Object, required: true }, plain: Boolean })
const emit = defineEmits(['changed'])
const busy = ref(false), open = ref(props.plain || window.innerWidth > 760)
const headline = computed(() => props.team.registeredAt ? '已報名' : leftText(props.team.daysLeft) || '截止日未公告')
const min = computed(() => props.team.competitionTeamMin), max = computed(() => props.team.competitionTeamMax)
const sizeOk = computed(() => { const n = props.team.members.length; return (min.value == null || n >= min.value) && (max.value == null || n <= max.value) })
const sizeRule = computed(() => {
  const n = props.team.members.length
  if (min.value != null && n < min.value) return `這場每隊至少 ${min.value} 人，還差 ${min.value - n} 人`
  if (max.value != null && n > max.value) return `這場每隊最多 ${max.value} 人`
  return min.value != null && max.value != null ? `這場每隊 ${min.value === max.value ? max.value : min.value + '–' + max.value} 人，可以報名` : '人數符合，可以報名'
})
async function run(fn, done) {
  busy.value = true
  try { emit('changed', await fn()); store.notify(done, 'success') } catch (e) { store.notify(e.message, 'error') } finally { busy.value = false }
}
const mark = () => run(() => post(`/cases/${props.team.id}/registration`), '已標記報名，名單鎖定')
const unmark = () => run(() => del(`/cases/${props.team.id}/registration`), '已取消標記')
</script>
