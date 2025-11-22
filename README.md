# 📱 Microfinance Mobile App

Aplicación móvil multiplataforma para gestión de microfinanzas, desarrollada con Flutter y Firebase.

## 🚀 Características

### Para Clientes
- ✅ Gestión de cuentas (Microcrédito, Ahorros)
- ✅ Solicitud de préstamos con formulario completo
- ✅ Visualización de cronograma de pagos
- ✅ Pagos de cuotas mediante tarjetas
- ✅ Historial de transacciones
- ✅ Perfil de usuario con validación biométrica
- ✅ Notificaciones push para recordatorios de pago
- ✅ Modo oscuro automático

### Para Asesores
- ✅ Bandeja de entrada de solicitudes
- ✅ Gestión de clientes asignados
- ✅ Aprobación/rechazo de solicitudes
- ✅ Visualización de estadísticas
- ✅ Reportes en tiempo real

## 🏗️ Arquitectura

El proyecto sigue **Clean Architecture** con patrón **BLoC** para gestión de estado:

```
lib/
├── data/                   # Capa de datos
│   ├── datasources/       # Firebase, APIs
│   ├── models/            # DTOs
│   └── repositories/      # Implementaciones
├── domain/                # Capa de dominio
│   ├── entities/          # Entidades del negocio
│   ├── repositories/      # Interfaces
│   └── usecases/          # Casos de uso
├── presentation/          # Capa de presentación
│   ├── bloc/              # BLoC (Estado)
│   ├── screens/           # Pantallas
│   ├── components/        # Widgets reutilizables
│   └── theme/             # Tema y colores
└── infrastructure/        # Servicios compartidos
    └── services/          # Notificaciones, Storage
```

## 🛠️ Tecnologías

### Core
- **Flutter** 3.x - Framework multiplataforma
- **Dart** 3.9.2+ - Lenguaje de programación
- **Material Design 3** - Sistema de diseño

### Estado y Arquitectura
- **flutter_bloc** ^8.1.6 - Gestión de estado
- **bloc_test** ^9.1.7 - Testing de BLoCs
- **equatable** ^2.0.7 - Comparación de objetos

### Backend y Base de Datos
- **Firebase Core** ^4.1.1
- **Cloud Firestore** ^6.0.2 - Base de datos NoSQL
- **Firebase Auth** ^6.1.0 - Autenticación
- **Firebase Messaging** ^16.0.3 - Notificaciones push
- **Google Sign In** ^7.2.0 - Login con Google

### UI/UX
- **google_fonts** ^6.2.1 - Tipografías
- **fl_chart** ^0.66.2 - Gráficos
- **shimmer** ^3.0.0 - Efectos de carga
- **flutter_local_notifications** ^19.5.0

### Utilidades
- **intl** ^0.20.2 - Formateo de fechas/moneda
- **google_maps_flutter** ^2.13.1 - Mapas
- **geolocator** ^13.0.4 - Geolocalización
- **permission_handler** ^11.4.0 - Permisos
- **url_launcher** ^6.3.1 - Abrir URLs
- **shared_preferences** ^2.3.4 - Almacenamiento local
- **flutter_secure_storage** ^9.2.2 - Almacenamiento seguro
- **flutter_dotenv** ^5.1.0 - Variables de entorno

### Pagos y Tarjetas
- **stripe_payment** - Procesamiento de pagos
- **credit_card_validator** - Validación de tarjetas

## 📋 Requisitos Previos

- Flutter SDK >= 3.9.2
- Dart SDK >= 3.9.2
- Android Studio / Xcode (para emuladores)
- Cuenta de Firebase configurada
- Node.js (para scripts de Firebase)

## 🔧 Instalación

### 1. Clonar el repositorio
```bash
git clone <repository-url>
cd Microfinance/apps/mobile
```

### 2. Instalar dependencias
```bash
flutter pub get
```

