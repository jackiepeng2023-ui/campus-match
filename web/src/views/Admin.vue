<template>
  <div v-if="p">
    <h1>管理後台</h1>
    <p class="sub">權重、係數、等級門檻、參數都在資料表裡，改了立即生效；AI 擷取的資料、學生自述的證據在這裡核准與驗證；AI 助理的評測指標與操作軌跡也在這裡（D37、D38、D41、D53–D57）。</p>
    <div class="grid grid-2">
      <div class="card">
        <h3>排序權重（總和須為 1.0）</h3>
        <table><tr v-for="w in p.weights" :key="w.key"><td>{{ w.label }}（{{ w.key }}）</td><td><input v-model.number="weights[w.key]" type="number" step="0.05" min="0" max="1" style="max-width:100px" /></td></tr></table>
        <div class="row between" style="margin-top:8px"><span class="sub small">目前總和 {{ sum.toFixed(2) }}</span><button class="btn sm" @click="save">儲存權重</button></div>
        <h3 style="margin-top:16px">可信度係數（依相符度平均）</h3>
        <table><tr><th>相符度</th><th>係數</th></tr><tr v-for="c in p.credibility" :key="c.matchLevel"><td>{{ c.matchLevel === 0 ? '尚無互評' : c.matchLevel }}</td><td><input v-model.number="cred[c.matchLevel]" type="number" step="0.1" min="0" max="1" style="max-width:100px" /></td></tr></table>
        <h3 style="margin-top:16px">系統參數</h3>
        <table><tr v-for="s in p.params" :key="s.key"><td class="small">{{ s.label }}</td><td><input v-model.number="params[s.key]" type="number" style="max-width:100px" /></td></tr></table>
        <button class="btn sm" style="margin-top:8px" @click="save">儲存全部</button>
        <h3 style="margin-top:16px">等級三階的門檻 <span class="sub small">教師討論表註明「可修改」；儲存後全體重新盤點（D53）</span></h3>
        <table><tr><th></th><th v-for="n in 3" :key="n">{{ labels.tier[n] }}（最低分）</th></tr>
          <tr v-for="g in ['BACHELOR', 'GRADUATE']" :key="g"><td class="small">{{ g === 'BACHELOR' ? '共同量尺（學士成績直接採用）' : '研究所修課成績（換算到共同量尺）' }}</td>
            <td v-for="n in 3" :key="n"><input v-model.number="bands[g + n]" type="number" min="1" max="100" style="max-width:90px" /></td></tr></table>
        <button class="btn sm" style="margin-top:8px" @click="saveBands">儲存門檻並重新盤點</button>
      </div>
      <div class="stack">
        <div class="card">
          <h3>Demo 時鐘 <span class="sub small">快轉後立即執行排程：提醒、逾時、結案確認、自動結案、互評公開、畢業生命週期</span></h3>
          <div class="row"><span class="pill blue">系統時間 {{ fmtTime(clock.now) }}（偏移 +{{ clock.offsetHours }}h）</span></div>
          <div class="row" style="margin-top:10px"><button class="btn secondary sm" @click="advance(24)">+24 小時</button><button class="btn secondary sm" @click="advance(49)">+49 小時</button><button class="btn secondary sm" @click="advance(73)">+73 小時</button><button class="btn secondary sm" @click="advance(24*8)">+8 天</button><button class="btn ghost sm" @click="resetClock">歸零</button></div>
          <pre v-if="jobs" class="prompt" style="max-height:140px;margin-top:10px">{{ jobs }}</pre>
        </div>
        <div class="card"><h3>媒合漏斗</h3><canvas ref="funnelEl" height="180"></canvas></div>
        <div class="card"><h3>推薦品質</h3><div class="stat-grid"><div class="stat"><div class="k">被核准人數</div><div class="v">{{ q.accepted }}</div></div><div class="stat"><div class="k">在推薦快照中</div><div class="v">{{ q.inSnapshot }}</div></div><div class="stat"><div class="k">平均名次</div><div class="v">{{ q.avgRank ?? '—' }}</div></div><div class="stat"><div class="k">前 5 名內</div><div class="v">{{ q.top5 }}</div></div></div><p class="sub small">快照只記錄發案方「查看推薦」後的名單；歷史種子案件未經推薦，因此不在快照中。</p></div>
      </div>
    </div>
    <div class="grid grid-2" style="margin-top:16px">
      <div class="card"><h3>技能供需缺口 <span class="sub small">供給 = 中階以上的人數；需求 = 招募中尚缺名額</span></h3><canvas ref="gapEl" height="300"></canvas></div>
      <div class="card"><h3>跨學院合作網絡 <span class="sub small">成案成員兩兩配對的學院組合（專題目的的直接證據）</span></h3>
        <table><tr><th>學院 A</th><th>學院 B</th><th>合作對數</th></tr><tr v-for="n in network" :key="n.a + n.b"><td>{{ n.a }}</td><td>{{ n.b }}</td><td><div class="row"><div class="bar" style="width:120px"><i :style="{ width: Math.round(n.n / network[0].n * 100) + '%' }"></i></div>{{ n.n }}</div></td></tr></table></div>
    </div>
    <div class="card" style="margin-top:16px" v-if="cs">
      <div class="row between"><h3 style="margin:0">科目表與科目→技能對照 <span class="sub small">科目表來自註冊課務組公告；對照由關鍵字規則建議、學生自填，須核准後才計入排序</span></h3>
        <div class="segment"><button :class="{on: csTab==='pending'}" @click="csTab='pending'">待核准 {{ cs.totals.pending }}</button><button :class="{on: csTab==='programs'}" @click="csTab='programs'">科目表 {{ cs.programs.length }} 份</button><button :class="{on: csTab==='add'}" @click="csTab='add'">補登科目</button></div></div>
      <div class="stat-grid" style="margin-top:10px"><div class="stat"><div class="k">科目</div><div class="v">{{ cs.totals.courses }}</div></div><div class="stat"><div class="k">系所</div><div class="v">{{ cs.totals.departments }}</div></div><div class="stat"><div class="k">已有技能對照</div><div class="v">{{ cs.totals.mapped }}</div></div><div class="stat"><div class="k">待核准對照</div><div class="v">{{ cs.totals.pending }}</div></div></div>
      <div v-if="csTab==='pending'" style="margin-top:10px">
        <div class="row"><input v-model="csQ" placeholder="搜尋科目或技能" style="max-width:260px" @keyup.enter="loadPending" /><button class="btn sm secondary" @click="loadPending">搜尋</button><span class="sub small">依填分數的學生數排序；核准後立即重新盤點相關學生的 Skill Profile</span></div>
        <p v-if="!pending.length" class="sub small" style="margin-top:10px">沒有待核准的對照。</p>
        <div v-else style="max-height:360px;overflow:auto;margin-top:8px"><table><tr><th>科目</th><th>系所／年度</th><th>技能</th><th>來源</th><th>學生數</th><th></th></tr>
          <tr v-for="m in pending" :key="m.courseId + '-' + m.skillId"><td>{{ m.course }} <span class="sub small">{{ m.code }}</span></td><td class="small">{{ m.department || '校共同／通識' }} · {{ m.entryYear }}</td><td>{{ m.skill }} <span class="sub small">{{ m.category }}</span></td>
            <td class="small"><span class="pill" :class="{ SELF: 'orange', LLM: 'purple', RULE: 'blue' }[m.source]">{{ { SELF: '學生自填', LLM: 'AI 建議', RULE: '規則', ADMIN: '管理員' }[m.source] }}</span> {{ m.confidence }}</td><td>{{ m.students }}</td>
            <td class="row"><button class="btn sm" @click="decide(m, true)">核准</button><button class="btn ghost sm" @click="decide(m, false)">退回</button></td></tr></table></div>
      </div>
      <div v-if="csTab==='programs'" style="margin-top:10px">
        <div class="row"><input v-model="progQ" placeholder="篩選系所" style="max-width:220px" /><span class="sub small">每份 = 一個系所 × 學制 × 入學學年度；「已對照」低的系所可用補登科目或等待學生自填</span></div>
        <div style="max-height:360px;overflow:auto;margin-top:8px"><table><tr><th>學院</th><th>系所</th><th>學制</th><th>入學年度</th><th>科目</th><th>必修</th><th>已對照</th></tr>
          <tr v-for="pr in cs.programs.filter(x => !progQ || x.department.includes(progQ) || x.college.includes(progQ))" :key="pr.departmentId + pr.degree + pr.entryYear"><td class="small">{{ pr.college }}</td><td>{{ pr.department }}</td><td class="small">{{ labels.degree[pr.degree] }}</td><td class="small">{{ pr.entryYear }}</td><td>{{ pr.courses }}</td><td class="small">{{ pr.required }}</td><td><div class="row"><div class="bar" style="width:80px"><i :style="{ width: Math.round(100 * pr.mapped / pr.courses) + '%' }"></i></div><span class="small">{{ pr.mapped }}</span></div></td></tr></table></div>
      </div>
      <form v-if="csTab==='add'" class="grid grid-2" style="gap:8px;margin-top:10px" @submit.prevent="addCourse">
        <select v-model.number="nc.departmentId"><option :value="null">校共同／通識（不分系）</option><option v-for="d in store.meta?.departments" :key="d.id" :value="d.id">{{ d.college }}／{{ d.name }}</option></select>
        <input v-model="nc.name" placeholder="科目名稱" required />
        <select v-model="nc.degree"><option value="BACHELOR">學士</option><option value="MASTER">碩士</option><option value="PHD">博士</option></select>
        <input v-model.number="nc.entryYear" type="number" placeholder="入學學年度，例如 115" required />
        <select v-model="nc.requirement"><option value="REQUIRED">必修</option><option value="ELECTIVE">選修</option><option value="GENERAL">校共同／通識</option></select>
        <div class="row"><input v-model.number="nc.gradeYear" type="number" min="1" max="7" placeholder="年級" /><input v-model.number="nc.term" type="number" min="1" max="2" placeholder="學期" /><input v-model.number="nc.credits" type="number" step="0.5" placeholder="學分" /></div>
        <select v-model="nc.skillIds" multiple style="grid-column:1/-1;height:70px"><option v-for="sk in store.meta?.skills" :key="sk.id" :value="sk.id">{{ sk.category }}｜{{ sk.name }}</option></select>
        <button class="btn sm" style="grid-column:1/-1">新增科目（直接核准所選技能對照）</button>
      </form>
    </div>
    <div class="card" style="margin-top:16px">
      <div class="row between"><h3 style="margin:0">證據驗證 <span class="sub small">學生自填的證照、作品集、得獎先標示「自述」；核對證明連結後按「驗證」→「已驗證」（D54）</span></h3>
        <div class="segment"><button :class="{on: !evDone}" @click="evDone = false; loadEvidence()">待驗證 {{ evDone ? '' : evidence.length }}</button><button :class="{on: evDone}" @click="evDone = true; loadEvidence()">已驗證</button></div></div>
      <p v-if="!evidence.length" class="sub small" style="margin-top:10px">沒有資料。</p>
      <div v-else style="max-height:340px;overflow:auto;margin-top:8px"><table><tr><th>學生</th><th>類型</th><th>名稱</th><th>對應技能</th><th>分數</th><th>證明</th><th></th></tr>
        <tr v-for="e in evidence" :key="e.kind + e.id"><td>{{ e.userName }}<div class="sub small">{{ e.department }}</div></td><td class="small"><span class="pill">{{ labels.evidence[e.type] }}</span></td>
          <td>{{ e.title }}<div class="sub small">{{ e.detail }}{{ e.occurredOn ? '・' + e.occurredOn : '' }}</div></td><td class="small">{{ e.skills }}</td><td>{{ e.score }}</td>
          <td class="small"><a v-if="e.proofUrl" :href="e.proofUrl" target="_blank" rel="noopener">開啟</a><span v-else class="muted">未附</span></td>
          <td><button class="btn sm" :class="{ secondary: evDone }" @click="verify(e, !evDone)">{{ evDone ? '撤銷' : '驗證' }}</button></td></tr></table></div>
    </div>
    <div class="grid grid-2" style="margin-top:16px">
      <div class="card">
        <h3>競賽資料庫 <span class="sub small">{{ comps.length }} 筆；每筆保留來源與查證日，停用後學生端與 Agent 都看不到</span></h3>
        <div style="max-height:320px;overflow:auto"><table><tr><th>競賽</th><th>報名截止</th><th>技能</th><th></th></tr>
          <tr v-for="c in comps" :key="c.id"><td><a :href="c.sourceUrl" target="_blank" rel="noopener">{{ c.shortName }}</a><div class="sub small">{{ c.category }} · 查證 {{ c.checkedAt }} · {{ { SEED: '內建', MANUAL: '人工', LLM: 'AI 擷取' }[c.source] }}</div></td>
            <td class="small">{{ c.applyDeadline || '—' }} <span class="pill" :class="c.status === 'OPEN' ? 'green' : c.status === 'CLOSED' ? '' : 'orange'">{{ { OPEN: '可報名', CLOSED: '已截止', UNKNOWN: '未公告' }[c.status] }}</span></td>
            <td class="small">{{ c.skills.length }} 項</td><td><button class="btn sm" :class="c.approved ? 'secondary' : ''" @click="approveComp(c)">{{ c.approved ? '停用' : '核准' }}</button></td></tr></table></div>
      </div>
      <div class="card">
        <h3>教師資料庫 <span class="sub small">{{ teacherCount }} 位；只收系所網頁公開的專長、研究方向與指導經歷</span></h3>
        <p class="sub small">AI 對到的教師技能，信心達 {{ params.llm_auto_approve_pct }}% 自動生效，其餘在這裡核准或退回。</p>
        <p v-if="!pendingTs.length" class="sub small">沒有待核准的教師技能。</p>
        <table v-else><tr><th>教師</th><th>技能</th><th>信心</th><th></th></tr><tr v-for="t in pendingTs" :key="t.teacherId + '-' + t.skillId"><td>{{ t.teacher }}<div class="sub small">{{ t.department }} · {{ t.expertise }}</div></td><td>{{ t.skill }}</td><td>{{ t.confidence }}</td>
          <td class="row"><button class="btn sm" @click="decideTs(t, true)">核准</button><button class="btn ghost sm" @click="decideTs(t, false)">退回</button></td></tr></table>
        <h3 style="margin-top:16px">教師下架 <span class="sub small">老師要求不被推薦時在這裡停用：名單與教師 Agent 都不再出現，重新匯入公開網頁也不會加回來</span></h3>
        <div class="row"><input v-model="tq" placeholder="輸入教師姓名或系所" style="max-width:260px" @keyup.enter="searchTeachers"><button class="btn sm" @click="searchTeachers">搜尋</button></div>
        <table v-if="tList.length" style="margin-top:8px"><tr><th>教師</th><th>系所</th><th>資料來源</th><th>狀態</th><th></th></tr>
          <tr v-for="t in tList" :key="t.id"><td>{{ t.name }} <span class="sub small">{{ t.title }}</span></td><td>{{ t.department }}</td>
            <td class="small"><a v-if="t.sourceUrl" :href="t.sourceUrl" target="_blank" rel="noopener">公開網頁</a> <span class="sub">{{ t.crawledAt }}</span></td>
            <td style="white-space:nowrap"><span class="pill" :class="t.active ? 'green' : 'red'">{{ t.active ? '推薦中' : '已下架' }}</span></td>
            <td style="white-space:nowrap"><button class="btn sm" :class="t.active ? 'ghost' : ''" @click="toggleTeacher(t)">{{ t.active ? '下架' : '恢復' }}</button></td></tr></table>
        <p v-else-if="tSearched" class="sub small">找不到符合的教師。</p>
      </div>
    </div>
    <div class="card" style="margin-top:16px" v-if="ex">
      <h3>AI 擷取 <span class="pill" :class="ex.llmEnabled ? 'purple' : ''">{{ ex.llmEnabled ? 'Claude（' + ex.model + '）' : '未設定金鑰：課綱對照改用關鍵字、結果一律待核准' }}</span>
        <span class="sub small">模型只做「擷取與對照」，不評分；結果要達信心門檻或經核准才生效（D57）。已快取課綱 {{ ex.cachedSyllabi }} 門、AI 對照 {{ ex.llmMappings }} 筆</span></h3>
      <div class="grid grid-2">
        <div>
          <label>課綱 → 技能：找一門科目，擷取學校公開課綱並對到 Skill 資料庫的 1–{{ params.max_skills_per_evidence }} 個技能</label>
          <div class="row"><input v-model="exQ" placeholder="科目名稱，例如：圖論" style="max-width:240px" @keyup.enter="searchCourses" /><button class="btn secondary sm" @click="searchCourses">搜尋</button></div>
          <table v-if="exCourses.length" style="margin-top:6px"><tr v-for="c in exCourses" :key="c.id"><td>{{ c.name }} <span class="sub small">{{ c.department }} · {{ c.entryYear }} 入學 · 已對照 {{ c.skills || '無' }}</span></td>
            <td><button class="btn sm" :disabled="exBusy" @click="mapCourse(c)">依課綱對照</button></td></tr></table>
          <div v-if="exResult" class="small" style="margin-top:8px;background:var(--bg);border-radius:10px;padding:10px">
            <strong>{{ exResult.course }}</strong>｜課綱：{{ { CACHE: '快取', FETCHED: '已從學校網站擷取', NONE: '查無課綱，只依課名' }[exResult.syllabus.origin] }}
            <a v-if="exResult.syllabus.sourceUrl" :href="exResult.syllabus.sourceUrl" target="_blank" rel="noopener">來源 ↗</a>｜{{ exResult.mode === 'LLM' ? 'AI 對照' : '關鍵字比對' }}
            <div v-for="a in exResult.added" :key="a.skillId">＋ {{ a.skill }}（信心 {{ a.confidence }}，{{ a.approved ? '自動生效' : '待核准' }}）<span class="sub">{{ a.evidence }}</span></div>
            <div v-if="!exResult.added.length" class="sub">沒有新增對照（已有對照，或課綱裡找不到可對應的技能）。</div>
          </div>
        </div>
        <form @submit.prevent="extractComp">
          <label>競賽簡章 → 草稿：貼上簡章文字，AI 擷取資格、時程、人數與所需技能，存成未核准的草稿</label>
          <textarea v-model="exText" rows="5" placeholder="貼上官方簡章的文字…" :disabled="!ex.llmEnabled"></textarea>
          <div class="row" style="margin-top:6px"><input v-model="exUrl" placeholder="來源網址（必填，供日後查證）" style="flex:1" required :disabled="!ex.llmEnabled" /><button class="btn sm" :disabled="exBusy || !ex.llmEnabled">擷取成草稿</button></div>
          <p class="sub small" style="margin:6px 0 0">草稿會出現在上方「競賽資料庫」並標示「AI 擷取」，核對無誤後按「核准」才會給學生與 Agent 使用。</p>
        </form>
      </div>
    </div>
    <div class="card" style="margin-top:16px" v-if="mx">
      <div class="row between"><h3 style="margin:0">AI 助理評測指標 <span class="sub small">最近 {{ mx.days }} 天；每一則回覆與每一步工具呼叫都有紀錄，可匯出操作軌跡查核</span></h3><button class="btn secondary sm" @click="loadMetrics">重新整理</button></div>
      <div class="stat-grid" style="margin-top:10px">
        <div class="stat"><div class="k">回合數（Claude／規則）</div><div class="v">{{ mx.turns.turns }} <span class="sub small">{{ mx.turns.llmTurns }}／{{ mx.turns.ruleTurns }}</span></div></div>
        <div class="stat"><div class="k">任務完成率</div><div class="v">{{ pct(mx.turns.successRate) }}</div></div>
        <div class="stat"><div class="k">工具調用成功率</div><div class="v">{{ pct(mx.turns.toolSuccessRate) }} <span class="sub small">{{ mx.turns.toolCalls }} 次</span></div></div>
        <div class="stat"><div class="k">輸出檢核通過率</div><div class="v">{{ pct(mx.turns.outputCheckPassRate) }}</div></div>
        <div class="stat"><div class="k">延遲 平均／P95／最大</div><div class="v" style="font-size:16px">{{ sec(mx.turns.avgLatencyMs) }}／{{ sec(mx.turns.p95LatencyMs) }}／{{ sec(mx.turns.maxLatencyMs) }}</div></div>
        <div class="stat"><div class="k">降級（API 失敗→規則）</div><div class="v">{{ pct(mx.turns.fallbackRate) }}</div></div>
        <div class="stat"><div class="k">中止（上限／拒答）</div><div class="v">{{ pct(mx.turns.abortRate) }}</div></div>
        <div class="stat"><div class="k">重試次數</div><div class="v">{{ mx.turns.llmRetries }}</div></div>
        <div class="stat"><div class="k">人工介入率</div><div class="v">{{ pct(mx.actions.humanInterventionRate) }} <span class="sub small">確認 {{ mx.actions.confirmed }}・取消 {{ mx.actions.cancelled }}</span></div></div>
        <div class="stat"><div class="k">估算成本（美元）</div><div class="v" style="font-size:16px">{{ mx.turns.estimatedCostUsd }} <span class="sub small">每回合 {{ mx.turns.costPerTurnUsd ?? '—' }}</span></div></div>
        <div class="stat"><div class="k">使用者回饋</div><div class="v">{{ mx.turns.feedbackUp }} <span class="sub small">有幫助／{{ mx.turns.feedbackDown }} 沒幫助</span></div></div>
      </div>
      <p class="sub small" style="margin-top:8px">{{ mx.turns.priceNote }}。{{ mx.actions.note }}。</p>
      <div class="grid grid-2" style="margin-top:8px">
        <div><h3>各工具</h3><table><tr><th>工具</th><th>Agent</th><th>呼叫</th><th>失敗</th><th>平均 ms</th><th>最大 ms</th></tr><tr v-for="t in mx.tools" :key="t.tool"><td class="small"><code>{{ t.tool }}</code></td><td class="small">{{ labels.agent[t.agent] }}</td><td>{{ t.calls }}</td><td>{{ t.errors }}</td><td>{{ t.avgMs }}</td><td>{{ t.maxMs }}</td></tr></table></div>
        <div><h3>停止原因與錯誤分類</h3><table><tr><th>結果</th><th>模式</th><th>回合</th></tr><tr v-for="t in mx.stops" :key="t.stop + t.mode"><td>{{ labels.stop[t.stop] || t.stop }}</td><td class="small">{{ t.mode }}</td><td>{{ t.n }}</td></tr>
          <tr v-for="e in mx.errors" :key="e.status + e.error"><td class="small" style="color:var(--red)">API {{ e.status }}</td><td class="small">{{ e.error }}</td><td>{{ e.n }}</td></tr></table>
          <h3 style="margin-top:12px">最近的對話（操作軌跡）</h3><table><tr v-for="x in mx.recentSessions.slice(0, 8)" :key="x.id"><td class="small">#{{ x.id }} · {{ fmtTime(x.updatedAt) }}</td><td class="small">{{ x.turns }} 回合 · 工具 {{ x.toolCalls }} 次 · {{ x.modes }}</td><td><button class="btn ghost sm" @click="trace(x.id)">下載軌跡</button></td></tr></table></div>
      </div>
    </div>
    <div class="card" style="margin-top:16px">
      <div class="row between"><h3 style="margin:0">事件紀錄（稽核）</h3><button class="btn danger sm" @click="reset">重置資料（彩排用）</button></div>
      <table style="margin-top:8px"><tr v-for="l in logs" :key="l.id"><td class="small muted">{{ fmtTime(l.createdAt) }}</td><td class="small">{{ l.actor || '系統' }}</td><td class="small">{{ l.entity }} #{{ l.entityId }} · {{ l.action }}</td><td class="small muted">{{ l.payload }}</td></tr></table>
    </div>
  </div>
