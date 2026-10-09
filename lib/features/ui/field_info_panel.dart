import 'package:flutter/material.dart';

import '../plantation/field_visuals.dart';
import '../plantation/plantation_config.dart';
import '../plantation/plantation_system.dart';
import '../plantation/tea_field.dart';
import '../workers/job_system.dart';
import '../workers/harvest_job.dart';

class FieldInfoPanel extends StatelessWidget {
  const FieldInfoPanel({
    required this.field,
    required this.system,
    required this.jobs,
    this.notify,
    this.showDebug = false,
    this.manualControls = true,
    super.key,
  });
  final TeaField field;
  final PlantationSystem system;
  final JobSystem jobs;
  final ValueChanged<String>? notify;
  final bool showDebug;
  final bool manualControls;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([field, jobs]),
    builder: (context, _) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        Text(
          'Durum: ${jobs.jobForField(field.id)?.status == JobStatus.inProgress
              ? 'Hasat yapılıyor'
              : field.state == TeaFieldState.harvested && field.harvestedStockKg == 0
              ? 'Yeniden büyüyor'
              : fieldStateNames[field.state]}',
        ),
        if (field.stageDuration != null && !showDebug)
          Text('Büyüyor · %${(field.overallProgress * 100).floor()}'),
        if (field.harvestedStockKg > 0)
          Text('Tarlada Bekleyen Yaş Çay: ${field.harvestedStockKg} kg'),
        if (showDebug && field.harvestedStockKg > 0) ...[
          Text(
            'Tarlada ${field.harvestedStockKg} kg yaş çay toplanmayı bekliyor.',
          ),
        ],
        if (field.state == TeaFieldState.empty) ...[
          const Text('Dikim bedeli: ${PlantationConfig.plantingCost} Altın'),
          const SizedBox(height: 6),
          FilledButton(
            key: const ValueKey('plant-field'),
            onPressed: system.plantingRestriction?.call(field) != null
                ? null
                : () {
                    final result = system.plant(field);
                    if (result == PlantResult.insufficientGold) {
                      if (notify != null) {
                        notify!('Yeterli altının yok.');
                        return;
                      }
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(
                            content: Text('Yeterli altının yok.'),
                            duration: Duration(seconds: 3),
                          ),
                        );
                    }
                  },
            child: const Text('Çay Dik'),
          ),
          if (system.plantingRestriction?.call(field) != null)
            Text(
              system.plantingRestriction!.call(field)!,
              style: const TextStyle(fontSize: 11),
            ),
        ],
        if (field.stageDuration != null && showDebug) ...[
          const SizedBox(height: 6),
          Text(
            field.state == TeaFieldState.harvested
                ? 'Yeniden büyüyor...'
                : 'Büyüme',
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: field.progress,
            semanticsLabel: 'Büyüme ilerlemesi',
            semanticsValue: '${(field.progress * 100).floor()}',
          ),
          Text(
            '%${(field.progress * 100).floor()} • Sonraki aşama: ${field.remainingSeconds} sn',
            style: const TextStyle(fontSize: 12),
          ),
        ],
        if (field.state == TeaFieldState.ready) ...[
          if (showDebug) Text('Tahmini ürün: ${field.yieldAmount} kg Yaş Çay'),
          const SizedBox(height: 6),
          if (!manualControls && jobs.jobForField(field.id)?.isActive != true)
            const Text('İşçi Bekliyor'),
          if (manualControls && jobs.jobForField(field.id)?.isActive != true)
            FilledButton(
              key: const ValueKey('harvest-field'),
              onPressed: () {
                jobs.requestHarvest(field);
                if (jobs.requestFailure != null) {
                  notify?.call(jobs.requestFailure!);
                }
              },
              child: const Text('Hasat Et'),
            ),
          if (jobs.jobForField(field.id)?.status == JobStatus.queued)
            const Text('Hasat sırası bekliyor'),
          if (jobs.jobForField(field.id)?.status == JobStatus.assigned)
            Text(
              '${jobs.assignedWorker(jobs.jobForField(field.id))?.name} tarlaya geliyor',
            ),
          if (jobs.jobForField(field.id)?.status == JobStatus.inProgress) ...[
            Text(
              'İşçi: ${jobs.assignedWorker(jobs.jobForField(field.id))?.name}',
            ),
            const Text('Hasat'),
            LinearProgressIndicator(
              value: jobs.progress(jobs.jobForField(field.id)!),
              semanticsLabel: 'Hasat ilerlemesi',
            ),
            Text(
              'Kalan süre: ${jobs.remainingSeconds(jobs.jobForField(field.id)!)} sn',
            ),
          ],
          if (jobs.jobForField(field.id)?.status == JobStatus.failed)
            Text(jobs.jobForField(field.id)!.failureMessage!),
        ],
        const SizedBox(height: 4),
        if (showDebug)
          Text(
            'Hasat sayısı: ${field.harvestCount}',
            style: const TextStyle(fontSize: 11),
          ),
      ],
    ),
  );
}
