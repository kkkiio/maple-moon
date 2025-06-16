<template>
  <div class="mx-auto p-6 bg-white rounded-lg shadow-lg">
    <!-- 顶部控制区域 -->
    <div class="flex flex-col lg:flex-row lg:items-start lg:justify-between gap-4 mb-6">
      <!-- 模式切换开关 -->
      <div class="flex items-center gap-3">
        <NSwitch v-model:value="isTransferMode" size="large">
          <template #checked>
            <span class="text-sm font-medium">SP转移模式</span>
          </template>
          <template #unchecked>
            <span class="text-sm font-medium">普通模式</span>
          </template>
        </NSwitch>
      </div>

      <!-- 转移模式提示区域 -->
      <div v-if="isTransferMode" class="flex-1 space-y-3">
        <div class="flex items-center gap-3">
          <n-text v-if="!selectedFromSkill" type="info" class="text-sm">
            💡 请选择要减少SP的技能
          </n-text>
          <n-text v-else-if="!selectedToSkill" type="warning" class="text-sm">
            ⚠️ 请选择要增加SP的技能
          </n-text>
          <n-button size="small" type="primary" :disabled="!selectedFromSkill || !selectedToSkill"
            @click="confirmTransfer" class="ml-auto">
            确定转移
          </n-button>
        </div>

        <div class="space-y-2">
          <n-alert type="info" class="text-xs">
            💰 此操作需要消耗对应的 SP 重置道具
          </n-alert>
          <n-alert v-if="hint" type="warning" class="text-xs">
            {{ hint }}
          </n-alert>
        </div>
      </div>
    </div>

    <!-- 技能标签页 -->
    <n-tabs type="line" animated class="skill-tabs">
      <n-tab-pane v-for="group in skillGroups" :key="group.job_level_value" :name="group.job_level_value"
        :tab="`Level ${group.job_level_value}`">
        <div class="mt-4">
          <n-list class="skill-list h-96 overflow-y-auto">
            <n-list-item v-for="skill in group.skills" :key="skill.id"
              class="skill-item px-4 py-3 hover:bg-gray-50 rounded-lg transition-colors duration-200">
              <div class="flex items-center justify-between w-full">
                <!-- 技能信息区域 -->
                <div class="flex items-center gap-4">
                  <!-- 技能图标 -->
                  <div class="flex-shrink-0 w-12 h-12 rounded-lg overflow-hidden border-2 border-gray-200 shadow-sm">
                    <lazy-image :image="skill.icon" class="w-full h-full object-cover" />
                  </div>

                  <!-- 技能详情 -->
                  <div class="flex-1">
                    <n-tooltip trigger="hover" placement="top" :show-arrow="false"
                      :style="{ backgroundColor: 'white' }">
                      <template #trigger>
                        <div class="flex flex-wrap items-center gap-2">
                          <span class="text-sm font-semibold text-blue-600 bg-blue-50 px-2 py-1 rounded">
                            Lv.{{ skill.level }}
                          </span>
                          <span class="text-base font-bold text-gray-800">
                            {{ skill.name }}
                          </span>
                          <!-- 选中状态标识 -->
                          <n-tag v-if="selectedFromSkill?.id === skill.id" type="warning" size="small"
                            class="animate-pulse">
                            🎯 源技能
                          </n-tag>
                          <n-tag v-if="selectedToSkill?.id === skill.id" type="success" size="small"
                            class="animate-pulse">
                            🎯 目标技能
                          </n-tag>
                        </div>
                      </template>
                      <div v-html="skill.desc"></div>
                    </n-tooltip>
                  </div>
                </div>

                <!-- 操作按钮区域 -->
                <div class="flex-shrink-0">
                  <!-- 普通模式按钮 -->
                  <n-button v-if="!isTransferMode" size="medium" type="primary" circle :disabled="!skill.can_raise"
                    @click="increaseSP(skill)" class="w-10 h-10 hover:scale-110 transition-transform duration-200">
                    <template #icon>
                      <n-icon size="18">
                        <PlusIcon />
                      </n-icon>
                    </template>
                  </n-button>

                  <!-- 转移模式按钮组 -->
                  <div v-else class="flex items-center gap-2">
                    <!-- 减少技能等级按钮 -->
                    <n-button size="medium" :type="selectedFromSkill?.id === skill.id ? 'warning' : 'default'"
                      :disabled="skill.level <= 0 || (selectedFromSkill && selectedFromSkill.id === skill.id)"
                      @click="selectFromSkill(skill)"
                      class="w-10 h-10 hover:scale-110 transition-transform duration-200"
                      :class="selectedFromSkill?.id === skill.id ? 'ring-2 ring-yellow-300' : ''">
                      <template #icon>
                        <n-icon size="16">
                          <MinusIcon />
                        </n-icon>
                      </template>
                    </n-button>

                    <!-- 增加技能等级按钮 -->
                    <n-button size="medium" :type="selectedToSkill?.id === skill.id ? 'success' : 'primary'"
                      :disabled="skill.level >= skill.master_level || !selectedFromSkill || selectedFromSkill.id === skill.id"
                      @click="selectToSkill(skill)" class="w-10 h-10 hover:scale-110 transition-transform duration-200"
                      :class="selectedToSkill?.id === skill.id ? 'ring-2 ring-green-300' : ''">
                      <template #icon>
                        <n-icon size="16">
                          <PlusIcon />
                        </n-icon>
                      </template>
                    </n-button>
                  </div>
                </div>
              </div>
            </n-list-item>
          </n-list>
        </div>
      </n-tab-pane>
    </n-tabs>

    <!-- 底部状态信息 -->
    <div class="flex flex-wrap items-center justify-center gap-6 p-1 bg-gray-50 rounded-lg border">
      <div class="flex items-center gap-2">
        <span class="text-sm text-gray-600">等级:</span>
        <span class="text-lg font-bold text-blue-600 bg-blue-50 rounded-full">
          {{ level }}
        </span>
      </div>
      <div class="flex items-center gap-2">
        <span class="text-sm text-gray-600">可用SP:</span>
        <span class="text-lg font-bold text-green-600 bg-green-50 rounded-full">
          {{ availableSp }}
        </span>
      </div>
    </div>
  </div>
