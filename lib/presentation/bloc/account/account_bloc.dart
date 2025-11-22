import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:fpdart/fpdart.dart';

import '../../../domain/core/error/failures.dart';
import '../../../domain/entities/account.dart';
import '../../../domain/usecases/account/get_user_accounts_usecase.dart';
import '../../../domain/usecases/account/get_account_by_id_usecase.dart';
import '../../../domain/usecases/account/create_account_usecase.dart';
import '../../../domain/usecases/account/update_account_usecase.dart';
import '../../../domain/usecases/account/delete_account_usecase.dart';
import '../../../domain/usecases/account/get_accounts_by_status_usecase.dart';
import '../../../domain/usecases/account/get_accounts_by_microfinanciera_usecase.dart';
// TODO: Implementar notificaciones más adelante
// import '../../../services/notification_service.dart';
// import '../../../domain/entities/notification.dart';
import 'account_event.dart';
import 'account_state.dart';

class AccountBloc extends Bloc<AccountEvent, AccountState> {
  final CreateAccountUseCase _createAccountUseCase;
  final GetUserAccountsUseCase _getUserAccountsUseCase;
  final GetAccountByIdUseCase _getAccountByIdUseCase;
  final UpdateAccountUseCase _updateAccountUseCase;
  final DeleteAccountUseCase _deleteAccountUseCase;
  final GetAccountsByMicrofinancieraUseCase
  _getAccountsByMicrofinancieraUseCase;
  final GetAccountsByStatusUseCase _getAccountsByStatusUseCase;

  StreamSubscription<Either<Failure, List<Account>>>? _accountsSubscription;

  AccountBloc({
    required CreateAccountUseCase createAccountUseCase,
    required GetUserAccountsUseCase getUserAccountsUseCase,
    required GetAccountByIdUseCase getAccountByIdUseCase,
    required UpdateAccountUseCase updateAccountUseCase,
    required DeleteAccountUseCase deleteAccountUseCase,
    required GetAccountsByMicrofinancieraUseCase
    getAccountsByMicrofinancieraUseCase,
    required GetAccountsByStatusUseCase getAccountsByStatusUseCase,
  }) : _createAccountUseCase = createAccountUseCase,
       _getUserAccountsUseCase = getUserAccountsUseCase,
       _getAccountByIdUseCase = getAccountByIdUseCase,
       _updateAccountUseCase = updateAccountUseCase,
       _deleteAccountUseCase = deleteAccountUseCase,
       _getAccountsByMicrofinancieraUseCase =
           getAccountsByMicrofinancieraUseCase,
       _getAccountsByStatusUseCase = getAccountsByStatusUseCase,
       super(const AccountInitial()) {
    on<AccountLoadUserAccounts>(_onAccountLoadUserAccounts);
    on<AccountCreate>(_onAccountCreate);
    on<AccountUpdate>(_onAccountUpdate);
    on<AccountDelete>(_onAccountDelete);
    on<AccountLoadById>(_onAccountLoadById);
    on<AccountLoadByMicrofinanciera>(_onAccountLoadByMicrofinanciera);
    on<AccountLoadByStatus>(_onAccountLoadByStatus);
  }

  Future<void> _onAccountLoadUserAccounts(
    AccountLoadUserAccounts event,
    Emitter<AccountState> emit,
  ) async {
    try {
      emit(const AccountLoading());

      await _accountsSubscription?.cancel();
      _accountsSubscription = _getUserAccountsUseCase(event.userId).listen(
        (result) => result.match(
          (failure) => emit(AccountError(failure.message)),
          (accounts) => emit(AccountLoaded(accounts)),
        ),
        onError: (error) => emit(AccountError(error.toString())),
      );
    } catch (e) {
      emit(AccountError(e.toString()));
    }
  }

