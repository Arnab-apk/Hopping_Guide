import { ChatFacts } from './facts';
import { ResolvedPlace } from './resolve';

/**
 * Deterministic, zero-cost template fallback answers.
 * Guarantees UMA Route Assistant NEVER goes dark during network outages or quota exhaustion.
 */

export function templateRouteAnswer(f: ChatFacts, lang: 'bn' | 'en'): string {
  const isBn = lang === 'bn';

  if (!f.to) {
    return isBn
      ? 'আপনি কোন মণ্ডপ বা স্টেশনে যেতে চান তা অনুগ্রহ করে উল্লেখ করুন (যেমন: "হাওড়া থেকে বাগবাজার")।'
      : 'Please specify your destination pandal or station (e.g., "From Howrah to Baghbazar").';
  }

  const fromName = f.from?.name || (isBn ? 'আপনার বর্তমান অবস্থান' : 'Your current location');
  const toName = f.to.name;
  const parts: string[] = [];

  // Route metrics
  if (f.route) {
    const km = (f.route.distance_m / 1000).toFixed(1);
    if (isBn) {
      parts.push(`🚶 ${fromName} থেকে ${toName}: প্রায় ${f.route.duration_min} মিনিট হাঁটা পথ (${km} কিমি)।`);
    } else {
      parts.push(`🚶 ${fromName} → ${toName}: about ${f.route.duration_min} min on foot (${km} km).`);
    }
  }

  // Blockages
  if (f.blockages_on_route.length === 0) {
    parts.push(
      isBn
        ? '✅ এই রুটে বর্তমানে কোনো পুলিশ ব্যারিকেড বা রাস্তা বন্ধের রিপোর্ট নেই।'
        : '✅ No blockages or barricades reported on this route recently.'
    );
  } else {
    const blkDetails = f.blockages_on_route
      .map((b) => {
        const typeStr = b.type.replace(/_/g, ' ');
        const age = `${b.updated_min_ago} min ago`;
        const src = b.source === 'police' ? 'Kolkata Police' : 'user report';
        return `${typeStr} near ${b.near} (${age}, ${src})`;
      })
      .join('; ');

    parts.push(
      isBn
        ? `⚠️ রুটে ${f.blockages_on_route.length}টি ট্রাফিক নিয়ন্ত্রণ/ব্যারিকেড রয়েছে: ${blkDetails}।`
        : `⚠️ ${f.blockages_on_route.length} traffic diversion(s) on route: ${blkDetails}.`
    );
  }

  // Crowd
  if (f.crowd_at_destination) {
    const c = f.crowd_at_destination;
    parts.push(
      isBn
        ? `👥 ${toName}-এ ভিড়ের মাত্রা: ${c.level.toUpperCase()} (${c.updated_min_ago} মিনিট আগের রিপোর্ট)।`
        : `👥 Crowd at ${toName}: ${c.level.toUpperCase()} (${c.updated_min_ago} min ago).`
    );
  }

  // Nearest stations
  if (f.nearest_stations_to_destination && f.nearest_stations_to_destination.length > 0) {
    const stn = f.nearest_stations_to_destination[0];
    parts.push(
      isBn
        ? `🚇 নিকটবর্তী স্টেশন: ${stn.name || stn.id} (${stn.distance_m} মিটার)।`
        : `🚇 Nearest transit: ${stn.name || stn.id} (${stn.distance_m} m walk).`
    );
  }

  return parts.join(' ');
}

export function templateBlockageAnswer(f: ChatFacts, lang: 'bn' | 'en'): string {
  const isBn = lang === 'bn';
  if (f.blockages_on_route.length === 0) {
    return isBn
      ? '✅ নিকটবর্তী এলাকায় ট্রাফিক ও পুলিশ ব্যারিকেড স্বাভাবিক রয়েছে। কোনো রাস্তা সম্পূর্ণ বন্ধের খবর নেই।'
      : '✅ Traffic and pedestrian movement are currently normal nearby. No full road closures reported.';
  }

  const items = f.blockages_on_route.map((b) => {
    return `• ${b.near}: ${b.type.replace(/_/g, ' ')} (${b.updated_min_ago} min ago, ${b.source})`;
  });

  return isBn
    ? `⚠️ সাম্প্রতিক ট্রাফিক সতর্কতা:\n${items.join('\n')}\nঅনুগ্ৰহ করে কর্তব্যরত ট্রাফিক পুলিশের নির্দেশ মেনে চলুন।`
    : `⚠️ Active Traffic Barricades & Diversions:\n${items.join('\n')}\nPlease follow Kolkata Police instructions on the ground.`;
}

