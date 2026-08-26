import 'package:fastway/features/wallet/domain/entities/wallet_entity.dart';

class WalletSummaryModel extends WalletSummaryEntity {
  const WalletSummaryModel({
    required super.balance,
    required super.balanceLabel,
    required super.balanceLabelAr,
    required super.realMoneyBalance,
    required super.cashbackBalance,
    super.expiringSoon,
    required super.stats,
    required super.history,
  });

  factory WalletSummaryModel.fromJson(Map<String, dynamic> json) {
    String ss(dynamic v, [String fallback = '']) {
      if (v == null) return fallback;
      if (v is String) return v;
      if (v is Map) return v['en']?.toString() ?? v.values.firstOrNull?.toString() ?? fallback;
      return v.toString();
    }

    final statsJson = json['stats'] as Map<String, dynamic>? ?? {};
    final expiringJson = json['expiring_soon'] as Map<String, dynamic>?;

    final balance = (json['balance'] as num?)?.toDouble() ?? 0.0;
    // Fall back to the full balance as "real money" if the backend hasn't
    // computed the split yet, so older responses still render sensibly.
    final cashbackBalance = (json['cashback_balance'] as num?)?.toDouble() ?? 0.0;
    final realMoneyBalance = (json['real_money_balance'] as num?)?.toDouble() ?? (balance - cashbackBalance);

    return WalletSummaryModel(
      balance: balance,
      balanceLabel: ss(json['balance_label']),
      balanceLabelAr: ss(json['balance_label_ar']),
      realMoneyBalance: realMoneyBalance,
      cashbackBalance: cashbackBalance,
      expiringSoon: expiringJson != null
          ? WalletExpiringSoon(
              amount: (expiringJson['amount'] as num?)?.toDouble() ?? 0.0,
              expiresAt: expiringJson['expires_at'] != null
                  ? DateTime.tryParse(expiringJson['expires_at'].toString())
                  : null,
              label: ss(expiringJson['label']),
              labelAr: ss(expiringJson['label_ar']),
            )
          : null,
      stats: WalletStats(
        totalCredited: (statsJson['total_credited'] as num?)?.toDouble() ?? 0.0,
        totalSpent: (statsJson['total_spent'] as num?)?.toDouble() ?? 0.0,
        totalCashback: (statsJson['total_cashback'] as num?)?.toDouble() ?? 0.0,
        totalRefunded: (statsJson['total_refunded'] as num?)?.toDouble() ?? 0.0,
        totalExpired: (statsJson['total_expired'] as num?)?.toDouble() ?? 0.0,
      ),
      history: (json['history'] as List<dynamic>?)
              ?.map((e) => WalletHistoryModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class WalletHistoryModel extends WalletHistoryEntity {
  const WalletHistoryModel({
    required super.id,
    required super.type,
    required super.source,
    required super.amount,
    required super.balanceAfter,
    required super.description,
    required super.descriptionAr,
    super.expiresAt,
    required super.date,
  });

  factory WalletHistoryModel.fromJson(Map<String, dynamic> json) {
    String ss(dynamic v, [String fallback = '']) {
      if (v == null) return fallback;
      if (v is String) return v;
      if (v is Map) return v['en']?.toString() ?? v.values.firstOrNull?.toString() ?? fallback;
      return v.toString();
    }

    return WalletHistoryModel(
      id: json['id']?.toString() ?? '',
      type: ss(json['type'], 'credit'),
      source: ss(json['source'], 'adjustment'),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      balanceAfter: (json['balance_after'] as num?)?.toDouble() ?? 0.0,
      description: ss(json['description']),
      descriptionAr: ss(json['description_ar']),
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'].toString())
          : null,
      date: json['date'] != null
          ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
