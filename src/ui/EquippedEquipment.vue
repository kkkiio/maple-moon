<template>
  <n-space vertical>
    <n-space vertical>
      <n-card v-for="equip in equips" :key="equip.id" size="small" class="item-card">
        <n-tooltip trigger="hover" placement="top">
          <template #trigger>
            <n-space align="center">
              <lazy-image :image="equip.icon" />
            </n-space>
          </template>
          <div class="tooltip-content">
            <div class="tooltip-name">
              {{ equip.name }}
            </div>
            <div class="tooltip-desc" v-html="equip.desc"></div>
          </div>
        </n-tooltip>
      </n-card>
    </n-space>
  </n-space>
</template>

<script setup>
import { watch_inventory_by_kind } from 'lib/ms/inventory/inventory.js';
import { NCard, NSpace, NTooltip } from 'naive-ui';
import { onUnmounted, ref } from 'vue';
import LazyImage from '@/components/LazyImage.vue';

const props = defineProps({
  mod: {
    type: Object,
  }
});

const equips = ref([]);
const enableWatch = ref(true);

// Watch inventory changes and update items
watch_inventory_by_kind(props.mod, 'equipped', (slots) => {
  if (!enableWatch.value) return false;
  equips.value = slots.filter(slot => slot)
  return true; // Continue watching
});
onUnmounted(() => {
  enableWatch.value = false;
});

</script>

<style scoped>
.item-card {
  max-width: 300px;
}

.item-icon {
  width: 32px;
  height: 32px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.tooltip-content {
  max-width: 200px;
}

.tooltip-name {
  font-weight: bold;
  margin-bottom: 4px;
}

.tooltip-desc {
  font-size: 12px;
  white-space: pre-wrap;
}
</style>