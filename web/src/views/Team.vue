<template>
  <div v-if="t">
    <div class="crumb"><router-link to="/">找隊友</router-link>　／　{{ t.title }}</div>

    <section class="card">
      <div class="row" style="align-items:flex-start;gap:20px 30px">
        <div style="flex:1 1 420px;min-width:0">
          <div class="tags">
            <span v-if="t.competitionCategory" class="tag yellow">{{ t.competitionCategory }}</span>
            <span class="tag" :class="statusTag(t.status)">{{ labels.status[t.status] }}{{ t.status === 'OPEN' ? ' · 還缺 ' + t.need + ' 人' : '' }}</span>
            <span v-if="t.rosterLocked" class="tag grey">名單鎖定</span>
            <span v-if="t.isOwner" class="tag peach">我是隊長</span><span v-else-if="t.isMember" class="tag peach">我的隊伍</span>
          </div>
          <h1 style="margin-top:12px">{{ t.title }}</h1>
          <p class="sub">
            <router-link v-if="t.competitionId" :to="'/competitions/' + t.competitionId" class="strong">{{ t.competitionName }}</router-link>
            · 隊長 {{ t.ownerName }}（{{ t.ownerDepartment }}）· 目前 {{ t.members.length }}／{{ t.teamSize }} 人
            <template v-if="t.competitionDeadline"> · 報名截止 {{ md(t.competitionDeadline) }}（<span :class="{ urgent: t.daysLeft >= 0 && t.daysLeft <= 7 }">{{ leftText(t.daysLeft) }}</span>）</template>
          </p>
          <p v-if="t.description" style="font-size:16px;line-height:1.75">{{ t.description }}</p>
          <h4 style="margin-top:14px">想找的人</h4>
          <div class="tags"><span v-for="s in skills" :key="s.skillId" class="tag">{{ s.name }}{{ s.minLevel > 1 ? ' ' + labels.tier[s.minLevel] + '以上' : '' }}<span v-if="s.isRequired" class="tag-req">一定要會</span></span></div>
        </div>

        <div style="flex:0 1 330px;min-width:260px">
          <template v-if="t.isMember">
            <button v-if="active" class="btn block" @click="openGroup"><Ico name="chat" />進入隊伍群組</button>
            <router-link v-if="t.pendingReviews" :to="`/cases/${t.id}/review`" class="btn block" style="margin-top:12px">給隊友回饋（{{ t.pendingReviews }} 位）</router-link>
            <p v-if="!active" class="sub small" style="margin:10px 0 0">{{ endedText }}</p>
          </template>
          <template v-else-if="admin"><p class="sub small">管理員只能檢視隊伍，不能申請。</p></template>
          <template v-else-if="pending">
            <p class="strong" style="margin-bottom:8px">{{ pending.direction === 'INVITE' ? '隊長邀請你加入' : '申請送出了，等隊長回覆' }}</p>
            <p class="sub small">回覆期限 {{ fmtTime(pending.dueAt) }}，逾時會自動失效。</p>
            <router-link :to="'/messages?e=' + pending.id" class="btn block">去聊聊</router-link>
            <div class="row" style="margin-top:12px">
              <template v-if="pending.direction === 'INVITE'"><button class="btn sm" :disabled="busy" @click="respond(pending.id, 'accept')">接受邀請</button><button class="btn sm white" :disabled="busy" @click="respond(pending.id, 'decline')">婉拒</button></template>
              <ConfirmButton v-else question="要取消這筆申請嗎？" yes="取消申請" :disabled="busy" @confirm="respond(pending.id, 'withdraw')">取消申請</ConfirmButton>
            </div>
          </template>
          <template v-else-if="t.status === 'OPEN'">
            <form v-if="fit && fit.passed" @submit.prevent="apply">
              <div class="tags" style="margin-bottom:10px"><span v-for="g in fit.tags" :key="g" class="tag green">{{ g }}</span></div>
              <label for="note">想跟隊長說的話（選填）</label>
              <textarea id="note" v-model="note" maxlength="300" placeholder="例：我做過兩次提案簡報，週末都有空。"></textarea>
              <button class="btn block" style="margin-top:10px" :disabled="busy">申請加入</button>
              <p class="hint">送出後會開一個和隊長的對話，可以先聊再決定。隊長 72 小時內沒回覆會自動失效。</p>
            </form>
            <div v-else-if="fit">
              <p class="strong" style="margin-bottom:6px">目前還不能申請這一隊</p>
              <ul class="tight" style="font-size:14px;color:var(--ink)"><li v-for="b in fit.blocked" :key="b">{{ b }}</li></ul>
              <p class="hint" style="margin-top:10px">技能是從個人頁的修課、證照、作品與得獎整理出來的。<router-link to="/profile">到個人頁補上經驗</router-link></p>
            </div>
          </template>
          <p v-else class="sub small">{{ endedText || '這支隊伍已經不在招募。' }}</p>
        </div>
      </div>
    </section>

    <RegistrationTrack v-if="t.isMember && active" :team="t" plain style="margin-top:22px" @changed="onChanged" />

    <div class="grid grid-2" style="margin-top:22px;align-items:start">
      <section class="card soft">
        <div class="row between"><h3 style="margin:0">隊伍成員（{{ t.members.length }} 人）</h3>
          <ConfirmButton v-if="t.isMember && !t.isOwner && canChange" question="確定要退出這支隊伍嗎？" yes="退出隊伍" danger :disabled="busy" @confirm="leave">退出隊伍</ConfirmButton></div>
        <div v-for="m in t.members" :key="m.userId" class="row between" style="padding:10px 0;border-top:1px solid var(--line);margin-top:10px">
          <div class="row" style="flex-wrap:nowrap;min-width:0"><span class="avatar">{{ initial(m.name) }}</span>
            <div style="min-width:0"><router-link :to="'/users/' + m.userId" class="strong">{{ m.name }}</router-link> <span v-if="m.isOwner" class="tag yellow">隊長</span>
              <div class="sub small">{{ m.department }} {{ grade(m.degree, m.year) }}</div></div></div>
          <ConfirmButton v-if="t.isOwner && !m.isOwner && canChange" :question="`要請 ${m.name} 離開隊伍嗎？`" yes="請離" danger :disabled="busy" @confirm="remove(m)">請離</ConfirmButton>
        </div>
        <p v-if="t.rosterLocked" class="hint" style="margin-top:10px">已經報名，名單鎖定。</p>
      </section>

      <div v-if="t.isOwner" class="stack">
        <section v-if="applications.length" class="card soft">
          <h3>等你回覆的申請（{{ applications.length }}）</h3>
          <div v-for="e in applications" :key="e.id" style="padding:10px 0;border-top:1px solid var(--line)">
            <div class="row between"><div class="row" style="flex-wrap:nowrap"><span class="avatar sm">{{ initial(e.name) }}</span>
                <div><router-link :to="'/users/' + e.userId" class="strong">{{ e.name }}</router-link><div class="sub small">{{ e.department }} {{ grade(e.degree, e.year) }} · {{ hoursLeft(e.dueAt) }} 小時內要回覆</div></div></div>
              <div class="row"><button class="btn sm" :disabled="busy" @click="respond(e.id, 'accept')">接受</button><button class="btn sm white" :disabled="busy" @click="respond(e.id, 'decline')">婉拒</button>
                <router-link :to="'/messages?e=' + e.id" class="btn sm white">聊聊</router-link></div></div>
            <p v-if="e.message" class="small" style="margin:8px 0 0;background:var(--grey-bg);border-radius:12px;padding:8px 12px">{{ e.message }}</p>
          </div>
        </section>
        <section v-if="invites.length" class="card soft">
          <h3>邀請中，等對方回覆（{{ invites.length }}）</h3>
          <div v-for="e in invites" :key="e.id" class="row between" style="padding:10px 0;border-top:1px solid var(--line)">
            <div class="row" style="flex-wrap:nowrap"><span class="avatar sm">{{ initial(e.name) }}</span>
              <div><router-link :to="'/users/' + e.userId" class="strong">{{ e.name }}</router-link><div class="sub small">{{ e.department }} {{ grade(e.degree, e.year) }} · 還有 {{ hoursLeft(e.dueAt) }} 小時</div></div></div>
            <div class="row"><router-link :to="'/messages?e=' + e.id" class="btn sm white">聊聊</router-link>
              <ConfirmButton question="要取消這筆邀請嗎？" yes="取消邀請" :disabled="busy" @confirm="respond(e.id, 'withdraw')">取消邀請</ConfirmButton></div>
          </div>
        </section>

        <section v-if="t.status === 'OPEN'" class="card soft">
          <div class="row between"><h3 style="margin:0">推薦的隊友</h3><span class="sub small">還能邀請 {{ invitable }} 人</span></div>
          <p class="sub small" style="margin:6px 0 0">符合「一定要會」的技能、時間配合得上的同學，最適合的排前面。</p>
          <div v-if="!rec" class="empty">整理中…</div>
          <div v-else-if="!rec.length" class="empty">目前沒有符合條件的同學。可以把「一定要會」的技能放寬，或等同學來申請。</div>
          <div v-for="p in (rec || []).slice(0, more ? 20 : 6)" :key="p.userId" style="padding:10px 0;border-top:1px solid var(--line);margin-top:10px">
            <div class="row between"><div class="row" style="flex-wrap:nowrap;min-width:0"><span class="avatar sm">{{ initial(p.name) }}</span>
                <div style="min-width:0"><router-link :to="'/users/' + p.userId" class="strong">{{ p.name }}</router-link><div class="sub small">{{ p.dept }} {{ grade(p.degree, p.year) }}</div></div></div>
              <button v-if="inviting !== p.userId" class="btn sm white" :disabled="busy || invitable <= 0" @click="inviting = p.userId; note = ''">邀請</button></div>
            <div class="tags" style="margin-top:8px"><span v-for="g in plainTags(p)" :key="g" class="tag" :class="{ green: g === '跨學院' || g === '不同系' }">{{ g }}</span></div>
            <form v-if="inviting === p.userId" style="margin-top:10px" @submit.prevent="invite(p)">
              <label :for="'inv' + p.userId">想跟 {{ p.name }} 說的話（選填）</label>
              <textarea :id="'inv' + p.userId" v-model="note" maxlength="300" placeholder="例：看到你會資料分析，想邀請你一起打這場比賽。"></textarea>
              <div class="row" style="margin-top:8px"><button class="btn sm" :disabled="busy">送出邀請</button><button type="button" class="btn sm white" @click="inviting = null">先不要</button></div>
            </form>
          </div>
          <button v-if="rec && rec.length > 6 && !more" class="btn sm white block" style="margin-top:12px" @click="more = true">看更多（還有 {{ rec.length - 6 }} 位）</button>
        </section>

        <section v-if="['OPEN', 'FORMED'].includes(t.status)" class="card soft">
          <h3>隊伍管理</h3>
          <div class="row">
            <ConfirmButton v-if="t.status === 'OPEN'" question="用目前的名單成隊？還在等回覆的申請與邀請會一併結束。" yes="確認成隊" :disabled="busy" @confirm="act('form', '成隊了，下一步是到比賽官網報名')">人夠了，提前成隊</ConfirmButton>
            <ConfirmButton question="解散後不能復原，隊友會收到通知。" yes="解散隊伍" danger :disabled="busy" @confirm="act('cancel', '隊伍已解散')">解散隊伍</ConfirmButton>
          </div>
          <p class="hint" style="margin-top:10px">{{ t.status === 'OPEN' ? '名額收滿會自動成隊；還沒滿但人夠了，可以提前成隊。' : '已經成隊。有人退出的話，隊伍會回到招募中。' }}</p>
        </section>
      </div>
    </div>
  </div>
  <div v-else class="empty">載入中…</div>
