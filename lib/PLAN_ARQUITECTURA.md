# Plan de trabajo para corregir violaciones de arquitectura

## Objetivo general
Alinear el proyecto con una arquitectura limpia: dominio sin dependencias externas, data con DTOs/mappers, UI sólo consumiendo casos de uso (`Either<Failure, T>`), servicios de infraestructura detrás de interfaces, y Tenant desacoplado.

## Fases y tareas

### 1. Migración a DTOs (dominio sin Firestore)
- [ ] `loan` (LoanDto ya creado): ajustar consumidores si aparecen; mover mapeos a DTO (entidad ya limpia, falta consumidor si existe).
- [x] `microfinance` (roles/branches/workers/metadata): usar `microfinance_dto.dart`; eliminar `from/toFirestore` y `Timestamp` en `domain/entities/microfinance.dart` (entidades limpias; sin consumidores identificados aún).
- [x] `ml_models`: crear DTOs o mover parsing a data; limpiar entidades (entidad limpia y DTO agregado).
- [x] `dashboard_outbox_audit`: usar `dashboard_outbox_dto.dart`; limpiar entidad (entidad limpia, DTO listo).
- [x] `notification`/`product`: confirmar uso real; si existen consumidores, crear DTOs (product ya tiene) y limpiar entidades. (Notificación: entidad limpia + DTO; product/credit_product ya con DTO; servicios de notificaciones siguen comentados.)
- [x] `customer` (hecho: entidad limpia, `CustomerDto` usado en `firebase_auth_datasource`).
- [x] `account/card/transaction/loan_application/user` (hecho previamente con DTOs).

### 2. Actualizar datasources/servicios
- [ ] Reemplazar `fromFirestore` en datasources/servicios por DTOs para entidades pendientes (microfinance, ml_models, dashboard/outbox, notification/product si aplican).
- [ ] Crear repos/datasources faltantes si alguna entidad sólo se usa en UI sin capa data (ej. loan).

### 3. Unificación de casos de uso y blocs
- [ ] Garantizar que todos los casos de uso devuelvan `Either<Failure, T>` (streams incluidos).
- [ ] Ajustar blocs restantes (auth, intake, loan, reports, etc.) para consumir sólo casos de uso; eliminar llamadas directas a repos/servicios.

### 4. Servicios e Infraestructura
- [ ] Definir interfaces de dominio para servicios (Cart, PaymentCard, ChatBot, Transaction, Location, etc.).
- [ ] Mover implementaciones a `infrastructure/services` y exponerlas vía casos de uso/repositorios.
- [ ] Revisar NotificationService y CreditProductService para que usen DTOs y no dependan del dominio.

### 5. Tenant
- [ ] Mantener `TenantResolver` en dominio y tratar `TenantController` como implementación de infraestructura; inyectarlo a datasources vía interfaces (evitar dependencia directa de Flutter en data).

### 6. Limpieza y validaciones
- [ ] Ejecutar `rg "fromFirestore"` y `rg "Timestamp"` en dominio para asegurar ausencia de dependencias externas.
- [ ] Añadir/actualizar pruebas unitarias en casos de uso y mappers DTO ↔ entidad.
- [ ] Correr analyzer/tests antes de entregar.
