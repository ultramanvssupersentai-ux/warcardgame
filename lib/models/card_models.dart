// lib/models/card_models.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'card_models.freezed.dart';
part 'card_models.g.dart';

enum CardType { leader, terrain, base, unit, resource, spy, intel }
enum ResourceType { gold, ore, wood }

@freezed
class GameCard with _$GameCard {
  const factory GameCard({
    required String id,
    required String name,
    required CardType type,
    required Map<ResourceType, int> cost, // ราคาสร้าง
    required String ownerId,
    String? displayedOwnerId,
    @Default(false) bool isFaceUp,
    @Default(false) bool isTapped,
    @Default(false) bool isToken, // สำหรับทรัพยากรที่ยึดมา
    ResourceType? resourceType,
    String? effectText,
    List<String>? keywords, // เช่น "infantry", "ranged", "stealth", "unbuyable"
  }) = _GameCard;

  factory GameCard.fromJson(Map<String, dynamic> json) => _$GameCardFromJson(json);
}
