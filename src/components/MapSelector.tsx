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
 * - Notifies parent when a map is selected.
 * 
 * Optimization:
 * - Wrapped in `memo` to prevent re-renders when parent state updates.
 * - Uses `limit={20}` to reduce rendering cost of the large dropdown list.
 */
export const MapSelector = memo(({
  api,
  mapOptions,
  selectedMapId,
  onMapChange,
}: {
  api: EditorAPI | null,
  mapOptions: any[],
  selectedMapId: string,
  onMapChange: (mapId: string) => void,
}) => {
  return (
    <Select
      placeholder="Select Map"
      data={mapOptions}
      value={selectedMapId}
      searchable
      limit={20} // Performance optimization for large lists
      size="xs"
      style={{ width: 300 }}
      onChange={(value) => {
        if (value && api) {
          onMapChange(value);
        }
      }}
    />
  );
});
