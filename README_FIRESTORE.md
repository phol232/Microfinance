# Esquema de Base de Datos Firestore - Microfinance

## Estructura Multi-tenant

Todos los datos están organizados bajo la estructura:
```
tenants/{tenantId}/[collection]/[docId]
```

## Colecciones Principales

### 1. intake_requests
Pre-solicitudes desde el portal web.
- **Path**: `tenants/{t}/intake_requests/{intakeId}`
- **Índices**: `routing.branchId + status + createdAt desc`

### 2. applications
Solicitudes formales de crédito.
- **Path**: `tenants/{t}/applications/{appId}`
- **Índices**: `status + submittedAt desc`

### 3. customers
Información de clientes.
- **Path**: `tenants/{t}/customers/{customerId}`
- **Índices**: `dni`, `branchId + status`

### 4. products
Productos financieros disponibles.
- **Path**: `tenants/{t}/products/{productId}`

### 5. loans
Préstamos activos y cerrados.
- **Path**: `tenants/{t}/loans/{loanId}`
- **Subcolecciones**:
  - `schedule/{installmentId}` - Cronograma de pagos
  - `repayments/{repaymentId}` - Pagos realizados

### 6. transactions
Transacciones contables.
- **Path**: `tenants/{t}/transactions/{txId}`
- **Subcolección**: `entries/{entryId}` - Asientos contables (doble entrada)

### 7. branches
Sucursales de la institución.
- **Path**: `tenants/{t}/branches/{branchId}`

### 8. agents
Agentes de crédito.
- **Path**: `tenants/{t}/agents/{agentId}`

### 9. ml_scores
Scores de machine learning.
- **Path**: `tenants/{t}/ml_scores/{scoreId}`

### 10. ml_metrics
Métricas de calidad de ML.
- **Path**: `tenants/{t}/ml_metrics/{mId}`

### 11. dashboards_public
Vistas denormalizadas para dashboards.
- **Path**: `tenants/{t}/dashboards_public/{docId}`

### 12. outbox
Cola de mensajes para Brevo.
- **Path**: `tenants/{t}/outbox/{msgId}`

### 13. auditLogs
Registro de auditoría.
- **Path**: `tenants/{t}/auditLogs/{logId}`

## Convenciones

- **Dinero**: Siempre en centavos (int) - `amountCents`, `feeCents`, etc.
- **Tiempos**: `createdAt`, `updatedAt` (Timestamp de Firestore)
- **Enums**: String legibles - `status`, `type`, `method`, etc.
- **Multi-tenant**: Todo anidado en `tenants/{tenantId}/...`

## Uso en Flutter

### 1. Importar modelos
```dart
import 'package:mobile/models/models.dart';
```

### 2. Usar FirestoreService
```dart
final service = FirestoreService(tenantId: 'your_tenant_id');

// Obtener customers
final customers = await service.customers.get();

// Crear nuevo customer
final customer = Customer(/* ... */);
await service.customers.doc(customer.id).set(customer.toFirestore());
```

### 3. Poblar datos de prueba
Descomenta las líneas en `main.dart`:
```dart
import 'services/data_seeder.dart';

// En main()
await runSeeder(tenantId: 'tenant_demo');
```

## Estructura de Archivos

```
lib/
├── models/
│   ├── common.dart              # Clases compartidas
│   ├── intake_request.dart      # Pre-solicitudes
│   ├── application.dart         # Solicitudes formales
│   ├── customer.dart           # Clientes
│   ├── product.dart            # Productos
│   ├── loan.dart               # Préstamos + subcolecciones
│   ├── transaction.dart        # Transacciones + entradas
│   ├── branch_agent.dart       # Sucursales y agentes
│   ├── ml_models.dart          # ML scores y métricas
│   ├── dashboard_outbox_audit.dart # Dashboards, outbox, audit
│   └── models.dart             # Barrel file
└── services/
    ├── firestore_service.dart   # Servicio base multi-tenant
    └── data_seeder.dart        # Poblador de datos de prueba
```

## Próximos Pasos

1. **Crear Firestore desde consola**: Usar los modelos para crear documentos de ejemplo
2. **Agregar validaciones**: Implementar reglas de seguridad en Firestore
3. **Crear servicios específicos**: CustomerService, LoanService, etc.
4. **Implementar UI**: Pantallas para cada entidad
5. **Migración de datos**: Scripts para cambios de esquema
