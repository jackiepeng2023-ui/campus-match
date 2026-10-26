<template>
  <div class="stars"><button v-for="n in 5" :key="n" type="button" :class="{on: modelValue >= n}" @click="$emit('update:modelValue', n)">{{ n }}</button></div>
</template>
<script setup>defineProps({ modelValue: Number }); defineEmits(['update:modelValue'])</script>
