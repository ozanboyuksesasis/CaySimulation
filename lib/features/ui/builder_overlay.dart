import 'package:flutter/material.dart';

import '../../game/cay_game.dart';
import '../builder/builder_system.dart';

class BuilderOverlay extends StatelessWidget {
  const BuilderOverlay({required this.game, super.key});
  final CayGame game;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([game.builder, game.playerInventory]),
    builder: (_, _) {
      final builder = game.builder;
      if (!builder.isPlacing) return const SizedBox.shrink();
      final moving = builder.mode == BuilderMode.movingExisting;
      final road = builder.mode == BuilderMode.placingRoad;
      final item = builder.selectedCatalogItem!;
      final result = builder.validationResult;
      return Positioned(
        left: 12,
        right: 12,
        bottom: 8,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Material(
              color: const Color(0xF517332F),
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${item.displayName} • ${moving
                          ? 'Ücretsiz taşıma'
                          : builder.paysOnPlacement
                          ? '${item.goldCost} Altın'
                          : 'Envanter: ${game.playerInventory.quantity(item.id)}'}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      builder.feedback ?? result.reason,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: result.valid
                            ? const Color(0xFF8CE8A2)
                            : const Color(0xFFFF9292),
                      ),
                    ),
                    Text(
                      road
                          ? 'Yol için dokun • Gezinmek için sürükle'
                          : 'Konuma dokun • Sürükle ve iki parmakla yakınlaş',
                      style: const TextStyle(fontSize: 12),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton.icon(
                          onPressed: builder.cancel,
                          icon: const Icon(Icons.close),
                          label: Text(moving ? 'Vazgeç' : 'İptal'),
                        ),
                        const SizedBox(width: 12),
                        FilledButton.icon(
                          onPressed: road
                              ? builder.cancel
                              : () {
                                  if (!builder.confirm()) {
                                    game.notifications.show(
                                      builder.feedback ??
                                          'Yerleştirme için uygun alan seç.',
                                    );
                                  }
                                },
                          icon: const Icon(Icons.check),
                          label: Text(
                            moving
                                ? 'Onayla'
                                : road
                                ? 'Bitir'
                                : 'Yerleştir',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
