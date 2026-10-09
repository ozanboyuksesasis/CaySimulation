import '../../game/world/isometric_grid.dart';
import '../../game/systems/game_assets.dart';
import '../economy/business_config.dart';

enum BuildCategory {
  agriculture,
  workers,
  equipment,
  production,
  logistics,
  infrastructure,
  decoration,
}

enum BuildType {
  field,
  collectionCenter,
  factory,
  packaging,
  teaShop,
  warehouse,
  road,
  decoration,
  house,
  market,
}

const categoryNames = {
  BuildCategory.agriculture: 'Tarım',
  BuildCategory.workers: 'İşçiler',
  BuildCategory.equipment: 'Ekipman',
  BuildCategory.production: 'Üretim',
  BuildCategory.logistics: 'Lojistik',
  BuildCategory.infrastructure: 'Altyapı',
  BuildCategory.decoration: 'Dekorasyon',
};

class BuildCatalogItem {
  const BuildCatalogItem({
    required this.id,
    required this.displayName,
    required this.category,
    required this.description,
    required this.assetPath,
    required this.footprint,
    required this.goldCost,
    required this.buildType,
    required this.visualWidth,
    required this.visualHeight,
    this.requiredRoadAccess = false,
    this.uniqueLimit,
    this.movable = true,
    this.requiredLevel = 1,
  });
  final String id, displayName, description, assetPath;
  final BuildCategory category;
  final Footprint footprint;
  final int goldCost;
  final int requiredLevel;
  final BuildType buildType;
  final double visualWidth, visualHeight;
  final bool requiredRoadAccess, movable;
  final int? uniqueLimit;
}

const buildCatalog = [
  BuildCatalogItem(
    id: 'field',
    displayName: 'Çay Tarlası',
    category: BuildCategory.agriculture,
    description: 'Yaş çay üretimi için kullanılır.',
    assetPath: GameAssets.fieldEmpty,
    footprint: Footprint(2, 2),
    goldCost: 500,
    buildType: BuildType.field,
    visualWidth: 240,
    visualHeight: 155,
  ),
  BuildCatalogItem(
    id: 'collection_center',
    displayName: 'Çay Alım Yeri',
    category: BuildCategory.logistics,
    description: 'Yaş çayı toplar; kamyonu kullanıma açar.',
    assetPath: GameAssets.collectionCenter,
    footprint: Footprint(3, 2),
    goldCost: 2500,
    buildType: BuildType.collectionCenter,
    visualWidth: 285,
    visualHeight: 230,
    requiredRoadAccess: true,
    uniqueLimit: 1,
  ),
  BuildCatalogItem(
    id: 'factory',
    requiredLevel: BusinessConfig.industrialLevel,
    displayName: 'Çay Fabrikası',
    category: BuildCategory.production,
    description: 'Yaş çayı kuru çaya dönüştürür.',
    assetPath: GameAssets.factory,
    footprint: Footprint(3, 3),
    goldCost: 4000,
    buildType: BuildType.factory,
    visualWidth: 365,
    visualHeight: 315,
    requiredRoadAccess: true,
    uniqueLimit: 1,
  ),
  BuildCatalogItem(
    id: 'warehouse',
    requiredLevel: 3,
    displayName: 'Depo',
    category: BuildCategory.logistics,
    description: 'Gelecekteki depolama işleri için yapı.',
    assetPath: GameAssets.warehouse,
    footprint: Footprint(2, 1),
    goldCost: 1500,
    buildType: BuildType.warehouse,
    visualWidth: 245,
    visualHeight: 205,
    requiredRoadAccess: true,
  ),
  BuildCatalogItem(
    id: 'road',
    displayName: 'Toprak Yol',
    category: BuildCategory.infrastructure,
    description: 'Kamyon için bağlantı kurar. Karo başına.',
    assetPath: GameAssets.roadStraight,
    footprint: Footprint(1, 1),
    goldCost: 25,
    buildType: BuildType.road,
    visualWidth: 128,
    visualHeight: 64,
    movable: false,
  ),
  BuildCatalogItem(
    id: 'well',
    displayName: 'Köy Kuyusu',
    category: BuildCategory.decoration,
    description: 'Bahçene köy havası katan süs kuyusu.',
    assetPath: GameAssets.well,
    footprint: Footprint(1, 1),
    goldCost: 50,
    buildType: BuildType.decoration,
    visualWidth: 95,
    visualHeight: 105,
  ),
  BuildCatalogItem(
    id: 'packaging',
    displayName: 'Paketleme Tesisi',
    category: BuildCategory.production,
    description: '20 kg kuru çayı 20 adet 1 kg pakete dönüştürür.',
    assetPath: GameAssets.packaging,
    footprint: Footprint(2, 2),
    goldCost: BusinessConfig.packagingCost,
    buildType: BuildType.packaging,
    visualWidth: 270,
    visualHeight: 230,
    requiredRoadAccess: true,
    uniqueLimit: 1,
    requiredLevel: BusinessConfig.industrialLevel,
  ),
  BuildCatalogItem(
    id: 'tea_shop',
    displayName: 'Çay Dükkânı',
    category: BuildCategory.logistics,
    description: 'Müşteriler paket çay satın alır.',
    assetPath: GameAssets.teaShop,
    footprint: Footprint(2, 2),
    goldCost: BusinessConfig.retailCost,
    buildType: BuildType.teaShop,
    visualWidth: 230,
    visualHeight: 210,
    requiredRoadAccess: true,
    uniqueLimit: 1,
    requiredLevel: BusinessConfig.retailLevel,
  ),
];
const houseCatalogItem = BuildCatalogItem(
  id: 'house',
  displayName: 'Çiftlik Evi',
  category: BuildCategory.infrastructure,
  description: 'Çiftliğin başlangıç evi.',
  assetPath: GameAssets.farmerHouse,
  footprint: Footprint(2, 2),
  goldCost: 0,
  buildType: BuildType.house,
  visualWidth: 245,
  visualHeight: 235,
  movable: false,
);
const marketCatalogItem = BuildCatalogItem(
  id: 'market',
  displayName: 'Pazar',
  category: BuildCategory.logistics,
  description: 'Test haritası yapısı.',
  assetPath: GameAssets.market,
  footprint: Footprint(2, 2),
  goldCost: 0,
  buildType: BuildType.market,
  visualWidth: 260,
  visualHeight: 220,
);
BuildCatalogItem catalogItem(String id) => [
  ...buildCatalog,
  houseCatalogItem,
  marketCatalogItem,
].singleWhere((e) => e.id == id);
