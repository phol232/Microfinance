# Firestore Migrations

Esta app incluye un pequeño andamiaje para versionar cambios de datos en
Firestore y mantener sincronizados los entornos.

## Componentes claves

- `lib/core/migrations/migration.dart`: contrato base `FirestoreMigration`.
- `lib/core/migrations/migration_runner.dart`: orquestador que asegura que cada
  migración se ejecute una sola vez almacenando un ledger en la colección
  `_migrations`.
- `lib/core/migrations/migrations/`: carpeta con las migraciones versionadas.
  El nombre del archivo debe comenzar con la fecha (`yyyyMMdd`) para mantener
  el orden cronológico.
- `lib/scripts/run_migrations.dart`: script que inicializa Firebase y ejecuta
  todas las migraciones registradas.

## Cómo agregar una nueva migración

1. Crea un archivo en `lib/core/migrations/migrations/` siguiendo la convención
   `yyyyMMdd_descripcion.dart`.
2. Extiende `FirestoreMigration` e implementa `id`, `description` y `run`.
3. Registra la migración en `lib/scripts/run_migrations.dart` dentro de la lista
   `migrations`.
4. Ejecuta `dart run lib/scripts/run_migrations.dart` apuntando al proyecto que
   quieras migrar. El script registrará cada ejecución exitosa en
   `/_migrations/{migrationId}` para mantener la idempotencia.

## Ejemplo: roles por defecto

La migración `20230930_seed_default_roles` asegura que cada microfinanciera
tenga los roles `admin`, `analyst` y `customer`. Estos mismos roles pueden
reutilizarse desde el servicio `FirestoreBootstrapService.ensureDefaultRoles`
para entornos de desarrollo.

## Consejos

- Mantén las migraciones pequeñas y fácilmente reversibles.
- Evita leer colecciones completas si podrían contener miles de documentos;
  usa lotes paginados cuando sea necesario.
- Los scripts viven en `lib/scripts/` para que puedan ejecutarse con
  `dart run` reutilizando la misma configuración de Firebase del proyecto.
