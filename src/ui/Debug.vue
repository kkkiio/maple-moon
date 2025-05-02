<script setup>
import { defineProps } from 'vue';
import { NButton } from 'naive-ui';
import { reset_player_position } from 'lib/ms/ms.js';

const { stage } = defineProps({
  stage: Object,
});

function resetPosition() {
  reset_player_position(stage);
}
</script>

<template>
  <div>
    <n-button @click="resetPosition">Reset Player Position</n-button>
  </div>
</template>
