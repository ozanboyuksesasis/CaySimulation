import 'dart:math';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cay_simulasyonu/features/workers/worker_dialogue.dart';
import 'package:cay_simulasyonu/features/workers/worker.dart';
import 'package:cay_simulasyonu/features/workers/worker_idle_system.dart';
import 'package:cay_simulasyonu/features/workers/harvest_job.dart';
import 'package:cay_simulasyonu/features/workers/equipment.dart';
import 'package:cay_simulasyonu/game/world/isometric_grid.dart';
import 'package:cay_simulasyonu/game/systems/grid_pathfinder.dart';
import 'package:cay_simulasyonu/game/systems/tutorial_system.dart';
import 'package:cay_simulasyonu/game/components/worker_speech_layer.dart';
import 'package:cay_simulasyonu/game/cay_game.dart';
import 'package:cay_simulasyonu/game/harvest_test_scene.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Worker turhan, havva;
  late WorkerDialogueSystem dialogue;
  final jobs = <String, HarvestJob>{};
  setUp(() {
    jobs.clear();
    turhan = Worker(
      id: 'turhan',
      name: 'Turhan',
      gridPosition: const GridPoint(3.5, 3.5),
      equipment: EquipmentType.teaShears,
    );
    havva = Worker(
      id: 'havva',
      name: 'Havva',
      gridPosition: const GridPoint(4.5, 3.5),
      equipment: EquipmentType.teaShears,
    );
    dialogue = WorkerDialogueSystem(
      workers: () => [turhan, havva],
      jobForWorker: (w) => jobs[w.id],
      random: Random(42),
    );
    dialogue.update(Duration.zero);
  });
  tearDown(() {
    turhan.dispose();
    havva.dispose();
  });
  WorkerDialogueDefinition phrase(String id) =>
      workerDialogues.singleWhere((d) => d.id == id);
  void harvest(Worker w) {
    final job =
        HarvestJob(
            id: 'job-${w.id}',
            createdAt: Duration.zero,
            fieldId: 'field',
          )
          ..status = JobStatus.inProgress
          ..assignedWorkerId = w.id;
    jobs[w.id] = job;
    w.assignedJobId = job.id;
    w.state = WorkerState.working;
  }

  List<WorkerSpeech> conversations(int seconds) {
    final result = <WorkerSpeech>[];
    WorkerSpeech? previous;
    for (var i = 1; i <= seconds * 10; i++) {
      dialogue.update(Duration(milliseconds: i * 100));
      final s = dialogue.active;
      if (s != null && !identical(s, previous)) {
        result.add(s);
        previous = s;
      }
    }
    return result;
  }

  test('All nine dialect phrases are preserved exactly', () {
    expect(workerDialogues.map((d) => d.text), [
      'Bezdum da!',
      'Yedunuz beni!',
      'Haydin çayluğa!',
      'Bu sevdaluk yedi beni!',
      'Bugün çay topliyamam çişelidur çişeli!',
      'Havva bunu Turhan desein!',
      'Darlandumi Parkun beni!',
      'Afkur!',
      'Rivrivriv!',
    ]);
  });
  test('Worker restrictions hold for character-specific phrases', () {
    expect(dialogue.matches(phrase('love'), turhan), isTrue);
    expect(dialogue.matches(phrase('love'), havva), isFalse);
    expect(dialogue.matches(phrase('afkur'), havva), isFalse);
    expect(dialogue.matches(phrase('drizzle'), turhan), isFalse);
    expect(dialogue.matches(phrase('drizzle'), havva), isTrue);
  });
  test('Complaints require an actual active harvest job', () {
    expect(dialogue.matches(phrase('tired'), turhan), isFalse);
    turhan.state = WorkerState.working;
    expect(dialogue.matches(phrase('tired'), turhan), isFalse);
    harvest(turhan);
    expect(dialogue.matches(phrase('tired'), turhan), isTrue);
    jobs[turhan.id]!.status = JobStatus.completed;
    expect(dialogue.matches(phrase('tired'), turhan), isFalse);
  });
  test('Walking phrase requires actual movement toward a job', () {
    turhan.state = WorkerState.movingToJob;
    dialogue.update(const Duration(milliseconds: 100));
    expect(dialogue.matches(phrase('walk'), turhan), isFalse);
    turhan.gridPosition = const GridPoint(3.7, 3.5);
    dialogue.update(const Duration(milliseconds: 200));
    expect(dialogue.matches(phrase('walk'), turhan), isTrue);
    dialogue.update(const Duration(milliseconds: 300));
    expect(dialogue.matches(phrase('walk'), turhan), isFalse);
  });
  test('Seeded intervals are reproducible, bounded and varied', () {
    final other = WorkerDialogueSystem(
      workers: () => [],
      jobForWorker: (_) => null,
      random: Random(42),
    );
    final fresh = WorkerDialogueSystem(
      workers: () => [],
      jobForWorker: (_) => null,
      random: Random(42),
    );
    final values = <int>{};
    for (var i = 0; i < 200; i++) {
      for (final first in [true, false]) {
        final a = fresh.randomDelay(first: first),
            b = other.randomDelay(first: first);
        expect(a, b);
        values.add(a.inMilliseconds);
        expect(
          a.inMilliseconds,
          inInclusiveRange(first ? 12000 : 25000, first ? 25000 : 65000),
        );
      }
    }
    expect(values.length, greaterThan(350));
    expect(
      dialogue.nextEligible.values.every(
        (d) => d.inSeconds >= 12 && d.inSeconds <= 25,
      ),
      isTrue,
    );
  });
  test('No immediate repeats and global cooldown prevents overlaps', () {
    final spoken = conversations(900), last = <String, String>{};
    expect(spoken.length, greaterThan(10));
    for (var i = 0; i < spoken.length; i++) {
      final s = spoken[i];
      expect(s.definition.id, isNot(last[s.worker.id]));
      last[s.worker.id] = s.definition.id;
      if (i > 0) {
        expect(
          s.startedAt - spoken[i - 1].endsAt,
          greaterThanOrEqualTo(DialogueConfig.globalCooldown),
        );
      }
    }
  });
  test('Both eligible workers receive fair opportunities', () {
    final spoken = conversations(900);
    final a = spoken.where((s) => s.worker.id == 'turhan').length,
        b = spoken.where((s) => s.worker.id == 'havva').length;
    expect(a, greaterThan(5));
    expect(b, greaterThan(5));
    expect((a - b).abs(), lessThanOrEqualTo(4));
  });
  test('Rare Havva phrase requires nearby Turhan and never belongs to him', () {
    expect(dialogue.matches(phrase('nearby'), havva), isTrue);
    expect(dialogue.matches(phrase('nearby'), turhan), isFalse);
    turhan.gridPosition = const GridPoint(15, 15);
    expect(dialogue.matches(phrase('nearby'), havva), isFalse);
  });
  test('Weighted selection leaves rare phrases reachable', () {
    final seen = <String>{};
    for (var i = 0; i < 200; i++) {
      seen.add(
        dialogue.weighted([
          phrase('riv'),
          phrase('drizzle'),
          phrase('nearby'),
        ]).id,
      );
    }
    expect(seen, {'riv', 'drizzle', 'nearby'});
  });
  test('Reading duration is bounded and long text lasts longer', () {
    expect(
      DialogueConfig.duration(phrase('afkur').text),
      const Duration(milliseconds: 2500),
    );
    expect(
      DialogueConfig.duration(phrase('drizzle').text),
      greaterThan(const Duration(milliseconds: 3500)),
    );
    for (final d in workerDialogues) {
      expect(
        DialogueConfig.duration(d.text).inMilliseconds,
        inInclusiveRange(2500, 4500),
      );
    }
  });
  test(
    'Bubble follows worker position without changing selection geometry',
    () {
      expect(dialogue.preview('turhan', 'love'), isTrue);
      final speech = dialogue.active!;
      turhan.gridPosition = const GridPoint(4.2, 3.5);
      expect(speech.groundPosition, same(turhan.gridPosition));
      for (final size in [
        const Size(844, 390),
        const Size(960, 540),
        const Size(1280, 720),
      ]) {
        for (final head in [Offset.zero, Offset(size.width, size.height)]) {
          final b = speechBounds(head, const Size(240, 45), size);
          expect(b.left, greaterThanOrEqualTo(12));
          expect(b.right, lessThanOrEqualTo(size.width - 12));
          expect(b.top, greaterThanOrEqualTo(56));
          expect(b.bottom, lessThanOrEqualTo(size.height - 76));
        }
      }
    },
  );
  test('All catalog text wraps within three lines', () {
    final painter = TextPainter(textDirection: TextDirection.ltr, maxLines: 3);
    addTearDown(painter.dispose);
    for (final d in workerDialogues) {
      painter.text = TextSpan(
        text: d.text,
        style: const TextStyle(fontSize: 13, height: 1.15),
      );
      painter.layout(maxWidth: 240);
      expect(painter.didExceedMaxLines, isFalse);
    }
  });
  test('Distant zoom dismisses and resumes with a fresh delay', () {
    dialogue.preview('turhan', 'love');
    dialogue.update(const Duration(seconds: 1), zoom: .4);
    expect(dialogue.active, isNull);
    dialogue.update(const Duration(seconds: 20), zoom: 1);
    expect(dialogue.active, isNull);
    expect(
      dialogue.nextEligible['turhan'],
      greaterThanOrEqualTo(const Duration(seconds: 32)),
    );
  });
  test('Critical tutorial suppression does not burst on resume', () {
    dialogue.update(const Duration(minutes: 5), suppressed: true);
    expect(dialogue.active, isNull);
    dialogue.update(const Duration(minutes: 6));
    expect(dialogue.active, isNull);
    final g = CayGame();
    addTearDown(g.disposeState);
    expect(g.dialogueSuppressed, isTrue);
    g.tutorial!.step = TutorialStep.waitGrowth;
    expect(g.dialogueSuppressed, isFalse);
    g.tutorial!.step = TutorialStep.firstWorker;
    expect(g.dialogueSuppressed, isTrue);
  });
  test('Pausing simulation freezes visible speech and schedules', () {
    dialogue.preview('turhan', 'love');
    dialogue.update(const Duration(milliseconds: 100));
    final speech = dialogue.active,
        opacity = dialogue.opacity,
        next = dialogue.nextEligible;
    for (var i = 0; i < 500; i++) {
      dialogue.update(const Duration(milliseconds: 100));
    }
    expect(dialogue.active, same(speech));
    expect(dialogue.opacity, opacity);
    expect(dialogue.nextEligible, next);
  });
  test('Disable immediately dismisses; no new bubbles until enabled', () {
    dialogue.preview('turhan', 'love');
    dialogue.enabled = false;
    expect(dialogue.active, isNull);
    dialogue.update(const Duration(minutes: 10));
    expect(dialogue.active, isNull);
    expect(dialogue.preview('turhan', 'love'), isFalse);
    dialogue.enabled = true;
    dialogue.update(const Duration(minutes: 10));
    expect(dialogue.active, isNull);
  });
  test('Speaking never changes worker state, XP, equipment or position', () {
    final before = turhan.toJson().toString();
    conversations(600);
    expect(turhan.toJson().toString(), before);
  });
  test(
    'Real harvesting, XP, Gold and yield are identical with dialogue on/off',
    () {
      final a = HarvestTestGame('Makas'), b = HarvestTestGame('Makas');
      addTearDown(a.disposeState);
      addTearDown(b.disposeState);
      final voice = WorkerDialogueSystem(
        workers: () => a.workforce.workers,
        jobForWorker: a.jobs.jobForWorker,
        random: Random(9),
      );
      for (var i = 0; i < 200; i++) {
        a.simulation.advance(const Duration(milliseconds: 100));
        b.simulation.advance(const Duration(milliseconds: 100));
        voice.update(a.plantation.simulationTime);
        if (i == 20) voice.preview('turhan', 'tired');
      }
      expect(a.economy.balance, b.economy.balance);
      expect(a.progression.currentXp, b.progression.currentXp);
      expect(
        a.plantation.fields.map((f) => f.toJson()).toList(),
        b.plantation.fields.map((f) => f.toJson()).toList(),
      );
      expect(
        a.workforce.workers.map((w) => w.toJson()).toList(),
        b.workforce.workers.map((w) => w.toJson()).toList(),
      );
    },
  );
  test(
    'Idle wandering is seeded, varied and has no four-step square cycle',
    () {
      List<GridTile> trail(int seed) {
        final w = Worker(
          id: 'turhan',
          name: 'Turhan',
          gridPosition: const GridPoint(5.5, 5.5),
        );
        final idle = WorkerIdleSystem(
          GridPathfinder(columns: 12, rows: 12, blocked: {}),
          random: Random(seed),
        );
        final result = <GridTile>[];
        for (var i = 0; i < 3000; i++) {
          idle.advance(const Duration(milliseconds: 100), [w], {});
          final t = tileAt(w.gridPosition);
          if (result.isEmpty || result.last != t) result.add(t);
        }
        w.dispose();
        return result;
      }

      final a = trail(13);
      expect(a, trail(13));
      expect(a, isNot(trail(14)));
      expect(a.toSet().length, greaterThan(5));
      expect(
        [for (var i = 4; i < a.length; i++) a[i] == a[i - 4]].every((v) => v),
        isFalse,
      );
    },
  );
}
