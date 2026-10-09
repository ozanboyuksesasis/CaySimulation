import 'package:cay_simulasyonu/features/plantation/plantation_config.dart';

import 'dart:convert';

import 'package:cay_simulasyonu/features/economy/economy_state.dart';
import 'package:cay_simulasyonu/features/economy/inventory_state.dart';
import 'package:cay_simulasyonu/features/plantation/plantation_system.dart';
import 'package:cay_simulasyonu/features/plantation/tea_field.dart';
import 'package:cay_simulasyonu/features/workers/worker.dart';
import 'package:cay_simulasyonu/features/workers/equipment.dart';
import 'package:cay_simulasyonu/features/workers/worker_config.dart';
import 'package:cay_simulasyonu/features/workers/job_system.dart';
import 'package:cay_simulasyonu/features/workers/harvest_job.dart';
import 'package:cay_simulasyonu/game/systems/grid_pathfinder.dart';
import 'package:cay_simulasyonu/game/world/isometric_grid.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late EconomyState economy;
  late InventoryState inventory;
  late PlantationSystem plantation;
  late Worker worker;
  late JobSystem jobs;
  late TeaField a;
  late TeaField b;
  late TeaField c;
  setUp(() {
    economy = EconomyState();
    inventory = InventoryState();
    TeaField field(String id, double x) => TeaField(
      id: id,
      gridPosition: GridPoint(x, 2),
      footprint: const Footprint(2, 2),
    );
    a = field('a', 2);
    b = field('b', 6);
    c = field('c', 10);
    plantation = PlantationSystem(
      economy: economy,
      inventory: inventory,
      fields: [a, b, c],
    );
    for (final field in plantation.fields) {
      plantation.plant(field);
    }
    plantation.advance(PlantationConfig.growthDuration);
    worker = Worker(
      equipment: EquipmentType.teaShears,
      id: 'worker',
      name: 'Mehmet',
      gridPosition: const GridPoint(2.5, 6.5),
    );
    jobs = JobSystem(
      worker: worker,
      plantation: plantation,
      pathfinder: GridPathfinder(
        columns: 20,
        rows: 20,
        blocked: {
          for (final field in plantation.fields)
            ...GridPathfinder.footprintTiles(
              field.gridPosition,
              field.footprint,
            ),
        },
      ),
    );
  });
  tearDown(() {
    jobs.dispose();
    worker.dispose();
    plantation.dispose();
    economy.dispose();
    inventory.dispose();
  });
  void arrive() {
    jobs.advance(const Duration(seconds: 1));
  }

  void complete() {
    jobs.advance(const Duration(seconds: 6));
  }

  test('01 Hazır tarla bir hasat işi oluşturur', () {
    final job = jobs.requestHarvest(a)!;
    expect(job.fieldId, a.id);
    expect(jobs.jobs.length, 1);
  });
  test('02 Tekrar tıklama yinelenen iş oluşturmaz', () {
    final first = jobs.requestHarvest(a);
    expect(jobs.requestHarvest(a), same(first));
    expect(jobs.jobs.length, 1);
  });
  test('03 Boştaki işçi sıradaki işi alır', () {
    final job = jobs.requestHarvest(a)!;
    expect(worker.assignedJobId, job.id);
    expect(job.assignedWorkerId, worker.id);
    expect(job.status, JobStatus.assigned);
  });
  test('04 Meşgul işçi ikinci eşzamanlı iş almaz', () {
    final first = jobs.requestHarvest(a)!;
    final second = jobs.requestHarvest(b)!;
    expect(worker.assignedJobId, first.id);
    expect(second.assignedWorkerId, isNull);
  });
  test('05 İkinci ve üçüncü işler FIFO sırasında bekler', () {
    jobs.requestHarvest(a);
    final second = jobs.requestHarvest(b)!;
    final third = jobs.requestHarvest(c)!;
    expect(second.status, JobStatus.queued);
    expect(third.status, JobStatus.queued);
    expect(jobs.queuedCount, 2);
    complete();
    expect(worker.assignedJobId, second.id);
    expect(third.status, JobStatus.queued);
  });
  test(
    '06 Boşta durumundan hareket durumuna geçer ve kesirli konumda yürür',
    () {
      expect(worker.state, WorkerState.idle);
      jobs.requestHarvest(a);
      expect(worker.state, WorkerState.movingToJob);
      jobs.advance(const Duration(milliseconds: 125));
      expect(worker.gridPosition.x, 2.5);
      expect(worker.gridPosition.y, closeTo(6.25, 1e-8));
    },
  );
  test('07 Ulaşılan karo tarla kenarına bitişik ve yürünebilir', () {
    final job = jobs.requestHarvest(a)!;
    arrive();
    expect(
      jobs.pathfinder.interactionTiles(a.gridPosition, a.footprint),
      contains(job.targetPosition),
    );
    expect(tileAt(worker.gridPosition), job.targetPosition);
    expect(jobs.pathfinder.walkable(job.targetPosition!), isTrue);
  });
  test('08 Yol ve hedef tarla içinden geçmez', () {
    final job = jobs.requestHarvest(a)!;
    final interior = GridPathfinder.footprintTiles(
      a.gridPosition,
      a.footprint,
    ).toSet();
    expect(interior.contains(job.targetPosition), isFalse);
    expect(jobs.remainingPath.any(interior.contains), isFalse);
  });
  test('09 Varışta hasada başlar', () {
    final job = jobs.requestHarvest(a)!;
    arrive();
    expect(worker.state, WorkerState.working);
    expect(job.status, JobStatus.inProgress);
  });
  test('10 Hasat yapılandırılmış beş saniyeden erken tamamlanmaz', () {
    final job = jobs.requestHarvest(a)!;
    arrive();
    jobs.advance(
      WorkerConfig.harvestDuration - const Duration(microseconds: 1),
    );
    expect(job.status, JobStatus.inProgress);
    expect(a.state, TeaFieldState.ready);
    jobs.advance(const Duration(microseconds: 1));
    expect(job.status, JobStatus.completed);
  });
  test('11 Tamamlanan hasat tam 25 kg tarla stoğu oluşturur', () {
    jobs.requestHarvest(a);
    complete();
    expect(a.harvestedStockKg, 25);
    expect(a.harvestCount, 1);
  });
  test('12 Global yaş çay hasattan etkilenmez', () {
    inventory.addFreshTea(7);
    jobs.requestHarvest(a);
    complete();
    expect(inventory.freshTeaKg, 7);
  });
  test('13 Tarla yalnızca iş bitince hasat edildi olur', () {
    jobs.requestHarvest(a);
    expect(a.state, TeaFieldState.ready);
    arrive();
    expect(a.state, TeaFieldState.ready);
    jobs.advance(WorkerConfig.harvestDuration);
    expect(a.state, TeaFieldState.harvested);
  });
  test('14 Stok bekleyen tarla uzun süre sonra bile yeniden büyümez', () {
    jobs.requestHarvest(a);
    complete();
    jobs.advance(const Duration(days: 1));
    expect(a.state, TeaFieldState.harvested);
    expect(a.stageDuration, isNull);
    expect(a.harvestedStockKg, 25);
  });
  test('15 Stok boşaldığı andan itibaren yenilenme sayacı başlar', () {
    jobs.requestHarvest(a);
    complete();
    jobs.advance(const Duration(seconds: 20));
    a.removeHarvestedStock(10);
    jobs.advance(const Duration(seconds: 20));
    expect(a.state, TeaFieldState.harvested);
    expect(a.harvestedStockKg, 15);
    a.removeHarvestedStock(15);
    expect(a.remainingSeconds, 5);
    jobs.advance(const Duration(milliseconds: 4999));
    expect(a.state, TeaFieldState.harvested);
    jobs.advance(const Duration(milliseconds: 1));
    expect(a.state, TeaFieldState.growing1);
  });
  test('16 İş bitince işçi tekrar boşta olur', () {
    jobs.requestHarvest(a);
    complete();
    expect(worker.state, WorkerState.idle);
    expect(worker.assignedJobId, isNull);
    expect(jobs.remainingPath, isEmpty);
  });
  test('17 İlk iş tamamlanınca sonraki iş otomatik atanır', () {
    jobs.requestHarvest(a);
    final second = jobs.requestHarvest(b)!;
    complete();
    expect(worker.assignedJobId, second.id);
    expect(worker.state, WorkerState.movingToJob);
  });
  test('18 Yol yoksa iş başarısız olur ve işçi serbest kalır', () {
    final blocked = {
      ...jobs.pathfinder.blocked,
      ...jobs.pathfinder.interactionTiles(a.gridPosition, a.footprint),
    };
    jobs.dispose();
    jobs = JobSystem(
      worker: worker,
      plantation: plantation,
      pathfinder: GridPathfinder(columns: 20, rows: 20, blocked: blocked),
    );
    final failed = jobs.requestHarvest(a)!;
    expect(failed.status, JobStatus.failed);
    expect(worker.state, WorkerState.idle);
    expect(failed.failureMessage, 'Tarlaya ulaşılacak yol bulunamadı.');
    final next = jobs.requestHarvest(b)!;
    expect(next.status, JobStatus.assigned);
  });
  test('19 Tarlalar bağımsız stok ve iş durumunu korur', () {
    final first = jobs.requestHarvest(a)!;
    final second = jobs.requestHarvest(b)!;
    complete();
    expect(a.harvestedStockKg, 25);
    expect(b.harvestedStockKg, 0);
    expect(first.status, JobStatus.completed);
    expect(second.status, JobStatus.assigned);
    jobs.advance(const Duration(seconds: 20));
    expect(b.harvestedStockKg, 25);
    expect(c.harvestedStockKg, 0);
  });
  test('20 Hasat ekonomiyi değiştirmez', () {
    final gold = economy.balance;
    jobs.requestHarvest(a);
    complete();
    expect(economy.balance, gold);
  });
  test('21 A* bina engelini dolaşır, sınır dışına çıkmaz ve en yakın ulaşılabilir kenarı seçer', () {
    final finder = GridPathfinder(
      columns: 8,
      rows: 8,
      blocked: {(x: 2, y: 1), (x: 2, y: 2), (x: 2, y: 3)},
    );
    final path = finder.findPath((x: 1, y: 2), [(x: 3, y: 2)])!;
    expect(path.length, 7);
    expect(path.every(finder.walkable), isTrue);
    expect(finder.findPath((x: -1, y: 0), [(x: 3, y: 2)]), isNull);
    final shortest = finder.findPath(
      (x: 1, y: 2),
      [(x: 3, y: 2), (x: 1, y: 4)],
    )!;
    expect(shortest.last, (x: 1, y: 4));
    expect(shortest.length, 3);
  });
  test('22 İşçi ve iş JSON uyumlu veri taşır', () {
    final job = jobs.requestHarvest(a)!;
    expect(jsonDecode(jsonEncode(worker.toJson()))['name'], 'Mehmet');
    expect(jsonDecode(jsonEncode(job.toJson()))['fieldId'], 'a');
  });
  test('23 Büyük zaman adımı ile küçük adımlar aynı hasadı üretir', () {
    jobs.requestHarvest(a);
    jobs.advance(const Duration(seconds: 60));
    expect(a.harvestedStockKg, 25);
    expect(a.harvestCount, 1);
    expect(worker.state, WorkerState.idle);
    expect(
      a.stateStartedAt,
      PlantationConfig.growthDuration + const Duration(seconds: 6),
    );
  });
  test('24 Geçersiz stok alma ve hazır olmayan tarla emri reddedilir', () {
    expect(() => a.removeHarvestedStock(-1), throwsArgumentError);
    expect(() => a.removeHarvestedStock(1), throwsArgumentError);
    jobs.requestHarvest(a);
    complete();
    expect(jobs.requestHarvest(a), isNull);
    expect(() => a.removeHarvestedStock(26), throwsArgumentError);
  });
}
