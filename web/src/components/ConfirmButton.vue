<template>
  <span v-if="asking" class="row" style="gap:8px">
    <span class="small strong">{{ question }}</span>
    <button type="button" class="btn sm" :class="{ danger }" :disabled="disabled" @click="asking = false; $emit('confirm')">{{ yes }}</button>
    <button type="button" class="btn sm white" @click="asking = false">先不要</button>
  </span>
  <button v-else type="button" class="btn" :class="[size, variant]" :disabled="disabled" @click="asking = true"><slot /></button>
</template>
<script setup>
// 會改變隊伍狀態的動作先問一次，直接寫在畫面上（不跳出瀏覽器的對話框）
import { ref } from 'vue'
defineProps({ question: { type: String, default: '確定嗎？' }, yes: { type: String, default: '確定' }, size: { type: String, default: 'sm' },
  variant: { type: String, default: 'white' }, danger: Boolean, disabled: Boolean })
defineEmits(['confirm'])
const asking = ref(false)
</script>
