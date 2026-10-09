import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../game/cay_game.dart';
import '../buildings/factory_config.dart';
import '../../game/systems/tutorial_system.dart';
import 'game_navigation.dart';

class TutorialCoach extends StatefulWidget {
  const TutorialCoach({required this.game, super.key});
  final CayGame game;
  @override
  State<TutorialCoach> createState() => _TutorialCoachState();
}

class _TutorialCoachState extends State<TutorialCoach> {
  bool minimized = true;
  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final tutorial = game.tutorial;
    if (tutorial == null) return const SizedBox.shrink();
    return ListenableBuilder(
      listenable: Listenable.merge([
        tutorial,
        game.panels,
        game.builder,
        game.showGrid,
      ]),
      builder: (_, _) {
        if (game.showGrid.value ||
            game.panels.panel != GamePanel.none ||
            game.builder.isPlacing) {
          return const SizedBox.shrink();
        }
        return Positioned(
          top: 56,
          right: 8,
          child: Container(
            width: math.min(240, MediaQuery.sizeOf(context).width * .29),
            constraints: BoxConstraints(
              maxHeight: math.max(155, MediaQuery.sizeOf(context).height * .32),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xEF17332F),
              border: Border.all(color: const Color(0xFFB8C887)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        tutorial.step == TutorialStep.completed
                            ? 'SIRADAKİ HEDEF'
                            : 'HEDEF',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: minimized ? 'Hedefi aç' : 'Hedefi küçült',
                      onPressed: () => setState(() => minimized = !minimized),
                      icon: Icon(
                        minimized ? Icons.expand_more : Icons.expand_less,
                      ),
                    ),
                  ],
                ),
                Flexible(
                  child: Text(
                    tutorial.message.split('\n').first,
                    key: const ValueKey('objective-summary'),
                    style: const TextStyle(fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 6),
                if (tutorial.step == TutorialStep.completed &&
                    tutorial.effectiveStep != TutorialStep.completed &&
                    tutorial.progression == ProgressionStep.accumulateInput)
                  Text(
                    '${tutorial.factoryInputKg} / ${FactoryConfig.inputKg} kg',
                    style: const TextStyle(fontSize: 11),
                  ),
                if (!minimized ||
                    tutorial.category != null ||
                    tutorial.targetEntityId != null ||
                    tutorial.step == TutorialStep.welcome ||
                    tutorial.step == TutorialStep.deliveryComplete) ...[
                  if (tutorial.message.contains('\n') &&
                      (!minimized ||
                          tutorial.step == TutorialStep.deliveryComplete))
                    Flexible(
                      child: SingleChildScrollView(
                        child: Text(
                          tutorial.message.contains('\n')
                              ? tutorial.message.split('\n').skip(1).join('\n')
                              : '',
                          key: const ValueKey('tutorial-message'),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  if (tutorial.step == TutorialStep.welcome)
                    FilledButton(
                      key: const ValueKey('tutorial-begin'),
                      onPressed: tutorial.begin,
                      child: const Text('Başlayalım'),
                    )
                  else if (tutorial.step == TutorialStep.deliveryComplete)
                    FilledButton(
                      key: const ValueKey('tutorial-finish'),
                      onPressed: tutorial.finish,
                      child: const Text('Devam Et'),
                    )
                  else if (tutorial.category != null)
                    FilledButton(
                      key: const ValueKey('tutorial-catalog'),
                      onPressed: () =>
                          game.panels.openCatalog(tutorial.category!),
                      child: const Text('Envanteri Aç'),
                    )
                  else if (tutorial.targetEntityId != null)
                    OutlinedButton(
                      key: const ValueKey('tutorial-show'),
                      onPressed: () =>
                          game.focusEntity(tutorial.targetEntityId!),
                      child: const Text('Göster'),
                    ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
