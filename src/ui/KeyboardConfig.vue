<script setup>
import { update_key_mappings, watch_keyboard } from 'lib/ms/keyboard/keyboard.js';
import { NButton, NInput, NInputNumber } from 'naive-ui';
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

const addNewMapping = () => {
    editingKeyMappings.value.push(createMapping());
};

const removeMapping = (index) => {
    editingKeyMappings.value.splice(index, 1);
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
    <div style="max-height: 80vh; overflow-y: auto; padding: 5px;">
        <div v-for="(mapping, index) in editingKeyMappings" :key="index"
            style="display: flex; align-items: center; margin-bottom: 5px;">
            <n-input v-model:value="mapping.keycode" placeholder="Key" style="margin-right: 5px; width: 100px;" />
            <n-input v-model:value="mapping.kind" placeholder="Kind" style="margin-right: 5px; width: 80px;" />
            <n-input-number v-model:value="mapping.action" clearable :show-button="false"
                style="margin-right: 5px; width: 120px;" />
            <n-button @click="removeMapping(index)" type="error" size="small">-</n-button>
        </div>
        <n-button type="primary" @click="addNewMapping" style="margin-top: 10px; margin-right: 5px;">Add New
            Mapping</n-button>
        <n-button type="primary" @click="saveKeyMappings" style="margin-top: 10px;">Save</n-button>
    </div>
</template>