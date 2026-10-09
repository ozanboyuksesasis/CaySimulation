import '../economy/economy_state.dart';
import '../economy/inventory_state.dart';
import 'plantation_config.dart';
import 'tea_field.dart';

enum PlantResult { planted, insufficientGold, invalidState, restricted }

class PlantationSystem {
  PlantationSystem({
    required this.economy,
    required this.inventory,
    required Iterable<TeaField> fields,
  }) : _fields = List.of(fields) {
    if (this.fields.map((field) => field.id).toSet().length !=
        this.fields.length) {
      throw ArgumentError('Tarla kimlikleri benzersiz olmalı.');
    }
  }
  final EconomyState economy;
  String? Function(TeaField field)? plantingRestriction;
  String? plantingFailure;
  final InventoryState inventory;
  final List<TeaField> _fields;
  List<TeaField> get fields => List.unmodifiable(_fields);
  void register(TeaField field) {
    if (_fields.any((f) => f.id == field.id)) {
      throw ArgumentError('Tarla kimliği zaten var.');
    }
    field.advanceTo(_now);
    _fields.add(field);
  }

  Duration _now = Duration.zero;
  Duration get simulationTime => _now;

  PlantResult plant(TeaField field) {
    plantingFailure = plantingRestriction?.call(field);
    if (plantingFailure != null) return PlantResult.restricted;
    if (!fields.contains(field) || field.state != TeaFieldState.empty) {
      return PlantResult.invalidState;
    }
    if (!economy.canAfford(PlantationConfig.plantingCost) ||
        !economy.spend(PlantationConfig.plantingCost)) {
      return PlantResult.insufficientGold;
    }
    field.plant(_now);
    return PlantResult.planted;
  }

  void advance(Duration elapsed) {
    if (elapsed.isNegative) throw ArgumentError('Süre negatif olamaz.');
    _now += elapsed;
    for (final field in fields) {
      field.advanceTo(_now);
    }
  }

  void dispose() {
    for (final field in fields) {
      field.dispose();
    }
  }
}
