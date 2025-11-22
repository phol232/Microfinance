import '../../data/datasources/account_datasource.dart';
import '../../data/datasources/card_datasource.dart';
import '../../data/datasources/firebase_auth_datasource.dart';
import '../../data/datasources/intake_request_datasource.dart';
import '../../data/datasources/loan_application_datasource.dart';
import '../../data/repositories/account_repository_impl.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/card_repository_impl.dart';
import '../../data/repositories/intake_request_repository_impl.dart';
import '../../data/repositories/loan_application_repository_impl.dart';
import '../../domain/repositories/account_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/card_repository.dart';
import '../../domain/repositories/intake_request_repository.dart';
import '../../domain/repositories/loan_application_repository.dart';
import '../../domain/usecases/account/create_account_usecase.dart';
import '../../domain/usecases/account/delete_account_usecase.dart';
import '../../domain/usecases/account/get_account_by_id_usecase.dart';
import '../../domain/usecases/account/get_accounts_by_microfinanciera_usecase.dart';
import '../../domain/usecases/account/get_accounts_by_status_usecase.dart';
import '../../domain/usecases/account/get_user_accounts_usecase.dart';
import '../../domain/usecases/account/update_account_usecase.dart';
import '../../domain/usecases/auth/anonymous_signin_usecase.dart';
import '../../domain/usecases/auth/get_current_user_usecase.dart';
import '../../domain/usecases/auth/get_microfinancieras_usecase.dart';
import '../../domain/usecases/auth/google_signin_usecase.dart';
import '../../domain/usecases/auth/login_user_usecase.dart';
import '../../domain/usecases/auth/logout_user_usecase.dart';
import '../../domain/usecases/auth/register_user_usecase.dart';
import '../../domain/usecases/auth/validate_user_access_usecase.dart';
import '../../domain/usecases/card/change_card_status_usecase.dart';
import '../../domain/usecases/card/get_card_by_id_usecase.dart';
import '../../domain/usecases/card/get_cards_by_account_usecase.dart';
import '../../domain/usecases/card/get_cards_by_status_usecase.dart';
import '../../domain/usecases/card/get_user_cards_usecase.dart';
import '../../domain/usecases/card/request_card_usecase.dart';
import '../../domain/usecases/card/update_card_limits_usecase.dart';
import '../../domain/usecases/card/update_card_security_settings_usecase.dart';
import '../../domain/usecases/card/update_card_usecase.dart';
import '../../domain/usecases/intake_request/get_all_intake_requests_usecase.dart';
import '../../domain/usecases/intake_request/get_intake_request_by_id_usecase.dart';
import '../../domain/usecases/intake_request/get_intake_request_status_counts_usecase.dart';
import '../../domain/usecases/intake_request/get_intake_requests_by_status_usecase.dart';
import '../../domain/usecases/intake_request/get_recent_intake_requests_usecase.dart';
import '../../domain/usecases/profile/check_dni_exists_usecase.dart';
import '../../domain/usecases/profile/get_user_profile_usecase.dart';
import '../../domain/usecases/profile/update_user_profile_usecase.dart';
import '../../infrastructure/tenant/tenant_controller.dart';

class AuthUseCases {
  AuthUseCases({
    required this.loginUserUseCase,
    required this.registerUserUseCase,
    required this.logoutUserUseCase,
    required this.getCurrentUserUseCase,
    required this.getMicrofinancierasUseCase,
    required this.googleSignInUseCase,
    required this.anonymousSignInUseCase,
    required this.validateUserAccessUseCase,
  });

  final LoginUserUseCase loginUserUseCase;
  final RegisterUserUseCase registerUserUseCase;
  final LogoutUserUseCase logoutUserUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final GetMicrofinancierasUseCase getMicrofinancierasUseCase;
  final GoogleSignInUseCase googleSignInUseCase;
  final AnonymousSignInUseCase anonymousSignInUseCase;
  final ValidateUserAccessUseCase validateUserAccessUseCase;
}

class ProfileUseCases {
  ProfileUseCases({
    required this.getUserProfileUseCase,
    required this.updateUserProfileUseCase,
    required this.checkDniExistsUseCase,
  });

