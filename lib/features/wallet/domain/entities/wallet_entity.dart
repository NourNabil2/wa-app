import 'package:equatable/equatable.dart';

class WalletSummaryEntity extends Equatable {
  final double balance;
  final String balanceLabel;
  final String balanceLabelAr;
  /// Real money — refunds, admin adjustments, order-edit overpayments. Never expires.
  final double realMoneyBalance;
  /// Outstanding (unexpired, unspent) cashback. Can expire — see [expiringSoon].
  final double cashbackBalance;
  final WalletExpiringSoon? expiringSoon;
  final WalletStats stats;
  final List<WalletHistoryEntity> history;

  const WalletSummaryEntity({
    required this.balance,
    required this.balanceLabel,
    required this.balanceLabelAr,
    required this.realMoneyBalance,
    required this.cashbackBalance,
    this.expiringSoon,
    required this.stats,
    required this.history,
  });

  WalletSummaryEntity copyWith({List<WalletHistoryEntity>? history}) {
    return WalletSummaryEntity(
      balance: balance,
      balanceLabel: balanceLabel,
      balanceLabelAr: balanceLabelAr,
      realMoneyBalance: realMoneyBalance,
      cashbackBalance: cashbackBalance,
      expiringSoon: expiringSoon,
      stats: stats,
      history: history ?? this.history,
    );
  }

  @override
  List<Object?> get props => [balance, realMoneyBalance, cashbackBalance, expiringSoon, stats, history];
}

class WalletExpiringSoon extends Equatable {
  final double amount;
  final DateTime? expiresAt;
  final String label;
  final String labelAr;

  const WalletExpiringSoon({
    required this.amount,
    this.expiresAt,
    required this.label,
    required this.labelAr,
  });

  @override
  List<Object?> get props => [amount, expiresAt];
}

class WalletStats extends Equatable {
  final double totalCredited;
  final double totalSpent;
  final double totalCashback;
  final double totalRefunded;
  final double totalExpired;

  const WalletStats({
    required this.totalCredited,
    required this.totalSpent,
    required this.totalCashback,
    required this.totalRefunded,
    required this.totalExpired,
  });

  @override
  List<Object?> get props => [totalCredited, totalSpent, totalCashback, totalRefunded, totalExpired];
}

class WalletHistoryEntity extends Equatable {
  final String id;
  final String type;      // 'credit' | 'debit'
  final String source;    // 'refund' | 'cashback' | 'checkout_payment' | ...
  final double amount;
  final double balanceAfter;
  final String description;
  final String descriptionAr;
  final DateTime? expiresAt;
  final DateTime date;

  const WalletHistoryEntity({
    required this.id,
    required this.type,
    required this.source,
    required this.amount,
    required this.balanceAfter,
    required this.description,
    required this.descriptionAr,
    this.expiresAt,
    required this.date,
  });

  bool get isCredit => type == 'credit';

  @override
  List<Object?> get props => [id, type, source, amount, date];
}