</template>

<script setup>
import { watch_player_char_stat } from 'lib/ms/char_stats/char_stats.js';
import { increase_sp, watch_skill_book, transfer_one_sp } from 'lib/ms/skill_book/skill_book.js';
import { NButton, NIcon, NList, NListItem, NTabPane, NTabs, NTooltip, NText, NTag, NAlert, NSwitch } from 'naive-ui';
import { Add as PlusIcon, Remove as MinusIcon } from '@vicons/ionicons5';
import { onUnmounted, ref } from 'vue';
import LazyImage from '@/components/LazyImage.vue';

const props = defineProps({
  skill_book_mod: {
    type: Object,
    required: true,
  },
  char_stats_mod: {
    type: Object,
    required: true,
  },
})

// Reactive state
const level = ref(0)
const availableSp = ref(0)
const skillGroups = ref([])
const enableWatch = ref(true)
// TODO: beginner sp
// let stats = player.get_stats()
// let beginner_sp = @math.minimum(
//     stats.get_stat(@maple_stat.Id::LEVEL) - 1,
//     6,
//   ) -
//   beginner_skills
//   .iter()
//   .filter(fn(skill_id) { skillbook.get_level(skill_id.int_value()) > 0 })
//   .count()

// 转移模式相关状态
const isTransferMode = ref(false)
const selectedFromSkill = ref(null)
const selectedToSkill = ref(null)

const hint = ref('')

// Methods
function increaseSP(skill) {
  increase_sp(props.skill_book_mod, skill.id)
}

function selectFromSkill(skill) {
  if (skill.level <= 0) return
  selectedFromSkill.value = skill
  selectedToSkill.value = null
}

function selectToSkill(skill) {
  if (!selectedFromSkill.value || selectedFromSkill.value.id === skill.id) return
  selectedToSkill.value = skill
}

function confirmTransfer() {
  if (!selectedFromSkill.value || !selectedToSkill.value) return

  const jobLevel = selectedFromSkill.value.job_level_value

  const result = transfer_one_sp(
    props.skill_book_mod,
    jobLevel,
    selectedFromSkill.value.id,
    selectedToSkill.value.id
  )

  if (result) {
    hint.value = result
  }
  // 允许连续转移
}

watch_skill_book(props.skill_book_mod, (evt) => {
  if (!enableWatch.value) return false

  if (evt.kind === 'data') {
    const value = evt.data_event
    skillGroups.value = value.skill_groups
  } else if (evt.kind === 'level') {
    const value = evt.level_event
    for (const group of skillGroups.value) {
      for (const skill of group.skills) {
        if (skill.id === value.skill_id) {
          skill.level = value.level
        }
      }
    }
  }
  return true
})
watch_player_char_stat(props.char_stats_mod, 'LEVEL', (_, new_value) => {
  if (!enableWatch.value) return false
  level.value = new_value
  return true
})
watch_player_char_stat(props.char_stats_mod, 'SP', (_, new_value) => {
  if (!enableWatch.value) return false
  availableSp.value = new_value
  return true
})

onUnmounted(() => {
  enableWatch.value = false
})
</script>