</template>
<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { get, post, del } from '../api'
import { store, labels, md, leftText, grade, initial, fmtTime, hoursLeft, statusTag } from '../store'
import { onEvent } from '../realtime'
import Ico from '../components/Ico.vue'
import ConfirmButton from '../components/ConfirmButton.vue'
import RegistrationTrack from '../components/RegistrationTrack.vue'

const route = useRoute(), router = useRouter(), id = +route.params.id
const admin = store.user.role === 'ADMIN'
const t = ref(null), fit = ref(null), rec = ref(null), busy = ref(false), note = ref(''), inviting = ref(null), more = ref(false)

const skills = computed(() => t.value.roles.flatMap(r => r.skills))
const active = computed(() => ['OPEN', 'FORMED', 'IN_PROGRESS'].includes(t.value.status))
const canChange = computed(() => ['OPEN', 'FORMED'].includes(t.value.status) && !t.value.rosterLocked)
const pending = computed(() => (t.value.myEngagements || []).find(e => e.status === 'PENDING') || null)
const applications = computed(() => (t.value.engagements || []).filter(e => e.status === 'PENDING' && e.direction === 'APPLY'))
const invites = computed(() => (t.value.engagements || []).filter(e => e.status === 'PENDING' && e.direction === 'INVITE'))
const invitable = computed(() => t.value.roles.reduce((n, r) => n + r.invitable, 0))
const endedText = computed(() => ({ CLOSED: '比賽結束了，隊伍已經結束。', CANCELLED: '這支隊伍已經解散。', EXPIRED: '報名截止前沒有成隊，隊伍已經結束。' }[t.value.status] || ''))

