import 'package:equatable/equatable.dart';
import '../../../domain/entities/account.dart';
import '../../../domain/usecases/account/create_account_usecase.dart';

abstract class AccountEvent extends Equatable {
  const AccountEvent();

  @override
  List<Object?> get props => [];
}

class AccountLoadUserAccounts extends AccountEvent {
  final String userId;

  const AccountLoadUserAccounts(this.userId);

  @override
  List<Object?> get props => [userId];
}

class AccountCreate extends AccountEvent {
  final CreateAccountParams params;

  const AccountCreate(this.params);

  @override
  List<Object?> get props => [params];
}

class AccountUpdate extends AccountEvent {
  final Account account;

  const AccountUpdate(this.account);

  @override
  List<Object?> get props => [account];
}

class AccountDelete extends AccountEvent {
  final String accountId;
  final String microfinancieraId;

  const AccountDelete(this.accountId, this.microfinancieraId);

  @override
  List<Object?> get props => [accountId, microfinancieraId];
}

class AccountLoadById extends AccountEvent {
  final String accountId;
  final String microfinancieraId;

  const AccountLoadById(this.accountId, this.microfinancieraId);

  @override
  List<Object?> get props => [accountId, microfinancieraId];
}

class AccountLoadByMicrofinanciera extends AccountEvent {
  final String microfinancieraId;

  const AccountLoadByMicrofinanciera(this.microfinancieraId);

  @override
  List<Object?> get props => [microfinancieraId];
}

class AccountLoadByStatus extends AccountEvent {
  final String userId;
  final AccountStatus status;
  final String microfinancieraId;

  const AccountLoadByStatus(this.userId, this.status, this.microfinancieraId);

  @override
  List<Object?> get props => [userId, status, microfinancieraId];
}