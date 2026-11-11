<template>
  <div>
    <div v-if="!data.teachers.length" class="sub small">教師資料庫裡沒有專長相符的老師。</div>
    <div v-for="t in data.teachers" :key="t.teacherId" class="item-row">
      <div class="row between">
        <label style="display:flex;gap:8px;align-items:center;margin:0;color:var(--text);font-size:14px"><input v-if="selectable" type="radio" style="width:auto" :checked="modelValue === t.teacherId" @click="$emit('update:modelValue', modelValue === t.teacherId ? null : t.teacherId)" />
          <strong>{{ t.name }}</strong> <span class="sub small">{{ t.title }} · {{ t.college }} {{ t.department }}</span></label>
        <span class="row"><span class="sub small">契合度</span><span class="fit">{{ t.fit.toFixed(1) }}</span></span>
      </div>
      <div class="sub small" style="margin-top:2px">專長 {{ t.breakdown.E }}・指導經驗 {{ t.breakdown.G }}・系所 {{ t.breakdown.D }}・研究方向 {{ t.breakdown.K }}
        <a v-if="t.profileUrl || t.sourceUrl" :href="t.profileUrl || t.sourceUrl" target="_blank" rel="noopener" style="margin-left:6px">系所網頁 ↗</a></div>
      <div class="kv" style="margin-top:6px">
        <span>契合原因</span><ul class="tight" style="margin:0"><li v-for="r in t.reasons" :key="r">{{ r }}</li></ul>
        <span>待確認</span><ul class="tight" style="margin:0;color:#b86a00"><li v-for="r in t.toConfirm" :key="r">{{ r }}</li></ul>
      </div>
    </div>
    <p class="sub small" style="margin:8px 0 0">教師不是平台使用者，平台不會替你聯絡老師；請自行聯絡並逐項確認。</p>
    <AgentTrace :lines="data.trace" />
  </div>
</template>
<script setup>
import AgentTrace from './AgentTrace.vue'
defineProps({ data: Object, selectable: Boolean, modelValue: Number })
defineEmits(['update:modelValue'])
</script>
