<template>
  <div class="card" style="padding:16px">
    <div class="row between">
      <div>
        <router-link v-if="item.userId" :to="'/users/' + item.userId"><strong>{{ item.name }}</strong></router-link>
        <strong v-else>{{ item.caseTitle }}</strong>
        <span class="sub small" v-if="item.userId"> · {{ item.college }} {{ item.dept }} · {{ labels.degree[item.degree] }}{{ item.year }}年級</span>
        <span class="sub small" v-else> · {{ labels.type[item.caseType] }} · 角色 {{ item.roleName }} · 名額 {{ item.filled }}/{{ item.headcount }}</span>
      </div>
      <div class="row">
        <span v-if="item.blockedBy && item.blockedBy.length" class="pill red">被擋下</span>
        <span class="score" :style="item.blockedBy && item.blockedBy.length ? 'color:var(--tertiary)' : ''">{{ item.score.toFixed(1) }}</span>
        <slot name="action"></slot>
      </div>
    </div>
    <div class="breakdown">
      <div v-for="k in ['S','T','R','P','C']" :key="k">
        <div class="f">{{ labels.factor[k] }} <span class="muted" v-if="weights">×{{ weights[k.toLowerCase()] }}</span></div>
        <div class="v">{{ item.breakdown[k].toFixed(2) }} <span class="muted small">→ {{ item.breakdown[k + '_weighted'].toFixed(1) }}</span></div>
        <div class="bar"><i :style="{ width: Math.round(item.breakdown[k] * 100) + '%' }"></i></div>
      </div>
    </div>
    <ul v-if="item.blockedBy && item.blockedBy.length" class="reasons" style="color:var(--red)"><li v-for="b in item.blockedBy" :key="b">{{ b }}</li></ul>
    <ul class="reasons"><li v-for="r in item.reasons" :key="r">{{ r }}</li></ul>
  </div>
</template>
<script setup>
import { labels } from '../store'
defineProps({ item: Object, weights: Object })
</script>
