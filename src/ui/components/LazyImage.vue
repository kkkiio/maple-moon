<script setup>
import { NSpin } from 'naive-ui';
import { computed, ref } from 'vue';


const props = defineProps({
    /**
     * @type {import('../../resource').LazyImage}
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

// poll image loading status
const imageLoading = ref(true);
if (props.image.loading) {
    const interval = setInterval(() => {
        if (!props.image.loading) {
            imageLoading.value = false;
            clearInterval(interval);
        }
    }, 500);
} else {
    imageLoading.value = false;
}

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

<template>
    <div class="lazy-image" :style="imageStyle">
        <n-spin v-if="imageLoading" size="small" />
        <div v-else v-element:replace="image.data" />
    </div>
</template>

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