<template>
  <div v-if="c">
    <div class="crumb"><router-link to="/competitions">比賽</router-link>　／　{{ c.shortName || c.name }}</div>

    <section class="card">
      <div class="row" style="align-items:flex-start;gap:22px 34px">
        <div style="flex:1 1 420px;min-width:0">
          <div class="tags"><span class="tag yellow">{{ c.category }}</span><span class="tag">{{ labels.level[c.level] }}</span></div>
          <h1 style="margin-top:12px">{{ c.shortName || c.name }}</h1>
          <p v-if="c.shortName && c.shortName !== c.name" class="strong">{{ c.name }}</p>
          <p class="sub small">{{ c.organizer }}</p>
          <p v-if="c.description" style="line-height:1.75">{{ c.description }}</p>
          <h4 style="margin-top:16px">這場比賽需要的能力</h4>
          <div class="tags">
            <span v-for="s in c.skills" :key="s.skillId" class="tag" :class="{ green: have.has(s.skillId) }">{{ have.has(s.skillId) ? '✓ ' : '' }}{{ s.name }}</span>
          </div>
          <p v-if="student" class="sub small" style="margin-top:8px">{{ have.size ? `打勾的 ${have.size} 項你已經會，其餘可以找隊友補。` : '這些你還沒有紀錄也沒關係：可以找會的隊友，或到個人頁補上你的經驗。' }}</p>
          <p v-if="student && c.eligible === false && c.blockedBy.length" class="small urgent" style="margin-top:6px">注意：{{ c.blockedBy.join('；') }}</p>
        </div>
        <div style="flex:0 1 330px;min-width:260px">
          <div class="tiles">
            <div class="tile"><div class="k">報名截止</div><div class="v">{{ c.applyDeadline ? md(c.applyDeadline) : '未公告' }}</div><div class="n" :class="{ urgent: c.daysLeft >= 0 && c.daysLeft <= 7 }">{{ leftText(c.daysLeft) }}</div></div>
            <div class="tile"><div class="k">每隊人數</div><div class="v">{{ teamSizeText(c.teamMin, c.teamMax) }}</div><div class="n">{{ c.teamMin === 1 && c.teamMax > 1 ? '一個人也能報' : '含隊長' }}</div></div>
            <div class="tile"><div class="k">指導老師</div><div class="v">{{ c.advisorRequired === true ? '需要' : c.advisorRequired === false ? '不需要' : '未註明' }}</div><div class="n">{{ c.eventDate ? '比賽 ' + md(c.eventDate) : '比賽日未公告' }}</div></div>
          </div>
          <a v-if="c.url" :href="c.url" target="_blank" rel="noopener" class="btn white block" style="margin-top:14px">官方網站與報名 <Ico name="out" :size="16" /></a>
          <p class="sub small" style="margin-top:10px">報名在主辦單位的網站完成。日期與資格以官方公告為準{{ c.checkedAt ? `（資料查證日 ${c.checkedAt}）` : '' }}。</p>
        </div>
      </div>
    </section>

    <div class="split" style="margin-top:30px">
      <div>
        <div class="row" style="margin-bottom:14px"><h2 style="margin:0">正在找人的隊伍</h2><span class="tag">{{ teams.length }} 隊</span></div>
        <div v-if="!teams.length" class="card soft empty"><b>這場比賽還沒有隊伍在找人</b>{{ canOpen ? '你可以當第一隊：填右邊的表單就能開隊。' : '' }}</div>
        <div v-for="t in teams" :key="t.id" class="listrow">
          <div class="body">
            <div><router-link :to="'/teams/' + t.id" class="strong" style="font-size:17px;text-decoration:none">{{ t.title }}</router-link>
              <span class="sub small">　隊長 {{ t.owner.name }}（{{ t.owner.department }} {{ grade(t.owner.degree, t.owner.year) }}）· 目前 {{ t.members }}／{{ t.teamSize }} 人 · 缺 {{ t.need }} 人</span></div>
            <p v-if="t.intro" style="margin:4px 0 8px">{{ t.intro }}</p>
            <div class="tags">
              <span v-for="s in t.roles.flatMap(r => r.skills)" :key="s.skillId" class="tag">{{ s.name }}<span v-if="s.required" class="tag-req">必</span></span>
              <template v-if="t.fit && t.fit.passed"><span v-for="g in t.fit.tags" :key="g" class="tag green">{{ g }}</span></template>
            </div>
            <form v-if="applying === t.id" style="margin-top:12px" @submit.prevent="apply(t)">
              <label :for="'note' + t.id">想跟隊長說的話（選填）</label>
              <textarea :id="'note' + t.id" v-model="note" maxlength="300" placeholder="例：我做過兩次提案簡報，週末都有空。"></textarea>
              <div class="row" style="margin-top:8px"><button class="btn sm" :disabled="busy">送出申請</button><button type="button" class="btn sm white" @click="applying = null">先不要</button>
                <span class="hint">送出後會開一個和隊長的對話，可以先聊再決定。</span></div>
            </form>
          </div>
          <template v-if="applying !== t.id">
            <router-link v-if="t.my.isOwner || t.my.isMember" :to="'/teams/' + t.id" class="btn sm white">我的隊伍</router-link>
            <router-link v-else-if="t.my.pending" :to="'/messages?e=' + t.my.pending.id" class="btn sm white">{{ t.my.pending.direction === 'INVITE' ? '隊長邀請了你' : '等回覆中' }}</router-link>
            <button v-else-if="t.fit && t.fit.passed && !myTeam" class="btn sm" @click="applying = t.id; note = ''">申請加入</button>
            <span v-else-if="myTeam" class="why">你已經有隊了</span>
            <span v-else-if="t.fit" class="why" style="max-width:190px">{{ t.fit.blocked[0] }}</span>
          </template>
        </div>

        <section v-if="student && c.advisorRequired && c.status !== 'CLOSED'" class="card soft" style="margin-top:22px">
          <div class="row between"><h3 style="margin:0">這場比賽需要指導老師</h3><button class="btn sm white" :disabled="busy" @click="findTeachers">{{ teachers ? '重新找' : '找專長相符的老師' }}</button></div>
          <TeachersCard v-if="teachers" :data="teachers" style="margin-top:12px" />
          <p v-else class="sub small" style="margin:8px 0 0">依比賽需要的能力，從教師的專長與指導經驗找人選，並列出要你自己向老師確認的事項。</p>
        </section>
      </div>

      <aside>
        <section v-if="myTeam" class="card">
          <h2>你已經有隊了</h2>
          <p>同一場比賽只能參加一隊。你在「{{ myTeam.title }}」（{{ labels.status[myTeam.status] }}）。</p>
          <router-link :to="'/teams/' + myTeam.id" class="btn block">到我的隊伍</router-link>
        </section>
        <section v-else-if="canOpen" class="card">
          <h2>我要開隊</h2>
          <form @submit.prevent="openTeam">
            <div class="field"><label for="tname">隊名</label><input id="tname" v-model.trim="f.title" maxlength="40" required placeholder="例：太陽能小隊" /></div>
            <div class="field"><label for="tneed">還缺幾人</label>
              <div class="row"><input id="tneed" v-model.number="f.need" type="number" min="1" :max="maxNeed" required style="width:96px" /><span class="hint" style="margin:0">這場每隊 {{ teamSizeText(c.teamMin, c.teamMax) }}（含你自己）</span></div></div>
            <div class="field"><label>想找什麼樣的人（至少選 1 項）</label>
              <div class="tags">
                <label v-for="s in options" :key="s.id" class="pick" :class="{ on: picked.has(s.id) }"><input type="checkbox" :checked="picked.has(s.id)" @change="toggle(s.id)" />{{ s.name }}</label>
              </div>
              <select v-model.number="extra" style="margin-top:10px" aria-label="加其他技能" @change="addExtra"><option :value="null">＋ 其他技能…</option>
                <optgroup v-for="(list, cat) in groups" :key="cat" :label="cat"><option v-for="s in list" :key="s.id" :value="s.id" :disabled="options.some(o => o.id === s.id)">{{ s.name }}</option></optgroup></select>
            </div>
            <div v-if="picked.size" class="field"><label>哪些是一定要會的？（可不選）</label>
              <div class="tags"><label v-for="id in [...picked]" :key="id" class="pick" :class="{ on: must.has(id) }"><input type="checkbox" :checked="must.has(id)" @change="toggleMust(id)" />{{ nameOf(id) }}</label></div>
              <div class="hint">勾了「一定要會」的技能，不會的同學就不能申請；沒勾的只影響推薦順序。</div></div>
            <div class="field"><label for="tintro">一句話介紹（選填）</label><textarea id="tintro" v-model.trim="f.intro" maxlength="200" placeholder="例：想認真打進決賽，每週固定討論一次。"></textarea></div>
            <button class="btn block" :disabled="busy">開隊</button>
            <p class="hint" style="margin-top:10px">報名截止日（{{ md(c.applyDeadline) }}）和人數上限會自動帶入。開隊後就會出現在「找隊友」，也會幫你開好隊伍群組。</p>
          </form>
        </section>
        <section v-else class="card soft">
          <h3>{{ c.status === 'CLOSED' ? '報名已經截止' : !c.applyDeadline ? '報名日期還沒公告' : c.teamMax === 1 ? '這是個人賽' : '管理員帳號不能開隊' }}</h3>
          <p class="sub small" style="margin:0">{{ c.status === 'CLOSED' ? '這場比賽不能再開隊或申請。' : !c.applyDeadline ? '公告之後就能開隊。' : c.teamMax === 1 ? '個人賽不需要隊友，直接到官方網站報名。' : '請用學生帳號登入。' }}</p>
        </section>
      </aside>
    </div>
  </div>
  <div v-else class="empty">載入中…</div>
