import '../../game/systems/game_assets.dart';
import 'tea_field.dart';

/// Actual master filenames take precedence over alternate pack numbering.
const fieldAssets = <TeaFieldState, String>{
  TeaFieldState.empty: GameAssets.fieldEmpty,
  TeaFieldState.planted: GameAssets.fieldPlanted,
  TeaFieldState.growing1: GameAssets.fieldGrowing,
  TeaFieldState.growing2: GameAssets.fieldGrowing,
  TeaFieldState.ready: GameAssets.fieldReady,
  TeaFieldState.harvested: GameAssets.fieldPlanted,
};

const fieldStateNames = <TeaFieldState, String>{
  TeaFieldState.empty: 'Boş',
  TeaFieldState.planted: 'Ekildi',
  TeaFieldState.growing1: 'Büyüyor — 1. aşama',
  TeaFieldState.growing2: 'Büyüyor — 2. aşama',
  TeaFieldState.ready: 'Hasada Hazır',
  TeaFieldState.harvested: 'Hasat Edildi',
};
