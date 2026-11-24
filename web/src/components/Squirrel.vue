<template>
  <span v-if="art.frame" class="sq-frame" :style="{ width: size + 'px', height: size + 'px' }">
    <img :src="art.src" alt="" decoding="async" />
  </span>
  <img v-else :src="art.src" :width="Math.round(size * art.ratio)" :height="size" :class="art.round ? 'sticker' : 'mascot'" alt="" decoding="async" />
</template>
<script setup>
// 品牌松鼠圖（圖檔由同學提供，web/tools/brand_assets.py 轉成這裡的尺寸）。都是裝飾用，不帶替代文字。
// stand：去背站姿。head、wink：去背半身，放進圓框（原圖在脖子的位置是平的，圓框剛好蓋住）。
// phone、cheer：從橫幅裁下來的方形，用圓框顯示。size 是高度，圓形的就是直徑。
import { computed } from 'vue'
import stand from '../assets/brand/squirrel-stand.webp'
import wink from '../assets/brand/squirrel-wink.webp'
import head from '../assets/brand/squirrel-head.webp'
import phone from '../assets/brand/sticker-phone.webp'
import cheer from '../assets/brand/sticker-cheer.webp'

const ART = {
  stand: { src: stand, ratio: 345 / 464 },
  head: { src: head, frame: true },
  wink: { src: wink, frame: true },
  phone: { src: phone, ratio: 1, round: true },
  cheer: { src: cheer, ratio: 1, round: true },
}
const props = defineProps({ pose: { type: String, default: 'stand' }, size: { type: Number, default: 110 } })
const art = computed(() => ART[props.pose] || ART.stand)
</script>
