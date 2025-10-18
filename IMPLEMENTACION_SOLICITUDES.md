# Implementación de Solicitudes Reales en la App Móvil

## Descripción

Esta implementación permite que los usuarios con rol "analyst" en la app móvil vean las solicitudes reales que los clientes (customers) envían desde el portal web.

## Diagnóstico actual del módulo móvil

### Estructura de directorios principales
- **`lib/core/`** Contiene configuración (`config/`) y manejo de entornos (`env/`), aún sin consolidar utilidades compartidas como logging o manejo de errores.
- **`lib/data/`** Agrupa `datasources/`, `models/`, `repositories/` y `services/`; se detectan implementaciones recientes como `IntakeRequestDataSource` que conviven con servicios heredados.
- **`lib/domain/`** Define entidades y contratos de repositorio; no existen `usecases/`, por lo que la lógica de dominio permanece principalmente en presentación o data.
- **`lib/presentation/`** Mezcla `screens/`, `pages/`, `components/`, `widgets/` y `bloc/` sin un criterio único por feature, lo que dificulta la trazabilidad y la reutilización.
- **`test/`** Incluye un único módulo; falta cobertura por capas para garantizar regresiones controladas.

### Configuración y dependencias
- **`pubspec.yaml`** Declara dependencias claves (`flutter_bloc`, `cloud_firestore`, `intl`, entre otras) y nuevas entradas ligadas a solicitudes; necesita depuración para identificar paquetes sin uso.
- **`analysis_options.yaml`** Mantiene reglas básicas sin `dart_code_metrics` ni configuraciones de lint estrictas.
- **Scripts de desarrollo** `package.json` y `pubspec.yaml` no exponen comandos unificados para análisis estático o pruebas, lo que limita la automatización.

## Arquitectura

### 1. Capa de Datos

#### DataSource
- **`IntakeRequestDataSource`**: Maneja las operaciones de Firestore
  - Ubicación: `lib/data/datasources/intake_request_datasource.dart`
  - Funciones:
    - `getAll()`: Obtiene todas las solicitudes
    - `getByStatus(status)`: Filtra por estado
    - `getRecent(limit)`: Obtiene las más recientes
    - `getById(id)`: Obtiene una solicitud específica
    - `watchAll()`: Stream en tiempo real
    - `getStatusCounts()`: Cuenta solicitudes por estado

#### Repository
- **`IntakeRequestRepository`**: Interfaz abstracta
  - Ubicación: `lib/domain/repositories/intake_request_repository.dart`
  
- **`IntakeRequestRepositoryImpl`**: Implementación concreta
  - Ubicación: `lib/data/repositories/intake_request_repository_impl.dart`

### 2. Capa de Dominio

#### Entidades
- **`IntakeRequest`**: Modelo principal de solicitud
  - Ubicación: `lib/domain/entities/intake_request.dart`
  - Campos principales:
    - `id`: Identificador único
    - `status`: Estado (received, validated, routed, rejected, converted)
    - `contact`: Información de contacto (teléfono, email, verificado)
    - `applicant`: Datos del solicitante (DNI, nombre, distrito, actividad)
    - `requested`: Información solicitada (monto, plazo, propósito)
    - `consent`: Información de consentimiento
    - `routing`: Enrutamiento (sucursal, usuario asignado)
    - `riskFlags`: Análisis de riesgo (spam score, razón)
    - `createdAt`, `updatedAt`: Timestamps

### 3. Capa de Presentación

#### BLoC (Business Logic Component)
- **`IntakeRequestBloc`**: Maneja el estado de las solicitudes
  - Ubicación: `lib/presentation/bloc/intake_request/`
  - Eventos:
    - `IntakeRequestLoadRequested`: Cargar todas
    - `IntakeRequestLoadByStatus`: Filtrar por estado
    - `IntakeRequestLoadRecent`: Cargar recientes
    - `IntakeRequestLoadById`: Cargar una específica
    - `IntakeRequestRefreshRequested`: Refrescar datos
  - Estados:
    - `initial`: Estado inicial
    - `loading`: Cargando datos
    - `success`: Datos cargados exitosamente
    - `error`: Error al cargar

#### Pantallas

##### HomeScreen
- **Ubicación**: `lib/presentation/screens/home_screen.dart`
- **Funcionalidad**:
  - Muestra estadísticas en tiempo real
  - Lista las últimas 5 solicitudes en "Actividad reciente"
  - Pull-to-refresh para actualizar datos
  - Navegación al detalle al hacer clic en una solicitud

##### ApplicationsScreen
- **Ubicación**: `lib/presentation/screens/applications_screen.dart`
- **Funcionalidad**:
  - Muestra todas las solicitudes
  - Estadísticas por estado (Pendientes, Aprobadas, Rechazadas)
  - Lista completa de solicitudes con información resumida
  - Pull-to-refresh
  - Navegación al detalle

