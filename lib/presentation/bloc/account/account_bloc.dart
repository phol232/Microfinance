import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';

import '../../../domain/entities/account.dart';
import '../../../domain/repositories/account_repository.dart';
import '../../../domain/usecases/account/get_user_accounts_usecase.dart';
import '../../../domain/usecases/account/get_account_by_id_usecase.dart';
import '../../../domain/usecases/account/create_account_usecase.dart';
// TODO: Implementar notificaciones más adelante
// import '../../../services/notification_service.dart';
// import '../../../domain/entities/notification.dart';
import 'account_event.dart';
import 'account_state.dart';

class AccountBloc extends Bloc<AccountEvent, AccountState> {
  final AccountRepository _accountRepository;
  final CreateAccountUseCase _createAccountUseCase;
  final GetUserAccountsUseCase _getUserAccountsUseCase;
  final GetAccountByIdUseCase _getAccountByIdUseCase;

  StreamSubscription<List<Account>>? _accountsSubscription;

  AccountBloc({
    required AccountRepository accountRepository,
    required CreateAccountUseCase createAccountUseCase,
    required GetUserAccountsUseCase getUserAccountsUseCase,
    required GetAccountByIdUseCase getAccountByIdUseCase,
  }) : _accountRepository = accountRepository,
       _createAccountUseCase = createAccountUseCase,
       _getUserAccountsUseCase = getUserAccountsUseCase,
       _getAccountByIdUseCase = getAccountByIdUseCase,
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
        (accounts) => emit(AccountLoaded(accounts)),
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
      
      final accountId = await _createAccountUseCase(event.params);
      emit(AccountCreated(accountId));
      
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
      
      await _accountRepository.updateAccount(event.account);
      emit(const AccountUpdated());
      
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
      
      await _accountRepository.deleteAccount(event.accountId, event.microfinancieraId);
      emit(const AccountDeleted());
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
      final account = await _getAccountByIdUseCase(params);
      if (account != null) {
        emit(AccountSingleLoaded(account));
      } else {
        emit(const AccountError('Cuenta no encontrada'));
      }
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
      _accountsSubscription = _accountRepository
          .getAccountsByMicrofinanciera(event.microfinancieraId)
          .listen(
            (accounts) => emit(AccountLoaded(accounts)),
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
      _accountsSubscription = _accountRepository
          .getAccountsByStatus(event.userId, event.status, event.microfinancieraId)
          .listen(
            (accounts) => emit(AccountLoaded(accounts)),
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