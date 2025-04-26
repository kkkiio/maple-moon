<script setup>
import { use_item, watch_inventory_by_kind, watch_meso } from 'lib/ms/inventory/inventory.js';
import { NAlert, NTabPane, NTabs, NTooltip, NButton } from 'naive-ui';
import { computed, onUnmounted, ref } from 'vue';
import LazyImage from '@/components/LazyImage.vue';

const { mod } = defineProps({
    mod: {
        type: Object,
        required: true
    }
})

// Tab types from Moonbit implementation
const TAB_KINDS = ['equip', 'use', 'setup', 'etc']

// Component props and state
const activeTab = ref(0)
const meso = ref(0)
// const maplePoints = ref(0)
const hint = ref('')
const inventoryItems = ref(
    TAB_KINDS.map(kind => ({
        [kind]: []
    }))
)

const enableWatch = ref(true)
for (const kind of TAB_KINDS) {
    watch_inventory_by_kind(mod, kind, (items) => {
        if (!enableWatch.value) return false;
        inventoryItems.value[kind] = items
        return true // Continue watching
    })
}
watch_meso(mod, (meso) => {
    if (!enableWatch.value) return false;
    meso.value = meso
    return true // Continue watching
})
onUnmounted(() => {
    enableWatch.value = false;
});

// Methods
// Selection state
const selected = ref({ kind: null, index: null })

const handleItemClick = (kind, index) => {
    if (selected.value.kind === kind && selected.value.index === index) {
        selected.value = { kind: null, index: null }
    } else {
        selected.value = { kind, index }
    }
}

const handleUseItem = () => {
    if (selected.value.kind !== null && selected.value.index !== null) {
        const result = use_item(mod, selected.value.kind, selected.value.index)
        if (result) {
            hint.value = result
        }
    }
}

const currentItems = computed(() => {
    const kind = TAB_KINDS[activeTab.value]
    return kind ? inventoryItems.value[kind] : []
})

// Helper methods for item access
const getItemIndex = (row, col) => {
    return (row - 1) * 4 + (col - 1)
}

const hasItemAt = (row, col) => {
    const index = getItemIndex(row, col)
    return index >= 0 && index < currentItems.value.length && currentItems.value[index] !== null && currentItems.value[index] !== undefined
}

const getItemAt = (row, col) => {
    if (!hasItemAt(row, col)) return null
    const index = getItemIndex(row, col)
    return currentItems.value[index]
}

const shouldShowCount = computed(() => {
    const kind = TAB_KINDS[activeTab.value]
    return kind !== 'equip'
})
</script>

<template>
    <NTabs v-model:value="activeTab" type="segment">
        <NTabPane v-for="(kind, index) in TAB_KINDS" :key="index" :name="index" :tab="kind">
            <div class="inventory-panel">
                <table class="inventory-table">
                    <tbody>
                        <tr v-for="row in Math.max(4, Math.ceil(currentItems.length / 4))" :key="'row-' + row">
                            <td v-for="col in 4" :key="'col-' + col" class="inventory-cell">
                                <div class="inventory-slot-wrapper">
                                    <!-- Item slot with content -->
                                    <template v-if="hasItemAt(row, col)">
                                        <NTooltip trigger="hover" placement="top">
                                            <template #trigger>
                                                <div class="inventory-slot"
                                                    :class="{ 'selected-slot': selected.kind === kind && selected.index === getItemIndex(row, col) }"
                                                    @click="() => handleItemClick(kind, getItemIndex(row, col))">
                                                    <LazyImage :image="getItemAt(row, col).icon" />
                                                    <div v-if="shouldShowCount && getItemAt(row, col).count"
                                                        class="item-count">
                                                        {{ getItemAt(row, col).count }}
                                                    </div>
                                                </div>
                                            </template>
                                            <div class="tooltip-content">
                                                <div class="tooltip-name">{{ getItemAt(row, col).name }}</div>
                                                <div class="tooltip-desc">{{ getItemAt(row, col).desc }}</div>
                                            </div>
                                        </NTooltip>
                                    </template>

                                    <!-- Empty slot -->
                                    <div v-else class="inventory-slot empty-slot"></div>
                                </div>
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </NTabPane>
    </NTabs>
    <div class="inventory-footer">
        <div class="currency">
            <span>Meso: {{ meso }}</span>
            <!-- <span>Maple Points: {{ maplePoints }}</span> -->
        </div>
    </div>
    <NAlert v-if="hint" type="warning" closable @close="hint = ''">
        {{ hint }}
    </NAlert>
    <div class="action-bar">
        <n-button type="primary" :disabled="selected.kind === null || selected.index === null" @click="handleUseItem">
            Use Item
        </n-button>
    </div>
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
