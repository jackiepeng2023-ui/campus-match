import { createApp } from 'vue'
import { createRouter, createWebHashHistory } from 'vue-router'
import App from './App.vue'
import './style.css'
import { token } from './api'
import { store } from './store'

// 主線：選比賽 → 開隊 → 推薦／找隊 → 申請／邀請 → 洽談 → 成隊 → 報名追蹤
const routes = [
  { path: '/', component: () => import('./views/Teams.vue') },
  { path: '/login', component: () => import('./views/Login.vue'), meta: { public: true } },
  { path: '/competitions', component: () => import('./views/Competitions.vue') },
  { path: '/competitions/:id', component: () => import('./views/CompetitionDetail.vue') },
  { path: '/teams/:id', component: () => import('./views/Team.vue') },
  { path: '/cases/:id', component: () => import('./views/Team.vue') },            // 通知裡的連結沿用 /cases/…
  { path: '/cases/:id/review', component: () => import('./views/Review.vue') },
  { path: '/messages', component: () => import('./views/Messages.vue') },
  { path: '/messages/:id', component: () => import('./views/Messages.vue') },
  { path: '/profile', component: () => import('./views/Profile.vue') },
  { path: '/users/:id', component: () => import('./views/PublicProfile.vue') },
  { path: '/assistant', component: () => import('./views/Assistant.vue') },
  { path: '/admin', component: () => import('./views/Admin.vue') },
  { path: '/cases', redirect: '/' },
  { path: '/growth', redirect: '/profile' },
  { path: '/:rest(.*)*', redirect: '/' },
]
const router = createRouter({ history: createWebHashHistory(), routes, scrollBehavior: (to, from) => to.path === from.path ? undefined : { top: 0 } })
router.beforeEach(async (to) => {
  if (to.meta.public) return true
  if (!token()) return '/login'
  if (!store.user) await store.loadMe()
  if (!store.user) return '/login'
  return true
})
createApp(App).use(router).mount('#app')
