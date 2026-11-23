<template>
  <div class="acard confirm" :class="a.status.toLowerCase()">
    <h4><span class="pill" :class="{ PENDING: 'orange', DONE: 'green', FAILED: 'red' }[a.status] || ''">{{ { PENDING: '待你確認', DONE: '已執行', CANCELLED: '已取消', FAILED: '執行失敗' }[a.status] }}</span>{{ a.title }}</h4>
    <div class="kv">
      <span>競賽</span><span><router-link :to="'/competitions/' + p.competitionId">{{ p.competitionName }}</router-link></span>
      <span>隊伍</span><span>{{ p.teamSize }} 人（含你）· 招募截止 {{ p.applyDeadline }} · 期間 {{ p.startDate }} ~ {{ p.endDate }}</span>
      <span>角色</span><span><div v-for="r in p.roles" :key="r.roleName"><strong>{{ r.roleName }}</strong>：{{ r.inviteName ? '邀請 ' + r.inviteName + '（' + r.inviteDepartment + '）' : '公開招募' }}
        <span class="sub small">條件 {{ r.skills.map(s => s.name + ' ' + labels.tier[s.minLevel] + (s.isRequired ? '' : '（加分）')).join('、') }} · 每週 {{ r.hoursPerWeek }} 小時</span></div></span>
      <span>指導老師</span><span>{{ p.advisorName || '尚未決定（確認後可在隊伍頁補上）' }}</span>
    </div>
    <template v-if="a.status === 'PENDING'">
      <p class="small" style="margin:10px 0 8px;color:#b86a00">按下確認後才會：① 開隊並開始招募　② 送出 {{ invites }} 封邀請（對方 72 小時內回覆，逾時自動視為放棄）。指導老師不會收到通知，需自行聯絡。不確認就不會有任何變動。</p>
      <div class="row"><button class="btn sm" :disabled="busy" @click="decide('confirm')">確認，建立並送出邀請</button><button class="btn secondary sm" :disabled="busy" @click="decide('cancel')">取消</button></div>
    </template>
    <div v-else-if="a.result" class="small" style="margin-top:10px">
      <div v-if="a.result.caseId">隊伍已建立：<router-link :to="'/cases/' + a.result.caseId">{{ a.result.title }}</router-link></div>
      <div v-if="a.result.invited && a.result.invited.length">已邀請：{{ a.result.invited.map(i => i.name + '（' + i.role + '）').join('、') }}</div>
      <div v-if="a.result.failed && a.result.failed.length" style="color:var(--red)">未送出：{{ a.result.failed.map(i => i.name + '—' + i.reason).join('；') }}</div>
      <div v-if="a.result.error" style="color:var(--red)">{{ a.result.error }}</div>
    </div>
  </div>
</template>
<script setup>
// 待確認動作：AI 助理與 Agent 只能提出草稿，使用者按確認才會開隊、送出邀請
import { ref, computed } from 'vue'
import { post } from '../api'
import { store, labels } from '../store'
const props = defineProps({ card: Object })
const emit = defineEmits(['changed'])
const a = ref({ ...props.card }), busy = ref(false)
const p = computed(() => a.value.payload)
const invites = computed(() => p.value.roles.filter(r => r.inviteUserId).length)
async function decide(what) {
  busy.value = true
  try { const r = await post(`/assistant/actions/${a.value.actionId || a.value.id}/${what}`); a.value = { ...a.value, status: r.status, result: r.result }; store.notify({ DONE: '已建立案件並送出邀請', CANCELLED: '已取消，沒有任何變動', FAILED: '執行失敗：' + (r.result?.error || '') }[r.status], r.status === 'FAILED' ? 'error' : 'success'); emit('changed', r) }
  catch (e) { store.notify(e.message, 'error') } finally { busy.value = false }
}
</script>
