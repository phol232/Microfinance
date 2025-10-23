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
import 'domain/usecases/auth/login_user_usecase.dart';
import 'domain/usecases/auth/register_user_usecase.dart';
import 'domain/usecases/auth/logout_user_usecase.dart';
import 'domain/usecases/auth/get_current_user_usecase.dart';
import 'domain/usecases/auth/get_microfinancieras_usecase.dart';
import 'domain/usecases/auth/google_signin_usecase.dart';
import 'domain/usecases/auth/anonymous_signin_usecase.dart';
import 'domain/usecases/auth/validate_user_access_usecase.dart';
import 'domain/usecases/profile/get_user_profile_usecase.dart';
import 'domain/usecases/profile/update_user_profile_usecase.dart';
import 'domain/usecases/profile/check_dni_exists_usecase.dart';
import 'domain/usecases/intake_request/get_all_intake_requests_usecase.dart';
import 'domain/usecases/intake_request/get_intake_requests_by_status_usecase.dart';
import 'domain/usecases/intake_request/get_recent_intake_requests_usecase.dart';
import 'domain/usecases/intake_request/get_intake_request_by_id_usecase.dart';
import 'domain/usecases/intake_request/get_intake_request_status_counts_usecase.dart';
import 'presentation/bloc/auth/auth_bloc.dart';
import 'presentation/bloc/auth/auth_event.dart';
import 'presentation/bloc/profile/profile_bloc.dart';
import 'presentation/bloc/intake_request/intake_request_bloc.dart';
import 'presentation/screens/splash/splash_page.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await EnvLoader.ensureInitialized();
    await Firebase.initializeApp(options: FirebaseConfig.currentPlatform);
  } catch (e) {
    debugPrint('❌ ERROR CRÍTICO: Error inicializando Firebase: $e');
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
                      create: (_) {
                        final loginUserUseCase = LoginUserUseCase(
                          authRepository,
                        );
                        final registerUserUseCase = RegisterUserUseCase(
                          authRepository,
                        );
                        final logoutUserUseCase = LogoutUserUseCase(
                          authRepository,
                        );
                        final getCurrentUserUseCase = GetCurrentUserUseCase(
                          authRepository,
                        );
                        final getMicrofinancierasUseCase =
                            GetMicrofinancierasUseCase(authRepository);
                        final googleSignInUseCase = GoogleSignInUseCase(
                          authRepository,
                        );
                        final anonymousSignInUseCase = AnonymousSignInUseCase(
                          authRepository,
                        );
                        final validateUserAccessUseCase =
                            ValidateUserAccessUseCase(authRepository);

                        return AuthBloc(
                          authRepository: authRepository,
                          loginUserUseCase: loginUserUseCase,
                          registerUserUseCase: registerUserUseCase,
                          logoutUserUseCase: logoutUserUseCase,
                          getCurrentUserUseCase: getCurrentUserUseCase,
                          getMicrofinancierasUseCase:
                              getMicrofinancierasUseCase,
                          googleSignInUseCase: googleSignInUseCase,
                          anonymousSignInUseCase: anonymousSignInUseCase,
                          validateUserAccessUseCase: validateUserAccessUseCase,
                        )..add(const AuthCheckRequested());
                      },
                    ),
                    BlocProvider<ProfileBloc>(
                      create: (_) {
                        final getUserProfileUseCase = GetUserProfileUseCase(
                          authRepository,
                        );
                        final updateUserProfileUseCase =
                            UpdateUserProfileUseCase(authRepository);
                        final checkDniExistsUseCase = CheckDniExistsUseCase(
                          authRepository,
                        );

                        return ProfileBloc(
                          getUserProfileUseCase: getUserProfileUseCase,
                          updateUserProfileUseCase: updateUserProfileUseCase,
                          checkDniExistsUseCase: checkDniExistsUseCase,
                        );
                      },
                    ),
                    BlocProvider<IntakeRequestBloc>(
                      create: (_) {
                        final getAllIntakeRequestsUseCase =
                            GetAllIntakeRequestsUseCase(
                              intakeRequestRepository,
                            );
                        final getIntakeRequestsByStatusUseCase =
                            GetIntakeRequestsByStatusUseCase(
                              intakeRequestRepository,
                            );
                        final getRecentIntakeRequestsUseCase =
                            GetRecentIntakeRequestsUseCase(
                              intakeRequestRepository,
                            );
                        final getIntakeRequestByIdUseCase =
                            GetIntakeRequestByIdUseCase(
                              intakeRequestRepository,
                            );
                        final getIntakeRequestStatusCountsUseCase =
                            GetIntakeRequestStatusCountsUseCase(
                              intakeRequestRepository,
                            );

                        return IntakeRequestBloc(
                          getAllIntakeRequestsUseCase,
                          getIntakeRequestsByStatusUseCase,
                          getRecentIntakeRequestsUseCase,
                          getIntakeRequestByIdUseCase,
                          getIntakeRequestStatusCountsUseCase,
                        );
                      },
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
