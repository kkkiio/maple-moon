<template>
    <div class="quest-log">
        <div class="quest-sections">
            <div class="quest-section">
                <h3>In Progress</h3>
                <div v-for="quest in inProgressQuests" :key="quest.id" class="quest-item">
                    <div class="quest-header">
                        <span class="quest-name">{{ quest.name }}</span>
                        <span class="quest-id">#{{ quest.id }}</span>
                    </div>
                    <div :key="quest.desc" class="quest-desc" v-html="quest.desc"></div>
                    <div class="quest-actions">
                        <n-button size="small" type="warning" @click="forfeitQuest(quest.id)">
                            Forfeit
                        </n-button>
                    </div>
                </div>
            </div>

            <div class="quest-section">
                <h3>Completed</h3>
                <div v-for="quest in completedQuests" :key="quest.id" class="quest-item completed">
                    <div class="quest-header">
                        <span class="quest-name">{{ quest.name }}</span>
                        <span class="quest-id">#{{ quest.id }}</span>
                    </div>
                    <div class="completion-time">
                        Completed: {{ formatCompletionTime(quest.completed_time) }}
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>

<script setup>
import { ref, computed, onUnmounted } from 'vue';
import { watch_quest_log_ffi, forfeit_quest_ffi } from 'lib/ms/quest/quest.js';
import { useDialog, NButton } from 'naive-ui';

const dialog = useDialog();
const { mod } = defineProps({
    mod: Object
});

const quests = ref([]);
const enableWatch = ref(true);
watch_quest_log_ffi(mod, (questData) => {
    if (!enableWatch.value) return false;
    quests.value = questData;
    return true;
});

const inProgressQuests = computed(() => {
    return quests.value.filter(q => q.completed_time === 0);
});

const completedQuests = computed(() => {
    return quests.value.filter(q => q.completed_time > 0);
});

// Format timestamp to readable date/time
const formatCompletionTime = (timestamp) => {
    if (!timestamp) return '';
    const date = new Date(timestamp);
    return date.toLocaleString();
};

const forfeitQuest = (questId) => {
    dialog.warning({
        title: 'Forfeit Quest',
        content: 'Are you sure you want to forfeit this quest? This action cannot be undone.',
        positiveText: 'Forfeit',
        negativeText: 'Cancel',
        onPositiveClick: () => {
            forfeit_quest_ffi(mod, questId);
        }
    });
};

onUnmounted(() => {
    enableWatch.value = false;
});
</script>

<style scoped>
.quest-log {
    padding: 8px;
    max-width: 600px;
}

.quest-sections {
    display: flex;
    flex-direction: column;
    gap: 10px;
}

.quest-section {
    background-color: #f9f9f9;
    border-radius: 6px;
    padding: 8px;
    border: 1px solid #e0e0e0;
}

.quest-section h3 {
    margin: 0 0 6px 0;
    padding-bottom: 4px;
    border-bottom: 1px solid #e0e0e0;
    color: #4a4a4a;
    font-size: 1em;
}

.quest-item {
    margin-bottom: 6px;
    padding: 6px;
    border-radius: 4px;
    background-color: white;
    border-left: 3px solid #6b88ff;
}

.quest-item.completed {
    border-left-color: #4caf50;
}

.quest-header {
    display: flex;
    justify-content: space-between;
    margin-bottom: 3px;
}

.quest-name {
    font-weight: bold;
    color: #333;
    font-size: 0.95em;
}

.quest-id {
    color: #888;
    font-size: 0.8em;
}

.quest-desc {
    font-size: 0.85em;
    color: #555;
    margin: 8px 0;
}

.completion-time {
    font-size: 0.75em;
    color: #4caf50;
    text-align: right;
    font-style: italic;
}

.empty-message {
    color: #999;
    font-style: italic;
    padding: 4px 0;
    text-align: center;
    font-size: 0.85em;
}

.quest-actions {
    display: flex;
    justify-content: flex-end;
    margin-top: 8px;
    padding-top: 8px;
    border-top: 1px solid #e0e0e0;
}
</style>