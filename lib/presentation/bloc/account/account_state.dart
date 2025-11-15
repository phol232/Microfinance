import 'package:equatable/equatable.dart';
import '../../../domain/entities/account.dart';

abstract class AccountState extends Equatable {
  const AccountState();

  @override
  List<Object?> get props => [];
}

class AccountInitial extends AccountState {
  const AccountInitial();
}

class AccountLoading extends AccountState {
  const AccountLoading();
}

class AccountLoaded extends AccountState {
  final List<Account> accounts;

  const AccountLoaded(this.accounts);

  @override
  List<Object?> get props => [accounts];
}

class AccountSingleLoaded extends AccountState {
  final Account account;

  const AccountSingleLoaded(this.account);

  @override
  List<Object?> get props => [account];
}

class AccountCreated extends AccountState {
  final String accountId;

  const AccountCreated(this.accountId);

  @override
  List<Object?> get props => [accountId];
}

class AccountUpdated extends AccountState {
  const AccountUpdated();
}

class AccountDeleted extends AccountState {
  const AccountDeleted();
}

class AccountError extends AccountState {
  final String message;

  const AccountError(this.message);

  @override
  List<Object?> get props => [message];
}

class AccountCreating extends AccountState {
  const AccountCreating();
}

class AccountUpdating extends AccountState {
  const AccountUpdating();
}

class AccountDeleting extends AccountState {
  const AccountDeleting();
}