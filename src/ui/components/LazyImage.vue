<template>
    <div class="lazy-image" :style="imageStyle">
        <n-spin v-if="image.loading" size="small" />
        <div v-else v-element:replace="image.data" />
    </div>
</template>

<script setup>
import { NSpin } from 'naive-ui';
import { computed } from 'vue';

/**
 * @typedef {Object} LazyImage
 * @property {HTMLImageElement} data
 * @property {boolean} loading
 * @property {number} w
 * @property {number} h
 */

const props = defineProps({
    /**
     * @type {LazyImage}
     */
    image: {
        type: Object,
        required: true
    },
    width: {
        type: [String, Number],
        default: 'auto'
    },
    height: {
        type: [String, Number],
        default: 'auto'
    },
    fit: {
        type: String,
        default: 'contain',
        validator: (value) => ['contain', 'cover', 'fill', 'none'].includes(value)
    }
});

const imageStyle = computed(() => {
    const width = typeof props.width === 'number' ? `${props.width}px` : props.width;
    const height = typeof props.height === 'number' ? `${props.height}px` : props.height;

    return {
        width,
        height,
        objectFit: props.fit
    };
});

const vElement = {
    mounted(el, { arg: type, value: element }) {
        if (type === 'replace') {
            el.replaceWith(element);
        } else if (type === 'append') {
            el.append(element);
        }
    }
};
</script>

<style scoped>
.lazy-image {
    display: flex;
    align-items: center;
    justify-content: center;
    overflow: hidden;
}

.lazy-image img {
    width: 100%;
    height: 100%;
    object-fit: inherit;
}
</style>