import 'dart:math';

import '../../game/world/isometric_grid.dart';
import 'harvest_job.dart';
import 'worker.dart';

enum DialogueContext { idle, walking, harvesting }

class WorkerDialogueDefinition {
  const WorkerDialogueDefinition(
    this.id,
    this.text,
    this.allowedWorkers,
    this.allowedStates,
    this.weight, {
    this.cooldown = const Duration(seconds: 90),
    this.requiresNearbyTurhan = false,
    this.priority = 0,
  });
  final String id, text;
  final Set<String> allowedWorkers;
  final Set<DialogueContext> allowedStates;
  final int weight, priority;
  final Duration cooldown;
  final bool requiresNearbyTurhan;
}

abstract final class DialogueConfig {
  static const firstMinMs = 12000, firstMaxMs = 25000;
  static const nextMinMs = 25000, nextMaxMs = 65000;
  static const globalCooldown = Duration(seconds: 8);
  static const minDurationMs = 2500, maxDurationMs = 4500;
  static const minZoom = .6, nearbyTiles = 3.0;
  static Duration duration(String text) => Duration(
    milliseconds: (minDurationMs + max(0, text.length - 12) * 70).clamp(
      minDurationMs,
      maxDurationMs,
    ),
  );
}

const workerDialogues = <WorkerDialogueDefinition>[
  WorkerDialogueDefinition(
    'tired',
    'Bezdum da!',
    {'turhan', 'havva'},
    {DialogueContext.harvesting},
    6,
  ),
  WorkerDialogueDefinition(
    'complaint',
    'Yedunuz beni!',
    {'turhan', 'havva'},
    {DialogueContext.harvesting},
    4,
  ),
  WorkerDialogueDefinition(
    'walk',
    'Haydin çayluğa!',
    {'turhan', 'havva'},
    {DialogueContext.walking},
    7,
  ),
  WorkerDialogueDefinition(
    'love',
    'Bu sevdaluk yedi beni!',
    {'turhan'},
    {DialogueContext.idle},
    2,
  ),
  WorkerDialogueDefinition(
    'drizzle',
    'Bugün çay topliyamam çişelidur çişeli!',
    {'havva'},
    {DialogueContext.idle},
    2,
  ),
  WorkerDialogueDefinition(
    'nearby',
    'Havva bunu Turhan desein!',
    {'havva'},
    {DialogueContext.idle, DialogueContext.walking, DialogueContext.harvesting},
    1,
    cooldown: Duration(seconds: 150),
    requiresNearbyTurhan: true,
  ),
  WorkerDialogueDefinition(
    'bored',
    'Darlandumi Parkun beni!',
    {'turhan', 'havva'},
    {DialogueContext.harvesting},
    3,
  ),
  WorkerDialogueDefinition(
    'afkur',
    'Afkur!',
    {'turhan'},
    {DialogueContext.idle},
    1,
  ),
  WorkerDialogueDefinition(
    'riv',
    'Rivrivriv!',
    {'turhan', 'havva'},
    {DialogueContext.idle},
    1,
  ),
];

class WorkerSpeech {
  WorkerSpeech(this.worker, this.definition, this.startedAt)
    : duration = DialogueConfig.duration(definition.text);
  final Worker worker;
  final WorkerDialogueDefinition definition;
  final Duration startedAt, duration;
  Duration get endsAt => startedAt + duration;
  GridPoint get groundPosition => worker.gridPosition;
}

/// Independent, read-only personality scheduler. It never mutates workers/jobs.
class WorkerDialogueSystem {
  WorkerDialogueSystem({
    required this.workers,
    required this.jobForWorker,
    Random? random,
  }) : random = random ?? Random();
  final List<Worker> Function() workers;
  final HarvestJob? Function(Worker) jobForWorker;
  final Random random;
  final Map<String, Duration> _next = {}, _lastSpoken = {}, _phraseUsed = {};
  final Map<String, List<String>> _recent = {};
  final Map<String, GridPoint> _previous = {};
  final Set<String> _moving = {};
  Duration now = Duration.zero, _globalReady = Duration.zero;
  WorkerSpeech? active;
  bool _enabled = true, _resumePending = false, _suppressed = false;
  bool get enabled => _enabled;
  set enabled(bool value) {
    if (_enabled == value) return;
    _enabled = value;
    active = null;
    _resumePending = true;
  }

  Map<String, Duration> get nextEligible => Map.unmodifiable(_next);
  Duration randomDelay({required bool first}) {
    final lo = first ? DialogueConfig.firstMinMs : DialogueConfig.nextMinMs;
    final hi = first ? DialogueConfig.firstMaxMs : DialogueConfig.nextMaxMs;
    return Duration(milliseconds: lo + random.nextInt(hi - lo + 1));
  }

