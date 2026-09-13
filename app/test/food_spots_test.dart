import 'package:flutter_test/flutter_test.dart';
import 'package:kolkata_puja/repositories/supplementary_repository.dart';
import 'package:kolkata_puja/utils/haversine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('SupplementaryRepository loads all 66 food spots correctly', () async {
    final repo = SupplementaryRepository();
    final foodSpots = await repo.getFoodSpots();

    expect(foodSpots.length, 66);

    final golbari = foodSpots.firstWhere((f) => f.id == 'f_golbari');
    expect(golbari.name, 'Golbari (New Punjabi Hotel)');
    expect(golbari.nearbyPandal, 'Shyambazar 5 Point Crossing Sarbojanin');
    expect(golbari.lat, closeTo(22.60, 0.05));
    expect(golbari.lng, closeTo(88.37, 0.05));
    expect(golbari.rating, 4.4);

    final mitraCafe = foodSpots.firstWhere((f) => f.id == 'f_mitra_cafe_shyam');
    expect(mitraCafe.name, 'Mitra Cafe (Shyambazar)');
    expect(mitraCafe.nearbyPandal, 'Jagat Mukherjee Park');
    expect(mitraCafe.rating, 4.5);

    final allenKitchen = foodSpots.firstWhere((f) => f.id == 'f_allen_kitchen');
    expect(allenKitchen.name, 'Allen Kitchen (Shobhabazar)');
    expect(allenKitchen.nearbyPandal, 'Sovabazar Rajbari Durga Puja');

    // Verify all 66 spots have valid lat/lng coordinates and names
    for (final spot in foodSpots) {
      expect(spot.name.isNotEmpty, true);
      expect(spot.type.isNotEmpty, true);
      expect(spot.nearbyPandal.isNotEmpty, true);
      expect(spot.lat, greaterThan(20.0));
      expect(spot.lng, greaterThan(80.0));
    }
  });

  test('Food spots filter strictly within 10km of Kolkata center', () async {
    final repo = SupplementaryRepository();
    final foodSpots = await repo.getFoodSpots();

    const centerLat = 22.5726; // Central Kolkata
    const centerLng = 88.3639;

    final nearby = foodSpots.where((f) {
      final dist = haversineMeters(centerLat, centerLng, f.lat, f.lng);
      return dist <= 10000;
    }).toList();

    expect(nearby.isNotEmpty, true);
  });
}
