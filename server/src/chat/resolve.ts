import fs from 'fs';
import path from 'path';

export interface ResolvedPlace {
  id: string;
  name: string;
  nameBn?: string;
  kind: 'pandal' | 'station' | 'landmark';
  lat: number;
  lng: number;
  code?: string;
  zone?: string;
  nearest_stations?: Array<{ id: string; name?: string; distance_m: number; kind?: string }>;
}

export interface ResolveResult {
  match: ResolvedPlace | null;
  confidence: number;
  suggestions: ResolvedPlace[];
}

let cachedPlaces: ResolvedPlace[] | null = null;

/**
 * Initializes and caches the searchable dictionary of Kolkata pandals, stations, and landmarks.
 */
export function getSearchablePlaces(): ResolvedPlace[] {
  if (cachedPlaces) return cachedPlaces;

  const places: ResolvedPlace[] = [];

  // 1. Load Pandals
  try {
    const pandalsPath = path.resolve(__dirname, '../../../data/pandals.json');
    if (fs.existsSync(pandalsPath)) {
      const raw = JSON.parse(fs.readFileSync(pandalsPath, 'utf8'));
      const list = Array.isArray(raw) ? raw : raw.pandals || [];
      for (const p of list) {
        places.push({
          id: p.id || `pandal_${places.length}`,
          name: p.name,
          nameBn: p.name_bn || p.bengali_name,
          kind: 'pandal',
          lat: p.lat,
          lng: p.lng,
          zone: p.zone,
          nearest_stations: p.nearest_stations || [],
        });
      }
    }
  } catch (err) {
    console.warn('[ChatResolve] Could not read pandals.json:', err);
  }

  // 2. Load Stations (Railway & Kolkata Metro)
  try {
    const stationsPath = path.resolve(__dirname, '../../../data/stations/stations.geojson');
    if (fs.existsSync(stationsPath)) {
      const geo = JSON.parse(fs.readFileSync(stationsPath, 'utf8'));
      for (const f of geo.features || []) {
        const props = f.properties || {};
        const coords = f.geometry?.coordinates || [0, 0];
        places.push({
          id: f.id || props.id || `stn_${places.length}`,
          name: props.name,
          nameBn: props.name_bn,
          code: props.code,
          kind: 'station',
          lat: coords[1],
          lng: coords[0],
        });
      }
    }
  } catch (err) {
    console.warn('[ChatResolve] Could not read stations.geojson:', err);
  }

  // 3. Prominent Kolkata Crossroads & Hubs
  const popularHubs: ResolvedPlace[] = [
    { id: 'hub_college_st', name: 'College Street', kind: 'landmark', lat: 22.5744, lng: 88.3629 },
    { id: 'hub_shyambazar', name: 'Shyambazar 5 Point Crossing', kind: 'landmark', lat: 22.6017, lng: 88.3711 },
    { id: 'hub_gariahat', name: 'Gariahat Crossing', kind: 'landmark', lat: 22.5186, lng: 88.3653 },
    { id: 'hub_esplanade', name: 'Esplanade Dharmatala', kind: 'landmark', lat: 22.5645, lng: 88.3522 },
    { id: 'hub_park_street', name: 'Park Street', kind: 'landmark', lat: 22.5512, lng: 88.3526 },
    { id: 'hub_hatibagan', name: 'Hatibagan Crossing', kind: 'landmark', lat: 22.5956, lng: 88.3718 },
    { id: 'hub_rashbehari', name: 'Rashbehari Avenue Crossing', kind: 'landmark', lat: 22.5189, lng: 88.3512 },
  ];

  places.push(...popularHubs);
  cachedPlaces = places;
  return cachedPlaces;
}

/**
 * Resolves a query string to a known place using multi-key fuzzy similarity.
 */
export function resolvePlace(query?: string): ResolveResult {
  if (!query || query.trim().length < 2) {
    return { match: null, confidence: 0, suggestions: [] };
  }

  const places = getSearchablePlaces();
  const q = normalize(query);

  const scored: Array<{ place: ResolvedPlace; score: number }> = [];

  for (const place of places) {
    let bestScore = 0;

    // Check code exact match (e.g. HWH, SDAH, KOAA)
    if (place.code && place.code.toLowerCase() === q) {
      bestScore = Math.max(bestScore, 1.0);
    }

    // Check English name
    const n = normalize(place.name);
    bestScore = Math.max(bestScore, calculateSimilarity(q, n));

    // Check Bengali name
    if (place.nameBn) {
      const bn = normalize(place.nameBn);
      bestScore = Math.max(bestScore, calculateSimilarity(q, bn));
    }

    if (bestScore > 0.35) {
      scored.push({ place, score: bestScore });
    }
  }

  scored.sort((a, b) => b.score - a.score);

  if (scored.length === 0) {
    return { match: null, confidence: 0, suggestions: [] };
  }

  const top = scored[0];
  const suggestions = scored.slice(0, 3).map((s) => s.place);

  if (top.score >= 0.65) {
    return { match: top.place, confidence: top.score, suggestions };
  }

  return { match: null, confidence: top.score, suggestions };
}

function normalize(str: string): string {
  return str
    .toLowerCase()
    .replace(/[.,\/#!$%\^&\*;:{}=\-_`~()]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

/**
 * String similarity combining token overlap, prefix matching, and substring match.
 */
function calculateSimilarity(query: string, target: string): number {
  if (query === target) return 1.0;
  if (target.includes(query) || query.includes(target)) {
    const ratio = Math.min(query.length, target.length) / Math.max(query.length, target.length);
    return Math.max(0.75, ratio);
  }

  const qTokens = query.split(' ').filter((t) => t.length > 1);
  const tTokens = target.split(' ').filter((t) => t.length > 1);

  if (qTokens.length === 0 || tTokens.length === 0) return 0;

  let matches = 0;
  for (const q of qTokens) {
    if (tTokens.some((t) => t.includes(q) || q.includes(t))) {
      matches++;
    }
  }

  const tokenScore = matches / Math.max(qTokens.length, tTokens.length);

  // Levenshtein distance for close typos
  const levScore = 1.0 - levenshteinDistance(query, target) / Math.max(query.length, target.length);

  return Math.max(tokenScore * 0.8, levScore * 0.7);
}

function levenshteinDistance(a: string, b: string): number {
  const m = a.length;
  const n = b.length;
  const d: number[][] = [];

  for (let i = 0; i <= m; i++) d[i] = [i];
  for (let j = 0; j <= n; j++) d[0][j] = j;

  for (let i = 1; i <= m; i++) {
    for (let j = 1; j <= n; j++) {
      const cost = a[i - 1] === b[j - 1] ? 0 : 1;
      d[i][j] = Math.min(d[i - 1][j] + 1, d[i][j - 1] + 1, d[i - 1][j - 1] + cost);
    }
  }

  return d[m][n];
}
