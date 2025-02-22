<template>
  <div class="skill-book-ui">
    <n-descriptions>
      <n-descriptions-item label="Level">{{ level }}</n-descriptions-item>
      <n-descriptions-item label="SP">{{ available_sp }}</n-descriptions-item>
    </n-descriptions>
    <n-tabs type="line" animated>
      <n-tab-pane v-for="(levelSkills, i) in skillGroups" :key="i" :name="i" :tab="'Job Level ' + (i + 1)">
        <n-list>
          <n-list-item v-for="skill in levelSkills" :key="skill.id">
            <n-space align="center">
              <lazy-image :image="skill.icon" />
              <n-tooltip trigger="hover">
                <template #trigger>
                  <span>Level: {{ skill.level }}</span>
                </template>
                <div>
                  <div style="font-weight: bold; margin-bottom: 4px">{{ skill.name }}</div>
                  <div>{{ skill.desc }}</div>
                </div>
              </n-tooltip>
              <n-button size="small" type="primary" :disabled="!skill.can_raise" @click="increaseSP(skill)">
                Increase SP
              </n-button>
            </n-space>
          </n-list-item>
        </n-list>
      </n-tab-pane>
    </n-tabs>
  </div>
</template>

<script setup>
import { watch_player_char_stat } from 'lib/ms/char_stats/char_stats.js';
import { increase_sp, watch_skill_book } from 'lib/ms/skill_book/skill_book.js';
import { NButton, NDescriptions, NDescriptionsItem, NList, NListItem, NSpace, NTabPane, NTabs, NTooltip } from 'naive-ui';
import { computed, onUnmounted, ref } from 'vue';
import LazyImage from './components/LazyImage.vue';

// Props
const props = defineProps({
  skill_book_mod: {
    type: Object,
  },
  char_stats_mod: {
    type: Object,
  },
})

// Reactive state
const level = ref(0)
const available_sp = ref(0)
const skills = ref([])
const enableWatch = ref(true)

// Computed
const skillGroups = computed(() => {
  const grouped = skills.value.reduce((acc, skill) => {
    const jobLevel = skill.job_level_value
    acc[jobLevel] = acc[jobLevel] || []
    acc[jobLevel].push(skill)
    return acc
  }, {})

  return Object.keys(grouped).sort().map(key => grouped[key])
})

// Methods
function increaseSP(skill) {
  increase_sp(props.skill_book_mod, skill.id)
}

watch_skill_book(props.skill_book_mod, (evt) => {
  if (!enableWatch.value) return false

  if (evt.kind === 'data') {
    const value = evt.data_event
    skills.value = value.skills
    level.value = value.level
    available_sp.value = value.available_sp
  } else if (evt.kind === 'level') {
    const value = evt.level_event
    skills.value = skills.value.map(skill =>
      skill.id === value.skill_id ? { ...skill, level: value.level } : skill
    )
  }
  return true
})
watch_player_char_stat(props.char_stats_mod, 'level', (_, new_value) => {
  if (!enableWatch.value) return false
  level.value = new_value
  return true
})
watch_player_char_stat(props.char_stats_mod, 'sp', (_, new_value) => {
  if (!enableWatch.value) return false
  available_sp.value = new_value
  return true
})

onUnmounted(() => {
  enableWatch.value = false
})
</script>

<style scoped>
.skill-book-ui {
  padding: 20px;
  max-width: 800px;
  margin: 0 auto;
}

.n-list-item {
  padding: 8px 0;
}
</style>