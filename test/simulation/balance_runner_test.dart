import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'balance_harness.dart';

void main() {
  test('Export real-domain balance scenarios', () {
    const enabled = bool.fromEnvironment('BALANCE_RUN');
    if (!enabled) return;
    const selected = String.fromEnvironment('BALANCE_SCENARIO');
    const minutes = int.fromEnvironment('BALANCE_MINUTES', defaultValue: 60);
    const seed = int.fromEnvironment('BALANCE_SEED', defaultValue: 10101);
    const output = String.fromEnvironment(
      'BALANCE_OUTPUT',
      defaultValue: 'balance_results',
    );
    final names = selected.isNotEmpty
        ? selected.split(',')
        : [
            'A_NORMAL',
            'B_CONSERVATIVE',
            'C_AGGRESSIVE',
            'D_POOR',
            'E_MINIMUM',
            'E_ROADS',
            'F_TURHAN',
            'F_HAVVA',
            'F_BOTH',
            'G_SHEARS',
            'G_MOTOR',
            'H_STABILITY',
            for (final id in [
              'growth',
              'collectionCapacity',
              'truckCapacity',
              'truckSpeed',
              'factorySpeed',
              'packagingSpeed',
              'shelfCapacity',
              'workerHarvest',
              'workerMovement',
            ])
              'U_$id',
          ];
    final results = <Map<String, Object?>>[];
    for (final name in names) {
      final run = BalanceRun(
        name,
        seed: seed,
        initialGold: name == 'E_MINIMUM' ? BalanceRun.minimumCapital : null,
      );
      try {
        results.add(run.run(minutes: minutes));
        File('$output.json').writeAsStringSync(
          const JsonEncoder.withIndent('  ').convert({
            'schema': 1,
            'stepMs': 250,
            'seed': seed,
            'results': results,
          }),
        );
        final rows = [
          for (final r in results)
            ...(r['checkpoints'] as List).map(
              (c) => Map<String, Object?>.from(c as Map),
            ),
        ];
        for (final row in rows) {
          for (final worker
              in (row['workers'] as List).cast<Map<String, Object?>>()) {
            for (final entry in worker.entries) {
              row['${worker['id']}_${entry.key}'] = entry.value;
            }
          }
          for (final entry
              in (row['levelTimes'] as Map<String, double>).entries) {
            row['level_${entry.key}_seconds'] = entry.value;
          }
        }
        final keys = rows.expand((r) => r.keys).toSet().toList();
        String csv(Object? v) =>
            '"${(v is Map || v is List ? jsonEncode(v) : v?.toString() ?? '').replaceAll('"', '""')}"';
        File('$output.csv').writeAsStringSync(
          [
            keys.map(csv).join(','),
            for (final row in rows) keys.map((k) => csv(row[k])).join(','),
          ].join('\n'),
        );
        // ignore: avoid_print
        print('$name: ${run.snapshot()}');
      } finally {
        run.dispose();
      }
    }
  }, timeout: const Timeout(Duration(minutes: 60)));
}
