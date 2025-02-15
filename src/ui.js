import { EquipInventoryUI } from './ui/equip_inventory.js';

// Added new GameUI component with multiple UI tabs.
export const GameUI = {
  template: `
    <div style="min-width: 300px; background-color: #f5f5f5; border: 1px solid #ddd; border-radius: 4px; padding: 16px; height: fit-content;">
      <div class="ui-tabs" v-if="game">
        <button 
          v-for="(tab, index) in tabs" 
          :key="tab.name" 
          :class="{ active: selectedTab === index }" 
          @click="selectedTab = index">
          {{ tab.name }}
        </button>
      </div>
      <div class="ui-tab-content" v-if="game">
        <component :is="tabs[selectedTab].component" :game="game"></component>
      </div>
    </div>
    `,
  components: {
    'equip-inventory': EquipInventoryUI,
    'status-panel': {
      // This is a placeholder for a future status panel.
      template: '<div>Status panel coming soon.</div>'
    }
  },
  data() {
    return {
      selectedTab: 0,
      tabs: [
        { name: 'Equipment', component: 'equip-inventory' },
        { name: 'Status', component: 'status-panel' }
      ]
    }
  },
  props: {
    game: {
      type: Object,
      default: null
    }
  }
};
