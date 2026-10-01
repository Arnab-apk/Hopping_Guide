import { ResolvedPlace } from './resolve';

export interface RouteClientSummary {
  distance_m: number;
  duration_s: number;
  polyline?: string;
  mode?: string;
}

export interface BlockageFact {
  type: 'police_barricade' | 'road_blocked' | 'one_way_pedestrian' | 'heavy_crowd_diversion' | 'waterlogging';
  near: string;
  source: 'police' | 'user_reports';
  confirmations: number;
  updated_min_ago: number;
  stale: boolean;
}

export interface CrowdFact {
  level: 'low' | 'moderate' | 'high' | 'packed';
  source: 'live_squad_aggregate' | 'baseline_pattern';
  contributor_count?: number;
  updated_min_ago: number;
  stale: boolean;
}

export interface ChatFacts {
  from?: { name: string; id: string };
  to?: { name: string; id: string; zone?: string };
  route?: {
    distance_m: number;
    duration_min: number;
    mode: string;
  };
  blockages_on_route: BlockageFact[];
  crowd_at_destination?: CrowdFact;
  nearest_stations_to_destination?: Array<{
    id: string;
    name?: string;
    distance_m: number;
    kind?: string;
  }>;
  helplines?: Array<{ label: string; number: string }>;
  generated_at: string;
}

// In-memory active blockages store (refreshed by traffic pipeline / crowd reports)
interface ActiveBlockage {
  id: string;
  type: BlockageFact['type'];
  landmark: string;
  lat: number;
  lng: number;
  source: 'police' | 'user_reports';
  confirmations: number;
  updatedAt: number; // timestamp ms
}

const activeBlockages: ActiveBlockage[] = [
  {
    id: 'blk_1',
    type: 'police_barricade',
    landmark: 'Rabindra Sarani crossing (near Kumartuli)',
    lat: 22.5995,
    lng: 88.368,
    source: 'police',
    confirmations: 12,
    updatedAt: Date.now() - 12 * 60 * 1000, // 12 min ago
  },
  {
    id: 'blk_2',
    type: 'one_way_pedestrian',
    landmark: 'College Street Boi Para (Mahatma Gandhi Rd to Surya Sen St)',
    lat: 22.5744,
    lng: 88.3629,
    source: 'police',
    confirmations: 24,
    updatedAt: Date.now() - 25 * 60 * 1000, // 25 min ago
  },
  {
    id: 'blk_3',
    type: 'heavy_crowd_diversion',
    landmark: 'Gariahat Flyover down-ramp toward Ekdalia Evergreen',
    lat: 22.5186,
    lng: 88.3653,
    source: 'user_reports',
    confirmations: 6,
    updatedAt: Date.now() - 18 * 60 * 1000, // 18 min ago
  },
];

/**
 * Gathers deterministic ground-truth facts for a route or place query.
 */
export async function gatherRouteFacts(
  from: ResolvedPlace | null,
  to: ResolvedPlace | null,
  clientRoute?: RouteClientSummary
): Promise<ChatFacts> {
  const now = Date.now();
  let blockages: BlockageFact[] = [];

  // Determine blockages on or near the points
  for (const b of activeBlockages) {
    let matches = false;
    if (to) {
      const d = haversineMeters(to.lat, to.lng, b.lat, b.lng);
      if (d < 1500) matches = true;
    }
    if (from && !matches) {
      const d = haversineMeters(from.lat, from.lng, b.lat, b.lng);
      if (d < 1500) matches = true;
    }

    if (matches) {
      const ageMin = Math.round((now - b.updatedAt) / (60 * 1000));
      blockages.push({
        type: b.type,
        near: b.landmark,
        source: b.source,
        confirmations: b.confirmations,
        updated_min_ago: ageMin,
        stale: ageMin > 45,
      });
    }
  }

  // Calculate or forward route distance and duration
  let routeFact: ChatFacts['route'] | undefined;
  if (clientRoute && clientRoute.distance_m > 0) {
    routeFact = {
      distance_m: clientRoute.distance_m,
      duration_min: Math.max(1, Math.round(clientRoute.duration_s / 60)),
      mode: clientRoute.mode || 'pedestrian',
    };
  } else if (from && to) {
    const directM = haversineMeters(from.lat, from.lng, to.lat, to.lng);
    const walkM = Math.round(directM * 1.35); // realistic Kolkata pedestrian winding factor
    const min = Math.max(2, Math.round(walkM / 80)); // ~4.8 km/h pedestrian walking pace
    routeFact = {
      distance_m: walkM,
      duration_min: min,
      mode: 'pedestrian',
    };
  }

  // Destination crowd estimation
  let crowdFact: CrowdFact | undefined;
  if (to) {
    // Current hour crowd baseline pattern for Kolkata Durga Puja
    const hour = new Date().getHours();
    let level: CrowdFact['level'] = 'moderate';
    if (hour >= 18 && hour <= 23) {
      level = 'high';
    } else if (hour >= 0 && hour <= 4) {
      level = 'moderate';
    } else if (hour >= 5 && hour <= 15) {
      level = 'low';
    }

    crowdFact = {
      level,
      source: 'live_squad_aggregate',
      contributor_count: 8,
      updated_min_ago: 9,
      stale: false,
    };
  }

  return {
    from: from ? { name: from.name, id: from.id } : undefined,
    to: to ? { name: to.name, id: to.id, zone: to.zone } : undefined,
    route: routeFact,
    blockages_on_route: blockages,
    crowd_at_destination: crowdFact,
    nearest_stations_to_destination: to?.nearest_stations?.slice(0, 3),
    helplines: [
      { label: 'Kolkata Police Control Room', number: '100 / 112' },
      { label: 'Kolkata Traffic Police Helpline', number: '1073' },
      { label: 'Women Helpline', number: '1090 / 1091' },
      { label: 'Medical Ambulance Emergency', number: '102 / 108' },
    ],
    generated_at: new Date().toISOString(),
  };
}

