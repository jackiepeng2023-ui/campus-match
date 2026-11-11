<template>
  <div class="item-row">
    <div class="row between">
      <div><router-link :to="'/competitions/' + c.id"><strong>{{ c.shortName || c.name }}</strong></router-link>
        <span class="pill" style="margin-left:6px">{{ c.category }}</span> <span class="pill">{{ labels.level[c.level] }}</span>
        <span class="pill" :class="c.status === 'OPEN' ? (c.daysLeft <= 14 ? 'orange' : 'green') : c.status === 'CLOSED' ? 'red' : ''" style="margin-left:4px">{{ c.status === 'OPEN' ? '報名截止 ' + c.applyDeadline + '（剩 ' + c.daysLeft + ' 天）' : c.status === 'CLOSED' ? '報名已截止 ' + c.applyDeadline : '報名日期未公告' }}</span></div>
      <div v-if="c.fit !== undefined" class="row"><span class="sub small">契合度</span><span class="fit" :style="c.eligible ? '' : 'color:var(--tertiary)'">{{ c.fit.toFixed(1) }}</span></div>
    </div>
    <div class="sub small" style="margin-top:2px">{{ c.organizer }} · {{ team }}{{ c.advisorRequired ? ' · 需指導老師' : '' }}</div>
    <template v-if="c.fit !== undefined">
      <div class="kv" style="margin-top:8px">
        <span>優點</span><span><span v-for="s in c.strengths" :key="s.skillId" class="chip" style="margin:0 4px 4px 0">{{ s.name }}<span v-if="s.core" class="tag-req">核心</span> <span class="lv">{{ s.mine }}</span> <span class="pill" :class="trustColor(s.trust)">{{ s.trust }}</span></span><span v-if="!c.strengths.length" class="muted">沒有達標的技能</span></span>
        <template v-if="c.weaknesses.length"><span>弱項</span><span><span v-for="s in c.weaknesses" :key="s.skillId" class="chip" style="margin:0 4px 4px 0">{{ s.name }}<span v-if="s.core" class="tag-req">核心</span> <span class="muted">{{ s.mine }} → 需 {{ s.required }}</span></span></span></template>
        <template v-if="c.gaps.length"><span>能力缺口</span><span><span v-for="s in c.gaps" :key="s.skillId" class="chip" style="margin:0 4px 4px 0;background:#ffe5e3">{{ s.name }}<span v-if="s.core" class="tag-req">核心</span> <span class="muted">需 {{ s.required }}</span></span></span></template>
      </div>
      <ul class="tight" v-if="c.blockedBy && c.blockedBy.length" style="color:var(--red)"><li v-for="b in c.blockedBy" :key="b">{{ b }}</li></ul>
      <ul class="tight" v-if="showReasons"><li v-for="r in c.reasons" :key="r">{{ r }}</li></ul>
    </template>
    <div v-else class="row" style="margin-top:6px"><span v-for="s in c.skills" :key="s.skillId" class="chip">{{ s.name }} <span class="lv">{{ s.tier }}</span> <span :class="s.importance === 'CORE' ? 'tag-req' : 'tag-opt'">{{ labels.importance[s.importance] }}</span></span></div>
    <slot></slot>
  </div>
</template>
<script setup>
import { computed } from 'vue'
import { labels, trustColor } from '../store'
const props = defineProps({ c: Object, showReasons: Boolean })
const team = computed(() => props.c.teamMax === 1 ? '個人賽' : `組隊 ${props.c.teamMin ?? '?'}–${props.c.teamMax ?? '?'} 人`)
</script>
