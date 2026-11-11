<template>
  <div>
    <div class="row">
      <select v-model.number="pick" style="max-width:260px"><option :value="null">選擇技能…</option><optgroup v-for="(list, cat) in groups" :key="cat" :label="cat"><option v-for="sk in list" :key="sk.id" :value="sk.id" :disabled="modelValue.includes(sk.id)">{{ sk.name }}</option></optgroup></select>
      <button type="button" class="btn secondary sm" :disabled="!pick || modelValue.length >= max" @click="add">加入</button>
      <span class="sub small">{{ modelValue.length }}／{{ max }}</span>
    </div>
    <div class="row" style="margin-top:6px" v-if="modelValue.length"><span v-for="id in modelValue" :key="id" class="chip">{{ name(id) }} <a href="#" @click.prevent="$emit('update:modelValue', modelValue.filter(x => x !== id))">✕</a></span></div>
  </div>
</template>
<script setup>
// 從共用 Skill 資料庫挑 1–max 個技能（每筆證據最多對應 max 個技能）
import { ref, computed } from 'vue'
import { store } from '../store'
const props = defineProps({ modelValue: { type: Array, default: () => [] }, max: { type: Number, default: 5 } })
const emit = defineEmits(['update:modelValue'])
const pick = ref(null)
const groups = computed(() => { const g = {}; for (const s of store.meta?.skills || []) (g[s.category] ||= []).push(s); return g })
const name = (id) => store.meta?.skills.find(s => s.id === id)?.name || id
function add() { if (pick.value && !props.modelValue.includes(pick.value) && props.modelValue.length < props.max) emit('update:modelValue', [...props.modelValue, pick.value]); pick.value = null }
</script>