</template>
<script setup>
import { ref, computed, onMounted, nextTick } from 'vue'
import { Chart, BarController, BarElement, CategoryScale, LinearScale, Tooltip, Legend } from 'chart.js'
import { get, put, post, del } from '../api'
import { store, labels, fmtTime } from '../store'
Chart.register(BarController, BarElement, CategoryScale, LinearScale, Tooltip, Legend)
const p = ref(null), weights = ref({}), cred = ref({}), params = ref({}), clock = ref({}), jobs = ref(''), q = ref({}), network = ref([]), logs = ref([])
const cs = ref(null), csTab = ref('pending'), csQ = ref(''), pending = ref([]), progQ = ref('')
const nc = ref({ departmentId: null, name: '', degree: 'BACHELOR', entryYear: null, requirement: 'ELECTIVE', gradeYear: null, term: null, credits: null, skillIds: [] })
async function loadCourses() { await store.loadMeta(); cs.value = await get('/admin/courses/summary'); if (!nc.value.entryYear) nc.value.entryYear = store.meta.currentAcademicYear; await loadPending() }
async function loadPending() { pending.value = await get('/admin/course-skills?approved=false' + (csQ.value ? '&q=' + encodeURIComponent(csQ.value) : '')) }
async function decide(m, ok) {
  try {
    if (ok) await put('/admin/course-skills', { courseId: m.courseId, skillId: m.skillId, approved: true, confidence: m.confidence })
    else await del(`/admin/course-skills/${m.courseId}/${m.skillId}`)
    store.notify(ok ? `已核准：${m.course} → ${m.skill}` : '已退回', 'success'); await loadCourses()
  } catch (e) { store.notify(e.message, 'error') }
}
async function addCourse() { try { await post('/admin/courses', nc.value); store.notify('已新增科目', 'success'); nc.value.name = ''; nc.value.skillIds = []; await loadCourses() } catch (e) { store.notify(e.message, 'error') } }
const funnelEl = ref(null), gapEl = ref(null)
let funnelChart, gapChart
const sum = computed(() => Object.values(weights.value).reduce((a, b) => a + (+b || 0), 0))
async function load() {
  p.value = await get('/admin/params')
  p.value.weights.forEach(w => weights.value[w.key] = +w.value); p.value.credibility.forEach(c => cred.value[c.matchLevel] = +c.coefficient); p.value.params.forEach(s => params.value[s.key] = s.value); p.value.levelBands.forEach(b => bands.value[b.degreeGroup + b.tier] = b.minScore)
  clock.value = await get('/admin/clock'); q.value = await get('/analytics/recommendation-quality'); network.value = await get('/analytics/network'); logs.value = await get('/admin/event-logs?limit=40')
  const funnel = await get('/analytics/funnel'), gap = (await get('/analytics/skill-gap')).slice(0, 12)
  await nextTick()
  funnelChart?.destroy(); gapChart?.destroy()
  funnelChart = new Chart(funnelEl.value, { type: 'bar', data: { labels: funnel.map(f => f.stage), datasets: [{ label: '案件數', data: funnel.map(f => f.n), backgroundColor: '#0a84ff', borderRadius: 6 }] }, options: { plugins: { legend: { display: false } }, scales: { y: { beginAtZero: true, ticks: { precision: 0 } } } } })
  gapChart = new Chart(gapEl.value, { type: 'bar', data: { labels: gap.map(g => g.skill), datasets: [{ label: '供給（中階以上人數）', data: gap.map(g => g.supply), backgroundColor: '#34c759', borderRadius: 6 }, { label: '需求（尚缺名額）', data: gap.map(g => g.demand), backgroundColor: '#ff9f0a', borderRadius: 6 }] }, options: { indexAxis: 'y', plugins: { legend: { position: 'bottom' } }, scales: { x: { beginAtZero: true, ticks: { precision: 0 } } } } })
}
// ----- NAPAI：等級門檻、證據驗證、競賽與教師、AI 助理評測 -----
const bands = ref({}), evidence = ref([]), evDone = ref(false), comps = ref([]), pendingTs = ref([]), teacherCount = ref(0), mx = ref(null)
const pct = (v) => v == null ? '—' : Math.round(v * 1000) / 10 + '%'
const sec = (v) => v == null ? '—' : (v / 1000).toFixed(1) + 's'
async function loadEvidence() { evidence.value = await get('/admin/evidence?verified=' + evDone.value) }
async function verify(e, v) { try { await put(`/admin/evidence/${e.kind === 'AWARD' ? 'award' : 'credential'}/${e.id}`, { verified: v }); store.notify(v ? `已驗證：${e.userName}「${e.title}」` : '已撤銷驗證', 'success'); await loadEvidence() } catch (err) { store.notify(err.message, 'error') } }
async function saveBands() {
  try {
    const list = ['BACHELOR', 'GRADUATE'].flatMap(g => [1, 2, 3].map(n => ({ degreeGroup: g, tier: n, minScore: bands.value[g + n] })))
    const r = await put('/admin/params', { levelBands: list }); store.notify(`已儲存，重新盤點 ${r.reprofiledStudents} 位學生`, 'success'); await load()
  } catch (e) { store.notify(e.message, 'error') }
}
async function loadCatalog() { comps.value = await get('/admin/competitions'); pendingTs.value = await get('/admin/teacher-skills/pending'); teacherCount.value = (await get('/teachers')).filter(t => t.active).length }
async function approveComp(c) { try { await put(`/admin/competitions/${c.id}/approval`, { approved: !c.approved }); await loadCatalog() } catch (e) { store.notify(e.message, 'error') } }
async function decideTs(t, ok) { try { await put(`/admin/teachers/${t.teacherId}/skills/${t.skillId}`, { approved: ok }); await loadCatalog() } catch (e) { store.notify(e.message, 'error') } }
const tq = ref(''), tList = ref([]), tSearched = ref(false)
async function searchTeachers() { if (!tq.value.trim()) return; tList.value = (await get('/teachers?q=' + encodeURIComponent(tq.value.trim()))).slice(0, 12); tSearched.value = true }
async function toggleTeacher(t) { try { await put(`/admin/teachers/${t.id}/active`, { active: !t.active }); store.notify(t.active ? `已下架：${t.name}` : `已恢復：${t.name}`, 'success'); await Promise.all([searchTeachers(), loadCatalog()]) } catch (e) { store.notify(e.message, 'error') } }
async function loadMetrics() { mx.value = await get('/admin/assistant/metrics') }
const ex = ref(null), exQ = ref(''), exCourses = ref([]), exResult = ref(null), exBusy = ref(false), exText = ref(''), exUrl = ref('')
async function loadExtract() { ex.value = await get('/admin/extract/status') }
async function searchCourses() { if (exQ.value.trim().length < 2) return; exCourses.value = (await get('/courses?q=' + encodeURIComponent(exQ.value.trim()))).slice(0, 8) }
async function mapCourse(c) { exBusy.value = true; try { exResult.value = await post('/admin/extract/course-skills', { courseId: c.id }); await Promise.all([loadExtract(), loadCourses(), searchCourses()]) } catch (e) { store.notify(e.message, 'error') } finally { exBusy.value = false } }
async function extractComp() { exBusy.value = true; try { const c = await post('/admin/extract/competition', { text: exText.value, sourceUrl: exUrl.value }); store.notify(`已建立草稿「${c.name}」，請在競賽資料庫核對後核准`, 'success'); exText.value = ''; exUrl.value = ''; await loadCatalog() } catch (e) { store.notify(e.message, 'error') } finally { exBusy.value = false } }
async function trace(id) { const t = await get(`/assistant/sessions/${id}/trace`); const a = document.createElement('a'); a.href = URL.createObjectURL(new Blob([JSON.stringify(t, null, 2)], { type: 'application/json' })); a.download = `agent-trace-${id}.json`; a.click() }
async function save() { try { await put('/admin/params', { weights: weights.value, credibility: cred.value, params: params.value }); store.notify('已儲存，推薦名單重新查詢即套用', 'success'); await load() } catch (e) { store.notify(e.message, 'error') } }
async function advance(h) { try { const r = await post('/admin/clock', { hours: h }); jobs.value = JSON.stringify(r, null, 1); store.notify('時間已快轉 ' + h + ' 小時並執行排程', 'success'); await load() } catch (e) { store.notify(e.message, 'error') } }
async function resetClock() { await post('/admin/clock/reset'); jobs.value = ''; await load() }
async function reset() { if (!confirm('重建 schema 與 50 位示範學生？所有操作紀錄會清除。')) return; await post('/admin/reset'); store.notify('已重置', 'success'); await load() }
onMounted(async () => { await load(); await loadCourses(); await Promise.all([loadEvidence(), loadCatalog(), loadMetrics(), loadExtract()]) })
</script>
