import '../../game/models/job.dart';
import '../../game/systems/grid_pathfinder.dart';
export '../../game/models/job.dart';

enum TransportLocation { field, collectionCenter, factory }

class TransportJob extends Job {
  TransportJob({
    required super.id,
    required super.createdAt,
    required String fieldId,
    required this.sourcePosition,
    required this.destinationId,
  }) : fieldId = fieldId,
       sourceId = fieldId,
       sourceType = TransportLocation.field,
       destinationType = TransportLocation.collectionCenter,
       requestedAmountKg = null;
  TransportJob.factoryShipment({
    required super.id,
    required super.createdAt,
    required this.sourceId,
    required this.sourcePosition,
    required this.destinationId,
    required int amountKg,
  }) : fieldId = null,
       sourceType = TransportLocation.collectionCenter,
       destinationType = TransportLocation.factory,
       requestedAmountKg = amountKg;
  final String? fieldId;
  final String sourceId;
  final TransportLocation sourceType;
  final TransportLocation destinationType;
  final int? requestedAmountKg;
  bool get isFactoryShipment => destinationType == TransportLocation.factory;
  final GridTile sourcePosition;
  final String destinationId;
  String? vehicleId;
  int amountKg = 0;
  int deliveredKg = 0;
  Duration phaseElapsed = Duration.zero;
  Map<String, Object?> toJson() => {
    'id': id,
    'fieldId': fieldId,
    'sourceId': sourceId,
    'sourceType': sourceType.name,
    'destinationType': destinationType.name,
    'requestedAmountKg': requestedAmountKg,
    'vehicleId': vehicleId,
    'sourceX': sourcePosition.x,
    'sourceY': sourcePosition.y,
    'destinationId': destinationId,
    'amountKg': amountKg,
    'deliveredKg': deliveredKg,
    'status': status.name,
    'createdAtMicros': createdAt.inMicroseconds,
    'phaseElapsedMicros': phaseElapsed.inMicroseconds,
    'failureMessage': failureMessage,
  };
}