  final GetUserProfileUseCase getUserProfileUseCase;
  final UpdateUserProfileUseCase updateUserProfileUseCase;
  final CheckDniExistsUseCase checkDniExistsUseCase;
}

class IntakeRequestUseCases {
  IntakeRequestUseCases({
    required this.getAllIntakeRequestsUseCase,
    required this.getIntakeRequestsByStatusUseCase,
    required this.getRecentIntakeRequestsUseCase,
    required this.getIntakeRequestByIdUseCase,
    required this.getIntakeRequestStatusCountsUseCase,
  });

  final GetAllIntakeRequestsUseCase getAllIntakeRequestsUseCase;
  final GetIntakeRequestsByStatusUseCase getIntakeRequestsByStatusUseCase;
  final GetRecentIntakeRequestsUseCase getRecentIntakeRequestsUseCase;
  final GetIntakeRequestByIdUseCase getIntakeRequestByIdUseCase;
  final GetIntakeRequestStatusCountsUseCase getIntakeRequestStatusCountsUseCase;
}

class AccountUseCases {
  AccountUseCases({
    required this.getUserAccountsUseCase,
    required this.getAccountByIdUseCase,
    required this.createAccountUseCase,
    required this.updateAccountUseCase,
    required this.deleteAccountUseCase,
    required this.getAccountsByMicrofinancieraUseCase,
    required this.getAccountsByStatusUseCase,
  });

  final GetUserAccountsUseCase getUserAccountsUseCase;
  final GetAccountByIdUseCase getAccountByIdUseCase;
  final CreateAccountUseCase createAccountUseCase;
  final UpdateAccountUseCase updateAccountUseCase;
  final DeleteAccountUseCase deleteAccountUseCase;
  final GetAccountsByMicrofinancieraUseCase getAccountsByMicrofinancieraUseCase;
  final GetAccountsByStatusUseCase getAccountsByStatusUseCase;
}

class CardUseCases {
  CardUseCases({
    required this.getUserCardsUseCase,
    required this.getCardsByAccountUseCase,
    required this.requestCardUseCase,
    required this.getCardsByStatusUseCase,
    required this.getCardByIdUseCase,
    required this.updateCardUseCase,
    required this.blockCardUseCase,
    required this.unblockCardUseCase,
    required this.cancelCardUseCase,
    required this.activateCardUseCase,
    required this.updateCardLimitsUseCase,
    required this.updateCardSecuritySettingsUseCase,
  });

  final GetUserCardsUseCase getUserCardsUseCase;
  final GetCardsByAccountUseCase getCardsByAccountUseCase;
  final RequestCardUseCase requestCardUseCase;
  final GetCardsByStatusUseCase getCardsByStatusUseCase;
  final GetCardByIdUseCase getCardByIdUseCase;
  final UpdateCardUseCase updateCardUseCase;
  final BlockCardUseCase blockCardUseCase;
  final UnblockCardUseCase unblockCardUseCase;
  final CancelCardUseCase cancelCardUseCase;
  final ActivateCardUseCase activateCardUseCase;
  final UpdateCardLimitsUseCase updateCardLimitsUseCase;
  final UpdateCardSecuritySettingsUseCase updateCardSecuritySettingsUseCase;
}

class AppDependencies {
  AppDependencies._({
    required this.tenantController,
    required this.authRepository,
    required this.intakeRequestRepository,
    required this.loanApplicationRepository,
    required this.accountRepository,
    required this.cardRepository,
    required this.auth,
    required this.profile,
    required this.intakeRequests,
    required this.accounts,
    required this.cards,
  });

  final TenantController tenantController;
  final AuthRepository authRepository;
  final IntakeRequestRepository intakeRequestRepository;
  final LoanApplicationRepository loanApplicationRepository;
  final AccountRepository accountRepository;
  final CardRepository cardRepository;

  final AuthUseCases auth;
  final ProfileUseCases profile;
  final IntakeRequestUseCases intakeRequests;
  final AccountUseCases accounts;
  final CardUseCases cards;

