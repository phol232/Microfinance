import 'package:fpdart/fpdart.dart';
import '../core/error/failures.dart';

/// Interfaz base para casos de uso que requieren parámetros
abstract class UseCase<T, Params> {
  Future<Either<Failure, T>> call(Params params);
}

/// Interfaz base para casos de uso que no requieren parámetros
abstract class UseCaseNoParams<T> {
  Future<Either<Failure, T>> call();
}

/// Parámetros vacíos para casos de uso que no requieren parámetros
class NoParams {
  const NoParams();
}