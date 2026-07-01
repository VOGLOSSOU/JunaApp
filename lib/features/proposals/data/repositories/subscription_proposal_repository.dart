import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/utils/enums.dart';
import '../../../subscriptions/domain/entities/meal_entity.dart';
import '../../domain/entities/subscription_proposal_entity.dart';

final subscriptionProposalRepositoryProvider =
    Provider<SubscriptionProposalRepository>((ref) {
  return SubscriptionProposalRepository(dio: ref.read(dioProvider));
});

class ProposalMealInput {
  final String mealId;
  final int quantity;
  final String? mealPricingLabel;

  const ProposalMealInput({
    required this.mealId,
    required this.quantity,
    this.mealPricingLabel,
  });

  Map<String, dynamic> toJson() => {
        'mealId': mealId,
        'quantity': quantity,
        if (mealPricingLabel != null) 'mealPricingLabel': mealPricingLabel,
      };
}

class SubscriptionProposalRepository {
  final Dio _dio;

  SubscriptionProposalRepository({required Dio dio}) : _dio = dio;

  Future<SubscriptionProposalEntity> createProposal({
    required String providerId,
    required SubscriptionType type,
    required SubscriptionCategory category,
    required SubscriptionDuration duration,
    String? message,
    required List<ProposalMealInput> meals,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.subscriptionProposals,
        data: {
          'providerId': providerId,
          'type': type.apiValue,
          'category': category.apiValue,
          'duration': duration.apiValue,
          if (message != null && message.trim().isNotEmpty) 'message': message.trim(),
          'meals': meals.map((m) => m.toJson()).toList(),
        },
      );
      final data = response.data['data'] as Map<String, dynamic>;
      return _mapProposal(data);
    } on DioException catch (e) {
      throw extractException(e);
    } catch (e) {
      throw Exception('Erreur de parsing: $e');
    }
  }

  Future<({List<SubscriptionProposalEntity> items, int total, int totalPages})>
      getMyProposals({
    ProposalStatus? status,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.mySubscriptionProposals,
        queryParameters: {
          'page': page,
          'limit': limit,
          if (status != null) 'status': _statusApiValue(status),
        },
      );
      final body = response.data;
      final data = body['data'];

      // L'API peut retourner la liste directement ou imbriquée dans un Map
      final List rawList;
      if (data is List) {
        rawList = data;
      } else if (data is Map) {
        rawList = (data['proposals'] ?? data['items'] ?? data['data'] ?? []) as List;
      } else {
        rawList = [];
      }

      // Pagination : peut être dans data['pagination'] ou à la racine de data
      int total;
      int totalPages;
      if (data is Map) {
        final pagination = data['pagination'] as Map?;
        total = pagination?['total'] as int? ?? data['total'] as int? ?? rawList.length;
        totalPages = pagination?['totalPages'] as int? ?? data['totalPages'] as int? ?? 1;
      } else {
        total = body['total'] as int? ?? rawList.length;
        totalPages = body['totalPages'] as int? ?? 1;
      }

      return (
        items: rawList.map((e) => _mapProposal(e as Map<String, dynamic>)).toList(),
        total: total,
        totalPages: totalPages,
      );
    } on DioException catch (e) {
      throw extractException(e);
    } catch (e) {
      throw Exception('Erreur de parsing: $e');
    }
  }

  Future<SubscriptionProposalEntity> getProposalById(String id) async {
    try {
      final response = await _dio.get(ApiEndpoints.subscriptionProposalById(id));
      final data = response.data['data'] as Map<String, dynamic>;
      return _mapProposal(data);
    } on DioException catch (e) {
      throw extractException(e);
    } catch (e) {
      throw Exception('Erreur de parsing: $e');
    }
  }

  static String _str(dynamic v, [String fallback = '']) {
    if (v == null) return fallback;
    if (v is String) return v;
    return v.toString();
  }

  static String _statusApiValue(ProposalStatus status) {
    switch (status) {
      case ProposalStatus.pending:
        return 'PENDING';
      case ProposalStatus.approved:
        return 'APPROVED';
      case ProposalStatus.rejected:
        return 'REJECTED';
    }
  }

  static ProposalStatus _parseStatus(String? status) {
    switch (status) {
      case 'APPROVED':
        return ProposalStatus.approved;
      case 'REJECTED':
        return ProposalStatus.rejected;
      case 'PENDING':
      default:
        return ProposalStatus.pending;
    }
  }

  static SubscriptionType _parseType(String? type) {
    switch (type) {
      case 'BREAKFAST':
        return SubscriptionType.breakfast;
      case 'DINNER':
        return SubscriptionType.dinner;
      case 'SNACK':
        return SubscriptionType.snack;
      case 'BREAKFAST_LUNCH':
        return SubscriptionType.breakfastLunch;
      case 'BREAKFAST_DINNER':
        return SubscriptionType.breakfastDinner;
      case 'LUNCH_DINNER':
        return SubscriptionType.lunchDinner;
      case 'FULL_DAY':
        return SubscriptionType.fullDay;
      case 'CUSTOM':
        return SubscriptionType.custom;
      case 'LUNCH':
      default:
        return SubscriptionType.lunch;
    }
  }

  static SubscriptionDuration _parseDuration(String? duration) {
    switch (duration) {
      case 'DAY':
        return SubscriptionDuration.day;
      case 'THREE_DAYS':
        return SubscriptionDuration.threeDays;
      case 'WEEK':
        return SubscriptionDuration.week;
      case 'TWO_WEEKS':
        return SubscriptionDuration.twoWeeks;
      case 'MONTH':
        return SubscriptionDuration.month;
      case 'WORK_WEEK_2':
        return SubscriptionDuration.workWeek2;
      case 'WORK_MONTH':
        return SubscriptionDuration.workMonth;
      case 'WEEKEND':
        return SubscriptionDuration.weekend;
      case 'WORK_WEEK':
      default:
        return SubscriptionDuration.workWeek;
    }
  }

  static SubscriptionCategory _parseCategory(String? category) {
    switch (category) {
      case 'EUROPEAN':
        return SubscriptionCategory.european;
      case 'ASIAN':
        return SubscriptionCategory.asian;
      case 'VEGETARIAN':
        return SubscriptionCategory.vegetarian;
      case 'HALAL':
        return SubscriptionCategory.halal;
      case 'VEGAN':
        return SubscriptionCategory.vegan;
      case 'FAST_FOOD':
        return SubscriptionCategory.fastFood;
      case 'HEALTHY':
        return SubscriptionCategory.healthy;
      case 'AMERICAN':
        return SubscriptionCategory.american;
      case 'FUSION':
        return SubscriptionCategory.fusion;
      case 'OTHER':
        return SubscriptionCategory.other;
      case 'AFRICAN':
      default:
        return SubscriptionCategory.african;
    }
  }

  static MealPriceType _parsePriceType(String? type) {
    switch (type) {
      case 'MULTIPLE':
        return MealPriceType.multiple;
      case 'RANGE':
        return MealPriceType.range;
      case 'FIXED':
      default:
        return MealPriceType.fixed;
    }
  }

  static SubscriptionProposalEntity _mapProposal(Map<String, dynamic> json) {
    final providerRaw = json['provider'];
    final providerJson = providerRaw is Map
        ? Map<String, dynamic>.from(providerRaw)
        : <String, dynamic>{};

    final meals = (json['meals'] as List? ?? []).map((m) {
      final mealJson = m as Map<String, dynamic>;
      final mealRaw = mealJson['meal'];
      final mealDetail =
          mealRaw is Map ? Map<String, dynamic>.from(mealRaw) : <String, dynamic>{};
      return ProposalMealEntity(
        mealId: _str(mealJson['mealId']),
        mealPricingLabel: mealJson['mealPricingLabel'] as String?,
        quantity: (mealJson['quantity'] as num?)?.toInt() ?? 1,
        mealName: _str(mealDetail['name']),
        mealImageUrl: _str(mealDetail['imageUrl']),
        mealPriceType: _parsePriceType(mealDetail['priceType'] as String?),
        mealPrice: (mealDetail['price'] as num?)?.toInt() ?? 0,
      );
    }).toList();

    return SubscriptionProposalEntity(
      id: _str(json['id']),
      type: _parseType(json['type'] as String?),
      category: _parseCategory(json['category'] as String?),
      duration: _parseDuration(json['duration'] as String?),
      message: _str(json['message']),
      status: _parseStatus(json['status'] as String?),
      rejectionReason: json['rejectionReason'] as String?,
      resultingSubscriptionId: json['resultingSubscriptionId'] as String?,
      providerId: _str(providerJson['id']),
      providerName: _str(providerJson['businessName'] ?? providerJson['name']),
      providerLogo: _str(providerJson['logo']),
      meals: meals,
      createdAt: DateTime.tryParse(_str(json['createdAt'])) ?? DateTime.now(),
    );
  }
}
