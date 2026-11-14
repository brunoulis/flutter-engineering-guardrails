import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:guardrails_async_example/search.dart';

class ControlledRepository implements SearchRepository {
  final pending = <String, Completer<List<SearchItem>>>{};

  @override
  Future<List<SearchItem>> search(String query) {
    return (pending[query] = Completer<List<SearchItem>>()).future;
  }
}

void main() {
  for (final staleFails in [false, true]) {
    test('stale completion (error: $staleFails) keeps latest loading',
        () async {
      final repository = ControlledRepository();
      final model = SearchViewModel(repository);
      addTearDown(model.dispose);
      var notifications = 0;
      model.addListener(() => notifications++);
      final first = model.search('A');
      final second = model.search('B');
      expect(notifications, 2);

      if (staleFails) {
        repository.pending['A']!.completeError(Exception('old request'));
      } else {
        repository.pending['A']!.complete([const SearchItem('A')]);
      }
      await first;
      expect(model.isLoading, true);
      expect(model.items, isEmpty);
      expect(model.lastError, isNull);
      expect(notifications, 2);

      repository.pending['B']!.complete([const SearchItem('B')]);
      await second;
      expect(model.isLoading, false);
      expect(model.items.single.label, 'B');
      expect(notifications, 3);
    });
  }

  test('failure after disposal is consumed without publishing state', () async {
    final repository = ControlledRepository();
    final model = SearchViewModel(repository);
    var notifications = 0;
    model.addListener(() => notifications++);
    final operation = model.search('A');
    model.dispose();
    repository.pending['A']!.completeError(Exception('late failure'));
    await operation;
    expect(notifications, 1);
    expect(model.lastError, isNull);
    expect(model.items, isEmpty);
  });

  test('snapshots survive repository mutation and retry can return empty',
      () async {
    final repository = ControlledRepository();
    final model = SearchViewModel(repository);
    addTearDown(model.dispose);
    final operation = model.search('A');
    final source = [const SearchItem('A')];
    repository.pending['A']!.complete(source);
    await operation;
    final snapshot = model.items;
    source.clear();
    expect(snapshot.single.label, 'A');

    final failing = model.search('B');
    repository.pending['B']!.completeError(Exception('network'));
    await failing;
    expect(model.lastError, isNotNull);
    final retry = model.search('C');
    expect(model.isLoading, true);
    expect(model.lastError, isNull);
    expect(model.items, same(snapshot));
    repository.pending['C']!.complete([]);
    await retry;
    expect(model.items, isEmpty);
    expect(model.isLoading, false);
    expect(model.lastError, isNull);
    expect(snapshot.single.label, 'A');
  });

  test('later query remains visible when earlier success arrives last',
      () async {
    final repository = ControlledRepository();
    final model = SearchViewModel(repository);
    final first = model.search('A');
    final second = model.search('B');
    repository.pending['B']!.complete([const SearchItem('B')]);
    await second;
    repository.pending['A']!.complete([const SearchItem('A')]);
    await first;
    expect(model.items.single.label, 'B');
    expect(model.isLoading, false);
    expect(model.lastError, isNull);
    model.dispose();
  });

  test('earlier failure does not replace later success', () async {
    final repository = ControlledRepository();
    final model = SearchViewModel(repository);
    final first = model.search('A');
    final second = model.search('B');
    repository.pending['B']!.complete([const SearchItem('B')]);
    await second;
    repository.pending['A']!.completeError(Exception('old request'));
    await first;
    expect(model.items.single.label, 'B');
    expect(model.lastError, isNull);
    model.dispose();
  });

  test('completion after disposal does not notify released listeners',
      () async {
    final repository = ControlledRepository();
    final model = SearchViewModel(repository);
    var notifications = 0;
    model.addListener(() => notifications++);
    final operation = model.search('A');
    expect(notifications, 1);
    model.dispose();
    repository.pending['A']!.complete([const SearchItem('A')]);
    await operation;
    expect(notifications, 1);
    expect(model.items, isEmpty);
  });

  test('current failure ends loading and preserves previous results', () async {
    final repository = ControlledRepository();
    final model = SearchViewModel(repository);
    final first = model.search('A');
    repository.pending['A']!.complete([const SearchItem('A')]);
    await first;
    final second = model.search('B');
    final failure = Exception('network');
    repository.pending['B']!.completeError(failure);
    await second;
    expect(model.items.single.label, 'A');
    expect(model.lastError, same(failure));
    expect(model.isLoading, false);
    expect(
        () => model.items.add(const SearchItem('C')), throwsUnsupportedError);
    model.dispose();
  });
}
