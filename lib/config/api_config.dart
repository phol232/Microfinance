class ApiConfig {
  static const String DEV_URL_ANDROID = 'http://10.0.2.2:3000';
  static const String DEV_URL_IOS = 'http://localhost:3000';

  static const String PROD_URL = 'https://backend-eight-zeta-41.vercel.app';

  static String get baseUrl {
    // En producción
    if (const bool.fromEnvironment('dart.vm.product')) {
      return PROD_URL;
    }

    return DEV_URL_ANDROID;
  }

  static bool get isDevelopment {
    return !const bool.fromEnvironment('dart.vm.product');
  }

  static bool get isProduction {
    return const bool.fromEnvironment('dart.vm.product');
  }
}
