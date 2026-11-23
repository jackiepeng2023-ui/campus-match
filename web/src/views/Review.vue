<template>
  <div v-if="p" style="max-width:760px">
    <h1>給隊友回饋：{{ p.caseTitle }}</h1>
    <p class="sub">四題各 1–5 分。第 2 題「能力與檔案相符」會影響對方自填資料在推薦中的權重（D9）。評價匿名，雙方都送出或 72 小時到期才同時公開（D40）。</p>
    <div v-if="!todo.length" class="card empty">這支隊伍的回饋你都送出了</div>
    <form v-else @submit.prevent="submit" class="stack">
      <div class="card" v-for="it in todo" :key="it.id">
        <h3>{{ it.name }} <span class="sub small">{{ it.department }}{{ it.isOwner ? ' · 隊長' : '' }}</span></h3>
        <table>
          <tr><td style="width:45%">整體合作滿意度</td><td><Stars v-model="it.satisfaction" /></td></tr>
          <tr><td>實際能力與檔案相符嗎</td><td><Stars v-model="it.matchScore" /></td></tr>
          <tr><td>是否準時完成分內工作</td><td><Stars v-model="it.onTime" /></td></tr>
          <tr><td>溝通與回應是否及時</td><td><Stars v-model="it.communication" /></td></tr>
          <tr v-if="p.askAttribution && it.isOwner"><td>當初說好的成果歸屬有沒有兌現</td><td><select v-model="it.attributionKept"><option value="YES">是</option><option value="PARTIAL">部分</option><option value="NO">否</option></select></td></tr>
          <tr><td>評語（選填，只有對方本人看得到）</td><td><input v-model="it.comment" placeholder="具體說明做得好或可以改進的地方" /></td></tr>
        </table>
      </div>
      <div class="row between"><span class="sub small">期限 {{ fmtTime(todo[0].dueAt) }}；逾時未填視為未回應，計入回應率</span><button class="btn" :disabled="busy">送出評價</button></div>
    </form>
    <div class="card" v-if="done.length" style="margin-top:16px"><h3>已送出</h3><div class="sub small">{{ done.map(d => d.name).join('、') }}</div></div>
  </div>
</template>
<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { get, post } from '../api'
import { store, fmtTime } from '../store'
import Stars from '../components/Stars.vue'
const route = useRoute(), router = useRouter()
const p = ref(null), busy = ref(false)
const todo = computed(() => p.value.items.filter(i => !i.submittedAt && !i.missed).map(i => Object.assign(i, { satisfaction: i.satisfaction || 0, matchScore: i.matchScore || 0, onTime: i.onTime || 0, communication: i.communication || 0, attributionKept: i.attributionKept || 'YES' })))
const done = computed(() => p.value.items.filter(i => i.submittedAt))
onMounted(async () => { p.value = await get('/cases/' + route.params.id + '/reviews/pending') })
async function submit() {
  for (const it of todo.value) if ([it.satisfaction, it.matchScore, it.onTime, it.communication].some(v => !v)) return store.notify('請為 ' + it.name + ' 的四題都評分', 'error')
  busy.value = true
  try {
    await post('/cases/' + route.params.id + '/reviews', todo.value.map(it => ({ revieweeId: it.revieweeId, satisfaction: it.satisfaction, matchScore: it.matchScore, onTime: it.onTime, communication: it.communication, attributionKept: p.value.askAttribution && it.isOwner ? it.attributionKept : null, comment: it.comment || null })))
    store.notify('評價已送出', 'success'); router.push('/cases/' + route.params.id)
  } catch (e) { store.notify(e.message, 'error') } finally { busy.value = false }
}
</script>
