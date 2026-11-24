<template>
  <div>
    <header class="top" v-if="store.user">
      <div class="top-in">
        <router-link to="/" class="logo" aria-label="Fomo鬆 首頁"><Squirrel pose="head" :size="40" /><span>FOMO<b>鬆</b></span></router-link>
        <nav class="mainnav" aria-label="主選單">
          <router-link v-for="t in tabs" :key="t.to" :to="t.to" :class="{ on: t.on }" :aria-current="t.on ? 'page' : null">{{ t.label }}<span v-if="t.badge" class="badge">{{ t.badge }}</span></router-link>
        </nav>
        <div class="tools">
          <router-link v-if="store.user.role !== 'ADMIN'" to="/assistant" class="round ai" aria-label="AI 助理"><Squirrel pose="wink" :size="40" /></router-link>
          <button type="button" class="round" :aria-label="store.unread ? `通知，${store.unread} 則未讀` : '通知'" @click="toggleBell">
            <Ico name="bell" /><span v-if="store.unread" class="badge">{{ store.unread > 99 ? '99+' : store.unread }}</span>
          </button>
          <button type="button" class="round me" aria-label="個人選單" @click="menu = !menu; bell = false">{{ initial(store.user.name) }}</button>
          <div v-if="bell" class="menu" role="dialog" aria-label="通知">
            <div class="row between" style="padding:4px 8px"><strong>通知</strong><button class="btn tiny white" @click="readAll">全部已讀</button></div>
            <div v-if="!notifs.length" class="empty">沒有通知</div>
            <div v-for="n in notifs" :key="n.id" class="item" :class="{ unread: !n.readAt }" @click="openNotice(n)">
              <div><strong>{{ n.title }}</strong> <span class="muted small">{{ fmtTime(n.createdAt) }}</span></div>
              <div class="sub small">{{ n.body }}</div>
            </div>
          </div>
          <div v-if="menu" class="menu" style="width:230px" role="menu">
            <div style="padding:8px 12px 10px"><strong>{{ store.user.name }}</strong><div class="sub small">{{ store.user.role === 'ADMIN' ? '管理員' : store.user.department }}</div></div>
            <router-link v-if="store.user.role !== 'ADMIN'" class="linkrow" to="/profile">個人頁</router-link>
            <router-link v-if="store.user.role !== 'ADMIN'" class="linkrow" to="/assistant">AI 助理</router-link>
            <router-link v-if="store.user.role === 'ADMIN'" class="linkrow" to="/admin">管理</router-link>
            <button type="button" class="linkrow" @click="store.logout()">登出</button>
          </div>
        </div>
      </div>
    </header>
    <div v-if="store.user && rt.state === 'polling'" class="offline" role="status">即時連線中斷，先改成每 10 秒更新一次，正在重新連線。</div>
    <div v-if="bell || menu" style="position:fixed;inset:0;z-index:25" @click="bell = menu = false"></div>

    <main :class="store.user ? 'page' : ''"><router-view :key="viewKey" /></main>

    <nav class="tabbar" v-if="store.user" aria-label="主選單">
      <router-link v-for="t in tabs" :key="t.to" :to="t.to" :class="{ on: t.on }"><Ico :name="t.icon" :size="22" />{{ t.label }}<span v-if="t.badge" class="badge">{{ t.badge }}</span></router-link>
    </nav>
    <router-link v-if="showFab" to="/assistant" class="fab" aria-label="AI 助理"><Squirrel pose="wink" :size="42" /><span class="lbl">AI 助理</span></router-link>
    <div v-if="store.toast" class="toast" :class="store.toast.kind" role="status">{{ store.toast.message }}</div>
  </div>
</template>
<script setup>
import { ref, computed, watch, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { store, fmtTime, initial } from './store'
import { get, post } from './api'
import { rt, connect, disconnect, onEvent } from './realtime'
import Ico from './components/Ico.vue'
import Squirrel from './components/Squirrel.vue'

const route = useRoute(), router = useRouter()
const bell = ref(false), menu = ref(false), notifs = ref([])

const tabs = computed(() => {
  const p = route.path, admin = store.user?.role === 'ADMIN'
  return [
    { to: '/', label: '找隊友', icon: 'team', on: p === '/' || p.startsWith('/teams') || /^\/cases\/\d+$/.test(p) },
    { to: '/competitions', label: '比賽', icon: 'trophy', on: p.startsWith('/competitions') },
    { to: '/messages', label: '訊息', icon: 'chat', on: p.startsWith('/messages'), badge: store.unreadMessages || null },
    admin ? { to: '/admin', label: '管理', icon: 'gear', on: p === '/admin' } : { to: '/profile', label: '個人頁', icon: 'me', on: p === '/profile' || p.startsWith('/users') },
  ]
})
// 訊息頁切換對話時不要整頁重建（列表會閃）；其他頁面換網址就重新載入
const viewKey = computed(() => route.path.startsWith('/messages') ? 'messages' : route.fullPath)
// 訊息頁的右下角是「傳送」按鈕，不放浮動按鈕（AI 助理在頭像選單裡也進得去）。手機上浮動按鈕會擋到卡片的按鈕，改放頁首（.round.ai）
const showFab = computed(() => store.user && store.user.role !== 'ADMIN' && route.path !== '/assistant' && !route.path.startsWith('/messages'))

async function toggleBell() {
  bell.value = !bell.value; menu.value = false
  if (bell.value) { const r = await get('/me/notifications'); notifs.value = r.items; store.unread = r.unread }
}
async function readAll() { await post('/me/notifications/read-all'); store.unread = 0; notifs.value.forEach(n => n.readAt = n.readAt || new Date().toISOString()) }
function openNotice(n) { bell.value = false; if (n.link) router.push(n.link) }

watch(() => route.fullPath, () => { bell.value = menu.value = false })
// 登入後連上即時通道、載入對話列表；登出就斷線
watch(() => store.user?.id, (id) => { if (id) { connect(); store.loadConversations() } else disconnect() }, { immediate: true })
onMounted(() => onEvent((ev) => store.onRealtime(ev)))
</script>
