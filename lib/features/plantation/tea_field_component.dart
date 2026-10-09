import '../../game/components/world_entity.dart';
import '../../game/systems/asset_catalog.dart';
import 'field_visuals.dart';
import 'tea_field.dart';

class TeaFieldComponent extends WorldEntity {
  TeaFieldComponent({
    required super.definition,
    required super.grid,
    required this.field,
    required this.catalog,
  });
  final TeaField field;
  final AssetCatalog catalog;
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    field.addListener(_syncSprite);
    _syncSprite();
  }

  void _syncSprite() {
    sprite = catalog.sprite(fieldAssets[field.state]);
  }

  @override
  void onRemove() {
    field.removeListener(_syncSprite);
    super.onRemove();
  }
}
