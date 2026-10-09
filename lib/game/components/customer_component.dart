import 'dart:ui';

import '../models/entity_definition.dart';
import '../systems/retail_system.dart';
import 'world_entity.dart';

class CustomerComponent extends WorldEntity {
  CustomerComponent({required this.customer, required super.grid, super.sprite})
    : super(
        definition: EntityDefinition(
          id: customer.id,
          name: 'Müşteri',
          kind: EntityKind.character,
          gridPosition: customer.gridPosition,
          visualSize: const Size(58, 90),
        ),
      );
  final Customer customer;
  @override
  Offset get groundPosition => grid.toWorld(customer.gridPosition);
  @override
  void update(double dt) {
    setGridPosition(customer.gridPosition);
    super.update(dt);
  }
}
