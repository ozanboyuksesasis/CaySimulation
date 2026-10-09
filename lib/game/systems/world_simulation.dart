import '../../features/workers/job_system.dart';
import '../../features/transport/transport_system.dart';
import '../../features/buildings/tea_factory.dart';
import 'automation_system.dart';
import 'retail_system.dart';

/// Both executors see the same elapsed time. Splitting at state boundaries keeps
/// stock transfers and the crop regeneration timestamp independent of frame rate.
class WorldSimulation {
  WorldSimulation({
    required this.workers,
    required this.transport,
    this.automation,
    this.retail,
  });
  final AutomationSystem? automation;
  final RetailSystem? retail;
  final JobSystem workers;
  final TransportSystem transport;
  void advance(Duration elapsed) {
    if (elapsed.isNegative) throw ArgumentError('Süre negatif olamaz.');
    var left = elapsed;
    automation?.tick();
    while (left > Duration.zero) {
      var step = retail != null && left > const Duration(milliseconds: 50)
          ? const Duration(milliseconds: 50)
          : left;
      for (final event in [
        workers.timeToNextEvent,
        transport.timeToNextEvent,
        if (automation?.enabled == true)
          ...workers.plantation.fields
              .where((f) => f.stageDuration != null)
              .map((f) => f.remaining),
        if (transport.factory?.state == FactoryState.processing)
          transport.factory!.remaining,
      ]) {
        if (event != null && event > Duration.zero && event < step) {
          step = event;
        }
      }
      workers.advance(step);
      transport.factory?.advance(step);
      transport.advance(step);
      retail?.advance(step, automatic: automation?.enabled == true);
      left -= step;
      automation?.tick();
      if (automation?.enabled == true) retail?.tick();
    }
  }
}