  DialogueContext? context(Worker w) {
    if (w.state == WorkerState.idle) return DialogueContext.idle;
    if (w.state == WorkerState.movingToJob && _moving.contains(w.id)) {
      return DialogueContext.walking;
    }
    final job = jobForWorker(w);
    if (w.state == WorkerState.working &&
        job?.status == JobStatus.inProgress &&
        job?.id == w.assignedJobId &&
        job?.assignedWorkerId == w.id) {
      return DialogueContext.harvesting;
    }
    return null;
  }

  bool matches(WorkerDialogueDefinition d, Worker w) {
    if (!d.allowedWorkers.contains(w.id) ||
        !d.allowedStates.contains(context(w))) {
      return false;
    }
    return !d.requiresNearbyTurhan ||
        workers().any(
          (other) =>
              other.id == 'turhan' &&
              pow(other.gridPosition.x - w.gridPosition.x, 2) +
                      pow(other.gridPosition.y - w.gridPosition.y, 2) <=
                  DialogueConfig.nearbyTiles * DialogueConfig.nearbyTiles,
        );
  }

  List<WorkerDialogueDefinition> candidates(Worker w) {
    final recent = _recent[w.id] ?? [];
    final valid = workerDialogues
        .where(
          (d) =>
              matches(d, w) &&
              (recent.isEmpty || recent.last != d.id) &&
              (!_phraseUsed.containsKey('${w.id}:${d.id}') ||
                  now - _phraseUsed['${w.id}:${d.id}']! >= d.cooldown),
        )
        .toList();
    final fresh = valid.where((d) => !recent.contains(d.id)).toList();
    return fresh.isNotEmpty ? fresh : valid;
  }

  WorkerDialogueDefinition weighted(List<WorkerDialogueDefinition> choices) {
    final top = choices.map((d) => d.priority).reduce(max);
    final pool = choices.where((d) => d.priority == top).toList();
    var draw = random.nextInt(pool.fold(0, (sum, d) => sum + d.weight));
    for (final d in pool) {
      draw -= d.weight;
      if (draw < 0) return d;
    }
    return pool.last;
  }

  void _start(Worker w, WorkerDialogueDefinition d) {
    active = WorkerSpeech(w, d, now);
    _lastSpoken[w.id] = now;
    _phraseUsed['${w.id}:${d.id}'] = now;
    final recent = _recent.putIfAbsent(w.id, () => []);
    recent.add(d.id);
    if (recent.length > 2) recent.removeAt(0);
    _next[w.id] = active!.endsAt + randomDelay(first: false);
  }

  void update(
    Duration simulationTime, {
    bool suppressed = false,
    double zoom = 1,
  }) {
    if (simulationTime < now) {
      throw ArgumentError('Konuşma zamanı geriye gidemez.');
    }
    final advanced = simulationTime > now;
    now = simulationTime;
    final owned = workers();
    if (advanced) {
      _moving.clear();
      for (final w in owned) {
        final old = _previous[w.id];
        if (old != null &&
            (old.x - w.gridPosition.x).abs() +
                    (old.y - w.gridPosition.y).abs() >
                1e-8) {
          _moving.add(w.id);
        }
        _previous[w.id] = w.gridPosition;
      }
    }
    _suppressed = suppressed || zoom < DialogueConfig.minZoom;
    if (!enabled || _suppressed) {
      active = null;
      _resumePending = true;
      return;
    }
    for (final w in owned) {
      if (_resumePending || !_next.containsKey(w.id)) {
        _next[w.id] = now + randomDelay(first: true);
      }
    }
    if (_resumePending) _globalReady = now + DialogueConfig.globalCooldown;
    _resumePending = false;
    final speech = active;
    if (speech != null) {
      if (now >= speech.endsAt ||
          !owned.contains(speech.worker) ||
          !matches(speech.definition, speech.worker)) {
        active = null;
        _globalReady = now + DialogueConfig.globalCooldown;
      } else {
        return;
      }
    }
    if (!advanced || now < _globalReady) return;
    final due = owned
        .where((w) => now >= _next[w.id]! && candidates(w).isNotEmpty)
        .toList();
    due.sort((a, b) {
      final order = (_lastSpoken[a.id] ?? const Duration(seconds: -1))
          .compareTo(_lastSpoken[b.id] ?? const Duration(seconds: -1));
      return order != 0 ? order : a.id.compareTo(b.id);
    });
    if (due.isNotEmpty) _start(due.first, weighted(candidates(due.first)));
  }

  /// Only development scenes call this; eligibility is still checked.
  bool preview(String workerId, String phraseId) {
    if (!enabled || _suppressed || active != null) return false;
    final owned = workers().where((w) => w.id == workerId);
    final phrases = workerDialogues.where((d) => d.id == phraseId);
    if (owned.isEmpty ||
        phrases.isEmpty ||
        !matches(phrases.single, owned.single)) {
      return false;
    }
    _start(owned.single, phrases.single);
    return true;
  }

  double get opacity {
    final s = active;
    if (s == null) return 0;
    return min(
      (now - s.startedAt).inMilliseconds / 160,
      (s.endsAt - now).inMilliseconds / 200,
    ).clamp(0.0, 1.0);
  }

  double get scale => .96 + .04 * opacity;
}
