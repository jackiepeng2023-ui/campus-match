<template>
  <div v-if="lines && lines.length" style="margin-top:8px">
    <a href="#" class="small" @click.prevent="open = !open">這個 Agent 怎麼算的 {{ open ? '▴' : '▾' }}</a>
    <ol v-if="open" class="tight" style="margin-top:4px"><li v-for="l in lines" :key="l">{{ l }}</li></ol>
  </div>
</template>
<script setup>
import { ref } from 'vue'
defineProps({ lines: Array })
const open = ref(false)
</script>
