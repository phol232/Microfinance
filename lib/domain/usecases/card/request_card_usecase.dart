import '../../entities/card.dart';
import '../../repositories/card_repository.dart';
import '../core/usecase.dart';
import '../../core/error/failures.dart';
import 'package:fpdart/fpdart.dart';

class RequestCardUseCase implements UseCase<String, RequestCardParams> {
  final CardRepository repository;

  RequestCardUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(RequestCardParams params) async {
    try {
      final canRequestByType = await repository.canRequestCardByType(
        params.accountId,
        params.microfinancieraId,
        params.cardType,
        params.cardBrand,
      );
      
      if (!canRequestByType) {
        if (params.cardType == CardType.debit) {
          final brandName = params.cardBrand == CardBrand.visa ? 'Visa' : 'Mastercard';
          return Left(ValidationFailure(
            'Ya tienes una tarjeta de débito $brandName para esta cuenta o has alcanzado el límite máximo de 2 tarjetas de débito por cuenta.',
          ));
        } else {
          return const Left(
            ValidationFailure('No se puede solicitar una tarjeta de este tipo para esta cuenta'),
          );
        }
      }

      final card = Card(
        id: '',
        userId: params.userId,
        accountId: params.accountId,
        microfinancieraId: params.microfinancieraId,
        cardNumber: '',
        cardType: params.cardType,
        cardBrand: params.cardBrand,
        holderName: params.holderName,
        expiryDate: DateTime.now().add(const Duration(days: 1460)),
        status: CardStatus.requested,
        createdAt: DateTime.now(),
        dailyLimit: params.dailyLimit,
        monthlyLimit: params.monthlyLimit,
        atmLimit: params.atmLimit,
        onlineLimit: params.onlineLimit,
        requestReason: params.requestReason,
        deliveryAddress: params.deliveryAddress,
        deliveryDistrict: params.deliveryDistrict,
        deliveryProvince: params.deliveryProvince,
        deliveryDepartment: params.deliveryDepartment,
        deliveryPhone: params.deliveryPhone,
        additionalComments: params.additionalComments,
        isContactlessEnabled: params.isContactlessEnabled ?? true,
        isOnlineEnabled: params.isOnlineEnabled ?? true,
        isAtmEnabled: params.isAtmEnabled ?? true,
        isInternationalEnabled: params.isInternationalEnabled ?? false,
      );

      final id = await repository.requestCard(card, params.microfinancieraId);
      return Right(id);
    } catch (e) {
      return Left(UnknownFailure(e.toString(), code: 'request_card'));
    }
  }
}

class RequestCardParams {
  final String userId;
  final String accountId;
  final String microfinancieraId;
  final CardType cardType;
  final CardBrand cardBrand;
  final String holderName;

  // Límites solicitados
  final double? dailyLimit;
  final double? monthlyLimit;
  final double? atmLimit;
  final double? onlineLimit;

  // Información de solicitud
  final String requestReason;
  final String? deliveryAddress;
  final String? deliveryDistrict;
  final String? deliveryProvince;
  final String? deliveryDepartment;
  final String? deliveryPhone;
  final String? additionalComments;

  // Configuraciones de seguridad
  final bool? isContactlessEnabled;
  final bool? isOnlineEnabled;
  final bool? isAtmEnabled;
  final bool? isInternationalEnabled;

  RequestCardParams({
    required this.userId,
    required this.accountId,
    required this.microfinancieraId,
    required this.cardType,
    required this.cardBrand,
    required this.holderName,
    this.dailyLimit,
    this.monthlyLimit,
    this.atmLimit,
    this.onlineLimit,
    required this.requestReason,
    this.deliveryAddress,
    this.deliveryDistrict,
    this.deliveryProvince,
    this.deliveryDepartment,
    this.deliveryPhone,
    this.additionalComments,
    this.isContactlessEnabled,
    this.isOnlineEnabled,
    this.isAtmEnabled,
    this.isInternationalEnabled,
  });
}