</template>
<script setup>
import { ref, computed, reactive, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { get, post } from '../api'
import { store, labels, md, leftText, grade, teamSizeText } from '../store'
import Ico from '../components/Ico.vue'
import TeachersCard from '../components/TeachersCard.vue'

const route = useRoute(), router = useRouter(), id = +route.params.id
const student = store.user.role !== 'ADMIN'
const c = ref(null), teams = ref([]), teachers = ref(null), busy = ref(false), applying = ref(null), note = ref('')
const f = reactive({ title: '', need: 2, intro: '' }), picked = ref(new Set()), must = ref(new Set()), extras = ref([]), extra = ref(null)

const have = computed(() => new Set((c.value?.strengths || []).map(s => s.skillId)))
const myTeam = computed(() => (c.value?.myCases || []).find(x => ['OPEN', 'FORMED', 'IN_PROGRESS'].includes(x.status)) || null)
const canOpen = computed(() => student && c.value && c.value.status !== 'CLOSED' && !!c.value.applyDeadline && c.value.teamMax !== 1)
const maxNeed = computed(() => c.value?.teamMax ? c.value.teamMax - 1 : 20)
const options = computed(() => [...(c.value?.skills || []).map(s => ({ id: s.skillId, name: s.name })), ...extras.value])
const groups = computed(() => { const g = {}; for (const s of store.meta?.skills || []) (g[s.category] ||= []).push(s); return g })
const nameOf = (sid) => options.value.find(o => o.id === sid)?.name || sid

function toggle(sid) {
  const s = new Set(picked.value)
  if (s.has(sid)) { s.delete(sid); const m = new Set(must.value); m.delete(sid); must.value = m }
  else if (s.size >= 6) return store.notify('想找的技能最多選 6 項', 'error')
  else s.add(sid)
  picked.value = s
}
function toggleMust(sid) { const m = new Set(must.value); m.has(sid) ? m.delete(sid) : m.add(sid); must.value = m }
function addExtra() {
  const s = (store.meta?.skills || []).find(x => x.id === extra.value)
  if (s && !options.value.some(o => o.id === s.id)) { extras.value = [...extras.value, { id: s.id, name: s.name }]; toggle(s.id) }
  extra.value = null
}
async function load() {
  const [comp, wall] = await Promise.all([get('/competitions/' + id), get('/cases/wall?competitionId=' + id)])
  c.value = comp; teams.value = wall
  if (f.need > maxNeed.value) f.need = maxNeed.value
}
async function guard(fn) { busy.value = true; try { return await fn() } catch (e) { store.notify(e.reasons?.length ? `${e.message}：${e.reasons.join('；')}` : e.message, 'error') } finally { busy.value = false } }
const openTeam = () => guard(async () => {
  if (!picked.value.size) return store.notify('至少選 1 項想找的技能', 'error')
  const team = await post('/cases', { competitionId: id, title: f.title, need: f.need, intro: f.intro,
    skills: [...picked.value].map(sid => ({ skillId: sid, required: must.value.has(sid), minLevel: 1 })) })
  store.notify('開隊成功，已經出現在「找隊友」', 'success'); router.push('/teams/' + team.id)
})
const apply = (t) => guard(async () => {
  const e = await post(`/roles/${t.fit.roleId}/engagements`, { direction: 'APPLY', message: note.value.trim() })
  store.notify('申請送出了，可以先和隊長聊聊', 'success'); router.push('/messages?e=' + e.id)
})
const findTeachers = () => guard(async () => { teachers.value = await post('/agents/teachers', { competitionId: id, limit: 5 }) })
onMounted(async () => { try { await store.loadMeta(); await load() } catch (e) { store.notify(e.message, 'error'); router.replace('/competitions') } })
</script>
