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
      onUserEarnedReward: () async {
        await access.activateOneHourPass();
        access.unlockTemporarily(packId);
        if (context.mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        onUnlocked();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("🔥 Pass Soirée 1H activé ! Tout est débloqué pendant 60 minutes !"),
              backgroundColor: Colors.greenAccent.shade700,
            ),
          );
        }
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

  void _buyPlan(BuildContext context, {required bool isAnnual}) async {
    final access = AccessControlProvider.instance;
    final success = await access.purchasePlan(isAnnual: isAnnual);

    if (!context.mounted) return;

    if (success) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      onUnlocked();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("👑 Bienvenue VIP ! Tous les packs sont débloqués et zéro pub !"),
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

  void _restorePurchases(BuildContext context) async {
    final access = AccessControlProvider.instance;
    final success = await access.restorePurchases();

    if (!context.mounted) return;

    if (success) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      onUnlocked();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✨ Achats restaurés avec succès !"),
          backgroundColor: Colors.greenAccent,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Aucun abonnement actif trouvé à restaurer."),
          backgroundColor: Colors.orangeAccent,
        ),
      );
    }
  }

  Widget _buildOneHourPassOption(BuildContext context) {
    final access = AccessControlProvider.instance;

    // Cas 1 : L'essai a déjà été utilisé et n'est plus actif
    if (access.hasUsedOneHourTrial && !access.isPass1hActive) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24, width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_clock_rounded, color: Colors.white38, size: 24),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "ESSAI 1H DÉJÀ UTILISÉ",
                    style: TextStyle(
                      color: Colors.white38,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    "Offre unique par téléphone déjà consommée",
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Text(
              "EXPIRÉ",
              style: TextStyle(
                color: Colors.white38,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    }

    // Cas 2 : Le pass 1H est actuellement actif
    if (access.isPass1hActive) {
      final remaining = access.pass1hRemainingTime;
      final minutes = remaining.inMinutes;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.amberAccent, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.amberAccent.withValues(alpha: 0.25),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Colors.amberAccent,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.local_fire_department_rounded, color: Colors.black, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "PASS 1H ACTIF",
                    style: TextStyle(
                      color: Colors.amberAccent,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Encore ~$minutes min de déblocage total pour la soirée !",
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.check_circle_rounded, color: Colors.amberAccent, size: 22),
          ],
        ),
      );
    }

    // Cas 3 : Essai 1H disponible (gratuit via pub récompensée)
    return InkWell(
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
                    "PASS SOIRÉE 1H GRATUIT",
                    style: TextStyle(
                      color: Colors.cyanAccent,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    "Regarde 1 vidéo pour TOUT débloquer (Essai unique)",
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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

            // 2. Option 1 : Pass Soirée 1H (Gratuit via Rewarded Ad, essai unique par appareil)
            _buildOneHourPassOption(context),
            const SizedBox(height: 14),

            // 3. Option 2 : Formule Duo VIP RevenueCat (Annuel -70% et Hebdomadaire)
            InkWell(
              onTap: () => _buyPlan(context, isAnnual: true),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.pinkAccent.withValues(alpha: 0.18),
                      Colors.purpleAccent.withValues(alpha: 0.12),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.pinkAccent, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.pinkAccent.withValues(alpha: 0.35),
                      blurRadius: 14,
                      spreadRadius: 1,
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                "PASS ANNUEL CLUB",
                                style: TextStyle(
                                  color: Colors.pinkAccent,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.pinkAccent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  "-70%",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            "Tous les jeux illimités & sans pub à l'année",
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          AccessControlProvider.instance.annualPrice,
                          style: const TextStyle(
                            color: Colors.pinkAccent,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                        const Text(
                          "/ an",
                          style: TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Formule Hebdomadaire (Soirée)
            InkWell(
              onTap: () => _buyPlan(context, isAnnual: false),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24, width: 1.2),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.flash_on_rounded, color: Colors.cyanAccent, size: 20),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "PASS HEBDOMADAIRE",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "Idéal pour animer votre soirée ce soir",
                            style: TextStyle(color: Colors.white60, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          AccessControlProvider.instance.weeklyPrice,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                        const Text(
                          "/ semaine",
                          style: TextStyle(color: Colors.white54, fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Bouton Restaurer mes achats
            Center(
              child: TextButton.icon(
                onPressed: () => _restorePurchases(context),
                icon: const Icon(Icons.restore_rounded, color: Colors.cyanAccent, size: 16),
                label: const Text(
                  "Restaurer mes achats",
                  style: TextStyle(color: Colors.cyanAccent, fontSize: 12),
                ),
              ),
            ),
            const SizedBox(height: 6),

            // 4. Espace Cadeau
            _GiftCodeRow(
              onSuccess: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
                onUnlocked();
              },
            ),
            const SizedBox(height: 10),

            // 5. Bouton Annuler
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

class _GiftCodeRow extends StatefulWidget {
  final VoidCallback onSuccess;

  const _GiftCodeRow({required this.onSuccess});

  @override
  State<_GiftCodeRow> createState() => _GiftCodeRowState();
}

class _GiftCodeRowState extends State<_GiftCodeRow> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _redeem() async {
    final code = _controller.text.trim();
    if (code.isEmpty) return;

    final success = await AccessControlProvider.instance.redeemPromoCode(code);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text("✨ Code validé ! Le mode Pro est débloqué à vie ! 👑"),
            backgroundColor: Colors.pinkAccent,
          ),
        );
      widget.onSuccess();
    } else {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text("Code cadeau invalide ou expiré."),
            backgroundColor: Colors.redAccent,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.5), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.card_giftcard_rounded, color: Colors.amberAccent, size: 18),
              SizedBox(width: 6),
              Text(
                "ESPACE CADEAU 🎁",
                style: TextStyle(
                  color: Colors.amberAccent,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  textCapitalization: TextCapitalization.characters,
                  onSubmitted: (_) => _redeem(),
                  decoration: InputDecoration(
                    hintText: "Code cadeau...",
                    hintStyle: const TextStyle(fontSize: 13, color: Colors.white38),
                    filled: true,
                    fillColor: const Color(0xFF101024),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _redeem,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amberAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Activer",
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
