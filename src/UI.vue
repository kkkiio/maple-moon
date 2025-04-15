<script setup>
import { NTabPane, NTabs } from 'naive-ui';
import { ref } from 'vue';
import EquippedEquipment from './ui/EquippedEquipment.vue';
import ItemInventory from './ui/ItemInventory.vue';
import KeyboardConfig from './ui/KeyboardConfig.vue';
import SkillBookUI from './ui/SkillBook.vue';
import { pollMod } from './utils';

const skill_book_mod = ref(null);
const char_stats_mod = ref(null);
const inventory_mod = ref(null);
const keyboard_mod = ref(null);

const { game } = defineProps({
  game: Object
});


pollMod(skill_book_mod, 'get_skill_book_mod', game);
pollMod(char_stats_mod, 'get_char_stats_mod', game);
pollMod(inventory_mod, 'get_inventory_mod', game);
pollMod(keyboard_mod, 'get_keyboard_mod', game);
</script>
<template>
  <div
    style="background-color: rgba(245, 245, 245, 0.9); border: 1px solid #ddd; border-radius: 4px; padding: 10px; max-height: 80vh; overflow-y: auto; box-shadow: 0 2px 8px rgba(0,0,0,0.15); display: flex; flex-direction: row-reverse;">
    <n-tabs type="line" placement="right" style="height: 100%;">
      <n-tab-pane name="Equipped" tab="Equipped">
        <EquippedEquipment v-if="inventory_mod" :mod="inventory_mod" />
      </n-tab-pane>
      <n-tab-pane name="Skill" tab="Skill">
        <SkillBookUI v-if="skill_book_mod && char_stats_mod" :skill_book_mod="skill_book_mod"
          :char_stats_mod="char_stats_mod" />
      </n-tab-pane>
      <n-tab-pane name="Inventory" tab="Inventory">
        <ItemInventory v-if="inventory_mod" :mod="inventory_mod" />
      </n-tab-pane>
      <n-tab-pane name="Keyboard" tab="Keyboard">
        <KeyboardConfig v-if="keyboard_mod" :mod="keyboard_mod" />
      </n-tab-pane>
    </n-tabs>
  </div>
</template>
