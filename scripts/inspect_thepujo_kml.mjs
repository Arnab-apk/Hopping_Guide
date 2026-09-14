import https from 'https';
import fs from 'fs';

const url = 'https://www.google.com/maps/d/kml?mid=1GQ8KBEuldEMnoAmccpMiNdoHX-M8UQI&forcekml=1';

https.get(url, (res) => {
  let xml = '';
  res.on('data', chunk => xml += chunk);
  res.on('end', () => {
    fs.writeFileSync('scripts/thepujo_dump.kml', xml);
    console.log('Saved raw KML to scripts/thepujo_dump.kml (' + xml.length + ' bytes)');

    // Parse folders
    const folderRegex = /<Folder>([\s\S]*?)<\/Folder>/g;
    let match;
    const folders = [];

    while ((match = folderRegex.exec(xml)) !== null) {
      const folderContent = match[1];
      const folderNameMatch = folderContent.match(/<name>(.*?)<\/name>/);
      const folderName = folderNameMatch ? folderNameMatch[1] : 'Unknown';

      const placemarkRegex = /<Placemark>([\s\S]*?)<\/Placemark>/g;
      let pMatch;
      const placemarks = [];

      while ((pMatch = placemarkRegex.exec(folderContent)) !== null) {
        const pContent = pMatch[1];
        const nameMatch = pContent.match(/<name>(.*?)<\/name>/);
        const descMatch = pContent.match(/<description>([\s\S]*?)<\/description>/);
        const coordMatch = pContent.match(/<coordinates>\s*([^\s<]+)\s*<\/coordinates>/);

        const name = nameMatch ? nameMatch[1].trim() : '';
        const description = descMatch ? descMatch[1].trim() : '';
        const coordsRaw = coordMatch ? coordMatch[1].trim() : '';
        const parts = coordsRaw.split(',');
        const lng = parseFloat(parts[0]);
        const lat = parseFloat(parts[1]);

        placemarks.push({
          name,
          description,
          lat,
          lng,
          folder: folderName
        });
      }

      folders.push({
        folderName,
        count: placemarks.length,
        placemarks
      });
    }

    let allPlacemarks = [];
    folders.forEach(f => allPlacemarks.push(...f.placemarks));

    console.log('Total folders:', folders.length);
    console.log('Total placemarks:', allPlacemarks.length);

    // Check for duplicates within the KML itself
    const nameMap = new Map();
    const duplicates = [];
    allPlacemarks.forEach(p => {
      const norm = p.name.toLowerCase().replace(/[^a-z0-9]/g, '');
      if (nameMap.has(norm)) {
        duplicates.push({ original: nameMap.get(norm), duplicate: p });
      } else {
        nameMap.set(norm, p);
      }
    });

    console.log('Unique normalized names in thepujo:', nameMap.size);
    console.log('Duplicate entries in thepujo:', duplicates.length);

    // Check coordinates range
    let minLat = 999, maxLat = -999, minLng = 999, maxLng = -999;
    let invalidCoords = 0;
    allPlacemarks.forEach(p => {
      if (isNaN(p.lat) || isNaN(p.lng)) {
        invalidCoords++;
      } else {
        if (p.lat < minLat) minLat = p.lat;
        if (p.lat > maxLat) maxLat = p.lat;
        if (p.lng < minLng) minLng = p.lng;
        if (p.lng > maxLng) maxLng = p.lng;
      }
    });

    console.log('Coordinates bounds:', { minLat, maxLat, minLng, maxLng, invalidCoords });

    // Show 5 sample items with description
    console.log('\n--- First 5 sample items ---');
    console.log(JSON.stringify(allPlacemarks.slice(0, 5), null, 2));

    // Also check how many have descriptions or extra info
    const withDesc = allPlacemarks.filter(p => p.description && p.description.length > 0);
    console.log('\nItems with description:', withDesc.length);
    if (withDesc.length > 0) {
      console.log('Sample description:', withDesc[0]);
    }
  });
}).on('error', err => console.error(err));
