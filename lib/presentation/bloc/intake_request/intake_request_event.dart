import 'package:equatable/equatable.dart';

abstract class IntakeRequestEvent extends Equatable {
  const IntakeRequestEvent();

  @override
  List<Object?> get props => [];
}

class IntakeRequestLoadRequested extends IntakeRequestEvent {
  const IntakeRequestLoadRequested();
}

class IntakeRequestLoadByStatus extends IntakeRequestEvent {
  final String status;

  const IntakeRequestLoadByStatus(this.status);

  @override
  List<Object?> get props => [status];
}

class IntakeRequestLoadRecent extends IntakeRequestEvent {
  final int limit;

  const IntakeRequestLoadRecent({this.limit = 10});

  @override
  List<Object?> get props => [limit];
}

class IntakeRequestLoadById extends IntakeRequestEvent {
  final String id;

  const IntakeRequestLoadById(this.id);

  @override
  List<Object?> get props => [id];
}

class IntakeRequestRefreshRequested extends IntakeRequestEvent {
  const IntakeRequestRefreshRequested();
}