// 推薦名單的理由只留白話的部分：會哪些想找的技能、是不是跨系；分數與比率不放在畫面上
function plainTags(p) {
  const out = []
  for (const r of p.reasons || []) {
    const m = /^(.+?) (初階|中階|進階)・.+（需求/.exec(r)
    if (m) out.push(`${m[1]} ${m[2]}`)
    else if (r.startsWith('跨學院')) out.push('跨學院')
    else if (r.startsWith('同學院不同系')) out.push('不同系')
  }
  out.push(`每週可投入 ${p.hoursPerWeek} 小時`)
  return out
}

async function load() {
  t.value = await get('/cases/' + id)
  if (!admin && !t.value.isMember && t.value.status === 'OPEN' && t.value.competitionId) {
    const card = (await get('/cases/wall?competitionId=' + t.value.competitionId)).find(x => x.id === id)
    fit.value = card ? card.fit : null
  }
  if (t.value.isOwner && t.value.status === 'OPEN' && t.value.roles.length) {
    try { rec.value = (await get(`/roles/${t.value.roles[0].id}/recommendations`)).recommended } catch { rec.value = [] }
  }
}
async function guard(fn, done) {
  busy.value = true
  try { const r = await fn(); if (done) store.notify(done, 'success'); return r }
  catch (e) { store.notify(e.reasons?.length ? `${e.message}：${e.reasons.join('；')}` : e.message, 'error') } finally { busy.value = false }
}
const onChanged = (team) => { t.value = team }
const apply = () => guard(async () => {
  const e = await post(`/roles/${fit.value.roleId}/engagements`, { direction: 'APPLY', message: note.value.trim() })
  store.notify('申請送出了，可以先和隊長聊聊', 'success'); router.push('/messages?e=' + e.id)
})
const invite = (p) => guard(async () => {
  await post(`/roles/${t.value.roles[0].id}/engagements`, { direction: 'INVITE', userId: p.userId, message: note.value.trim() })
  inviting.value = null; await load()
}, '邀請送出了')
const respond = (eid, what) => guard(async () => { await post(`/engagements/${eid}/${what}`); await load() },
  { accept: '成為隊友了', decline: '已婉拒', withdraw: '已取消' }[what])
const act = (what, done) => guard(async () => { t.value = await post(`/cases/${id}/${what}`); await load() }, done)
const remove = (m) => guard(async () => { t.value = await del(`/cases/${id}/members/${m.userId}`); await load() }, `${m.name} 已離開隊伍`)
const leave = () => guard(async () => { await post(`/cases/${id}/leave`); store.notify('已退出隊伍', 'success'); router.push('/') })
const openGroup = () => guard(async () => { router.push('/messages/' + (await get(`/cases/${id}/conversation`)).conversationId) })

// 有人申請、接受、退出時，畫面跟著更新
const off = onEvent((ev) => { if ((ev.type === 'team.updated' || ev.type === 'engagement.updated') && ev.caseId === id) load().catch(() => {}) })
onMounted(async () => { try { await load() } catch (e) { store.notify(e.message, 'error'); router.replace('/') } })
onUnmounted(off)
</script>
