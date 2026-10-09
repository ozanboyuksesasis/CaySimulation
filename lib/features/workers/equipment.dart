import '../../game/systems/game_assets.dart';

enum EquipmentType { none, teaShears, teaHarvesterMotor }

class EquipmentDefinition {
  const EquipmentDefinition(
    this.type,
    this.name,
    this.assetPath,
    this.cost,
    this.duration,
    this.description, {
    this.requiredLevel = 1,
  });
  final EquipmentType type;
  final String name, assetPath, description;
  final int cost;
  final int requiredLevel;
  final Duration duration;
}

const equipmentCatalog = [
  EquipmentDefinition(
    EquipmentType.teaShears,
    'Çay Makası',
    GameAssets.teaShears,
    250,
    Duration(seconds: 5),
    'Çay hasadı için temel ekipman.',
  ),
  EquipmentDefinition(
    EquipmentType.teaHarvesterMotor,
    'Çay Motoru',
    GameAssets.teaHarvesterMotor,
    2500,
    Duration(milliseconds: 2500),
    'Çayı daha hızlı toplar.',
    requiredLevel: 6,
  ),
];
EquipmentDefinition equipmentDefinition(EquipmentType type) =>
    equipmentCatalog.singleWhere((e) => e.type == type);
String equipmentName(EquipmentType type) =>
    type == EquipmentType.none ? 'Yok' : equipmentDefinition(type).name;
