/// Paths relative to AssetCatalog's image root. Only reviewed V3 pieces belong
/// here; source sheets and rejected crops remain in the development archive.
abstract final class GameAssets {
  static const packaging = 'buildings/36_PACKAGING_FACTORY.png';
  static const teaShop = 'buildings/10_VILLAGE_TEA_SHOP.png';
  static const customer = 'characters/23_VILLAGE_ELDER.png';
  static const fieldEmpty = 'fields/01_FIELD_EMPTY.png';
  static const fieldPlanted = 'fields/02_FIELD_PLANTED.png';
  static const fieldGrowing = 'fields/03_FIELD_GROWING.png';
  static const fieldReady = 'fields/04_FIELD_HARVEST.png';
  static const farmerHouse = 'buildings/05_FARMER_HOUSE.png';
  static const warehouse = 'buildings/06_TEA_WAREHOUSE.png';
  static const factory = 'buildings/09_TEA_FACTORY.png';
  static const collectionCenter = 'buildings/35_TEA_COLLECTION_CENTER.png';
  static const market = 'buildings/39_MARKET.png';
  static const well = 'infrastructure/12_VILLAGE_WELL.png';
  static const transportTruck = 'vehicles/14_TEA_TRANSPORT_TRUCK.png';
  static const farmerMale = 'characters/15_FARMER_MALE.png';
  static const farmerFemale = 'characters/16_FARMER_FEMALE.png';
  static const teaShears = 'equipment/34_TEA_SHEARS.png';
  static const teaHarvesterMotor = 'equipment/33_TEA_HARVESTER_MOTOR.png';

  // Scenic pieces, not a complete modular road set. Logical road drawing and
  // traversal remain unchanged. The straight piece also serves as shop artwork.
  static const roadStraight = 'tiles/roads/road_straight_horizontal.png';
  static const roadGate = 'tiles/roads/road_gate.png';
  static const roadShrub = 'tiles/roads/road_shrub.png';
  static const roadTreeSmall = 'tiles/roads/road_tree_small.png';
  static const roadPieces = [roadStraight, roadGate, roadShrub, roadTreeSmall];

  static const pathPlatform = 'tiles/paths/path_platform.png';
  static const pathRaisedPlatform = 'tiles/paths/path_raised_platform.png';
  static const pathSteps = 'tiles/paths/path_steps.png';
  static const pathPieces = [pathPlatform, pathRaisedPlatform, pathSteps];

  static const teaSackEmptyFolded = 'items/tea_sacks/tea_sack_empty_folded.png';
  static const teaSackSpilling = 'items/tea_sacks/tea_sack_spilling.png';
  static const teaSackQuarter = 'items/tea_sacks/tea_sack_quarter.png';
  static const teaSackHalf = 'items/tea_sacks/tea_sack_half.png';
  static const teaSackFull = 'items/tea_sacks/tea_sack_full.png';
  static const teaSacks = [
    teaSackEmptyFolded,
    teaSackSpilling,
    teaSackQuarter,
    teaSackHalf,
    teaSackFull,
  ];

  static const teaBasketEmptySmall =
      'items/tea_baskets/tea_basket_empty_small.png';
  static const teaBasketEmptyLarge =
      'items/tea_baskets/tea_basket_empty_large.png';
  static const teaBasketBackFull = 'items/tea_baskets/tea_basket_back_full.png';
  static const teaBasketQuarter = 'items/tea_baskets/tea_basket_quarter.png';
  static const teaBasketHalf = 'items/tea_baskets/tea_basket_half.png';
  static const teaBasketFull = 'items/tea_baskets/tea_basket_full.png';
  static const teaBaskets = [
    teaBasketEmptySmall,
    teaBasketEmptyLarge,
    teaBasketBackFull,
    teaBasketQuarter,
    teaBasketHalf,
    teaBasketFull,
  ];

  static const largeTree = 'decorations/large_tree.png';
  static const woodenFence = 'decorations/wooden_fence.png';
  static const woodenGate = 'decorations/wooden_gate.png';
  static const stackedFirewood = 'decorations/stacked_firewood.png';
  static const decorations = [
    largeTree,
    woodenFence,
    woodenGate,
    stackedFirewood,
  ];

  // No safe separated pieces in these V3 groups; do not expose damaged crops.
  static const wallPieces = <String>[];
  static const streamPieces = <String>[];
  static const teaPackages = <String>[];

  static const preparedPieces = [
    ...roadPieces,
    ...pathPieces,
    ...teaSacks,
    ...teaBaskets,
    ...decorations,
  ];
}
