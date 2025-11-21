# Análisis de arquitectura – `apps/mobile/lib`

## 1. Visión general

El árbol principal ya intenta replicar una arquitectura limpia (`config`, `core`, `data`, `domain`, `infrastructure`, `presentation`), pero varias responsabilidades están cruzadas entre capas. La mayor parte de la lógica vive en `main.dart`, `data/*`, `domain/*` y `presentation/*`, mientras que `core/` contiene servicios híbridos que actúan como “catch-all” cuando una pieza no tiene ubicación clara. Para evaluar el grado de alineamiento con Clean Architecture se revisaron los archivos clave dentro de cada carpeta.

## 2. Observaciones por capa

### Dominio (`domain/`)
- **Entidades acopladas a Firestore**: tanto `domain/entities/account.dart` como `domain/entities/user.dart` importan `cloud_firestore` y exponen `fromFirestore`/`toFirestore`, por lo que dependen de infraestructuras concretas y de `Timestamp`. El dominio deja de ser puro y obliga a que cualquier cambio en la base de datos impacte a la capa más alta.
- **Casos de uso inconsistentes**: existen interfaces base (`domain/usecases/core/usecase.dart`), pero varios BLoCs invocan repositorios concretos sin pasar por un `UseCase` (p. ej. actualización y borrado de cuentas en `presentation/bloc/account/account_bloc.dart`). Además, los casos de uso retornan entidades o listas sin envolver errores en `Either`/`Result`, dejando los fallos como excepciones genéricas.
- **Errores declarados pero no utilizados**: `domain/core/error/failures.dart` define jerarquía de errores, sin embargo el flujo termina propagando excepciones de Firebase/HTTP desde la capa de datos.

### Datos (`data/`)
- **DataSources remotos**: la carpeta `data/datasources` contiene clases específicas de Firebase (`AccountDataSource`, `LoanApplicationDataSource`, etc.) que mezclan consultas, mapeo y reglas de negocio menores. Al no existir DTOs ni mappers dedicados (excepto `app_user_mapper.dart`), los modelos de dominio se serializan directamente, duplicando lógica de conversión en las entidades.
- **Dependencias hacia `core/tenant`**: varios data sources reciben `TenantResolver` que vive en `core/tenant`. Esto introduce una dependencia invertida (infra → core → Flutter) que debería resolverse con interfaces definidas en dominio/aplicación y adaptadores en infraestructura.
- **Carpeta `data/services` vacía**: sugiere intención de aislar servicios adicionales, pero al estar vacía se pierde claridad sobre dónde extender la capa.

### Infraestructura (`infrastructure/`)
- Sólo contiene `services/credit_product_service.dart`, el cual también habla directamente con Firestore y construye entidades de dominio. El resto de servicios con dependencias externas (HTTP, plataforma, almacenamiento seguro, etc.) se desplazan a `core/services` o incluso `presentation/services`. Esta carpeta no está cumpliendo su propósito de alojar implementaciones concretas.

### Núcleo (`core/`)
- `core/services` aloja clases como `TransactionService` y `ChatBotService`. La primera coordina casos de uso **y además** formatea montos para la UI y escribe trazas (`print`), lo que rompe el aislamiento entre dominio/aplicación/presentación. La segunda realiza llamadas HTTP (`package:http`) y obtiene su configuración desde `config/api_config.dart`, responsabilidad más propia de infraestructura.
- `core/tenant/TenantController` extiende `ChangeNotifier` (dependencia de Flutter) pero también actúa como `TenantResolver`, siendo consumido incluso desde data sources. Este acoplamiento transversal dificulta testear e impide reutilizar la lógica fuera de Flutter.
- `core/di` está vacío, por lo que la inyección de dependencias queda dispersa en `main.dart` y en constructores manuales.

### Presentación (`presentation/`)
- Se usan BLoCs y Providers, pero el cableado de dependencias se hace en `main.dart` con creación manual de repositorios concretos (`AuthRepositoryImpl`, etc.), sin un contenedor o módulo de inyección reutilizable.
- La carpeta `presentation/services` incluye clases como `CartService` que persisten datos (SharedPreferences) y notifican a la UI. Esta lógica pertenece al caso de uso/aplicación y debería exponerse mediante repositorios + use cases para mantener la UI pasiva.
- Algunos widgets/blocs invocan directamente métodos de repositorio (`AccountRepository.updateAccount` o `getAccountsByStatus`) mezclando responsabilidades de aplicación y presentación.

### Configuración y scripts
- `config/api_config.dart` elige URLs a partir de variables de entorno y `dart:io Platform`. El archivo está bien aislado, pero al estar en la raíz de `lib/` se importa desde cualquier capa, lo cual puede provocar que dominio/infra dependan implícitamente del entorno de Flutter.
- `scripts/` está vacío y sin documentación.

## 3. Principales brechas frente a Clean Architecture

1. **Dominio no es independiente**: Entidades y casos de uso dependen de Firestore y Flutter (`cloud_firestore`, `Timestamp`, `ChangeNotifier`). Esto impide reutilizar la lógica y rompe la regla de “inner layers know nothing about outer layers”.
2. **Ausencia de DTOs/mappers dedicados**: Las clases de dominio se encargan de serializar y deserializar. En una arquitectura limpia, los data sources deberían mapear DTOs ↔ entidades para que el dominio desconozca el backend.
3. **Servicios fuera de lugar**: `core/services/*` y `presentation/services/*` contienen lógica de aplicación (procesos de pago, carrito, chatbot) y detalles de infraestructura (HTTP, SharedPreferences). Estas clases deberían vivir en módulos de aplicación/infrastructure y exponerse mediante interfaces al resto del sistema.
4. **Inyección de dependencias incompleta**: `main.dart` (`apps/mobile/lib/main.dart`) crea instancias concretas dentro de la UI. La carpeta `core/di` está vacía y no hay configuración modular, lo que hace difícil testear, sustituir implementaciones o ejecutar en diferentes entornos.
5. **Uso inconsistente de casos de uso**: Algunos BLoCs combinan repositorios y casos de uso (p. ej. `AccountBloc` usa `_accountRepository.updateAccount` directamente), lo que rompe la separación de responsabilidades y hace difícil centralizar reglas de negocio.
6. **Capas con responsabilidades mezcladas**: `TenantController` (gestor multi-tenant) actúa a la vez como fuente de verdad para datos (almacenamiento), proveedor de contexto para data sources y `ChangeNotifier` para la UI. Este patrón produce dependencias circulares entre UI → core → data.
7. **Capas infra/presentación escribiendo en almacenamiento**: `CartService` persiste datos locales desde la capa de presentación; lo mismo ocurre con las clases de Firebase dentro de `data`. Faltan repositorios locales o servicios específicos de infraestructura que puedan ser mockeados.

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
