<template>
  <div style="display: flex; flex-direction: column; gap: 10px;">
    <button @click="refreshItems">Refresh</button>
    <div style="display: flex; flex-direction: column; gap: 10px;">
      <div v-for="item in items" :key="item.id">
        <div v-element:replace="item.icon.data" v-if="!item.icon.loading"></div>
        <span>{{ item.name }}</span>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'EquipInventoryUI',
  props: {
    game: {
      type: Object,
      default: null
    }
  },
  data() {
    return {
      items: []
    }
  },
  directives: {
    element: {
      mounted(el, { arg: type, value: element }) {
        if (type === 'replace') {
          el.replaceWith(element);
        } else if (type === 'append') {
          el.append(element);
        }
      }
    }
  },
  mounted() {
    this.refreshItems();
  },
  methods: {
    refreshItems() {
      this.items = this.game.get_all_inventory_items_by_type(-1);
    }
  }
}

/**
 * @typedef {Object} ItemUIData
 * @property {string} id
 * @property {string} name
 * @property {import('resource.js').LazyImage} icon
 */
</script>

<style scoped>
/* Add component-specific styles here */
</style> 