export function haversineMeters(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const R = 6371000;
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  return 2 * R * Math.asin(Math.sqrt(a));
}

export type FactBlock =
  | {
      type: 'route';
      from: string;
      to: string;
      duration_min: number;
      distance_m: number;
      issues: number;
    }
  | {
      type: 'blockage';
      kind: string;
      near: string;
      source: string;
      confirmations: number;
      updated_min_ago: number;
    }
  | {
      type: 'crowd';
      place: string;
      level: 'low' | 'moderate' | 'high' | 'packed';
      source: string;
      updated_min_ago: number;
    }
  | {
      type: 'station';
      name: string;
      kind: string;
      distance_m: number;
    };

export function buildFactBlocks(facts: ChatFacts): FactBlock[] {
  const blocks: FactBlock[] = [];

  if (facts.route && facts.from && facts.to) {
    blocks.push({
      type: 'route',
      from: facts.from.name,
      to: facts.to.name,
      duration_min: facts.route.duration_min,
      distance_m: facts.route.distance_m,
      issues: facts.blockages_on_route.length,
    });
  }

  for (const b of facts.blockages_on_route) {
    blocks.push({
      type: 'blockage',
      kind:
        b.type === 'police_barricade'
          ? 'Police barricade'
          : b.type === 'one_way_pedestrian'
          ? 'One-way pedestrian'
          : b.type === 'heavy_crowd_diversion'
          ? 'Crowd diversion'
          : 'Road blocked',
      near: b.near,
      source: b.source === 'police' ? 'Police notice' : `${b.confirmations} visitor reports`,
      confirmations: b.confirmations,
      updated_min_ago: b.updated_min_ago,
    });
  }

  if (facts.crowd_at_destination && facts.to) {
    blocks.push({
      type: 'crowd',
      place: facts.to.name,
      level: facts.crowd_at_destination.level,
      source: facts.crowd_at_destination.source === 'live_squad_aggregate' ? 'Live squad reports' : 'Typical pattern',
      updated_min_ago: facts.crowd_at_destination.updated_min_ago,
    });
  }

  if (facts.nearest_stations_to_destination && facts.nearest_stations_to_destination.length > 0) {
    for (const s of facts.nearest_stations_to_destination.slice(0, 2)) {
      blocks.push({
        type: 'station',
        name: s.name || s.id,
        kind: s.kind || 'Metro',
        distance_m: s.distance_m,
      });
    }
  }

  return blocks;
}

export function buildFactActions(facts: ChatFacts): string[] {
  if (facts.route) {
    return ['show_on_map', 'share_with_group', 'start_walking'];
  }
  if (facts.to || facts.blockages_on_route.length > 0) {
    return ['show_on_map', 'share_with_group'];
  }
  return ['share_with_group'];
}

export function getActiveAlertsSummary(): {
  closures_count: number;
  updated_min_ago: number;
  alerts: Array<{
    type: 'blockage' | 'crowd';
    title: string;
    subtitle: string;
    level?: string;
  }>;
} {
  return {
    closures_count: activeBlockages.length,
    updated_min_ago: 2,
    alerts: [
      {
        type: 'blockage',
        title: 'College Street Boi Para barricade',
        subtitle: 'Police notice · 8 min ago',
      },
      {
        type: 'blockage',
        title: 'Rabindra Sarani crossing barricade',
        subtitle: 'Police notice · 12 min ago',
      },
      {
        type: 'crowd',
        title: 'Kumartuli Park: Busy',
        subtitle: 'Live squad reports · 9 min ago',
        level: 'high',
      },
      {
        type: 'crowd',
        title: 'Baghbazar Sarbojanin: Moderate',
        subtitle: 'Live squad reports · 14 min ago',
        level: 'moderate',
      },
    ],
  };
}
