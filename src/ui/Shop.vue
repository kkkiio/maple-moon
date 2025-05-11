<template>
  <div v-if="shopData" class="shop-container">
    <!-- Main Content Area -->
    <div class="shop-content">

      <!-- Buy Section (Left Column) -->
      <div class="buy-section">
        <h3>Buy Items</h3>
        <div class="item-list buy-list">
          <div v-for="item in shopItems" :key="item.id" class="shop-item"
            :class="{ selected: selectedBuyItem?.id === item.id }" @click="selectBuyItem(item)">
            <n-tooltip trigger="hover" placement="top">
              <template #trigger>
                <div class="item-display">
                  <LazyImage :image="item.icon" :width="32" :height="32" />
                  <span class="item-name">{{ item.name }}</span>
                  <span class="item-price">{{ formatMeso(item.price) }} Meso</span>
                </div>
              </template>
              <div class="tooltip-content">
                <div class="tooltip-name">{{ item.name }}</div>
                <div class="tooltip-desc" v-html="item.desc"></div>
              </div>
            </n-tooltip>
          </div>
        </div>
      </div>

      <!-- Sell Section (Right Column) -->
      <div class="sell-section">
        <h3>Sell Items</h3>
        <n-tabs type="segment" v-model:value="activeTab">
          <n-tab-pane v-for="(kind, index) in TAB_KINDS" :key="index" :name="index" :tab="kind">
            <div class="inventory-panel">
              <table class="inventory-table">
                <tbody>
                  <tr v-for="row in Math.max(4, Math.ceil(currentItems.length / 4))" :key="'row-' + row">
                    <td v-for="col in 4" :key="'col-' + col" class="inventory-cell">
                      <div class="inventory-slot-wrapper">
                        <!-- Item slot with content -->
                        <template v-if="hasItemAt(row, col)">
                          <n-tooltip trigger="hover" placement="top">
                            <template #trigger>
                              <div class="inventory-slot"
                                :class="{ 'selected-slot': selected.kind === kind && selected.index === getItemIndex(row, col) }"
                                @click="() => handleItemClick(kind, getItemIndex(row, col))">
                                <LazyImage :image="getItemAt(row, col).icon" :width="32" :height="32" />
                                <div v-if="shouldShowCount && getItemAt(row, col).count" class="item-count">
                                  {{ getItemAt(row, col).count }}
                                </div>
                              </div>
                            </template>
                            <div class="tooltip-content">
                              <div class="tooltip-name">{{ getItemAt(row, col).name }}</div>
                              <div class="tooltip-desc" v-html="getItemAt(row, col).desc"></div>
                            </div>
                          </n-tooltip>
                        </template>
                        <!-- Empty slot -->
                        <div v-else class="inventory-slot empty-slot"></div>
                      </div>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </n-tab-pane>
        </n-tabs>
      </div>
    </div>

    <!-- Footer / Actions -->
    <div class="shop-footer">
      <div class="meso-display">
        Your Mesos: {{ formatMeso(meso) }}
      </div>
      <div class="action-buttons">
        <NSpace>
          <n-button type="primary" :disabled="!selectedBuyItem" @click="handleBuyOne">
            Buy One
          </n-button>
          <n-button type="info" :disabled="!selectedBuyItem" @click="handleBuyMultiple">
            Buy Multiple
          </n-button>
          <n-button type="warning" :disabled="!selected.kind || selected.index === null" @click="handleSellItem">
            Sell
          </n-button>
          <n-button type="error" @click="closeShop">
            Exit Shop
          </n-button>
        </NSpace>
      </div>
    </div>

    <!-- Alert for hints/errors -->
    <n-alert v-if="hint" type="warning" closable @close="hint = ''">
      {{ hint }}
    </n-alert>

    <!-- Sell quantity modal -->
    <n-modal v-model:show="showSellModal" preset="dialog" title="Sell Item">
      <template #default>
        <div style="margin-bottom: 12px;">
          Enter the number of items to sell:
        </div>
        <n-input-number v-model:value="sellCount" :min="1"
          :max="selected.kind !== null && selected.index !== null ? currentItems[selected.index]?.count || 1 : 1" />
      </template>
      <template #action>
        <n-button @click="handleSellCancel">Cancel</n-button>
        <n-button type="warning" @click="handleSellConfirm" style="margin-left: 8px;">
          Sell
        </n-button>
      </template>
    </n-modal>

    <!-- Buy quantity modal -->
    <n-modal v-model:show="showBuyModal" preset="dialog" title="Buy Item">
      <template #default>
        <div style="margin-bottom: 12px;">
          Enter the number of items to buy:
        </div>
        <n-input-number v-model:value="buyCount" :min="1" :max="selectedBuyItem?.buyable_qty || 1" />
      </template>
      <template #action>
        <n-button @click="handleBuyCancel">Cancel</n-button>
        <n-button type="primary" @click="handleBuyConfirm" style="margin-left: 8px;">
          Buy
        </n-button>
      </template>
    </n-modal>
  </div>
  <div v-else>
    <NEmpty description="No shop open" />
  </div>
