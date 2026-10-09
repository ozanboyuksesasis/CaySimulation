import 'package:flutter/material.dart';

import '../workers/job_system.dart';
import '../workers/worker.dart';
import '../workers/workforce_state.dart';
import '../workers/equipment.dart';

class WorkerInfoPanel extends StatelessWidget {
  const WorkerInfoPanel({
    required this.jobs,
    this.selectedWorker,
    this.workforce,
    this.notify,
    this.showDebug = false,
    super.key,
  });
  final JobSystem jobs;
  final Worker? selectedWorker;
  final WorkforceState? workforce;
  final ValueChanged<String>? notify;
  final bool showDebug;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([jobs, ?workforce]),
    builder: (_, _) {
      final worker = selectedWorker ?? jobs.worker;
      final job = jobs.jobForWorker(worker);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          if (showDebug) const Text('İşçi'),
          Text('Durum: ${workerStateNames[worker.state]}'),
          Text(
            'Seviye ${worker.workerLevel} · ${worker.workerXp} / ${worker.workerXpForNextLevel} XP',
          ),
          if (showDebug) Text('Görev: ${job == null ? 'Yok' : 'Çay hasadı'}'),
          Text('Ekipman: ${equipmentName(worker.equipment)}'),
          if (worker.canHarvest)
            Text(
              'Hasat: ${(worker.harvestDuration.inMilliseconds / 1000).toStringAsFixed(1).replaceAll('.', ',')} sn',
            ),
          if (workforce != null)
            OutlinedButton(
              key: const ValueKey('change-equipment'),
              onPressed:
                  worker.state != WorkerState.idle ||
                      workforce!.equipmentRestriction?.call(
                            worker,
                            EquipmentType.teaShears,
                          ) !=
                          null
                  ? null
                  : () => showModalBottomSheet<void>(
                      context: context,
                      useSafeArea: true,
                      builder: (sheetContext) => ListenableBuilder(
                        listenable: workforce!,
                        builder: (_, _) => SafeArea(
                          child: ListView(
                            shrinkWrap: true,
                            children: [
                              ListTile(
                                title: Text(
                                  '${worker.name} • Ekipman Değiştir',
                                ),
                              ),
                              for (final type in EquipmentType.values)
                                ListTile(
                                  key: ValueKey('equip-${type.name}'),
                                  title: Text(equipmentName(type)),
                                  subtitle: type == EquipmentType.none
                                      ? null
                                      : Text(
                                          'Boşta: ${workforce!.inventory.equipmentQuantity(type)}',
                                        ),
                                  enabled:
                                      workforce!.equipmentRestriction?.call(
                                            worker,
                                            type,
                                          ) ==
                                          null &&
                                      (type == EquipmentType.none ||
                                          workforce!.inventory
                                                  .equipmentQuantity(type) >
                                              0),
                                  onTap: () {
                                    final result = workforce!.equip(
                                      worker,
                                      type,
                                    );
                                    notify?.call(result.message);
                                    if (result.success) {
                                      Navigator.pop(sheetContext);
                                    }
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
              child: const Text('Ekipman'),
            ),
          if (showDebug)
            Text(
              'İşçi karosu: ${worker.gridPosition.x.floor()}, ${worker.gridPosition.y.floor()}',
            ),
          if (worker.state == WorkerState.working && job != null) ...[
            const Text('Hedef: Çay Tarlası'),
            Text('Kalan süre: ${jobs.remainingSeconds(job)} sn'),
            LinearProgressIndicator(
              value: jobs.progress(job),
              semanticsLabel: 'Hasat ilerlemesi',
            ),
          ],
        ],
      );
    },
  );
}
