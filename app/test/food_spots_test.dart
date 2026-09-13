import 'package:flutter_test/flutter_test.dart';
import 'package:kolkata_puja/repositories/supplementary_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('SupplementaryRepository loads all 41 food spots correctly', () async {
    final repo = SupplementaryRepository();
    final foodSpots = await repo.getFoodSpots();

    expect(foodSpots.length, 41);

    // Verify properties of specific notable food spots
    final shreebhumi = foodSpots.firstWhere((f) => f.id == 'f1');
    expect(shreebhumi.name, 'Bhog at Shreebhumi');
    expect(shreebhumi.type, 'Bhog & Prasadam');
    expect(shreebhumi.nearbyPandal, 'Shreebhumi Sporting Club');
    expect(shreebhumi.lat, 22.572);
    expect(shreebhumi.lng, 88.4135);

    final suryaModak = foodSpots.firstWhere((f) => f.id == 'f4');
    expect(suryaModak.name, 'Surya Kumar Modak');
    expect(suryaModak.type, 'Traditional Sweets (Jolbhora)');
    expect(suryaModak.nearbyPandal, 'Sandheswartala Sarbojanin, Chinsurah');

    final mitraCafe = foodSpots.firstWhere((f) => f.id == 'f13');
    expect(mitraCafe.name, 'Mitra Cafe');
    expect(mitraCafe.type, 'Heritage Cutlets & Mughlai');

    final barbecueNation = foodSpots.firstWhere((f) => f.id == 'f41');
    expect(barbecueNation.name, 'Barbeque Nation- Salt Lake, Kolkata');
    expect(barbecueNation.nearbyPandal, 'Salt Lake BJ Block');

    // Verify all 41 spots have valid lat/lng coordinates and names
    for (final spot in foodSpots) {
      expect(spot.name.isNotEmpty, true);
      expect(spot.type.isNotEmpty, true);
      expect(spot.nearbyPandal.isNotEmpty, true);
      expect(spot.lat, greaterThan(20.0));
      expect(spot.lng, greaterThan(80.0));
    }
  });
}
