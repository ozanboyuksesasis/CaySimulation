class PlantationConfig {
  static const plantingCost = 250;
  static const yieldKg = 25;
  static const plantedDuration = Duration(seconds: 5);
  static const growing1Duration = Duration(seconds: 5);
  static const growing2Duration = Duration(seconds: 40);
  static Duration get growthDuration =>
      plantedDuration + growing1Duration + growing2Duration;
  static const regenerationDuration = Duration(seconds: 5);
  static const notificationInterval = Duration(milliseconds: 100);
}
