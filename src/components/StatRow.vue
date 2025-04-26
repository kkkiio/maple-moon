<template>
  <div class="stat-row">
    <div class="stat-label">{{ label }}:</div>
    <div class="stat-value-container">
      <div class="stat-value">
        {{ value }}<span v-if="max"> / {{ max }}</span>{{ suffix }}
        <span v-if="percentage !== null" class="stat-percentage">({{ percentage }}%)</span>
      </div>
      <slot name="suffix"></slot>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue';

const {
  label,
  value,
  max,
  suffix,
  showPercentage
} = defineProps({
  label: { type: String, required: true },
  value: { type: [Number, String], required: true },
  max: { type: [Number, String], default: null },
  suffix: { type: String, default: '' },
  showPercentage: { type: Boolean, default: false }
});

const percentage = computed(() => {
  if (!max || !showPercentage) return null;
  return Math.floor((Number(value) / Number(max)) * 100);
});
</script>

<style scoped>
.stat-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 8px;
}

.stat-label {
  font-weight: 500;
  min-width: 80px;
}

.stat-value-container {
  display: flex;
  align-items: center;
}

.stat-value {
  margin-right: 8px;
}

.stat-percentage {
  color: #888;
  margin-left: 4px;
  font-size: 0.9em;
}
</style>