##### IntakeRequestDetailPage
- **Ubicación**: `lib/presentation/pages/intake_request_detail_page.dart`
- **Funcionalidad**:
  - Muestra toda la información de la solicitud
  - Secciones:
    - Estado actual con indicador visual
    - Información de contacto
    - Datos del solicitante
    - Información solicitada (monto, plazo, propósito)
    - Enrutamiento (sucursal, asignación)
    - Análisis de riesgo
    - Fechas de creación y actualización

## Estructura de Firestore

Las solicitudes se almacenan en:
```
tenants/{tenantId}/intake_requests/{requestId}
```

### Ejemplo de documento:
```json
{
  "status": "received",
  "contact": {
    "phone": "+51999999999",
    "email": "cliente@example.com",
    "verified": true
  },
  "applicant": {
    "dni": "12345678",
    "fullName": "Juan Pérez",
    "district": "Miraflores",
    "activity": "Comerciante"
  },
  "requested": {
    "amountCents": 500000,
    "termMonths": 12,
    "purpose": "Capital de trabajo"
  },
  "consent": {
    "accepted": true,
    "version": "1.0",
    "at": "2024-01-15T10:30:00Z"
  },
  "routing": {
    "branchId": "branch_001",
    "assignedUserId": "user_123"
  },
  "risk_flags": {
    "spamScore": 0.15,
    "reason": null
  },
  "createdAt": "2024-01-15T10:30:00Z",
  "updatedAt": "2024-01-15T10:30:00Z"
}
```

## Estados de Solicitud

| Estado | Descripción | Color |
|--------|-------------|-------|
| `received` | Recibida | Azul |
| `validated` | Validada | Verde |
| `routed` | Enrutada/En Revisión | Naranja |
| `rejected` | Rechazada | Rojo |
| `converted` | Convertida/Aprobada | Púrpura |

## Configuración

### 1. Tenant ID
Actualmente configurado como `tenant_demo` en `main.dart`. 

**TODO**: Obtener el tenant ID del usuario autenticado.

```dart
RepositoryProvider<IntakeRequestRepository>(
  create: (_) => IntakeRequestRepositoryImpl(
    IntakeRequestDataSource(
      tenantId: 'tenant_demo', // Cambiar por el tenant del usuario
    ),
  ),
),
```

### 2. Dependencias
Asegúrate de tener estas dependencias en `pubspec.yaml`:
```yaml
dependencies:
  flutter_bloc: ^8.1.6
  bloc: ^8.1.4
  equatable: ^2.0.5
  intl: ^0.19.0
  cloud_firestore: ^6.0.2
```

## Flujo de Datos

1. **Usuario abre la app** → `HomeScreen` se carga
2. **HomeScreen.initState()** → Dispara `IntakeRequestLoadRecent`
3. **IntakeRequestBloc** → Llama al repositorio
4. **Repository** → Llama al datasource
5. **DataSource** → Consulta Firestore
6. **Firestore** → Retorna documentos
7. **DataSource** → Convierte a entidades `IntakeRequest`
8. **BLoC** → Emite nuevo estado con datos
9. **UI** → Se actualiza automáticamente con BlocBuilder

## Características Implementadas

✅ Listado de solicitudes en tiempo real
✅ Filtrado por estado
✅ Estadísticas agregadas
✅ Vista de detalle completa
✅ Pull-to-refresh
✅ Manejo de errores
✅ Estados de carga
✅ Navegación entre pantallas
✅ Formateo de fechas y montos
✅ Indicadores visuales de estado
✅ Análisis de riesgo

## Próximas Mejoras

- [ ] Implementar filtros avanzados
- [ ] Agregar búsqueda por nombre/DNI
- [ ] Implementar paginación
- [ ] Agregar acciones (aprobar, rechazar)
- [ ] Notificaciones push para nuevas solicitudes
- [ ] Modo offline con sincronización
- [ ] Exportar reportes
- [ ] Agregar comentarios/notas
- [ ] Historial de cambios de estado
- [ ] Asignación de solicitudes a analistas

## Testing

Para probar la funcionalidad:

1. Asegúrate de tener datos en Firestore en la ruta correcta
2. Ejecuta la app: `flutter run`
3. Inicia sesión con un usuario analyst
4. Navega a "Inicio" o "Solicitudes"
5. Verifica que se muestren las solicitudes reales
6. Haz clic en una solicitud para ver el detalle

## Troubleshooting

### No se muestran solicitudes
- Verifica que el `tenantId` sea correcto
- Confirma que hay datos en Firestore
- Revisa los permisos de Firestore Rules
- Verifica la conexión a internet

### Error al cargar
- Revisa los logs de Flutter
- Verifica la estructura de los documentos en Firestore
- Confirma que todos los campos requeridos existen

### Problemas de rendimiento
- Implementa paginación si hay muchas solicitudes
- Usa índices compuestos en Firestore
- Considera caché local
