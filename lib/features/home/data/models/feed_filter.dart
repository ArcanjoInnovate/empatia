// lib/features/home/data/models/feed_filter.dart

import 'package:empatia/features/home/data/models/feed_item_.dart';

class FeedFilter {
  final FeedItemType? type;
  final String? stateCode; // sigla ex: "GO"
  final String? stateName; // nome ex: "Goiás"
  final String? city;

  const FeedFilter({
    this.type,
    this.stateCode,
    this.stateName,
    this.city,
  });

  bool get hasAny => type != null || stateCode != null || city != null;

  FeedFilter copyWith({
    FeedItemType? type,
    Object? stateCode = _sentinel,
    Object? stateName = _sentinel,
    Object? city = _sentinel,
  }) {
    return FeedFilter(
      type: type ?? this.type,
      stateCode: stateCode == _sentinel ? this.stateCode : stateCode as String?,
      stateName: stateName == _sentinel ? this.stateName : stateName as String?,
      city: city == _sentinel ? this.city : city as String?,
    );
  }

  static const _sentinel = Object();
}