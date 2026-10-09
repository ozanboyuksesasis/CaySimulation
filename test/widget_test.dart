import 'package:cay_simulasyonu/features/economy/economy_state.dart';
import 'package:cay_simulasyonu/features/ui/game_hud.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Başlangıç bakiyesi ve Türkçe sayı biçimi', () {
    final state = EconomyState();
    expect(state.balance, 10000);
    expect(formatGold(state.balance), '10.000');
    state.dispose();
  });
  test('Ekonomi işlemleri atomik ve negatif miktarlara kapalı', () {
    final state = EconomyState();
    var notifications = 0;
    state.addListener(() => notifications++);
    expect(state.canAfford(10000), isTrue);
    expect(state.spend(10001), isFalse);
    expect(state.balance, 10000);
    expect(state.spend(10000), isTrue);
    expect(state.balance, 0);
    state.earn(75);
    expect(state.balance, 75);
    expect(notifications, 2);
    expect(() => state.spend(-1), throwsArgumentError);
    expect(() => state.earn(-1), throwsArgumentError);
    expect(() => state.canAfford(-1), throwsArgumentError);
    state.dispose();
  });
}