### 3. Configurar Firebase
1. Crear proyecto en [Firebase Console](https://console.firebase.google.com)
2. Descargar `google-services.json` (Android) → `android/app/`
3. Descargar `GoogleService-Info.plist` (iOS) → `ios/Runner/`
4. Habilitar servicios:
   - Authentication (Email/Password, Google)
   - Cloud Firestore
   - Cloud Messaging
   - Storage

### 4. Configurar variables de entorno
Crear archivo `assets/env/.env`:
```env
FIREBASE_API_KEY=your_api_key
FIREBASE_PROJECT_ID=your_project_id
STRIPE_PUBLISHABLE_KEY=your_stripe_key
```

### 5. Generar iconos de la aplicación
```bash
flutter pub run flutter_launcher_icons
```

## 🚀 Ejecución

### Modo Debug
```bash
flutter run
```

### Modo Release
```bash
flutter run --release
```

### Android APK
```bash
flutter build apk --release
# APK generado en: build/app/outputs/flutter-apk/app-release.apk
```

### Android App Bundle (Google Play)
```bash
flutter build appbundle --release
# AAB generado en: build/app/outputs/bundle/release/app-release.aab
```

### iOS
```bash
flutter build ios --release
```

## 🧪 Testing

### Tests unitarios
```bash
flutter test
```

### Tests de integración
```bash
flutter test integration_test/
```

### Cobertura de código
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## 📱 Pantallas Principales

### Autenticación
- Login (Email/Password, Google)
- Registro de usuario
- Recuperación de contraseña

### Cliente
- **Cuentas**: Lista de cuentas activas
- **Solicitudes**: Nueva solicitud de préstamo
- **Préstamos**: Préstamos activos y cronograma
- **Perfil**: Datos personales y configuración

### Asesor
- **Bandeja de Entrada**: Solicitudes asignadas
- **Clientes**: Gestión de clientes
- **Reportes**: Estadísticas y métricas

## 🎨 Tema y Diseño

### Colores Principales
```dart
primary: #2196F3      // Azul vibrante (Material Blue)
primaryVariant: #42A5F5
secondary: #BBE1FA
success: #4CAF50      // Verde
warning: #FF9800      // Naranja
error: #EF4444        // Rojo
```

### Modo Oscuro
La aplicación soporta modo oscuro automático basado en la configuración del sistema.

## 📂 Estructura de Firebase

### Collections
```
microfinancieras/
├── {microId}/
│   ├── customers/
│   ├── loans/
│   ├── accounts/
│   ├── loan_applications/
│   ├── transactions/
│   └── cards/
```

## 🔐 Seguridad

- Autenticación con Firebase Auth
- Reglas de seguridad de Firestore
- Almacenamiento seguro de tokens
- Validación de permisos por rol (CUSTOMER, ADVISOR, ADMIN)
- Cifrado de datos sensibles

## 📝 Scripts Útiles

### Limpiar proyecto
```bash
flutter clean && flutter pub get
```

### Analizar código
```bash
flutter analyze
```

### Formatear código
```bash
dart format lib/
```

### Actualizar dependencias
```bash
flutter pub upgrade
```

## 🐛 Troubleshooting

### Error: integration_test en release mode
```bash
flutter clean
rm -f android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java
flutter pub get
flutter run --release
```

### Error: Icono no actualiza
```bash
flutter pub run flutter_launcher_icons
adb shell pm clear <package_name>
adb reboot
```

## 📦 Versionado

Versión actual: **1.3.0**

Formato: `MAJOR.MINOR.PATCH`
- **MAJOR**: Cambios incompatibles en la API
- **MINOR**: Nueva funcionalidad compatible
- **PATCH**: Correcciones de errores

## 👥 Roles de Usuario

### CUSTOMER
- Ver y solicitar préstamos
- Gestionar cuentas
- Realizar pagos
- Ver historial

### ADVISOR
- Gestionar solicitudes
- Aprobar/rechazar préstamos
- Ver clientes asignados
- Generar reportes

### ADMIN
- Configuración del sistema
- Gestión de usuarios
- Administración completa

## 📄 Licencia

Proyecto privado - Todos los derechos reservados

## 🤝 Contribución

1. Fork del proyecto
2. Crear rama feature (`git checkout -b feature/AmazingFeature`)
3. Commit cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abrir Pull Request

## 📞 Soporte

Para soporte y consultas, contactar al equipo de desarrollo.

---

**Desarrollado con ❤️ usando Flutter**
