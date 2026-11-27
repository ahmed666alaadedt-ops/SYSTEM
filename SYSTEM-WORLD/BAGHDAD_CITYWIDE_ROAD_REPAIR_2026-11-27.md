# Baghdad Citywide Road Coverage Repair
Date: 2026-11-27
Repository: ahmed666alaadedt-ops/SYSTEM
Base: main at dc3d9ba942251173ef0a9a5aa57d83b097937986
Work branch: fix/baghdad-citywide-osm-road-network-20261127

## Confirmed root cause
The existing detailed OSM artifact is intentionally limited to 200 m cells with inclusive bounds [-2, 20, -9, 2], at most 276 occupied cells. It contains Baghdad core detail and the Republic Bridge/Tigris area, not citywide road coverage. The source workflow hard-coded those bounds and the Android workflow only installed that detailed pack. The existing runtime validator checked the center cell and the Republic Bridge cell, so its green result did not certify the municipal road network.

## Repair implemented on the work branch
- Preserved the existing 200 m detailed pack and its surveyed Republic Bridge/Tigris features.
- Generalized the metric-cell pack builder to select layers and derive cell bounds from the official boundary geometry in the same ECEF tangent coordinate frame.
- Added a separate 1 km roads-only overview pack generated from all roads clipped to Baghdad municipality relation 5638803. This avoids expanding the detailed buildings/amenities pack to tens of thousands of 200 m cells.
- Added a second instance of the existing OSM streamer for the regional roads pack. It follows the same player position and loads a 3x3 neighborhood of 1 km road cells while the detailed 200 m core pack remains unchanged.
- Extended source-pack checks to require broad X/Z extents, road-occupied cells in all four quadrants, and minimum counts of road fragments and distinct OSM ways.
- Extended Godot runtime validation to check the central overview cell and automatic player-driven selection/loading of the Republic Bridge overview cell.
- Updated the source and canonical Android workflows to publish, install and validate the extra road pack on repair branches.

## Validation status
- **Source workflow:** passed on 2026-11-27, run [46046395053](https://github.com/ahmed666alaadedt-ops/SYSTEM/actions/runs/46046395053).
- **Verified municipal OSM source:** 64,593 distinct road ways in the Baghdad municipal clip.
- **Generated citywide overview pack:** 1 km cells; projected bounds [-17, 18, -20, 15]; 927 occupied cells; 81,859 clipped road fragments; all four municipal bounding-box quadrants contain road cells. ZIP size 3,608,423 bytes.
- **Detailed core pack preserved:** 200 m cells; 276 occupied cells; 47 mapped entrance points; Republic Bridge and Tigris source IDs remain present.
- **Canonical Godot/Android runtime validation:** pending a new build that downloads the successful source artifact and exercises both the detailed pack and the citywide road streamer.
- No physical-device visual, collision, vehicle navigation or performance acceptance is claimed.

## Guardrails
- Do not delete or replace the existing detailed Baghdad OSM pack.
- Do not change Power Tower or the Baghdad tower layouts as part of this repair.
- Do not merge this branch to main without explicit owner approval.
- The 1 km pack is an overview road geometry layer; it is not a claim of production vehicle routing, lane-level navigation, verified elevation, or a finished photorealistic city.
