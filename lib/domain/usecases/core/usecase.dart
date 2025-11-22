import 'package:fpdart/fpdart.dart';

import '../../core/error/failures.dart';

/// Interfaz base para todos los casos de uso asíncronos
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

/// Caso de uso sin parámetros
abstract class NoParamsUseCase<Type> {
  Future<Either<Failure, Type>> call();
}

/// Caso de uso que retorna un Stream
abstract class StreamUseCase<Type, Params> {
  Stream<Either<Failure, Type>> call(Params params);
}

/// Caso de uso que retorna un Stream sin parámetros
abstract class NoParamsStreamUseCase<Type> {
  Stream<Either<Failure, Type>> call();
}
