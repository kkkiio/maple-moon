<template>
  <n-space vertical>
    <n-space vertical>
      <n-card v-for="item in items" :key="item.id" size="small" class="item-card">
        <n-space align="center">
          <lazy-image :image="item.icon" />
          <n-text>{{ item.name }}</n-text>
        </n-space>
      </n-card>
    </n-space>
  </n-space>
</template>

<script setup>
import { watch_inventory_by_kind } from 'lib/ms/inventory/inventory.js';
import { NCard, NSpace, NText } from 'naive-ui';
import { onUnmounted, ref } from 'vue';
import LazyImage from '@/components/LazyImage.vue';

const props = defineProps({
  mod: {
    type: Object,
  }
});

const items = ref([]);
const enableWatch = ref(true);

// Watch inventory changes and update items
watch_inventory_by_kind(props.mod, 'equipped', (newItems) => {
  if (!enableWatch.value) return false;
  items.value = newItems;
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
</style>