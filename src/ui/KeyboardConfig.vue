<script setup>
import { update_key_mappings, watch_keyboard } from 'lib/ms/keyboard/keyboard.js';
import { NButton, NCard, NInput, NSpace } from 'naive-ui';
import { onMounted, ref } from 'vue';

const { mod } = defineProps({
    mod: Object
});

const jsonText = ref('[]');

// Save the key mappings
const saveKeyMappings = () => {
    try {
        const mappings = JSON.parse(jsonText.value);
        update_key_mappings(mod, mappings);
    } catch (e) {
        console.error('Invalid JSON:', e);
    }
};

// Watch for changes in the module
onMounted(() => {
    watch_keyboard(mod, (mappings) => {
        jsonText.value = JSON.stringify(mappings, null, 2);
    });
});
</script>

<template>
    <div>
        <n-card title="Keyboard Configuration">
            <n-space vertical>
                <n-input v-model:value="jsonText" type="textarea" :autosize="{ minRows: 10, maxRows: 20 }"
                    placeholder="Edit key mappings JSON here" />
                <n-button type="primary" @click="saveKeyMappings">Save Key Mappings</n-button>
            </n-space>
        </n-card>
    </div>
</template>