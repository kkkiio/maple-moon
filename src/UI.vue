<script setup>
import { NCheckbox } from 'naive-ui';
import Window from './components/Window.vue';
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

// Window visibility controls
const show_equipped_equipment = ref(false);
const show_skill_book = ref(false);
const show_inventory = ref(false);
const show_keyboard = ref(false);
const show_character = ref(false);
const show_debug = ref(false);
const show_shop = ref(false);
const show_quests = ref(false);
</script>
<template>
  <div
    style="background-color: rgba(245, 245, 245, 0.9); border: 1px solid #ddd; border-radius: 4px; padding: 10px; max-height: 80vh; overflow-y: auto; box-shadow: 0 2px 8px rgba(0,0,0,0.15); display: flex; flex-direction: column;">
    <n-dialog-provider>
      <!-- Window Controls -->
      <div
        style="display: flex; flex-direction: column; gap: 16px; margin-bottom: 16px; padding: 8px; border-bottom: 1px solid #ddd;">
        <n-checkbox v-model:checked="show_equipped_equipment">
          Equipped
        </n-checkbox>
        <n-checkbox v-model:checked="show_skill_book">
          Skill
        </n-checkbox>
        <n-checkbox v-model:checked="show_inventory">
          Inventory
        </n-checkbox>
        <n-checkbox v-model:checked="show_keyboard">
          Keyboard
        </n-checkbox>
        <n-checkbox v-model:checked="show_character">
          Character
        </n-checkbox>
        <n-checkbox v-model:checked="show_debug">
          Debug
        </n-checkbox>
        <n-checkbox v-model:checked="show_shop">
          Shop
        </n-checkbox>
        <n-checkbox v-model:checked="show_quests">
          Quests
        </n-checkbox>
      </div>

      <!-- Windows -->
      <Window :active="show_equipped_equipment" :z-index="10">
        <EquippedEquipment v-if="show_equipped_equipment && inventory_mod" :mod="inventory_mod" />
      </Window>

      <Window :active="show_skill_book" :z-index="10">
        <SkillBookUI v-if="show_skill_book && skill_book_mod && char_stats_mod" :skill_book_mod="skill_book_mod"
          :char_stats_mod="char_stats_mod" />
      </Window>

      <Window :active="show_inventory" :z-index="10">
        <ItemInventory v-if="show_inventory && inventory_mod" :mod="inventory_mod" />
      </Window>

      <Window :active="show_keyboard" :z-index="10">
        <KeyboardConfig v-if="show_keyboard && keyboard_mod" :mod="keyboard_mod" />
      </Window>

      <Window :active="show_character" :z-index="10">
        <CharacterStats v-if="show_character && char_stats_mod" :mod="char_stats_mod" />
      </Window>

      <Window :active="show_debug" :z-index="10">
        <Debug v-if="show_debug && stage" :stage="stage" />
      </Window>

      <Window :active="show_shop" :z-index="10">
        <Shop v-if="show_shop && shop_mod && inventory_mod" :shop_mod="shop_mod" :inventory_mod="inventory_mod" />
      </Window>

      <Window :active="show_quests" :z-index="10">
        <QuestLog v-if="show_quests && quest_mod" :mod="quest_mod" />
      </Window>
    </n-dialog-provider>
  </div>
</template>