  static Future<AppDependencies> init() async {
    final tenantController = TenantController();
    await tenantController.initialize();

    final authRepository = AuthRepositoryImpl(
      dataSource: FirebaseAuthDataSource(),
    );
    final intakeRequestRepository = IntakeRequestRepositoryImpl(
      IntakeRequestDataSource(tenantResolver: tenantController),
    );
    final loanApplicationRepository = LoanApplicationRepositoryImpl(
      dataSource: LoanApplicationDataSource(),
    );
    final accountRepository = AccountRepositoryImpl(
      accountDataSource: AccountDataSource(tenantResolver: tenantController),
    );
    final cardRepository = CardRepositoryImpl(cardDataSource: CardDataSource());

    final authUseCases = AuthUseCases(
      loginUserUseCase: LoginUserUseCase(authRepository),
      registerUserUseCase: RegisterUserUseCase(authRepository),
      logoutUserUseCase: LogoutUserUseCase(authRepository),
      getCurrentUserUseCase: GetCurrentUserUseCase(authRepository),
      getMicrofinancierasUseCase: GetMicrofinancierasUseCase(authRepository),
      googleSignInUseCase: GoogleSignInUseCase(authRepository),
      anonymousSignInUseCase: AnonymousSignInUseCase(authRepository),
      validateUserAccessUseCase: ValidateUserAccessUseCase(authRepository),
    );

    final profileUseCases = ProfileUseCases(
      getUserProfileUseCase: GetUserProfileUseCase(authRepository),
      updateUserProfileUseCase: UpdateUserProfileUseCase(authRepository),
      checkDniExistsUseCase: CheckDniExistsUseCase(authRepository),
    );

    final intakeRequestUseCases = IntakeRequestUseCases(
      getAllIntakeRequestsUseCase: GetAllIntakeRequestsUseCase(
        intakeRequestRepository,
      ),
      getIntakeRequestsByStatusUseCase: GetIntakeRequestsByStatusUseCase(
        intakeRequestRepository,
      ),
      getRecentIntakeRequestsUseCase: GetRecentIntakeRequestsUseCase(
        intakeRequestRepository,
      ),
      getIntakeRequestByIdUseCase: GetIntakeRequestByIdUseCase(
        intakeRequestRepository,
      ),
      getIntakeRequestStatusCountsUseCase: GetIntakeRequestStatusCountsUseCase(
        intakeRequestRepository,
      ),
    );

    final accountUseCases = AccountUseCases(
      getUserAccountsUseCase: GetUserAccountsUseCase(accountRepository),
      getAccountByIdUseCase: GetAccountByIdUseCase(accountRepository),
      createAccountUseCase: CreateAccountUseCase(accountRepository),
      updateAccountUseCase: UpdateAccountUseCase(accountRepository),
      deleteAccountUseCase: DeleteAccountUseCase(accountRepository),
      getAccountsByMicrofinancieraUseCase: GetAccountsByMicrofinancieraUseCase(
        accountRepository,
      ),
      getAccountsByStatusUseCase: GetAccountsByStatusUseCase(accountRepository),
    );

    final cardUseCases = CardUseCases(
      getUserCardsUseCase: GetUserCardsUseCase(cardRepository),
      getCardsByAccountUseCase: GetCardsByAccountUseCase(cardRepository),
      requestCardUseCase: RequestCardUseCase(cardRepository),
      getCardsByStatusUseCase: GetCardsByStatusUseCase(cardRepository),
      getCardByIdUseCase: GetCardByIdUseCase(cardRepository),
      updateCardUseCase: UpdateCardUseCase(cardRepository),
      blockCardUseCase: BlockCardUseCase(cardRepository),
      unblockCardUseCase: UnblockCardUseCase(cardRepository),
      cancelCardUseCase: CancelCardUseCase(cardRepository),
      activateCardUseCase: ActivateCardUseCase(cardRepository),
      updateCardLimitsUseCase: UpdateCardLimitsUseCase(cardRepository),
      updateCardSecuritySettingsUseCase: UpdateCardSecuritySettingsUseCase(
        cardRepository,
      ),
    );

    return AppDependencies._(
      tenantController: tenantController,
      authRepository: authRepository,
      intakeRequestRepository: intakeRequestRepository,
      loanApplicationRepository: loanApplicationRepository,
      accountRepository: accountRepository,
      cardRepository: cardRepository,
      auth: authUseCases,
      profile: profileUseCases,
      intakeRequests: intakeRequestUseCases,
      accounts: accountUseCases,
      cards: cardUseCases,
    );
  }
}
