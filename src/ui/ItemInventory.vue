<script setup>
import {
  use_item_at,
  watch_inventory_by_kind,
  watch_meso,
  drop_item,
} from "lib/ms/inventory/inventory.js";
import {
  NAlert,
  NTabPane,
  NTabs,
  NTooltip,
  NButton,
  NModal,
  NInputNumber,
} from "naive-ui";
import { computed, onUnmounted, ref } from "vue";
import LazyImage from "@/components/LazyImage.vue";

const { mod } = defineProps({
  mod: {
    type: Object,
    required: true,
  },
});

const TAB_KINDS = ["equip", "use", "setup", "etc"];

const meso = ref(0);
const hint = ref("");
const inventoryItems = ref({});

const enableWatch = ref(true);
for (const kind of TAB_KINDS) {
  watch_inventory_by_kind(mod, kind, (items) => {
    if (!enableWatch.value) return false;
    inventoryItems.value[kind] = items;
    return true; // Continue watching
  });
}
watch_meso(mod, (newMeso) => {
  if (!enableWatch.value) return false;
  meso.value = newMeso;
  return true; // Continue watching
});
onUnmounted(() => {
  enableWatch.value = false;
});

const panels = computed(() => {
  const panels = [];
  for (const kind of TAB_KINDS) {
    const items = inventoryItems.value[kind];
    const table = [];
    for (let i = 0; i < items.length; i += 4) {
      table.push(items.slice(i, i + 4));
    }
    panels.push({ kind, table });
  }
  return panels;
});

// Selection state
const selected = ref({ tab: null, row: null, col: null });
const selectedItemSlot = computed(() => {
  if (
    selected.value.tab === null ||
    selected.value.row === null ||
    selected.value.col === null
  ) {
    return null;
  }
  const panel = panels.value[selected.value.tab];
  const item = panel.table[selected.value.row][selected.value.col];
  return {
    kind: panel.kind,
    item: item,
  };
});

// Drop item modal state
const showDropModal = ref(false);
const dropCount = ref(1);

const handleItemClick = (tab, row, col) => {
  if (
    selected.value.tab === tab &&
    selected.value.row === row &&
    selected.value.col === col
  ) {
    selected.value = { tab: null, row: null, col: null };
  } else {
    selected.value = { tab, row, col };
  }
};

const handleUseItem = () => {
  if (selectedItemSlot.value) {
    const result = use_item_at(
      mod,
      selectedItemSlot.value.kind,
      selectedItemSlot.value.item.slot_no
    );
    if (result) {
      hint.value = result;
    }
  }
};

const handleDropClick = () => {
  if (selectedItemSlot.value) {
    const item = selectedItemSlot.value.item;
    if (item.count === 1 || !item.count) {
      // Directly drop if count is 1 or undefined
      const result = drop_item(
        mod,
        selectedItemSlot.value.kind,
        item.slot_no,
        1
      );
      if (result) {
        hint.value = result;
      }
    } else {
      dropCount.value = 1;
      showDropModal.value = true;
    }
  }
};

const handleDropConfirm = () => {
  if (selectedItemSlot.value) {
    const item = selectedItemSlot.value.item;
    const count = Math.max(1, Math.min(dropCount.value, item.count || 1));
    const result = drop_item(
      mod,
      selectedItemSlot.value.kind,
      item.slot_no,
      count
    );
    if (result) {
      hint.value = result;
    }
    showDropModal.value = false;
    dropCount.value = 1;
  }
};

const handleDropCancel = () => {
  showDropModal.value = false;
  dropCount.value = 1;
};
</script>

