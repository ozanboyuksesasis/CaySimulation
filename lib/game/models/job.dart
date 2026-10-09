enum JobStatus {
  queued,
  assigned,
  inProgress,
  movingToSource,
  loading,
  movingToDestination,
  unloading,
  completed,
  failed,
}

abstract class Job {
  Job({required this.id, required this.createdAt});
  final String id;
  final Duration createdAt;
  JobStatus status = JobStatus.queued;
  String? failureMessage;
  bool get isActive =>
      status != JobStatus.completed && status != JobStatus.failed;
}
