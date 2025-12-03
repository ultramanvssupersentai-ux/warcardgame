// lib/providers/game_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_state.dart';
import '../services/game_rules.dart';

final gameProvider = StateNotifierProvider.family<GameNotifier, GameState, String>(
  (ref, gameId) => GameNotifier(gameId),
);

class GameNotifier extends StateNotifier<GameState> {
  GameNotifier(String gameId) : super(GameState.loading()) {
    FirebaseFirestore.instance
        .collection('games')
        .doc(gameId)
        .snapshots()
        .listen((snap) {
      if (snap.exists) state = GameState.fromJson(snap.data()!);
    });
  }

  Future<void> summonCard(String playerId, GameCard card, {bool isFaceDown = false}) async {
    if (!GameRules.canSummon(card, state.playerResources[playerId] ?? {})) return;

    // หักทรัพยากร
    final newResources = Map<ResourceType, int>.from(state.playerResources[playerId] ?? {});
    for (var cost in card.cost.entries) {
      newResources[cost.key] = (newResources[cost.key] ?? 0) - cost.value;
    }

    final newCard = card.copyWith(
      ownerId: playerId,
      isFaceUp: !isFaceDown,
    );

    await FirebaseFirestore.instance.collection('games').doc(state.gameId).update({
      'battlefield': FieldValue.arrayUnion([newCard.toJson()]),
      'playerResources.$playerId': newResources,
    });
  }

  Future<void> attack(String attackerId, String targetId) async {
    final attacker = state.battlefield.firstWhere((c) => c.id == attackerId);
    final defender = state.battlefield.firstWhere((c) => c.id == targetId);

    if (GameRules.resolveAttack(attacker, defender, state.battlefield)) {
      await FirebaseFirestore.instance.collection('games').doc(state.gameId).update({
        'battlefield': FieldValue.arrayRemove([defender.toJson()]),
      });

      // ตรวจชัยชนะ
      final winner = GameRules.checkVictory(state);
      if (winner != null) {
        await FirebaseFirestore.instance.collection('games').doc(state.gameId).update({'winnerId': winner});
      }
    }
  }

  Future<void> revealTerrain(String cardId) async {
    final index = state.battlefield.indexWhere((c) => c.id == cardId);
    final card = state.battlefield[index];
    if (card.type == CardType.terrain) {
      final updated = card.copyWith(isFaceUp: true);
      final list = [...state.battlefield]..[index] = updated;
      await FirebaseFirestore.instance.collection('games').doc(state.gameId).update({
        'battlefield': list.map((e) => e.toJson()).toList(),
      });
    }
  }

  }

  // + endTurn, sendIntel, buySpy, tradeResource ฯลฯ เพิ่มได้หมด
}
