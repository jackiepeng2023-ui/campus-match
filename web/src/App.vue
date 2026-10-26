<template>
  <div>
    <nav class="nav" v-if="store.user">
      <div class="nav-inner">
        <router-link to="/" class="brand">跨系媒合</router-link>
        <router-link to="/" class="link" :class="{active: $route.path === '/'}">首頁</router-link>
        <router-link to="/cases" class="link" :class="{active: $route.path.startsWith('/cases')}">案件</router-link>
        <router-link to="/profile" class="link" :class="{active: $route.path === '/profile'}">我的檔案</router-link>
        <router-link to="/growth" class="link" :class="{active: $route.path === '/growth'}">成長</router-link>
        <router-link v-if="store.user.role === 'ADMIN'" to="/admin" class="link" :class="{active: $route.path === '/admin'}">管理</router-link>
        <span class="spacer"></span>
        <div style="position:relative">
          <button class="btn ghost" @click="toggleBell">通知<span v-if="store.unread" class="dot"></span></button>
          <div v-if="bell" class="menu" @mouseleave="bell=false">
            <div class="row between" style="padding:4px 8px"><strong class="small">通知</strong><button class="btn ghost sm" @click="readAll">全部已讀</button></div>
            <div v-if="!notifs.length" class="empty">沒有通知</div>
            <div v-for="n in notifs" :key="n.id" class="item" :class="{unread: !n.readAt}" @click="open(n)">
              <div><strong>{{ n.title }}</strong> <span class="muted small">{{ fmtTime(n.createdAt) }}</span></div>
              <div class="sub small">{{ n.body }}</div>
            </div>
          </div>
        </div>
        <span class="sub small username">{{ store.user.name }}</span>
        <button class="btn ghost sm" @click="store.logout()">登出</button>
      </div>
    </nav>
    <main class="container"><router-view :key="$route.fullPath" /></main>
    <div v-if="store.toast" class="toast" :class="store.toast.kind">{{ store.toast.message }}</div>
  </div>
</template>
<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { store, fmtTime } from './store'
import { get, post } from './api'
const router = useRouter()
const bell = ref(false), notifs = ref([])
async function toggleBell() {
  bell.value = !bell.value
  if (bell.value) { const r = await get('/me/notifications'); notifs.value = r.items; store.unread = r.unread }
}
async function readAll() { await post('/me/notifications/read-all'); store.unread = 0; notifs.value.forEach(n => n.readAt = n.readAt || new Date().toISOString()) }
function open(n) { bell.value = false; if (n.link) router.push(n.link) }
</script>
