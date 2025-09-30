# Arquitectura BLoC en Microfinance Mobile

Este documento resume la nueva estructura basada en BLoC y clean architecture adoptada para la app móvil. El objetivo principal es separar la lógica de negocio de la UI, facilitar el mantenimiento y permitir configuraciones de entorno flexibles.

## Dependencias clave (`pubspec.yaml`)

```yaml
dependencies:
  flutter_bloc: ^8.1.6
  bloc: ^8.1.4
  equatable: ^2.0.5
  firebase_core: ^4.1.1
  firebase_auth: ^6.1.0
  cloud_firestore: ^6.0.2
  google_sign_in: ^7.2.0
  flutter_facebook_auth: ^6.0.3
  flutter_dotenv: ^5.1.0
```

## Estructura de carpetas

```
lib/
├── core/
│   ├── config/              # Configuración (Firebase, etc.)
│   └── env/                 # Carga de variables (.env)
├── data/
│   ├── datasources/         # Integraciones externas (Firebase)
│   ├── models/              # Mapeos entre capas
│   └── repositories/        # Implementaciones concretas
├── domain/
│   ├── entities/            # Entidades de negocio puras
│   └── repositories/        # Contratos utilizados por los BLoC
├── presentation/
│   ├── bloc/                # BLoC + eventos + estados
│   ├── components/          # Componentes UI reutilizables
│   ├── pages/               # Pantallas de alto nivel
│   ├── screens/             # Secciones principales
│   └── theme/               # Theming centralizado
└── main.dart                # Arranque de la app
```

## Flujo de datos

1. **UI (pages/screens/widgets)** emite eventos al BLoC correspondiente.
2. **BLoC** orquesta la lógica usando un repositorio de dominio.
3. **Repositorio de dominio** delega en las implementaciones de `data/` para conversar con Firebase.
4. **Estados** generados por el BLoC vuelven a la UI, que se actualiza de forma reactiva.

## BLoC principales

### AuthBloc
- Maneja login, registro, autenticación social y cierre de sesión.
- Expone estados basados en la entidad `AppUser` (no objetos de Firebase).
- Escucha `authStateChanges()` del repositorio para reaccionar a cambios externos.

Eventos destacados: `AuthLoginRequested`, `AuthRegisterRequested`, `AuthGoogleSignInRequested`, `AuthLogoutRequested`.

### ProfileBloc
- Carga, actualiza y valida información del perfil (`UserProfile`).
- Reutiliza el mismo repositorio de autenticación para mantener una única fuente de datos.

Eventos destacados: `ProfileLoadRequested`, `ProfileUpdateRequested`, `ProfileCheckDniRequested`.

## Configuración y bootstrapping

`main.dart` realiza:

1. Carga del archivo `.env` empaquetado en `assets/env/.env`.
2. Resolución de `FirebaseOptions` desde `core/config/firebase_config.dart`.
3. Registro de `AuthRepositoryImpl` como dependencia global.
4. Registro de `AuthBloc` y `ProfileBloc` dentro de `MultiBlocProvider`.

```dart
await EnvLoader.ensureInitialized();
await Firebase.initializeApp(options: FirebaseConfig.currentPlatform);

RepositoryProvider<AuthRepository>(
  create: (_) => AuthRepositoryImpl(dataSource: FirebaseAuthDataSource()),
);
```

## Configuración de entorno

- Archivo empaquetado: `assets/env/.env`
- Variables mínimas:
  - `FIREBASE_ANDROID_API_KEY`, `FIREBASE_ANDROID_APP_ID`, `FIREBASE_ANDROID_CLIENT_ID`
  - `FIREBASE_IOS_API_KEY`, `FIREBASE_IOS_APP_ID`, `FIREBASE_IOS_CLIENT_ID`, `FIREBASE_IOS_BUNDLE_ID`
  - `FIREBASE_PROJECT_ID`, `FIREBASE_MESSAGING_SENDER_ID`, `FIREBASE_STORAGE_BUCKET`

## Ejemplo de uso en UI

```dart
// Disparo de evento
elevatedButton.onPressed = () {
  context.read<AuthBloc>().add(
    const AuthLoginRequested(email: 'demo@demo.com', password: '123456'),
  );
};

// Reacción a estados
BlocListener<AuthBloc, AuthState>(
  listener: (context, state) {
    if (state is AuthAuthenticated) {
      Navigator.of(context).pushReplacementNamed('/');
    }
    if (state is AuthError) {
      showSnackBar(state.message);
    }
  },
  child: ...,
);
```

## Beneficios obtenidos

- **Separación estricta de responsabilidades**: la UI no conoce detalles de Firebase.
- **Escalabilidad**: agregar nuevas fuentes de datos solo requiere implementar interfaces de `domain/`.
- **Testabilidad**: los BLoC se testean inyectando repositorios fakes.
- **Configuración segura**: credenciales de Firebase se aíslan en `.env` y no quedan hardcodeadas.

## Próximos pasos sugeridos

- Agregar `watchUserProfile` al `ProfileBloc` para reaccionar a cambios en tiempo real.
- Incorporar pruebas unitarias para `AuthBloc` y `ProfileBloc` utilizando `bloc_test`.
- Ampliar los repositorios con caché local (por ejemplo, Hive o SharedPreferences) si se requiere funcionamiento offline.
