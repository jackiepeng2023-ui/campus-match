<template>
  <div>
    <div class="row between" style="margin-bottom:16px">
      <div><h1>案件</h1><div class="sub">專題、競賽、短期支援、研究協作都是案件，規則相同（D18）</div></div>
      <router-link to="/cases/new" class="btn">＋ 發布需求</router-link>
    </div>
    <div class="card" style="padding:14px">
      <div class="row">
        <input v-model="q" placeholder="搜尋標題或描述" style="max-width:260px" @keyup.enter="load" />
        <select v-model="type" style="max-width:150px" @change="load"><option value="">所有類型</option><option v-for="(l, k) in labels.type" :key="k" :value="k">{{ l }}</option></select>
        <select v-model="status" style="max-width:150px" @change="load"><option value="">所有狀態</option><option v-for="(l, k) in labels.status" :key="k" :value="k">{{ l }}</option></select>
        <select v-model="skillId" style="max-width:180px" @change="load"><option value="">所有技能</option><option v-for="s in store.meta?.skills" :key="s.id" :value="s.id">{{ s.category }}｜{{ s.name }}</option></select>
        <div class="segment"><button :class="{on: scope==='all'}" @click="scope='all';load()">全部</button><button :class="{on: scope==='mine'}" @click="scope='mine';load()">我發起</button><button :class="{on: scope==='member'}" @click="scope='member';load()">我參與</button></div>
      </div>
    </div>
    <div class="card" style="margin-top:16px">
      <div v-if="!items.length" class="empty">{{ loaded ? '沒有符合的案件' : '載入中…' }}</div>
      <table v-else><tr><th>案件</th><th>類型</th><th>發案方</th><th>需要</th><th>名額</th><th>截止</th><th>狀態</th></tr>
        <tr v-for="c in items" :key="c.id">
          <td><router-link :to="'/cases/' + c.id"><strong>{{ c.title }}</strong></router-link><div class="sub small">{{ c.roleNames }}</div></td>
          <td>{{ labels.type[c.type] }}</td>
          <td class="small">{{ c.ownerName }}<div class="sub">{{ c.ownerCollege }}</div></td>
          <td class="small">{{ c.skillNames }}</td>
          <td>{{ c.filled }}/{{ c.headcount }}</td>
          <td class="small">{{ fmtDate(c.applyDeadline) }}</td>
          <td><span class="pill" :class="statusColor(c.status)">{{ labels.status[c.status] }}</span></td>
        </tr></table>
    </div>
  </div>
</template>
<script setup>
import { ref, onMounted } from 'vue'
import { get } from '../api'
import { store, labels, fmtDate, statusColor } from '../store'
const items = ref([]), q = ref(''), type = ref(''), status = ref(''), skillId = ref(''), scope = ref('all'), loaded = ref(false)
async function load() {
  const p = new URLSearchParams()
  if (q.value) p.set('q', q.value); if (type.value) p.set('type', type.value); if (status.value) p.set('status', status.value); if (skillId.value) p.set('skillId', skillId.value)
  if (scope.value === 'mine') p.set('mine', 'true'); if (scope.value === 'member') p.set('member', 'true')
  items.value = await get('/cases?' + p.toString()); loaded.value = true
}
onMounted(async () => { await store.loadMeta(); await load() })
</script>