<template>
  <NTabs type="segment">
    <NTabPane v-for="(panel, tabIndex) in panels" :key="tabIndex" :name="panel.kind" :tab="panel.kind">
      <table class="inventory-table">
        <tbody>
          <tr v-for="(row, rowIndex) in panel.table" :key="'row-' + rowIndex">
            <td v-for="(item, colIndex) in row" :key="'col-' + colIndex" class="inventory-cell">
              <div class="inventory-slot-wrapper">
                <!-- Item slot with content -->
                <template v-if="item">
                  <NTooltip trigger="hover" placement="top">
                    <template #trigger>
                      <div class="inventory-slot" :class="{
                        'selected-slot':
                          selected.tab === tabIndex &&
                          selected.row === rowIndex &&
                          selected.col === colIndex,
                      }" @click="
                          () => handleItemClick(tabIndex, rowIndex, colIndex)
                        ">
                        <LazyImage :image="item.icon" />
                        <div v-if="item.count" class="item-count">
                          {{ item.count }}
                        </div>
                      </div>
                    </template>
                    <div class="tooltip-content">
                      <div class="tooltip-name">
                        {{ item.name || item.id }}
                      </div>
                      <div class="tooltip-desc" v-html="item.desc"></div>
                    </div>
                  </NTooltip>
                </template>
                <div v-else class="inventory-slot empty-slot"></div>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </NTabPane>
  </NTabs>
  <div class="inventory-footer">
    <div class="currency">
      <span>Meso: {{ meso }}</span>
    </div>
  </div>
  <NAlert v-if="hint" type="warning" closable @close="hint = ''">
    {{ hint }}
  </NAlert>
  <div class="action-bar">
    <n-button type="primary" :disabled="selected.tab === null || selected.row === null || selected.col === null
      " @click="handleUseItem">
      Use Item
    </n-button>
    <n-button type="error" style="margin-left: 8px" :disabled="selected.tab === null || selected.row === null || selected.col === null
      " @click="handleDropClick">
      Drop
    </n-button>
  </div>
  <n-modal v-model:show="showDropModal" preset="dialog" title="Drop Item" @after-leave="handleDropCancel">
    <template #default>
      <div style="margin-bottom: 12px">Enter the number of items to drop:</div>
      <n-input-number v-model:value="dropCount" :min="1" :max="selectedItemSlot.value ? selectedItemSlot.value.item.count || 1 : 1
        " />
    </template>
    <template #action>
      <n-button @click="handleDropCancel">Cancel</n-button>
      <n-button type="error" @click="handleDropConfirm" :keyboard="false" style="margin-left: 8px">Drop</n-button>
    </template>
  </n-modal>
</template>

<style scoped>
.inventory-panel {
  padding: 8px;
}

.inventory-table {
  border-collapse: collapse;
  width: 100%;
}

.inventory-cell {
  width: 25%;
  height: 40px;
  padding: 2px;
  vertical-align: middle;
  text-align: center;
}

.inventory-slot-wrapper {
  width: 100%;
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
}

.inventory-slot {
  width: 40px;
  height: 40px;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  position: relative;
  margin: 0 auto;
  border: 1px solid transparent;
  transition: border 0.2s;
}

.selected-slot {
  border: 2px solid #18a058;
  box-shadow: 0 0 2px #18a058;
}

.inventory-slot:hover {
  background: #f0f0f0;
}

.empty-slot {
  border: 1px dashed #ccc;
  background: rgba(0, 0, 0, 0.03);
  cursor: default;
}

.empty-slot:hover {
  background: rgba(0, 0, 0, 0.05);
}

.item-count {
  position: absolute;
  bottom: 1px;
  right: 1px;
  background: rgba(0, 0, 0, 0.7);
  color: white;
  padding: 0 2px;
  font-size: 10px;
  border-radius: 2px;
  min-width: 12px;
  text-align: center;
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

.inventory-footer {
  display: flex;
  flex-direction: column;
  gap: 8px;
  margin-top: 16px;
  background: #f5f5f5;
  padding: 8px;
  position: sticky;
  bottom: 0;
}

.action-bar {
  display: flex;
  justify-content: flex-end;
  padding-top: 4px;
}

.currency {
  display: flex;
  gap: 16px;
}
</style>
