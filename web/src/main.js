import { createApp } from 'vue'
import { createRouter, createWebHashHistory } from 'vue-router'
import App from './App.vue'
import './style.css'
import { token } from './api'
import { store } from './store'

const routes = [
  { path: '/', component: () => import('./views/Home.vue') },
  { path: '/login', component: () => import('./views/Login.vue'), meta: { public: true } },
  { path: '/cases', component: () => import('./views/Cases.vue') },
  { path: '/cases/new', component: () => import('./views/CaseForm.vue') },
  { path: '/cases/:id/edit', component: () => import('./views/CaseForm.vue') },
  { path: '/cases/:id', component: () => import('./views/CaseDetail.vue') },
  { path: '/cases/:id/review', component: () => import('./views/Review.vue') },
  { path: '/profile', component: () => import('./views/Profile.vue') },
  { path: '/users/:id', component: () => import('./views/PublicProfile.vue') },
  { path: '/growth', component: () => import('./views/Growth.vue') },
  { path: '/admin', component: () => import('./views/Admin.vue') },
]
const router = createRouter({ history: createWebHashHistory(), routes })
router.beforeEach(async (to) => {
  if (to.meta.public) return true
  if (!token()) return '/login'
  if (!store.user) await store.loadMe()
  if (!store.user) return '/login'
  return true
})
createApp(App).use(router).mount('#app')