  Future<void> _onAccountCreate(
    AccountCreate event,
    Emitter<AccountState> emit,
  ) async {
    try {
      emit(const AccountCreating());

      final result = await _createAccountUseCase(event.params);
      result.match(
        (failure) => emit(AccountError(failure.message)),
        (accountId) => emit(AccountCreated(accountId)),
      );

      // TODO: Implementar notificaciones más adelante
      // Enviar notificación de cuenta creada
      // await NotificationService.sendNotification(
      //   userId: event.params.userId,
      //   title: '¡Felicidades!',
      //   message: 'Tu cuenta ha sido activada exitosamente',
      //   type: NotificationType.accountActivated,
      //   data: {
      //     'accountId': accountId,
      //     'accountType': event.params.accountType.name,
      //   },
      // );

      // Recargar las cuentas del usuario
      add(AccountLoadUserAccounts(event.params.userId));
    } catch (e) {
      emit(AccountError(e.toString()));
    }
  }

  Future<void> _onAccountUpdate(
    AccountUpdate event,
    Emitter<AccountState> emit,
  ) async {
    try {
      emit(const AccountUpdating());

      final result = await _updateAccountUseCase(event.account);
      result.match(
        (failure) => emit(AccountError(failure.message)),
        (_) => emit(const AccountUpdated()),
      );

      // Recargar las cuentas del usuario
      add(AccountLoadUserAccounts(event.account.userId));
    } catch (e) {
      emit(AccountError(e.toString()));
    }
  }

  Future<void> _onAccountDelete(
    AccountDelete event,
    Emitter<AccountState> emit,
  ) async {
    try {
      emit(const AccountDeleting());

      final params = DeleteAccountParams(
        accountId: event.accountId,
        microfinancieraId: event.microfinancieraId,
      );
      final result = await _deleteAccountUseCase(params);
      result.match(
        (failure) => emit(AccountError(failure.message)),
        (_) => emit(const AccountDeleted()),
      );
    } catch (e) {
      emit(AccountError(e.toString()));
    }
  }

  Future<void> _onAccountLoadById(
    AccountLoadById event,
    Emitter<AccountState> emit,
  ) async {
    try {
      emit(const AccountLoading());

      final params = GetAccountByIdParams(
        accountId: event.accountId,
        microfinancieraId: event.microfinancieraId,
      );
      final accountResult = await _getAccountByIdUseCase(params);
      accountResult.match((failure) => emit(AccountError(failure.message)), (
        account,
      ) {
        if (account != null) {
          emit(AccountSingleLoaded(account));
        } else {
          emit(const AccountError('Cuenta no encontrada'));
        }
      });
    } catch (e) {
      emit(AccountError(e.toString()));
    }
  }

  Future<void> _onAccountLoadByMicrofinanciera(
    AccountLoadByMicrofinanciera event,
    Emitter<AccountState> emit,
  ) async {
    try {
      emit(const AccountLoading());

      await _accountsSubscription?.cancel();
      _accountsSubscription =
          _getAccountsByMicrofinancieraUseCase(event.microfinancieraId).listen(
            (result) => result.match(
              (failure) => emit(AccountError(failure.message)),
              (accounts) => emit(AccountLoaded(accounts)),
            ),
            onError: (error) => emit(AccountError(error.toString())),
          );
    } catch (e) {
      emit(AccountError(e.toString()));
    }
  }

  Future<void> _onAccountLoadByStatus(
    AccountLoadByStatus event,
    Emitter<AccountState> emit,
  ) async {
    try {
      emit(const AccountLoading());

      await _accountsSubscription?.cancel();
      _accountsSubscription =
          _getAccountsByStatusUseCase(
            GetAccountsByStatusParams(
              userId: event.userId,
              status: event.status,
              microfinancieraId: event.microfinancieraId,
            ),
          ).listen(
            (result) => result.match(
              (failure) => emit(AccountError(failure.message)),
              (accounts) => emit(AccountLoaded(accounts)),
            ),
            onError: (error) => emit(AccountError(error.toString())),
          );
    } catch (e) {
      emit(AccountError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _accountsSubscription?.cancel();
    return super.close();
  }
}