export function templateCrowdAnswer(f: ChatFacts, lang: 'bn' | 'en'): string {
  const isBn = lang === 'bn';
  if (!f.to) {
    return isBn
      ? 'সাধারণত সন্ধ্যা ৭টা থেকে রাত ১২টা পর্যন্ত মণ্ডপগুলিতে সর্বোচ্চ ভিড় থাকে। সকাল ও গভীর রাতে তুলনামূলকভাবে ভিড় কম থাকে।'
      : 'Peak pandal crowd is typically between 7:00 PM and midnight. Early mornings and late post-midnight hours offer the lightest lines.';
  }

  const c = f.crowd_at_destination;
  if (!c) {
    return isBn
      ? `বর্তমানে ${f.to.name}-এর জন্য কোনো সরাসরি ভিড়ের রিপোর্ট নেই।`
      : `No live crowd reports submitted for ${f.to.name} in the last 45 minutes.`;
  }

  return isBn
    ? `👥 ${f.to.name}: ভিড়ের মাত্রা ${c.level.toUpperCase()} (${c.updated_min_ago} মিনিট আগে আপডেট)।`
    : `👥 ${f.to.name}: Crowd level is currently ${c.level.toUpperCase()} (reported ${c.updated_min_ago} min ago via live squad tracking).`;
}

export function templateStationAnswer(f: ChatFacts, lang: 'bn' | 'en'): string {
  const isBn = lang === 'bn';
  if (!f.to) {
    return isBn
      ? 'কলকাতা মেট্রো এবং শহরতলি লোকাল ট্রেন পুজো পরিক্রমার জন্য সবচেয়ে নির্ভরযোগ্য মাধ্যম। আপনি কোন মণ্ডপের কাছের স্টেশন জানতে চান?'
      : 'Kolkata Metro and suburban local trains provide the fastest transit during Durga Puja. Which pandal do you need nearest station for?';
  }

  if (!f.nearest_stations_to_destination || f.nearest_stations_to_destination.length === 0) {
    return isBn
      ? `${f.to.name}-এর নিকটবর্তী মেট্রো বা লোকাল স্টেশন খুঁজতে ম্যাপের "Stations" লেয়ারটি দেখুন।`
      : `Check the "Stations" layer on UMA map to view all walkable railway and metro stations near ${f.to.name}.`;
  }

  const list = f.nearest_stations_to_destination
    .map((s) => `• ${s.name || s.id}: ${(s.distance_m / 1000).toFixed(1)} km (${s.distance_m} m)`)
    .join('\n');

  return isBn
    ? `🚇 ${f.to.name}-এর নিকটবর্তী স্টেশনসমূহ:\n${list}`
    : `🚇 Nearest stations to ${f.to.name}:\n${list}`;
}

export function templateHelplineAnswer(lang: 'bn' | 'en'): string {
  const isBn = lang === 'bn';
  return isBn
    ? `🚨 জরুরি হেল্পলাইন নম্বরসমূহ:\n• কলকাতা পুলিশ কন্ট্রোল রুম: 100 / 112\n• ট্রাফিক পুলিশ কন্ট্রোল: 1073\n• উইমেন হেল্পলাইন: 1090 / 1091\n• অ্যাম্বুলেন্স: 102 / 108\n• চাইল্ডলাইন: 1098`
    : `🚨 Kolkata Emergency Helplines:\n• Kolkata Police Control Room: 100 / 112\n• Traffic Control Room: 1073\n• Women in Distress: 1090 / 1091\n• Ambulance / Medical: 102 / 108\n• Childline: 1098`;
}

export function templateSuggestionsAnswer(suggestions: ResolvedPlace[], lang: 'bn' | 'en'): string {
  const isBn = lang === 'bn';
  const list = suggestions.map((s) => `• "${s.name}"`).join('\n');
  return isBn
    ? `সঠিক অবস্থান চিহ্নিত করা যায়নি। আপনি কি এই স্থানগুলির কোনো একটি খুঁজছেন?\n${list}`
    : `Could not identify that place with certainty. Did you mean one of these?\n${list}`;
}
