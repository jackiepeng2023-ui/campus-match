<template>
  <section class="card">
    <h3>AI 成長建議 Prompt</h3>
    <p class="sub small">由系統從你的資料組出 Prompt，預覽、刪改後貼到你自己選的 AI。平台不會替你送出，也不會保存這段內容。</p>
    <div class="grid grid-2" style="gap:12px">
      <div class="field" style="margin:0"><label for="gp-goal">成長目標</label><input id="gp-goal" v-model="goal" placeholder="例：畢業後成為前端工程師" /></div>
      <div class="field" style="margin:0"><label for="gp-q">我想問的問題</label><input id="gp-q" v-model="question" placeholder="例：下學期該補什麼、該參加哪種比賽？" /></div>
    </div>
    <div class="row" style="margin-top:12px"><button class="btn sm" :disabled="busy || !goal.trim() || !question.trim()" @click="gen">產生 Prompt</button>
      <span v-if="!goal.trim() || !question.trim()" class="hint" style="margin:0">兩格都填了才能產生。</span></div>
    <div v-if="prompt" style="margin-top:14px">
      <p class="small urgent">{{ notice }}</p>
      <label for="gp-text">Prompt（可以直接改）</label>
      <textarea id="gp-text" v-model="prompt" rows="14" style="font-family:ui-monospace,Menlo,monospace;font-size:12.5px"></textarea>
      <div class="row" style="margin-top:10px"><button class="btn sm" @click="copy">複製到剪貼簿</button>
        <span class="sub small">貼到：</span>
        <a v-for="a in targets" :key="a.name" class="btn tiny white" :href="a.url" target="_blank" rel="noopener">{{ a.name }}</a></div>
    </div>
  </section>
</template>
<script setup>
// D84：AI 成長建議 Prompt 留在個人頁。後端只組字串，不呼叫任何外部服務，也不保存。
import { ref } from 'vue'
import { post } from '../api'
import { store } from '../store'
const goal = ref(''), question = ref(''), prompt = ref(''), notice = ref(''), busy = ref(false)
const targets = [{ name: 'Claude', url: 'https://claude.ai/new' }, { name: 'ChatGPT', url: 'https://chatgpt.com/' }, { name: 'Gemini', url: 'https://gemini.google.com/' },
  { name: 'Grok', url: 'https://grok.com/' }, { name: 'Perplexity', url: 'https://www.perplexity.ai/' }]
async function gen() {
  busy.value = true
  try { const r = await post('/me/growth-prompt', { goal: goal.value, question: question.value }); prompt.value = r.prompt; notice.value = r.notice }
  catch (e) { store.notify(e.message, 'error') } finally { busy.value = false }
}
async function copy() {
  try { await navigator.clipboard.writeText(prompt.value); store.notify('已複製，貼到你選的 AI 就可以', 'success') }
  catch { store.notify('瀏覽器不允許自動複製，請手動選取文字複製', 'error') }
}
</script>
