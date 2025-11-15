# Configuración de Google Sign-In para Android

## Problema
El inicio de sesión con Google falla porque el SHA-1 del keystore de release no está registrado en Firebase.

## SHA-1 del Keystore de Release
```
A9:AE:87:16:23:B1:34:FF:D1:10:11:60:FE:EF:08:98:66:0A:4B:97
```

## Pasos para Solucionar

### 1. Agregar SHA-1 a Firebase Console

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Selecciona el proyecto: **microfinance-3753e**
3. Haz clic en el ícono de configuración (⚙️) y selecciona **Project Settings**
4. En la sección **Your apps**, selecciona tu app Android: `com.example.mobile`
5. Desplázate hasta la sección **SHA certificate fingerprints**
6. Haz clic en **Add fingerprint**
7. Pega el SHA-1 de release: `A9:AE:87:16:23:B1:34:FF:D1:10:11:60:FE:EF:08:98:66:0A:4B:97`
8. Haz clic en **Save**

### 2. Descargar el nuevo google-services.json

1. En la misma página de configuración de la app
2. Haz clic en **Download google-services.json**
3. Reemplaza el archivo en: `apps/mobile/android/app/google-services.json`

### 3. Limpiar y Reconstruir

```bash
cd apps/mobile
flutter clean
flutter pub get
flutter build apk --release
```

### 4. Instalar y Probar

```bash
flutter install --release
```

## Verificación

Para verificar que el SHA-1 está correctamente configurado:

```bash
# Ver SHA-1 del keystore de release
keytool -list -v -keystore /Users/phol1201/upload-keystore.jks -alias upload -storepass 123456 -keypass 123456 | grep SHA1

# Ver SHA-1 del keystore de debug (para desarrollo)
keytool -list -v -keystore android/app/debug.keystore -alias androiddebugkey -storepass android -keypass android | grep SHA1
```

## Notas Importantes

- El SHA-1 de **debug** es diferente al de **release**
- Para desarrollo (debug builds), necesitas agregar también el SHA-1 de debug
- El Web Client ID ya está configurado correctamente en el código: `862824702457-sldad0un2uhsg6tbfhlbostj6bui450j.apps.googleusercontent.com`

## Configuración Actual

- **Package Name**: com.example.mobile
- **Android Client ID**: 862824702457-1faki5bgf2sblhiauqfis1sncga2el23.apps.googleusercontent.com
- **Web Client ID** (serverClientId): 862824702457-sldad0un2uhsg6tbfhlbostj6bui450j.apps.googleusercontent.com
- **SHA-1 Actual en Firebase**: edc495bc3e900b24364bf2569226bacb0d544476 (debug)
- **SHA-1 Necesario**: A9:AE:87:16:23:B1:34:FF:D1:10:11:60:FE:EF:08:98:66:0A:4B:97 (release)
