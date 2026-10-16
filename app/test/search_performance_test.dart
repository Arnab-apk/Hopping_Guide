import 'package:flutter_test/flutter_test.dart';
import 'package:kolkata_puja/repositories/local_pandal_repository.dart';
import 'package:kolkata_puja/services/pandal_search_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('search benchmark over the real directory', () async {
    final pandals = await LocalAssetPandalRepository().all();
    final search = PandalSearchService.instance;
    const queries = [
      's',
      'sr',
      'sre',
      'sree',
      'sreebhumi',
      'b',
      'ba',
      'bag',
      'bagbazar',
      'metro',
    ];
    // Warm up the VM before measuring repeated typing across the same dataset.
    for (final query in queries) {
      search.searchPandals(query, pandals);
    }
    for (final pandal in pandals) {
      final full = search.scorePandal(pandal, 's');
      final scoreOnly = search.scorePandal(
        pandal,
        's',
        includeHighlights: false,
      );
      expect(scoreOnly?.score, full?.score);
      expect(scoreOnly?.matchedField, full?.matchedField);
      if (scoreOnly != null) expect(scoreOnly.nameHighlightSpans, isEmpty);
    }
    final watch = Stopwatch()..start();
    var matches = 0;
    for (var repeat = 0; repeat < 10; repeat++) {
      for (final query in queries) {
        matches += search.searchPandals(query, pandals).length;
      }
    }
    watch.stop();
    expect(matches, greaterThan(0));
    // Diagnostic timing, not a machine-dependent pass/fail threshold.
    // ignore: avoid_print
    print(
      'SEARCH_BENCHMARK ${pandals.length} pandals, 100 queries: ${watch.elapsedMilliseconds} ms; $matches matches',
    );
  });
}
