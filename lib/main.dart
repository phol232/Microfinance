import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/config/firebase_config.dart';
import 'core/env/env_loader.dart';
import 'data/datasources/firebase_auth_datasource.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'domain/repositories/auth_repository.dart';
import 'presentation/bloc/auth/auth_bloc.dart';
import 'presentation/bloc/auth/auth_event.dart';
import 'presentation/bloc/profile/profile_bloc.dart';
import 'presentation/pages/splash/splash_page.dart';
import 'presentation/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await EnvLoader.ensureInitialized();

  await Firebase.initializeApp(
    options: FirebaseConfig.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<AuthRepository>(
      create: (_) => AuthRepositoryImpl(
        dataSource: FirebaseAuthDataSource(),
      ),
      child: Builder(
        builder: (context) {
          final authRepository = context.read<AuthRepository>();

          return MultiBlocProvider(
            providers: [
              BlocProvider<AuthBloc>(
                create: (_) =>
                    AuthBloc(authRepository: authRepository)
                      ..add(const AuthCheckRequested()),
              ),
              BlocProvider<ProfileBloc>(
                create: (_) => ProfileBloc(authRepository: authRepository),
              ),
            ],
            child: MaterialApp(
              title: 'Microfinance App',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              home: const SplashPage(),
            ),
          );
        },
      ),
    );
  }
}
