// lib/services/game_rules.dart
import '../models/card_models.dart';
import '../models/game_state.dart';

class GameRules {
  // 1. ระบบ Summon
  static bool canSummon(GameCard card, Map<ResourceType, int> available) {
    if (card.type == CardType.terrain) return true; // วางฟรีตอน setup
    for (var entry in card.cost.entries) {
      if ((available[entry.key] ?? 0) < entry.value) return false;
    }
    return true;
  }

  // 2. ระบบโจมตีแบบ situational (ไม่มีพลัง)
  static bool resolveAttack(GameCard attacker, GameCard defender, List<GameCard> battlefield) {
    if (attacker.isTapped) return false;

    // กรณีพิเศษ: ฆ่า Leader ได้ทันที
    if (defender.type == CardType.leader) return true;

    // ฐานทัพป้องกันกองทัพด้านหลัง
    final baseInFront = battlefield.any((c) =>
        c.type == CardType.base &&
        c.ownerId == defender.ownerId &&
        _isInFrontOf(c, defender, battlefield));
    if (baseInFront && attacker.keywords?.contains("flanking") != true) {
      return false; // โดนฐานทัพบล็อก
    }

    // ผลกระทบจากภูมิประเทศ
    final terrain = battlefield.where((c) => c.type == CardType.terrain && c.isFaceUp);
    for (var t in terrain) {
      if (t.effectText?.contains("mountain") == true && attacker.keywords?.contains("infantry") == true) {
        return false; // ภูเขาบล็อกทหารราบ
      }
    }

    // จารชนหักหลัง
    if (defender.keywords?.contains("betrayed") == true) return true;

    return true; // โจมตีสำเร็จตามปกติ
  }

  static bool _isInFrontOf(GameCard base, GameCard unit, List<GameCard> field) {
    // Logic ตำแหน่ง (สมมติเรียงจากบนลงล่าง)
    return true; // placeholder
  }

  // 3. ตรวจชัยชนะ 7 แบบ
  static String? checkVictory(GameState state) {
    final p1 = state.players[0]!;
    final p2 = state.players[1]!;

    // 1. ฆ่า Leader
    if (!state.battlefield.any((c) => c.type == CardType.leader && c.ownerId == p1)) return p2;
    if (!state.battlefield.any((c) => c.type == CardType.leader && c.ownerId == p2)) return p1;

    // 2. ทำลายฐานทัพทั้งหมด
    if (!state.battlefield.any((c) => c.type == CardType.base && c.ownerId == p1)) return p2;

    // 3. ยึดชัยภูมิทั้งหมด
    final allTerrain = state.battlefield.where((c) => c.type == CardType.terrain).length;
    final p1Terrain = state.battlefield.where((c) => c.type == CardType.terrain && c.ownerId == p1).length;
    if (p1Terrain == allTerrain && allTerrain > 0) return p1;

    // 4. ไม่เหลือทรัพยากร + ถูกโจมตีทุกพื้นที่
    if (state.playerResources[p1]?.isEmpty == true &&
        state.battlefield.where((c) => c.ownerId == p2 && c.type == CardType.unit).isNotEmpty) {
      return p2;
    }

    return null;
  }
}
