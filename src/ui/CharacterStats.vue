<template>
  <div class="character-stats-ui">
    <n-card title="Character Stats" size="small">
      <!-- Basic Stats Section -->
      <n-space vertical>
        <n-space justify="space-between" align="center">
          <div class="stat-header">
            <n-avatar round :size="48" :src="characterAvatar" />
            <div class="character-info">
              <div class="character-job">{{ job }}</div>
            </div>
          </div>
        </n-space>

        <n-divider />

        <!-- Basic Stats View -->
        <div class="stats-container">
          <n-grid :cols="2" :x-gap="12">
            <n-grid-item>
              <n-space vertical>
                <stat-row label="Level" :value="level" />
                <stat-row label="HP" :value="hp" :max="maxHp">
                  <template #suffix>
                    <n-button size="tiny" :disabled="!hasAp" @click="spendAp('hp')" circle>
                      <template #icon>
                        <n-icon><plus-icon /></n-icon>
                      </template>
                    </n-button>
                  </template>
                </stat-row>
                <stat-row label="MP" :value="mp" :max="maxMp">
                  <template #suffix>
                    <n-button size="tiny" :disabled="!hasAp" @click="spendAp('mp')" circle>
                      <template #icon>
                        <n-icon><plus-icon /></n-icon>
                      </template>
                    </n-button>
                  </template>
                </stat-row>
              </n-space>
            </n-grid-item>

            <n-grid-item>
              <n-space vertical>
                <stat-row label="STR" :value="str">
                  <template #suffix>
                    <n-button size="tiny" :disabled="!hasAp" @click="spendAp('str')" circle>
                      <template #icon>
                        <n-icon><plus-icon /></n-icon>
                      </template>
                    </n-button>
                  </template>
                </stat-row>
                <stat-row label="DEX" :value="dex">
                  <template #suffix>
                    <n-button size="tiny" :disabled="!hasAp" @click="spendAp('dex')" circle>
                      <template #icon>
                        <n-icon><plus-icon /></n-icon>
                      </template>
                    </n-button>
                  </template>
                </stat-row>
                <stat-row label="INT" :value="int">
                  <template #suffix>
                    <n-button size="tiny" :disabled="!hasAp" @click="spendAp('int')" circle>
                      <template #icon>
                        <n-icon><plus-icon /></n-icon>
                      </template>
                    </n-button>
                  </template>
                </stat-row>
                <stat-row label="LUK" :value="luk">
                  <template #suffix>
                    <n-button size="tiny" :disabled="!hasAp" @click="spendAp('luk')" circle>
                      <template #icon>
                        <n-icon><plus-icon /></n-icon>
                      </template>
                    </n-button>
                  </template>
                </stat-row>
              </n-space>
            </n-grid-item>
          </n-grid>

          <n-space justify="space-between" style="margin-top: 12px">
            <div>
              <n-tag type="success">AP: {{ ap }}</n-tag>
              <n-tag type="info" style="margin-left: 8px">Fame: {{ fame }}</n-tag>
            </div>
            <n-button size="small" :disabled="!hasAp" @click="autoAssignAp">Auto Assign</n-button>
          </n-space>
        </div>
      </n-space>
    </n-card>
  </div>
</template>

<script setup>
import { watch_player_char_stat, spend_ap, get_recommend_assign } from 'lib/ms/char_stats/char_stats.js';
import { NAvatar, NButton, NCard, NDivider, NGrid, NGridItem, NIcon, NSpace, NTag, useDialog } from 'naive-ui';
import { Add as PlusIcon } from '@vicons/ionicons5';
import { onUnmounted, ref } from 'vue';
import StatRow from '../components/StatRow.vue';

const props = defineProps({
  mod: {
    type: Object,
    required: true
  }
});

// Reactive state
const job = ref('');
const level = ref(1);
const hp = ref(50);
const maxHp = ref(50);
const mp = ref(5);
const maxMp = ref(5);
const exp = ref(0);
const maxExp = ref(100);
const str = ref(4);
const dex = ref(4);
const int = ref(4);
const luk = ref(4);
const ap = ref(0);
const fame = ref(0);
const hasAp = ref(false);

// Detailed stats

// UI state
const enableWatch = ref(true);
const characterAvatar = ref(''); // This would be set from character data

// Initialize dialog provider
const dialog = useDialog();

// Methods
function spendAp(statType) {
  spend_ap(props.mod, statType);
}

function autoAssignAp() {
  // Get the recommended AP assignment
  const assign = get_recommend_assign(props.mod);

  // Create message for confirmation dialog
  const message = `Your AP will be distributed as follows:
STR: +${assign.str}
DEX: +${assign.dex}
INT: +${assign.int}
LUK: +${assign.luk}`;

  // Show confirmation dialog
  dialog.info({
    title: 'Auto Assign AP',
    content: message,
    positiveText: 'Apply',
    negativeText: 'Cancel',
    onPositiveClick: () => {
      // Apply the recommended AP assignment
      applyRecommendedAssignment(assign);
    }
  });
}

// Helper function to apply the recommended AP assignment
function applyRecommendedAssignment(assign) {
  // Apply STR points
  for (let i = 0; i < assign.str; i++) {
    spend_ap(props.mod, 'str');
  }

  // Apply DEX points
  for (let i = 0; i < assign.dex; i++) {
    spend_ap(props.mod, 'dex');
  }

  // Apply INT points
  for (let i = 0; i < assign.int; i++) {
    spend_ap(props.mod, 'int');
  }

  // Apply LUK points
  for (let i = 0; i < assign.luk; i++) {
    spend_ap(props.mod, 'luk');
  }
}

// Watch for stat changes
const statMappings = {
  'job': (val) => job.value = val,
  'level': (val) => level.value = val,
  'hp': (val) => hp.value = val,
  'maxhp': (val) => maxHp.value = val,
  'mp': (val) => mp.value = val,
  'maxmp': (val) => maxMp.value = val,
  'exp': (val) => exp.value = val,
  'str': (val) => str.value = val,
  'dex': (val) => dex.value = val,
  'int': (val) => int.value = val,
  'luk': (val) => luk.value = val,
  'ap': (val) => {
    ap.value = val;
    hasAp.value = val > 0;
  },
  'fame': (val) => fame.value = val,

};


// Set up watchers for all stats
Object.entries(statMappings).forEach(([statName, updateFn]) => {
  watch_player_char_stat(props.mod, statName, (_, newValue) => {
    if (!enableWatch.value) return false;
    updateFn(newValue);
    return true;
  });
});

onUnmounted(() => {
  enableWatch.value = false;
});
</script>

<style scoped>
.character-stats-ui {
  width: 100%;
  max-width: 480px;
  margin: 0 auto;
}

.stat-header {
  display: flex;
  align-items: center;
  gap: 12px;
}

.character-info {
  display: flex;
  flex-direction: column;
}

.character-job {
  font-size: 14px;
  color: #666;
}

.stats-container {
  padding: 8px 0;
}

.stat-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 4px 0;
}

.stat-label {
  font-weight: 500;
  min-width: 80px;
}

.stat-value-container {
  display: flex;
  align-items: center;
  gap: 8px;
}

.stat-value {
  text-align: right;
}

.stat-percentage {
  font-size: 12px;
  color: #666;
  margin-left: 4px;
}
</style>
