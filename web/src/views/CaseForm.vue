<template>
  <div style="max-width:820px">
    <h1>{{ id ? '編輯案件' : '發布需求' }}</h1>
    <p class="sub">需求不是留言板文字，而是「角色 × 技能 × 最低等級 × 名額 × 時程」的受控欄位，推薦引擎才算得出來。</p>
    <form @submit.prevent="save" class="stack">
      <div class="card">
        <div class="grid grid-2" style="gap:12px">
          <div class="field" style="grid-column:1/-1"><label>標題</label><input v-model="f.title" required placeholder="例：創業競賽需要網站 Demo" /></div>
          <div class="field"><label>類型</label><select v-model="f.type"><option v-for="(l, k) in labels.type" :key="k" :value="k">{{ l }}</option></select></div>
          <div class="field"><label>每隊人數 N（含你）</label><input v-model.number="f.teamSize" type="number" min="2" /><div class="sub small">角色名額總和須等於 N − 1 = {{ f.teamSize - 1 }}（目前 {{ totalHeadcount }}）</div></div>
          <div class="field"><label>申請截止日</label><input v-model="f.applyDeadline" type="date" required /></div>
          <div class="field"><label>開始日</label><input v-model="f.startDate" type="date" required /></div>
          <div class="field"><label>結束日</label><input v-model="f.endDate" type="date" required /></div>
          <div class="field" v-if="f.type === 'RESEARCH'"><label>成果歸屬（研究協作必填，D13）</label><select v-model="f.attribution"><option value="AUTHORSHIP">論文掛名</option><option value="ACK">致謝</option><option value="NONE">無</option></select></div>
          <div class="field" style="grid-column:1/-1"><label>描述</label><textarea v-model="f.description" rows="3"></textarea></div>
        </div>
      </div>
      <div class="card" v-for="(r, i) in f.roles" :key="i">
        <div class="row between"><h3 style="margin:0">角色 {{ i + 1 }}</h3><button type="button" class="btn ghost sm" @click="f.roles.splice(i, 1)" v-if="f.roles.length > 1">移除</button></div>
        <div class="grid grid-3" style="gap:12px;margin-top:8px">
          <div class="field"><label>角色名稱</label><input v-model="r.roleName" required placeholder="前端" /></div>
          <div class="field"><label>名額</label><input v-model.number="r.headcount" type="number" min="1" /></div>
          <div class="field"><label>每週需投入時數（時間閘門）</label><input v-model.number="r.hoursPerWeek" type="number" min="1" /></div>
        </div>
        <label>技能條件（必要技能未達最低等級會被閘門擋下；加分技能只影響分數）</label>
        <table><tr v-for="(s, j) in r.skills" :key="j">
          <td style="width:45%"><select v-model.number="s.skillId"><option v-for="sk in store.meta?.skills" :key="sk.id" :value="sk.id">{{ sk.category }}｜{{ sk.name }}</option></select></td>
          <td style="width:20%"><select v-model.number="s.minLevel"><option v-for="n in 5" :key="n" :value="n">≥ {{ n }} 級</option></select></td>
          <td style="width:25%"><select v-model="s.isRequired"><option :value="true">必要</option><option :value="false">加分</option></select></td>
          <td><button type="button" class="btn ghost sm" @click="r.skills.splice(j, 1)" v-if="r.skills.length > 1">✕</button></td>
        </tr></table>
        <button type="button" class="btn secondary sm" style="margin-top:8px" @click="r.skills.push({ skillId: store.meta.skills[0].id, minLevel: 3, isRequired: false })">＋ 技能條件</button>
      </div>
      <div class="row between">
        <button type="button" class="btn secondary" @click="f.roles.push(newRole())">＋ 新增角色</button>
        <div class="row"><button type="submit" class="btn secondary" :disabled="busy">儲存草稿</button><button type="button" class="btn" :disabled="busy" @click="save(true)">儲存並發布</button></div>
      </div>
      <p v-if="error" style="color:var(--red)">{{ error }}</p>
    </form>
  </div>
</template>
<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { get, post, put } from '../api'
import { store, labels } from '../store'
const route = useRoute(), router = useRouter()
const id = route.params.id
const newRole = () => ({ roleName: '', headcount: 1, hoursPerWeek: 4, skills: [{ skillId: store.meta?.skills?.[0]?.id || 1, minLevel: 3, isRequired: true }] })
const f = ref({ title: '', type: 'PROJECT', description: '', teamSize: 3, applyDeadline: '', startDate: '', endDate: '', attribution: 'ACK', roles: [] })
const busy = ref(false), error = ref('')
const totalHeadcount = computed(() => f.value.roles.reduce((a, r) => a + (r.headcount || 0), 0))
onMounted(async () => {
  await store.loadMeta()
  if (id) {
    const c = await get('/cases/' + id)
    f.value = { title: c.title, type: c.type, description: c.description, teamSize: c.teamSize, applyDeadline: String(c.applyDeadline).slice(0, 10), startDate: c.startDate, endDate: c.endDate, attribution: c.attribution || 'ACK',
      roles: c.roles.map(r => ({ roleName: r.roleName, headcount: r.headcount, hoursPerWeek: r.hoursPerWeek, skills: r.skills.map(s => ({ skillId: s.skillId, minLevel: s.minLevel, isRequired: s.isRequired })) })) }
  } else {
    const d = new Date(); const iso = (x) => x.toISOString().slice(0, 10)
    f.value.applyDeadline = iso(new Date(d.getTime() + 10 * 864e5)); f.value.startDate = iso(new Date(d.getTime() + 12 * 864e5)); f.value.endDate = iso(new Date(d.getTime() + 60 * 864e5))
    f.value.roles = [newRole()]
  }
})
async function save(publish = false) {
  busy.value = true; error.value = ''
  try {
    const c = id ? await put('/cases/' + id, f.value) : await post('/cases', f.value)
    if (publish === true) await post('/cases/' + c.id + '/publish')
    store.notify(publish === true ? '已發布' : '已儲存草稿', 'success'); router.push('/cases/' + c.id)
  } catch (e) { error.value = e.message } finally { busy.value = false }
}
</script>
