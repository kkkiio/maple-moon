import { Select } from '@mantine/core';
import { memo } from 'react';
import { EditorAPI } from '../engine/bridge';

/**
 * MapSelector Component
 * 
 * Renders a searchable dropdown menu for selecting maps.
 * 
 * Functions:
 * - Loads available maps from mapDataRaw (passed as options).
 * - Triggers `api.loadMap` when a selection is made.
 * - Notifies parent via `onMapLoad` to reset selection state.
 * 
 * Optimization:
 * - Wrapped in `memo` to prevent re-renders when parent state updates.
 * - Uses `limit={20}` to reduce rendering cost of the large dropdown list.
 */
export const MapSelector = memo(({ api, mapOptions, onMapLoad }: { api: EditorAPI | null, mapOptions: any[], onMapLoad: () => void }) => {
  return (
    <Select
      placeholder="Select Map"
      data={mapOptions}
      searchable
      limit={20} // Performance optimization for large lists
      size="xs"
      style={{ width: 300 }}
      onChange={(value) => {
        if (value && api) {
          api.loadMap(parseInt(value));
          onMapLoad(); // Notify parent that map has loaded/changed
        }
      }}
    />
  );
});
