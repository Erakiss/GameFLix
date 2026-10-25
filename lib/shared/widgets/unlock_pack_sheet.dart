// lib/shared/widgets/unlock_pack_sheet.dart
import 'package:flutter/material.dart';
import 'package:gameflix/services/ad_manager.dart';
import 'package:gameflix/state/access_control_provider.dart';

/// Boîte de dialogue modale permettant de débloquer un pack ou une catégorie Spicy :
/// Option 1 : Abonnement VIP permanent (RevenueCat).
/// Option 2 : Visionnage d'une publicité récompensée AdMob (déblocage pour la partie en cours).
class UnlockPackSheet extends StatelessWidget {
  final String packId;
  final String packTitle;
  final VoidCallback onUnlocked;

  const UnlockPackSheet({
    super.key,
    required this.packId,
    required this.packTitle,
    required this.onUnlocked,
  });

  /// Ouvre la modale de déblocage
  static Future<void> show(
    BuildContext context, {
    required String packId,
    required String packTitle,
    required VoidCallback onUnlocked,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF16162D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (_) => UnlockPackSheet(
        packId: packId,
        packTitle: packTitle,
        onUnlocked: onUnlocked,
      ),
    );
  }

  void _watchRewardedAd(BuildContext context) {
    final access = AccessControlProvider.instance;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Chargement de la vidéo récompensée... 🎬"),
        duration: Duration(seconds: 2),
      ),
    );

    AdManager.instance.showRewardedAd(
      onUserEarnedReward: () {
        access.unlockTemporarily(packId);
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        onUnlocked();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("🔥 $packTitle débloqué pour cette partie !"),
            backgroundColor: Colors.greenAccent.shade700,
          ),
        );
      },
      onAdFailed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Vidéo indisponible ou appareil hors-ligne. Réessaie dans un instant !"),
            backgroundColor: Colors.redAccent,
          ),
        );
      },
    );
  }

  void _buySubscription(BuildContext context) async {
    final access = AccessControlProvider.instance;
    final success = await access.purchaseSubscription();

    if (!context.mounted) return;

    if (success) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      onUnlocked();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("👑 Bienvenue VIP ! Tous les packs sont débloqués à vie !"),
          backgroundColor: Colors.pinkAccent,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Achat annulé ou indisponible."),
          backgroundColor: Colors.orangeAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. En-tête avec cadenas néon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.redAccent, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.redAccent.withValues(alpha: 0.4),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(Icons.lock_rounded, color: Colors.redAccent, size: 36),
            ),
            const SizedBox(height: 16),

            Text(
              "DÉBLOQUER $packTitle".toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),

            const Text(
              "Ce contenu Spicy est réservé aux membres VIP ou débloquable pour cette session de jeu !",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: 25),

            // 2. Option 1 : Déblocage 1 partie (Gratuit via Rewarded Ad)
            InkWell(
              onTap: () => _watchRewardedAd(context),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.cyanAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.cyanAccent, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyanAccent.withValues(alpha: 0.2),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Colors.cyanAccent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 24),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "DÉBLOQUER 1 PARTIE",
                            style: TextStyle(
                              color: Colors.cyanAccent,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "Regarde 1 courte vidéo pour jouer maintenant",
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const Text(
                      "GRATUIT",
                      style: TextStyle(
                        color: Colors.cyanAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // 3. Option 2 : Pass VIP Illimité (RevenueCat)
            InkWell(
              onTap: () => _buySubscription(context),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.pinkAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.pinkAccent, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.pinkAccent.withValues(alpha: 0.2),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Colors.pinkAccent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "PASS VIP ILLIMITÉ",
                            style: TextStyle(
                              color: Colors.pinkAccent,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "Tous les packs débloqués, zéro publicité",
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.pinkAccent, size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),

            // 4. Bouton Annuler
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                "Plus tard",
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
