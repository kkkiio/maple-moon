<template>
  <div style="min-width: 300px; background-color: #f5f5f5; border: 1px solid #ddd; border-radius: 4px; padding: 16px; height: fit-content;">
    <n-tabs>
      <n-tab-pane name="Equipment" tab="Equipment">
        <equip-inventory v-if="game" :game="game" />
      </n-tab-pane>
      <n-tab-pane name="Status" tab="Status">
        <div v-if="game">Status panel coming soon.</div>
      </n-tab-pane>
    </n-tabs>
  </div>
</template>

<script>
import { NTabPane, NTabs } from 'naive-ui';
import { defineComponent } from 'vue';
import EquipInventoryUI from './ui/equip_inventory.vue';

export default defineComponent({
  name: 'GameUI',
  components: {
    'equip-inventory': EquipInventoryUI,
    NTabs,
    NTabPane
  },
  props: {
    game: {
      type: Object,
      default: null
    }
  },
});
</script>

<style scoped>
/* Additional styling can go here if needed */
</style> 