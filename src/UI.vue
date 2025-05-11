<script setup>
import { NTabPane, NTabs } from 'naive-ui';
import { ref } from 'vue';
import EquippedEquipment from './ui/EquippedEquipment.vue';
import ItemInventory from './ui/ItemInventory.vue';
import KeyboardConfig from './ui/KeyboardConfig.vue';
import SkillBookUI from './ui/SkillBook.vue';
import CharacterStats from './ui/CharacterStats.vue';
import { pollMod } from './utils';
import { NDialogProvider } from 'naive-ui';
import Debug from './ui/Debug.vue';
import Shop from './ui/Shop.vue';
import QuestLog from './ui/QuestLog.vue';
const skill_book_mod = ref(null);
const char_stats_mod = ref(null);
const inventory_mod = ref(null);
const shop_mod = ref(null);
const keyboard_mod = ref(null);
const stage = ref(null);
const quest_mod = ref(null);
const { game } = defineProps({
  game: Object
});


pollMod(skill_book_mod, 'skill_book', game);
pollMod(char_stats_mod, 'char_stats', game);
pollMod(inventory_mod, 'inventory', game);
pollMod(keyboard_mod, 'keyboard', game);
pollMod(stage, 'stage', game);
pollMod(shop_mod, 'shop', game);
pollMod(quest_mod, 'quest', game);
</script>
<template>
  <div
    style="background-color: rgba(245, 245, 245, 0.9); border: 1px solid #ddd; border-radius: 4px; padding: 10px; max-height: 80vh; overflow-y: auto; box-shadow: 0 2px 8px rgba(0,0,0,0.15); display: flex; flex-direction: row-reverse;">
    <n-dialog-provider>
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
        <n-tab-pane name="Character" tab="Character">
          <CharacterStats v-if="char_stats_mod" :mod="char_stats_mod" />
        </n-tab-pane>
        <n-tab-pane name="Debug" tab="Debug">
          <Debug v-if="stage" :stage="stage" />
        </n-tab-pane>
        <n-tab-pane name="Shop" tab="Shop">
          <Shop v-if="shop_mod && inventory_mod" :shop_mod="shop_mod" :inventory_mod="inventory_mod" />
        </n-tab-pane>
        <n-tab-pane name="Quests" tab="Quests">
          <QuestLog v-if="quest_mod" :mod="quest_mod" />
        </n-tab-pane>
      </n-tabs>
    </n-dialog-provider>
  </div>
</template>
