<script setup>
import { useDraggable } from '@vueuse/core'
import { useTemplateRef } from 'vue'
import { computed } from 'vue'

const props = defineProps({
    initialPosition: {
        type: Object,
        default: () => ({ x: 40, y: 40 }),
    },
    zIndex: {
        type: Number,
        default: 10,
    },
    active: {
        type: Boolean,
        default: true,
    },
})

const el = useTemplateRef('el');
const { x, y, style } = useDraggable(el, {
    preventDefault: true,
    initialValue: props.initialPosition,
})
</script>

<template>
    <div ref="el" :style="[style, { position: 'fixed', zIndex: zIndex }]" v-show="active">
        <div class="window-container">
            <slot />
        </div>
    </div>
</template>

<style scoped>
.window-container {
    border: 1px solid #ddd;
    border-radius: 4px;
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.15);
    background-color: #fff;
}
</style>