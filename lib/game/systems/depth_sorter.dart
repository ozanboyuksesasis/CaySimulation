import '../components/world_entity.dart';

class DepthSorter {
  // Footprint separation resolves side approaches; ground Y/X/ID break ties.
  void sort(List<WorldEntity> entities) {
    final pending = [...entities]
      ..sort((a, b) {
        final y = a.depthY.compareTo(b.depthY);
        if (y != 0) return y;
        final x = a.groundPosition.dx.compareTo(b.groundPosition.dx);
        return x != 0 ? x : a.definition.id.compareTo(b.definition.id);
      });
    final before = {for (final e in pending) e: <WorldEntity>{}};
    for (var i = 0; i < pending.length; i++) {
      for (var j = i + 1; j < pending.length; j++) {
        final a = pending[i], b = pending[j];
        final ar = a.depthFootprint, br = b.depthFootprint;
        final ab = ar.right <= br.left || ar.bottom <= br.top;
        final ba = br.right <= ar.left || br.bottom <= ar.top;
        if (ab && !ba) before[b]!.add(a);
        if (ba && !ab) before[a]!.add(b);
      }
    }
    var priority = 1;
    while (pending.isNotEmpty) {
      // Ambiguous/cyclic flat sprites fall back to deterministic ground order.
      final next = pending.firstWhere(
        (e) => before[e]!.isEmpty,
        orElse: () => pending.first,
      );
      if (next.priority != priority) next.priority = priority;
      priority++;
      pending.remove(next);
      for (final e in pending) {
        before[e]!.remove(next);
      }
    }
  }
}
