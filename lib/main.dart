import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import 'core/config/firebase_config.dart';
import 'core/env/env_loader.dart';
import 'data/datasources/firebase_auth_datasource.dart';
import 'data/datasources/intake_request_datasource.dart';
import 'data/datasources/loan_application_datasource.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/intake_request_repository_impl.dart';
import 'data/repositories/loan_application_repository_impl.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/intake_request_repository.dart';
import 'domain/repositories/loan_application_repository.dart';
import 'presentation/bloc/auth/auth_bloc.dart';
import 'presentation/bloc/auth/auth_event.dart';
import 'presentation/bloc/intake_request/intake_request_bloc.dart';
import 'presentation/bloc/profile/profile_bloc.dart';
import 'presentation/pages/splash/splash_page.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await EnvLoader.ensureInitialized();
    await Firebase.initializeApp(options: FirebaseConfig.currentPlatform);
  } catch (e) {
    debugPrint('Error inicializando Firebase: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MultiRepositoryProvider(
            providers: [
              RepositoryProvider<AuthRepository>(
                create: (_) =>
                    AuthRepositoryImpl(dataSource: FirebaseAuthDataSource()),
              ),
              RepositoryProvider<IntakeRequestRepository>(
                create: (_) => IntakeRequestRepositoryImpl(
                  IntakeRequestDataSource(microfinancieraId: 'mf_demo_001'),
                ),
              ),
              RepositoryProvider<LoanApplicationRepository>(
                create: (_) => LoanApplicationRepositoryImpl(
                  dataSource: LoanApplicationDataSource(),
                ),
              ),
            ],
            child: Builder(
              builder: (context) {
                final authRepository = context.read<AuthRepository>();
                final intakeRequestRepository = context
                    .read<IntakeRequestRepository>();

                return MultiBlocProvider(
                  providers: [
                    BlocProvider<AuthBloc>(
                      create: (_) =>
                          AuthBloc(authRepository: authRepository)
                            ..add(const AuthCheckRequested()),
                    ),
                    BlocProvider<ProfileBloc>(
                      create: (_) =>
                          ProfileBloc(authRepository: authRepository),
                    ),
                    BlocProvider<IntakeRequestBloc>(
                      create: (_) => IntakeRequestBloc(intakeRequestRepository),
                    ),
                  ],
                  child: MaterialApp(
                    title: 'Microfinance App',
                    debugShowCheckedModeBanner: false,
                    theme: AppTheme.lightTheme,
                    darkTheme: AppTheme.darkTheme,
                    themeMode: themeProvider.themeMode,
                    home: const SplashPage(),
                    builder: (context, child) {
                      return child ?? const SizedBox.shrink();
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
