/// Kolkata & suburban zones used for the zone filter (P0: browse by zone).
enum KolkataZone {
  northKolkata,
  centralKolkata,
  southKolkata,
  saltLake,
  newTown,
  nadiaKalyani,
  hooghlyChinsurah,
  hooghlyBandel,
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
      case KolkataZone.nadiaKalyani:
        return 'Kalyani (Nadia)';
      case KolkataZone.hooghlyChinsurah:
        return 'Chinsurah (Hooghly)';
      case KolkataZone.hooghlyBandel:
        return 'Bandel (Hooghly)';
    }
  }

  String get shortLabel {
    switch (this) {
      case KolkataZone.northKolkata:
        return 'North';
      case KolkataZone.centralKolkata:
        return 'Central';
      case KolkataZone.southKolkata:
        return 'South';
      case KolkataZone.saltLake:
        return 'Salt Lake';
      case KolkataZone.newTown:
        return 'New Town';
      case KolkataZone.nadiaKalyani:
        return 'Kalyani';
      case KolkataZone.hooghlyChinsurah:
        return 'Chinsurah';
      case KolkataZone.hooghlyBandel:
        return 'Bandel';
    }
  }

  bool get isKolkataCity {
    switch (this) {
      case KolkataZone.northKolkata:
      case KolkataZone.centralKolkata:
      case KolkataZone.southKolkata:
      case KolkataZone.saltLake:
      case KolkataZone.newTown:
        return true;
      case KolkataZone.nadiaKalyani:
      case KolkataZone.hooghlyChinsurah:
      case KolkataZone.hooghlyBandel:
        return false;
    }
  }
}
