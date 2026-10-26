<template>
  <div v-if="c">
    <div class="row between" style="margin-bottom:14px">
      <div>
        <div class="row"><span class="pill" :class="statusColor(c.status)">{{ labels.status[c.status] }}</span><span class="pill">{{ labels.type[c.type] }}</span><span v-if="c.attribution" class="pill purple">成果歸屬：{{ labels.attribution[c.attribution] }}</span></div>
        <h1 style="margin-top:6px">{{ c.title }}</h1>
        <div class="sub">發案方 <router-link :to="'/users/' + c.ownerId">{{ c.ownerName }}</router-link>（{{ c.ownerCollege }}／{{ c.ownerDepartment }}） · 每隊 {{ c.teamSize }} 人 · 申請截止 {{ fmtTime(c.applyDeadline) }} · 期間 {{ c.startDate }} ～ {{ c.endDate }}</div>
      </div>
      <div class="row" v-if="c.isOwner">
        <router-link v-if="c.status === 'DRAFT'" :to="'/cases/' + c.id + '/edit'" class="btn secondary">編輯</router-link>
        <button v-if="c.status === 'DRAFT'" class="btn" @click="act('publish')">發布</button>
        <button v-if="c.status === 'FORMED'" class="btn" @click="act('start')">開始執行</button>
        <button v-if="['FORMED','IN_PROGRESS'].includes(c.status)" class="btn secondary" @click="closeOpen = true">提出結案</button>
        <button v-if="['DRAFT','OPEN','FORMED'].includes(c.status)" class="btn danger" @click="act('cancel')">取消案件</button>
      </div>
    </div>
    <p v-if="c.description" class="card" style="white-space:pre-wrap">{{ c.description }}</p>

    <!-- 結案確認 -->
    <div v-if="closeOpen" class="card" style="border:1px solid var(--accent)">
      <h3>提出結案</h3>
      <p class="sub small">成員在 72 小時內確認，超過一半同意就成立；未回應視為同意（D34）。完成與未完成都會開放互評（D35）。</p>
      <div class="row"><button class="btn" @click="requestClose('COMPLETED')">完成結案</button><button class="btn secondary" @click="requestClose('INCOMPLETE')">未完成（中途解散）</button><button class="btn ghost" @click="closeOpen = false">取消</button></div>
    </div>
    <div v-if="c.closeRequest && c.closeRequest.status === 'OPEN'" class="card" style="border:1px solid var(--orange)">
      <h3>結案確認中</h3>
      <p class="sub small">發案方提出「{{ c.closeRequest.result === 'COMPLETED' ? '完成' : '未完成' }}」結案，期限 {{ fmtTime(c.closeRequest.dueAt) }}；已投票 {{ c.closeRequest.votes.length }} 人。</p>
      <div v-if="c.isMember && !c.isOwner && !c.closeRequest.myVote" class="row"><button class="btn" @click="vote(true)">同意結案</button><button class="btn secondary" @click="vote(false)">不同意</button></div>
      <div v-else-if="c.closeRequest.myVote" class="sub small">你已投票：{{ c.closeRequest.myVote.agree ? '同意' : '不同意' }}</div>
    </div>
    <div v-if="c.status === 'CLOSED'" class="card" style="border:1px solid var(--purple)">
      <div class="row between"><div><h3 style="margin:0">已結案（{{ c.closeResult === 'COMPLETED' ? '完成' : '未完成' }}）· {{ fmtTime(c.closedAt) }}</h3><div class="sub small">雙盲互評：雙方都送出或 72 小時到期才同時公開（D40）</div></div>
        <router-link v-if="c.pendingReviews > 0" :to="'/cases/' + c.id + '/review'" class="btn">完成互評（{{ c.pendingReviews }}）</router-link><span v-else-if="c.isMember" class="pill green">你已完成互評</span></div>
    </div>

    <div class="grid grid-2" style="margin-top:16px">
      <div class="stack">
        <div class="card" v-for="r in c.roles" :key="r.id">
          <div class="row between">
            <div><h3 style="margin:0">{{ r.roleName }}</h3><div class="sub small">名額 {{ r.filledCount }}/{{ r.headcount }} · 每週 {{ r.hoursPerWeek }} 小時<span v-if="c.isOwner"> · 待處理邀請 {{ r.pendingInvites }} · 可邀請 {{ r.invitable }}（D25）</span></div></div>
            <div v-if="!c.isOwner && c.status === 'OPEN'">
              <span v-if="myEng(r.id)" class="pill" :class="myEng(r.id).status === 'PENDING' ? 'orange' : myEng(r.id).status === 'ACCEPTED' ? 'green' : ''">{{ myEng(r.id).direction === 'INVITE' ? '邀請' : '申請' }}：{{ labels.eng[myEng(r.id).status] }}</span>
              <button v-else-if="!c.isMember && r.filledCount < r.headcount" class="btn sm" @click="apply(r)">申請此角色</button>
            </div>
            <button v-if="c.isOwner && c.status === 'OPEN'" class="btn sm secondary" @click="loadRec(r)">{{ rec[r.id] ? '重新整理推薦' : '查看推薦人選' }}</button>
          </div>
          <div class="row" style="margin-top:8px"><span v-for="s in r.skills" :key="s.skillId" class="chip">{{ s.name }} <span class="lv">≥{{ s.minLevel }}</span> <span :class="s.isRequired ? 'tag-req' : 'tag-opt'">{{ s.isRequired ? '必要' : '加分' }}</span></span></div>
          <div v-if="myEng(r.id) && myEng(r.id).status === 'PENDING'" class="row" style="margin-top:8px">
            <span class="sub small">{{ hoursLeft(myEng(r.id).dueAt) }} 小時內需回覆</span>
            <template v-if="myEng(r.id).direction === 'INVITE'"><button class="btn sm" @click="engAct(myEng(r.id).id, 'accept')">接受邀請</button><button class="btn sm secondary" @click="engAct(myEng(r.id).id, 'decline')">拒絕</button></template>
            <button v-else class="btn sm secondary" @click="engAct(myEng(r.id).id, 'withdraw')">撤回申請</button>
          </div>
          <!-- 推薦名單（發案方） -->
          <div v-if="rec[r.id]" style="margin-top:14px">
            <div class="row between"><h3 style="margin:0">推薦人選 <span class="sub small">分數 = 100 × (0.4S + 0.2T + 0.2R + 0.1P + 0.1C)，S 已乘可信度係數</span></h3></div>
            <div v-if="!rec[r.id].recommended.length" class="empty">沒有人通過閘門</div>
            <div class="stack" style="margin-top:8px">
              <ScoreCard v-for="p in rec[r.id].recommended" :key="p.userId" :item="p" :weights="rec[r.id].weights">
                <template #action><button class="btn sm" :disabled="rec[r.id].role.invitable <= 0" @click="invite(r, p)">邀請</button></template>
              </ScoreCard>
            </div>
            <details v-if="rec[r.id].blocked.length" style="margin-top:10px"><summary class="sub small" style="cursor:pointer">技能符合但被閘門擋下的 {{ rec[r.id].blocked.length }} 人（顯示原因）</summary>
              <div class="stack" style="margin-top:8px"><ScoreCard v-for="p in rec[r.id].blocked" :key="p.userId" :item="p" :weights="rec[r.id].weights" /></div></details>
          </div>
        </div>
      </div>
      <div class="stack">
        <div class="card">
          <h3>成員（{{ c.members.length }}/{{ c.teamSize }}）</h3>
          <table><tr v-for="m in c.members" :key="m.userId"><td><router-link :to="'/users/' + m.userId">{{ m.name }}</router-link><div class="sub small">{{ m.college }}／{{ m.department }}</div></td><td style="text-align:right"><span class="pill" :class="m.isOwner ? 'blue' : ''">{{ m.isOwner ? '發案方' : m.roleName }}</span></td></tr></table>
        </div>
        <div class="card" v-if="c.isOwner && c.engagements">
          <h3>申請與邀請</h3>
          <div v-if="!c.engagements.length" class="empty">還沒有申請或邀請</div>
          <table v-else><tr v-for="e in c.engagements" :key="e.id">
            <td><router-link :to="'/users/' + e.userId"><strong>{{ e.name }}</strong></router-link> <span class="sub small">{{ e.department }}</span><div class="sub small">{{ e.direction === 'APPLY' ? '申請' : '你邀請' }} {{ e.roleName }} · 分數 {{ e.score }}<span v-if="e.message"> · 「{{ e.message }}」</span></div></td>
            <td style="text-align:right;white-space:nowrap"><span class="pill" :class="e.status === 'PENDING' ? 'orange' : e.status === 'ACCEPTED' ? 'green' : ''">{{ labels.eng[e.status] }}</span>
              <div v-if="e.status === 'PENDING'" class="row" style="justify-content:flex-end;margin-top:6px">
                <template v-if="e.direction === 'APPLY'"><button class="btn sm" @click="engAct(e.id, 'accept')">核准</button><button class="btn sm secondary" @click="engAct(e.id, 'decline')">拒絕</button></template>
                <button v-else class="btn sm secondary" @click="engAct(e.id, 'withdraw')">撤回邀請</button>
              </div>
              <div v-if="e.status === 'PENDING'" class="sub small">{{ hoursLeft(e.dueAt) }} 小時後逾時</div></td>
          </tr></table>
        </div>
      </div>
    </div>
  </div>
