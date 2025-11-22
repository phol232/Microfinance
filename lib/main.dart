import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import 'core/config/firebase_config.dart';
import 'core/di/app_di.dart';
import 'core/env/env_loader.dart';
import 'infrastructure/tenant/tenant_controller.dart';
import 'presentation/bloc/auth/auth_bloc.dart';
import 'presentation/bloc/auth/auth_event.dart';
import 'presentation/bloc/profile/profile_bloc.dart';
import 'presentation/bloc/intake_request/intake_request_bloc.dart';
import 'presentation/bloc/account/account_bloc.dart';
import 'presentation/bloc/card/card_bloc.dart';
import 'presentation/screens/auth/auth_wrapper.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/theme/app_theme.dart';
// TODO: Implementar notificaciones más adelante
// import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await EnvLoader.ensureInitialized();
    await Firebase.initializeApp(options: FirebaseConfig.currentPlatform);

    // TODO: Inicializar el servicio de notificaciones más adelante
    // await NotificationService.initialize();
  } catch (e) {
    debugPrint('❌ ERROR CRÍTICO: Error inicializando Firebase: $e');
  }

  final dependencies = await AppDependencies.init();

  runApp(MyApp(dependencies: dependencies));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider<TenantController>.value(
          value: dependencies.tenantController,
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MultiRepositoryProvider(
            providers: [
              RepositoryProvider.value(
                value: dependencies.authRepository,
              ),
              RepositoryProvider.value(
                value: dependencies.intakeRequestRepository,
              ),
              RepositoryProvider.value(
                value: dependencies.loanApplicationRepository,
              ),
              RepositoryProvider.value(
                value: dependencies.accountRepository,
              ),
              RepositoryProvider.value(
                value: dependencies.cardRepository,
              ),
            ],
            child: Builder(
              builder: (context) {
                return MultiBlocProvider(
                  providers: [
                    BlocProvider<AuthBloc>(
                      create: (_) {
                        return AuthBloc(
                          authRepository: dependencies.authRepository,
                          loginUserUseCase:
                              dependencies.auth.loginUserUseCase,
                          registerUserUseCase:
                              dependencies.auth.registerUserUseCase,
                          logoutUserUseCase:
                              dependencies.auth.logoutUserUseCase,
                          getCurrentUserUseCase:
                              dependencies.auth.getCurrentUserUseCase,
                          getMicrofinancierasUseCase:
                              dependencies.auth.getMicrofinancierasUseCase,
                          googleSignInUseCase:
                              dependencies.auth.googleSignInUseCase,
                          anonymousSignInUseCase:
                              dependencies.auth.anonymousSignInUseCase,
                          validateUserAccessUseCase:
                              dependencies.auth.validateUserAccessUseCase,
                          tenantController: dependencies.tenantController,
                        )..add(const AuthCheckRequested());
                      },
                    ),
                    BlocProvider<ProfileBloc>(
                      create: (_) {
                        return ProfileBloc(
                          getUserProfileUseCase:
                              dependencies.profile.getUserProfileUseCase,
                          updateUserProfileUseCase:
                              dependencies.profile.updateUserProfileUseCase,
                          checkDniExistsUseCase:
                              dependencies.profile.checkDniExistsUseCase,
                        );
                      },
                    ),
                    BlocProvider<IntakeRequestBloc>(
                      create: (_) {
                        return IntakeRequestBloc(
                          dependencies.intakeRequests.getAllIntakeRequestsUseCase,
                          dependencies
                              .intakeRequests.getIntakeRequestsByStatusUseCase,
                          dependencies
                              .intakeRequests.getRecentIntakeRequestsUseCase,
                          dependencies.intakeRequests.getIntakeRequestByIdUseCase,
                          dependencies.intakeRequests
                              .getIntakeRequestStatusCountsUseCase,
                        );
                      },
                    ),
                    BlocProvider<AccountBloc>(
                      create: (_) {
                        return AccountBloc(
                          createAccountUseCase:
                              dependencies.accounts.createAccountUseCase,
                          getUserAccountsUseCase:
                              dependencies.accounts.getUserAccountsUseCase,
                          getAccountByIdUseCase:
                              dependencies.accounts.getAccountByIdUseCase,
                          updateAccountUseCase:
                              dependencies.accounts.updateAccountUseCase,
                          deleteAccountUseCase:
                              dependencies.accounts.deleteAccountUseCase,
                          getAccountsByMicrofinancieraUseCase:
                              dependencies.accounts
                                  .getAccountsByMicrofinancieraUseCase,
                          getAccountsByStatusUseCase:
                              dependencies.accounts.getAccountsByStatusUseCase,
                        );
                      },
                    ),
                    BlocProvider<CardBloc>(
                      create: (_) {
                        return CardBloc(
                          getUserCardsUseCase:
                              dependencies.cards.getUserCardsUseCase,
                          getCardsByAccountUseCase:
                              dependencies.cards.getCardsByAccountUseCase,
                          requestCardUseCase:
                              dependencies.cards.requestCardUseCase,
                          getCardsByStatusUseCase:
                              dependencies.cards.getCardsByStatusUseCase,
                          updateCardUseCase:
                              dependencies.cards.updateCardUseCase,
                          blockCardUseCase:
                              dependencies.cards.blockCardUseCase,
                          unblockCardUseCase:
                              dependencies.cards.unblockCardUseCase,
                          cancelCardUseCase:
                              dependencies.cards.cancelCardUseCase,
                          activateCardUseCase:
                              dependencies.cards.activateCardUseCase,
                          getCardByIdUseCase:
                              dependencies.cards.getCardByIdUseCase,
                          updateCardLimitsUseCase:
                              dependencies.cards.updateCardLimitsUseCase,
                          updateCardSecuritySettingsUseCase: dependencies
                              .cards.updateCardSecuritySettingsUseCase,
                        );
                      },
                    ),
                  ],
                  child: MaterialApp(
                    title: 'Avante',
                    debugShowCheckedModeBanner: false,
                    theme: AppTheme.lightTheme,
                    darkTheme: AppTheme.darkTheme,
                    themeMode: themeProvider.themeMode,
                    home: const AuthWrapper(),
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
