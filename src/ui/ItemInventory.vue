<script setup>
import { use_item, watch_inventory_by_kind } from 'lib/ms/inventory/inventory.js';
import { NAlert, NTabPane, NTabs } from 'naive-ui';
import { computed, onUnmounted, ref } from 'vue';
import LazyImage from './components/LazyImage.vue';

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
onUnmounted(() => {
    enableWatch.value = false;
});

// TODO: meso

// Methods
const handleItemDoubleClick = (kind, slot) => {
    const result = use_item(mod, kind, slot)
    if (result) {
        hint.value = result
    }
}

const currentItems = computed(() => {
    const kind = TAB_KINDS[activeTab.value]
    return kind ? inventoryItems.value[kind] : []
})

const shouldShowCount = computed(() => {
    const kind = TAB_KINDS[activeTab.value]
    return kind !== 'equip'
})
</script>

<template>
    <NTabs v-model:value="activeTab" type="segment">
        <NTabPane v-for="(kind, index) in TAB_KINDS" :key="index" :name="index" :tab="kind">
            <div class="inventory-panel">
                <div v-for="(item, index) in currentItems" :key="item.id" class="inventory-slot"
                    @dblclick="() => handleItemDoubleClick(kind, index)">
                    <LazyImage :image="item.icon" />
                    <div v-if="shouldShowCount && item.count" class="item-count">
                        {{ item.count }}
                    </div>
                </div>
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
</template>

<style scoped>
.inventory-panel {
    display: flex;
    flex-wrap: wrap;
    padding: 8px;
}

.inventory-slot {
    width: 40px;
    height: 40px;
    display: flex;
    align-items: center;
    justify-content: center;
    cursor: pointer;
    position: relative;
}

.inventory-slot:hover {
    background: #f0f0f0;
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

.inventory-footer {
    display: flex;
    justify-content: space-between;
    margin-top: 16px;
    background: #f5f5f5;
    padding: 8px;
    position: sticky;
    bottom: 0;
}

.currency {
    display: flex;
    gap: 16px;
}
</style>