</template>

<script setup>
import { ref, computed, onUnmounted } from 'vue';
import { watch_inventory_by_kind, watch_meso } from 'lib/ms/inventory/inventory.js';
import {
  watch_opening_shop_ffi,
  watch_confirm_shop_transaction_ffi,
  buy_shop_item_ffi,
  sell_inventory_item_ffi,
  leave_shop_ffi
} from 'lib/ms/shop/shop.js';

import {
  NButton,
  NIcon,
  NTooltip,
  NTabs,
  NTabPane,
  NAlert,
  NModal,
  NInputNumber,
  NSpace,
  NEmpty
} from 'naive-ui';
import { Close as CloseIcon } from '@vicons/ionicons5';
import LazyImage from '@/components/LazyImage.vue';

const props = defineProps({
  shop_mod: {
    type: Object,
    required: true
  },
  inventory_mod: {
    type: Object,
    required: true
  }
});

// Constants
const TAB_KINDS = ['equip', 'use', 'setup', 'etc'];

// ShopUIData
const shopData = ref(null);

// Component state
const activeTab = ref(0);
const meso = ref(0);
const hint = ref('');
const inventoryItems = ref(
  TAB_KINDS.reduce((acc, kind) => ({ ...acc, [kind]: [] }), {})
);

// Selection state
const selected = ref({ kind: null, index: null });
const selectedBuyItem = ref(null);

const shopItems = computed(() => shopData.value?.shop_items || []);

// Sell modal state
const showSellModal = ref(false);
const sellCount = ref(1);

// Buy modal state
const buyCount = ref(1);
const showBuyModal = ref(false);

// Watch setup
const enableWatch = ref(true);
watch_opening_shop_ffi(props.shop_mod, (data) => {
  shopData.value = data;
});
watch_confirm_shop_transaction_ffi(props.shop_mod, (code) => {
  hint.value = code;
});

// Set up inventory watchers for each tab
for (const kind of TAB_KINDS) {
  watch_inventory_by_kind(props.inventory_mod, kind, (items) => {
    if (!enableWatch.value) return false;
    inventoryItems.value[kind] = items;
    return true;
  });
}

// Watch meso changes
watch_meso(props.inventory_mod, (newMeso) => {
  if (!enableWatch.value) return false;
  meso.value = newMeso;
  return true;
});

// Cleanup on unmount
onUnmounted(() => {
  enableWatch.value = false;
});

// Computed
const currentItems = computed(() => {
  const kind = TAB_KINDS[activeTab.value];
  return kind ? inventoryItems.value[kind] : [];
});

const shouldShowCount = computed(() => {
  const kind = TAB_KINDS[activeTab.value];
  return kind !== 'equip';
});

// Methods
function selectBuyItem(item) {
  selectedBuyItem.value = item;
  selected.value = { kind: null, index: null };
}

function handleItemClick(kind, index) {
  if (selected.value.kind === kind && selected.value.index === index) {
    selected.value = { kind: null, index: null };
  } else {
    selected.value = { kind, index };
    selectedBuyItem.value = null;
  }
}

