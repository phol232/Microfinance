# Análisis de arquitectura – `apps/mobile/lib`

## 1. Visión general

El árbol principal ya intenta replicar una arquitectura limpia (`config`, `core`, `data`, `domain`, `infrastructure`, `presentation`), pero varias responsabilidades están cruzadas entre capas. La mayor parte de la lógica vive en `main.dart`, `data/*`, `domain/*` y `presentation/*`, mientras que `core/` contiene servicios híbridos que actúan como “catch-all” cuando una pieza no tiene ubicación clara. Para evaluar el grado de alineamiento con Clean Architecture se revisaron los archivos clave dentro de cada carpeta.

## 2. Observaciones por capa

### Dominio (`domain/`)
- **Entidades acopladas a Firestore**: se migraron `account`, `user`, `card`, `financial_transaction` y `loan_application` a DTOs en `data/models`, retirando `cloud_firestore` del dominio. Aún quedan entidades con `fromFirestore` para completar.
- **Casos de uso inconsistentes**: la base `domain/usecases/core/usecase.dart` ahora retorna `Either<Failure, T>` y `AccountBloc`/`CardBloc` consumen exclusivamente casos de uso. Otros BLoCs siguen invocando repositorios o servicios concretos sin pasar por un `UseCase`.
- **Errores declarados pero no utilizados**: `domain/core/error/failures.dart` define jerarquía de errores, sin embargo el flujo termina propagando excepciones de Firebase/HTTP desde la capa de datos.

### Datos (`data/`)
- **DataSources remotos**: `AccountDataSource`, `LoanApplicationDataSource`, `CardDataSource` y `TransactionDatasource` usan DTOs dedicados, separando mapeo de dominio. Falta extender el patrón al resto de colecciones.
- **Dependencias hacia `core/tenant`**: los data sources usan `domain/services/tenant_resolver.dart`, retirando la dependencia directa a `core`.
- **Carpeta `data/services` vacía**: sigue sin contenido/documentación.

### Infraestructura (`infrastructure/`)
- `services/` concentra ahora los servicios concretos (ubicación, chatbot, biometría, carrito, transacciones, productos de crédito). Falta aislar dependencias externas detrás de interfaces de dominio/aplicación.

### Núcleo (`core/`)
- `core/services` se eliminó en favor de `infrastructure/services`. `TenantController` sigue siendo `ChangeNotifier` y contenedor de estado de tenant; idealmente debería separarse implementación y contrato.
- `core/di` ahora contiene `app_di.dart` con la construcción centralizada de repositorios/use cases.

### Presentación (`presentation/`)
- El cableado se mueve a `core/di/app_di.dart`, consumido desde `main.dart`. Aún faltan módulos por contexto/feature.
- `presentation/services` se eliminó; la UI ahora importa desde `infrastructure/services`, aunque sigue existiendo lógica de aplicación allí.
- `AccountBloc` y `CardBloc` usan casos de uso con `Either`; otros widgets/blocs siguen llamando repositorios/servicios directamente.

### Configuración y scripts
- `config/api_config.dart` elige URLs a partir de variables de entorno y `dart:io Platform`. El archivo está bien aislado, pero al estar en la raíz de `lib/` se importa desde cualquier capa, lo cual puede provocar que dominio/infra dependan implícitamente del entorno de Flutter.
- `scripts/` está vacío y sin documentación.

## 3. Principales brechas frente a Clean Architecture

1. **Dominio aún parcialmente dependiente**: Falta migrar las entidades restantes con `fromFirestore`/`toFirestore` a DTOs para aislar el dominio totalmente.
2. **DTOs/mappers incompletos**: El patrón ya existe para cuentas, tarjetas, transacciones y aplicaciones de préstamo; debe extenderse a las colecciones restantes.
3. **Servicios fuera de lugar**: Aunque se centralizaron en `infrastructure/services`, siguen mezclando reglas de negocio y dependencias externas. Se necesitan interfaces de dominio y casos de uso que los orquesten.
4. **Inyección de dependencias incompleta**: `core/di/app_di.dart` centraliza dependencias, pero faltan módulos por feature y soporte de mocks/tests.
5. **Uso inconsistente de casos de uso**: `AccountBloc` y `CardBloc` ya usan casos de uso con `Either<Failure, T>`, pero otros bloques/servicios aún llaman repositorios o servicios concretos.
6. **Capas con responsabilidades mezcladas**: `TenantController` sigue combinando UI (`ChangeNotifier`) y resolución de tenant consumida por data sources; debe dividirse contrato/implementación.
7. **Persistencia desde servicios UI**: Servicios como `CartService`/`PaymentCardService` siguen escribiendo almacenamiento sin pasar por repositorios/use cases; requieren refactor para facilitar tests y mocks.

## 4. Recomendaciones

1. **Separar entidades de la infraestructura**  
   - Crear DTOs en `data/models` para cada colección (AccountDto, UserDto, etc.) y mover allí los métodos `fromFirestore`/`toFirestore`.  
   - Hacer que las entidades de `domain/entities` usen únicamente tipos del SDK de Dart, introduciendo value objects cuando sea necesario.

2. **Definir una capa de aplicación (use cases) coherente**  
   - Asegurarse de que toda interacción de la UI pase por un caso de uso.  
   - Actualizar los casos de uso para devolver `Either<Failure, Entity>` (por ejemplo con `fpdart`) y aprovechar `Failure` en lugar de excepciones.

3. **Reubicar servicios según su responsabilidad**  
   - Mover `TransactionService`, `ChatBotService`, `CartService` y cualquier servicio con dependencias externas a `infrastructure/` (o a un nuevo módulo `application/services`) y exponer interfaces en dominio/aplicación.  
   - Mantener `core/` solamente para utilitarios libres de dependencias (helpers, constantes).

4. **Introducir un módulo real de DI**  
   - Completar `core/di` con configuraciones (ej. usando `get_it`/`injectable`) para registrar repositorios, data sources y servicios.  
   - En `main.dart`, pedir instancias al contenedor en lugar de crear dependencias manualmente.

5. **Aislar TenantResolver**  
   - Definir `TenantResolver` en el dominio (o capa de aplicación) como una interfaz pura, y mover `TenantController` a `infrastructure/tenant` donde pueda depender de Flutter/almacenamiento.  
   - Inyectar `TenantResolver` en data sources a través del contenedor, evitando importar clases de Flutter.

6. **Ordenar carpetas vacías y documentación**  
   - Completar o eliminar `data/services`, `scripts/` y cualquier carpeta sin contenido para evitar confusión.  
   - Documentar en un README por carpeta qué responsabilidad cumple.

7. **Automatizar validaciones**  
   - Añadir pruebas unitarias para los casos de uso y pruebas de integración para los data sources (idealmente contra emuladores de Firebase).  
   - Integrar un analizador estático (por ejemplo `very_good_analysis`) para reforzar las dependencias permitidas entre capas.

Adoptar estos pasos permitirá acercar el proyecto a una arquitectura limpia real, reduciendo el acoplamiento con Firebase/Flutter y facilitando la reutilización del dominio en otros clientes (web, escritorio, servicios).
