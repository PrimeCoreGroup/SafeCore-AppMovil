// @pure-dart
import 'package:flutter_test/flutter_test.dart';
import 'package:safecore_mobile/core/errors/failures.dart';
import 'package:safecore_mobile/core/storage/cached_fetch.dart';
import 'package:safecore_mobile/core/storage/local_cache.dart';
import 'package:safecore_mobile/core/utils/data_result.dart';

import '../helpers/test_clock.dart';

void main() {
  late TestClock clock;
  late InMemoryLocalCache cache;

  setUp(() {
    clock = TestClock();
    cache = InMemoryLocalCache(clock: clock.call);
  });

  Future<DataResult<List<int>>> fetch(Future<List<int>> Function() remote) =>
      fetchWithCache<List<int>>(
        cache: cache,
        key: 'k',
        remote: remote,
        toJson: (d) => d,
        fromJson: (j) => (j! as List).cast<int>(),
        staleAfter: const Duration(minutes: 5),
        clock: clock.call,
      );

  test('con red devuelve datos remotos y los guarda', () async {
    final r = await fetch(() async => [1, 2]);
    expect(r.source, DataSourceKind.remote);
    expect((await cache.read('k'))!.value, equals([1, 2]));
  });

  test('sin red usa el último estado conocido', () async {
    await fetch(() async => [7]);
    clock.advance(const Duration(minutes: 1));
    final r = await fetch(() async => throw const NetworkFailure());
    expect(r.data, equals([7]));
    expect(r.fromCache, isTrue);
    expect(r.isStale, isFalse);
  });

  test('marca como desactualizados los datos antiguos', () async {
    await fetch(() async => [7]);
    clock.advance(const Duration(minutes: 10));
    final r = await fetch(() async => throw const TimeoutFailure());
    expect(r.isStale, isTrue);
  });

  test('sin red y sin caché propaga el error', () async {
    await expectLater(
      () => fetch(() async => throw const OfflineFailure()),
      throwsA(isA<OfflineFailure>()),
    );
  });

  test('un 403 no se oculta con datos en caché', () async {
    await fetch(() async => [7]);
    await expectLater(
      () => fetch(() async => throw const ForbiddenFailure()),
      throwsA(isA<ForbiddenFailure>()),
    );
  });
}
