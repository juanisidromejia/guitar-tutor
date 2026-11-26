import { createApp } from 'vue'
import { createRouter, createWebHistory } from 'vue-router'
import './style.css'
import App from './App.vue'
import Home from './views/HomeView.vue'
import Practice from './views/PracticeView.vue'
import Scores from './views/SheetMusicView.vue'
import StaffPractice from './views/StaffFretboardLesson.vue'
import OpenStrings from './views/OpenStringsLesson.vue'
import PhrasePractice from './views/PhrasePracticeView.vue'
import RhythmReading from './views/RhythmReadingView.vue'
import Assessment from './views/AssessmentView.vue'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    { path: '/', component: Home },
    { path: '/fundamentos', component: OpenStrings },
    { path: '/practicar', component: Practice },
    { path: '/partitura', component: Scores },
    { path: '/notas-pentagrama', component: StaffPractice },
    { path: '/lectura-ritmica', component: RhythmReading },
    { path: '/evaluacion', component: Assessment },
    { path: '/del-papel-a-la-guitarra', component: PhrasePractice },
    { path: '/:pathMatch(.*)*', redirect: '/' },
  ],
  scrollBehavior: () => ({ top: 0 }),
})

createApp(App).use(router).mount('#app')
