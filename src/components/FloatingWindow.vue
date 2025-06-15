<template>
    <!-- Use v-show to make sure width and height will be calculated -->
    <div v-show="modelValue" class="fixed rounded-xl shadow-xl bg-white"
        :style="`top: ${windowPosition.top}px; left: ${windowPosition.left}px`">
        <!-- Register top bar as drag handle -->
        <div ref="windowHandle" @mousedown.prevent="startDragging" @touches.prevent="startDragging"
            class="h-6 w-full gap-1 bg-gray-200 rounded-t-xl"></div>
        <div class="flex-1 overflow-auto">
            <!-- Pass content to slot -->
            <slot></slot>
        </div>
    </div>
</template>
<script setup lang="ts">
import { ref } from 'vue'
// Define v-model for FloatingWindow component
const modelValue = defineModel<boolean>();

// Reference to window handle
const windowHandle = ref(null);

// Define tempPosition as reference to drag
const tempPosition = ref({
    x: 0,
    y: 0,
});

// Define postion of the window
const windowPosition = ref({
    top: 0,
    left: 0,
});

// Check drag state
const dragging = ref(false);

// Handle start drag
const startDragging = (event) => {
    dragging.value = true;
    tempPosition.value.x = event.clientX - windowPosition.value.left;
    tempPosition.value.y = event.clientY - windowPosition.value.top;

    // Create window event listeners for drag event and stop drag
    window.addEventListener("mousemove", dragElement);
    window.addEventListener("mouseup", stopDragging);
};
// Handle drag action
const dragElement = (event) => {
    event.preventDefault();
    if (dragging.value) {
        // Get position of the window handle
        const windowRect = windowHandle.value.getBoundingClientRect();
        const clientX = event.clientX;
        const clientY = event.clientY;

        // Calculate the new position
        let left = clientX - tempPosition.value.x;
        let top = clientY - tempPosition.value.y;

        // Check if the target is in bounds of the body
        const bodyRect = document.body.getBoundingClientRect();

        // Check if element is touching it's boundaries
        if (left < bodyRect.left) {
            left = bodyRect.left;
        } else if (left + windowRect.width > bodyRect.right) {
            left = bodyRect.right - windowRect.width;
        }

        if (top < bodyRect.top) {
            top = bodyRect.top;
        } else if (top + windowRect.height > bodyRect.bottom) {
            top = bodyRect.bottom - windowRect.height;
        }

        // Update position of the window
        windowPosition.value.left = left;
        windowPosition.value.top = top;
    }
};
// Remove event listeners on stop drag
const stopDragging = () => {
    dragging.value = false;
    window.removeEventListener("mousemove", dragElement);
    window.removeEventListener("mouseup", stopDragging);
};
</script>

<style scoped></style>