/// Kolkata zones used for the zone filter (P0: browse by zone).
enum KolkataZone {
  northKolkata,
  centralKolkata,
  southKolkata,
  saltLake,
  newTown,
}

extension KolkataZoneX on KolkataZone {
  String get label {
    switch (this) {
      case KolkataZone.northKolkata:
        return 'North Kolkata';
      case KolkataZone.centralKolkata:
        return 'Central Kolkata';
      case KolkataZone.southKolkata:
        return 'South Kolkata';
      case KolkataZone.saltLake:
        return 'Salt Lake';
      case KolkataZone.newTown:
        return 'New Town';
    }
  }
}
