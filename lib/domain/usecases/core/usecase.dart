/// Interfaz base para todos los casos de uso
abstract class UseCase<Type, Params> {
  Future<Type> call(Params params);
}

/// Caso de uso sin parámetros
abstract class NoParamsUseCase<Type> {
  Future<Type> call();
}

/// Caso de uso que retorna un Stream
abstract class StreamUseCase<Type, Params> {
  Stream<Type> call(Params params);
}

/// Caso de uso que retorna un Stream sin parámetros
abstract class NoParamsStreamUseCase<Type> {
  Stream<Type> call();
}