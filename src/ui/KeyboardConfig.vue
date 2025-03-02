<script setup>
import { update_key_mappings, watch_keyboard } from 'lib/ms/keyboard/keyboard.js';
import { NButton, NDynamicInput, NInput } from 'naive-ui';
import { onMounted, ref } from 'vue';

const { mod } = defineProps({
    mod: Object
});

const originKeyMappings = ref([]);
const editingKeyMappings = ref([]);

// Save the key mappings
const saveKeyMappings = () => {
    const originMap = originKeyMappings.value.reduce((acc, m) => {
        acc[m.keycode] = m;
        return acc;
    }, {});
    const newMap = editingKeyMappings.value.reduce((acc, m) => {
        acc[m.keycode] = m;
        return acc;
    }, {});
    // findout new/update mappings
    const mappings = editingKeyMappings.value.filter(m => {
        const origin = originMap[m.keycode];
        return !origin || origin.kind !== m.kind || origin.action !== m.action
    });
    // findout remove mappings
    for (const m of originKeyMappings.value) {
        if (!newMap[m.keycode]) {
            mappings.push({
                keycode: m.keycode,
                kind: "", // empty string means remove
                action: 0,
            });
        }
    }
    update_key_mappings(mod, mappings);
};
// Create empty mapping template
const createMapping = () => {
    return {
        keycode: '',
        kind: '',
        action: 0,
    };
};

// Watch for changes in the module
onMounted(() => {
    watch_keyboard(mod, (mappings) => {
        originKeyMappings.value = mappings;
        editingKeyMappings.value = JSON.parse(JSON.stringify(mappings)); // deep copy
    });
});
</script>

<template>
    <div style="max-height: 80vh; overflow-y: auto;">
        <n-dynamic-input v-model:value="editingKeyMappings" :on-create="createMapping">
            <template #default="{ value }">
                <div style="display: flex; align-items: center; width: 100%;">
                    <n-input v-model:value="value.keycode" placeholder="Enter keycode" />
                    <n-input v-model:value="value.kind" placeholder="Enter kind" />
                    <n-input v-model:value="value.action" placeholder="Enter action" />
                </div>
            </template>
        </n-dynamic-input>
        <n-button type="primary" @click="saveKeyMappings">Save</n-button>
    </div>
</template>