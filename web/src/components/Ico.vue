<template>
  <svg viewBox="0 0 24 24" :width="size" :height="size" aria-hidden="true" style="fill:none;stroke:currentColor;stroke-width:2;stroke-linecap:round;stroke-linejoin:round;flex:0 0 auto">
    <template v-if="name === 'bell'"><path d="M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9" /><path d="M10.3 21a1.94 1.94 0 0 0 3.4 0" /></template>
    <template v-else-if="name === 'team'"><circle cx="9" cy="8" r="3.2" /><path d="M2.8 20a6.2 6.2 0 0 1 12.4 0" /><path d="M16 5.2a3.2 3.2 0 0 1 0 5.6" /><path d="M18 14.3a6.2 6.2 0 0 1 3.2 5.7" /></template>
    <template v-else-if="name === 'out'"><path d="M7 17 17 7" /><path d="M8 7h9v9" /></template>
    <template v-else-if="name === 'back'"><path d="m15 18-6-6 6-6" /></template>
    <template v-else-if="name === 'down'"><path d="m6 9 6 6 6-6" /></template>
    <template v-else-if="name === 'search'"><circle cx="11" cy="11" r="7" /><path d="m20 20-3.5-3.5" /></template>
    <template v-else-if="name === 'trophy'"><path d="M8 4h8v5a4 4 0 0 1-8 0z" /><path d="M8 6H5a3 3 0 0 0 3 4" /><path d="M16 6h3a3 3 0 0 1-3 4" /><path d="M12 13v4" /><path d="M8 20h8" /></template>
    <template v-else-if="name === 'chat'"><path d="M4 5h16v11H9l-5 4z" /></template>
    <template v-else-if="name === 'me'"><circle cx="12" cy="8" r="3.6" /><path d="M4.5 20a7.5 7.5 0 0 1 15 0" /></template>
    <template v-else-if="name === 'spark'"><path d="M12 3v4M12 17v4M3 12h4M17 12h4" /><path d="m6 6 2.5 2.5M15.500 15.500 18 18M18 6l-2.500 2.500M8.500 15.500 6 18" /></template>
    <template v-else-if="name === 'gear'"><circle cx="12" cy="12" r="3" /><path d="M12 3v3M12 18v3M3 12h3M18 12h3M5.600 5.600l2.100 2.100M16.300 16.300l2.100 2.100M18.400 5.600l-2.100 2.100M7.700 16.300l-2.100 2.100" /></template>
  </svg>
</template>
<script setup>
defineProps({ name: String, size: { type: [Number, String], default: 20 } })
</script>
