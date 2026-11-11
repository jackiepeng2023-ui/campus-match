<template>
  <div>
    <div class="kv">
      <span>組隊需求</span><span>「{{ data.context.title }}」每週 {{ data.context.hoursPerWeek }} 小時 · {{ data.context.startDate }} ~ {{ data.context.endDate }} · 還可找 {{ data.context.seats }} 人</span>
      <span>技能涵蓋</span><span><span v-for="c in data.coverage" :key="c.skillId" class="chip" style="margin:0 4px 4px 0" :style="c.status === 'MET' ? 'background:#e3f8e8' : 'background:#ffe5e3'">{{ c.name }}<span v-if="c.importance === 'CORE'" class="tag-req">核心</span>
        <span class="muted">{{ c.status === 'MET' ? c.by.join('、') : c.status === 'BELOW' ? '只到' + c.best + '，需 ' + c.required : '缺，需 ' + c.required }}</span></span></span>
      <template v-if="data.suggestedTeam.picks.length"><span>建議組合</span><span><span v-for="p in data.suggestedTeam.picks" :key="p.userId" class="chip" style="margin:0 4px 4px 0;background:var(--accent-weak)"><strong>{{ p.name }}</strong>（{{ p.department }}）補 {{ p.fills.join('、') }}</span>
        <span class="sub small">→ 補完後涵蓋 {{ data.suggestedTeam.coveredAfter }}／{{ data.suggestedTeam.total }} 項{{ data.suggestedTeam.remainingGaps.length ? '，仍缺 ' + data.suggestedTeam.remainingGaps.join('、') : '' }}</span></span></template>
    </div>
    <div v-if="!data.candidates.length" class="sub small" style="margin-top:8px">沒有同時通過時間、身分閘門又能補上缺口的人選。</div>
    <div v-for="c in data.candidates.slice(0, limit)" :key="c.userId" class="item-row" style="margin-top:8px">
      <div class="row between">
        <label style="display:flex;gap:8px;align-items:center;margin:0;color:var(--text);font-size:14px"><input v-if="selectable" type="checkbox" style="width:auto" :checked="modelValue.includes(c.userId)" @change="toggle(c.userId)" />
          <router-link :to="'/users/' + c.userId"><strong>{{ c.name }}</strong></router-link><span class="sub small">{{ c.college }} {{ c.department }} · {{ labels.degree[c.degree] }}{{ c.year }}年級</span></label>
        <span class="row"><span class="sub small">媒合分數</span><span class="fit">{{ c.score.toFixed(1) }}</span></span>
      </div>
      <ul class="tight"><li v-for="r in c.complementReasons" :key="r">{{ r }}</li><li class="muted">{{ c.reasons.filter(x => x.startsWith('每週') || x.startsWith('隊友評價') || x.startsWith('尚無互評') || x.startsWith('回應率')).join('；') }}</li></ul>
    </div>
    <div v-if="data.blocked.length" class="sub small" style="margin-top:8px">技能符合但被閘門擋下：{{ data.blocked.map(b => b.name + '（' + b.blockedBy[0] + '）').join('、') }}</div>
    <AgentTrace :lines="data.trace" />
  </div>
</template>
<script setup>
import { labels } from '../store'
import AgentTrace from './AgentTrace.vue'
const props = defineProps({ data: Object, selectable: Boolean, modelValue: { type: Array, default: () => [] }, limit: { type: Number, default: 6 } })
const emit = defineEmits(['update:modelValue'])
const toggle = (id) => emit('update:modelValue', props.modelValue.includes(id) ? props.modelValue.filter(x => x !== id) : [...props.modelValue, id])
</script>