function handleBuyOne() {
  if (!selectedBuyItem.value) return;
  buy_shop_item_ffi(
    props.shop_mod,
    selectedBuyItem.value.slot_no,
    selectedBuyItem.value.item_id,
    1
  );
}

function handleBuyMultiple() {
  if (!selectedBuyItem.value) return;
  buyCount.value = 1;
  showBuyModal.value = true;
}

function handleBuyConfirm() {
  if (!selectedBuyItem.value) return;
  const count = Math.max(1, Math.min(buyCount.value, selectedBuyItem.value.buyable_qty || 1));
  buy_shop_item_ffi(
    props.shop_mod,
    selectedBuyItem.value.slot_no,
    selectedBuyItem.value.item_id,
    count
  );
  showBuyModal.value = false;
  buyCount.value = 1;
}

function handleBuyCancel() {
  showBuyModal.value = false;
  buyCount.value = 1;
}

function handleSellItem() {
  if (!selected.value.kind || selected.value.index === null) return;
  const item = currentItems.value[selected.value.index];
  if (!item) return;

  if (item.count === 1 || !item.count) {
    // Directly sell if count is 1 or undefined
    handleSellConfirm();
  } else {
    sellCount.value = 1;
    showSellModal.value = true;
  }
}

function handleSellConfirm() {
  if (!selected.value.kind || selected.value.index === null) return;
  const item = currentItems.value[selected.value.index];
  if (!item) return;

  const count = Math.max(1, Math.min(sellCount.value, item.count || 1));
  sell_inventory_item_ffi(props.shop_mod, item.slot_no, item.id, count);
  showSellModal.value = false;
  sellCount.value = 1;
}

function handleSellCancel() {
  showSellModal.value = false;
  sellCount.value = 1;
}

function closeShop() {
  leave_shop_ffi(props.shop_mod);
}

// Helper methods for item grid
function getItemIndex(row, col) {
  return (row - 1) * 4 + (col - 1);
}

function hasItemAt(row, col) {
  const index = getItemIndex(row, col);
  return index >= 0 &&
    index < currentItems.value.length &&
    currentItems.value[index] !== null &&
    currentItems.value[index] !== undefined;
}

function getItemAt(row, col) {
  if (!hasItemAt(row, col)) return null;
  const index = getItemIndex(row, col);
  return currentItems.value[index];
}

function formatMeso(amount) {
  return amount.toLocaleString();
}
</script>

<style scoped>
.shop-container {
  width: 800px;
  background-color: #ffffff;
  border-radius: 8px;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.1);
  padding: 20px;
}

.shop-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.shop-content {
  display: flex;
  gap: 20px;
  margin-bottom: 20px;
}

.buy-section,
.sell-section {
  flex: 1;
  min-height: 400px;
}

.item-list {
  height: 360px;
  overflow-y: auto;
  border: 1px solid #eee;
  border-radius: 4px;
  padding: 8px;
}

.shop-item {
  padding: 8px;
  border-bottom: 1px solid #f0f0f0;
  cursor: pointer;
}

.shop-item:hover {
  background-color: #f9f9f9;
}

.shop-item.selected {
  background-color: #e6f4ff;
  border: 1px solid #91caff;
}

.item-display {
  display: flex;
  align-items: center;
  gap: 12px;
}

.item-name {
  flex: 1;
  font-size: 14px;
}

.item-price {
  color: #666;
  font-size: 12px;
}

/* Inventory grid styles from ItemInventory.vue */
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
  border: 1px solid transparent;
  transition: all 0.2s;
}

.selected-slot {
  border-color: #18a058;
  box-shadow: 0 0 2px #18a058;
}

.empty-slot {
  border: 1px dashed #ddd;
  background: rgba(0, 0, 0, 0.02);
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

.shop-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding-top: 16px;
  border-top: 1px solid #eee;
}

.meso-display {
  font-size: 16px;
  font-weight: 500;
}

.action-buttons {
  display: flex;
  gap: 12px;
}
</style>