</template>
<script setup>
import { ref, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { get, post } from '../api'
import { store, labels, fmtTime, hoursLeft, statusColor } from '../store'
import ScoreCard from '../components/ScoreCard.vue'
const route = useRoute()
const c = ref(null), rec = ref({}), closeOpen = ref(false)
const myEng = (roleId) => c.value.myEngagements.find(e => e.roleId === roleId && ['PENDING', 'ACCEPTED'].includes(e.status)) || c.value.myEngagements.find(e => e.roleId === roleId)
async function load() { c.value = await get('/cases/' + route.params.id) }
async function loadRec(r) { try { rec.value[r.id] = await get('/roles/' + r.id + '/recommendations') } catch (e) { store.notify(e.message, 'error') } }
async function run(fn, ok) { try { await fn(); if (ok) store.notify(ok, 'success'); await load() } catch (e) { store.notify(e.reasons && e.reasons.length ? e.message + '：' + e.reasons.join('；') : e.message, 'error') } }
const act = (what) => run(() => post('/cases/' + c.value.id + '/' + what), '已更新')
const engAct = (id, what) => run(() => post('/engagements/' + id + '/' + what), '已處理')
const apply = (r) => run(() => post('/roles/' + r.id + '/engagements', { direction: 'APPLY', message: '' }), '已送出申請，發案方將在期限內回覆')
const invite = (r, p) => run(async () => { await post('/roles/' + r.id + '/engagements', { direction: 'INVITE', userId: p.userId, message: '' }); await loadRec(r) }, '已送出邀請，對方將在期限內回覆')
const requestClose = (result) => run(async () => { await post('/cases/' + c.value.id + '/close-requests', { result }); closeOpen.value = false }, '已提出結案')
const vote = (agree) => run(() => post('/close-requests/' + c.value.closeRequest.id + '/votes', { agree }), '已投票')
onMounted(load)
</script>
