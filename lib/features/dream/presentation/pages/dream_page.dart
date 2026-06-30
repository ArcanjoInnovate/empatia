// lib/features/dream/presentation/pages/dream_page.dart

import 'dart:async';

import 'package:empatia/core/data/models/dream_model.dart';
import 'package:empatia/core/data/models/user_model.dart';
import 'package:empatia/core/theme/app_decorations.dart';
import 'package:empatia/core/theme/app_theme.dart';
import 'package:empatia/core/widget/verification_block_dialog.dart';
import 'package:empatia/features/donation/controller/donation_controller.dart';
import 'package:empatia/features/donation/data/model/donation_model.dart';
import 'package:empatia/features/donation/presentation/widgets/donation_item_form_sheet.dart';
import 'package:empatia/features/dream/controller/dream_controller.dart';
import 'package:empatia/features/dream/presentation/widgets/donation_card_widget.dart';
import 'package:empatia/features/dream/presentation/widgets/dream_card_widget.dart';
import 'package:empatia/features/dream/presentation/widgets/dream_form_sheet.dart';
import 'package:empatia/features/profile/data/service/profile_service.dart';
import 'package:empatia/features/request/controller/request_controller.dart';
import 'package:empatia/features/request/data/model/request_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ══════════════════════════════════════════════════════════════════════════════
// MODEL
// ══════════════════════════════════════════════════════════════════════════════

class DonationHistoryEntry {
  final String id;
  final String type; // 'donated' | 'received'
  final String? itemId;
  final String? itemType; // 'dream' | 'donation'
  final String? itemTitle;
  final String? itemPhotoUrl;
  final String? itemCategory;
  final String? otherUid;
  final String? chatId;
  final int timestamp;

  const DonationHistoryEntry({
    required this.id,
    required this.type,
    this.itemId,
    this.itemType,
    this.itemTitle,
    this.itemPhotoUrl,
    this.itemCategory,
    this.otherUid,
    this.chatId,
    required this.timestamp,
  });

  factory DonationHistoryEntry.fromMap(Map map, String id) => DonationHistoryEntry(
        id:           id,
        type:         map['type']?.toString() ?? 'donated',
        itemId:       map['itemId']?.toString(),
        itemType:     map['itemType']?.toString(),
        itemTitle:    map['itemTitle']?.toString(),
        itemPhotoUrl: map['itemPhotoUrl']?.toString(),
        itemCategory: map['itemCategory']?.toString(),
        otherUid:     map['otherUid']?.toString(),
        chatId:       map['chatId']?.toString(),
        timestamp:    (map['timestamp'] as num?)?.toInt() ??
            DateTime.now().millisecondsSinceEpoch,
      );

  bool get isDonated  => type == 'donated';
  bool get isReceived => type == 'received';
}

// ══════════════════════════════════════════════════════════════════════════════
// REPOSITORY — leitura do DonationHistory
// ══════════════════════════════════════════════════════════════════════════════

class _HistoryRepository {
  static Stream<List<DonationHistoryEntry>> watch(String uid) {
    return FirebaseDatabase.instance
        .ref('DonationHistory/$uid')
        .orderByChild('timestamp')
        .onValue
        .map((event) {
      final data = event.snapshot.value;
      if (data == null || data is! Map) return <DonationHistoryEntry>[];
      final list = <DonationHistoryEntry>[];
      (data as Map).forEach((key, val) {
        if (val is Map) {
          list.add(DonationHistoryEntry.fromMap(val, key.toString()));
        }
      });
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    });
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// PAGE
// ══════════════════════════════════════════════════════════════════════════════

class DreamPage extends StatefulWidget {
  const DreamPage({Key? key}) : super(key: key);

  @override
  State<DreamPage> createState() => _DreamPageState();
}

class _DreamPageState extends State<DreamPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<UserModel?>();
    final myUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppTheme.dreamBackground,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          _DreamHeader(tab: _tab),
        ],
        body: TabBarView(
          controller: _tab,
          children: [
            _TabSonhos(currentUser: currentUser),
            _TabDoacoes(currentUser: currentUser),
            _TabHistorico(myUid: myUid),
          ],
        ),
      ),
      floatingActionButton: _tab.index == 0 && currentUser != null
          ? FloatingActionButton.extended(
              onPressed: () {
                if (!ProfileService.isFullyVerified(currentUser)) {
                  showVerificationRequiredDialog(context, feature: 'publicar um sonho');
                  return;
                }
                showDreamFormSheet(context, currentUser: currentUser);
              },
              backgroundColor: AppTheme.accentPurple,
              elevation: 6,
              icon: const Text('✨', style: TextStyle(fontSize: 18)),
              label: const Text(
                'Novo sonho!',
                style: TextStyle(
                  color: AppTheme.backgroundColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            )
          : _tab.index == 1 && currentUser != null
              ? FloatingActionButton.extended(
                  onPressed: () {
                    if (!ProfileService.isFullyVerified(currentUser)) {
                      showVerificationRequiredDialog(context, feature: 'criar uma doação');
                      return;
                    }
                    showDonationItemFormSheet(context, currentUser: currentUser);
                  },
                  backgroundColor: AppTheme.accentPink,
                  elevation: 6,
                  icon: const Text('🎁', style: TextStyle(fontSize: 18)),
                  label: const Text(
                    'Nova doação!',
                    style: TextStyle(
                      color: AppTheme.backgroundColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                )
              : null,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// HEADER COM TABS
// ══════════════════════════════════════════════════════════════════════════════

class _DreamHeader extends StatelessWidget {
  final TabController tab;
  const _DreamHeader({required this.tab});

  @override
  Widget build(BuildContext context) {
    final dreamCtrl    = context.read<DreamController>();
    final donationCtrl = context.read<DonationController>();
    final requestCtrl  = context.read<RequestController>();
    final myUid        = FirebaseAuth.instance.currentUser?.uid;

    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      stretch: true,
      automaticallyImplyLeading: false,
      backgroundColor: AppTheme.primaryBlue,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          color: AppTheme.primaryBlue,
          child: TabBar(
            controller: tab,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            tabs: const [
              Tab(text: '💭  Sonhos'),
              Tab(text: '🎁  Doações'),
              Tab(text: '📋  Histórico'),
            ],
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.blurBackground],
        background: Stack(
          children: [
            Container(decoration: AppDecorations.dreamHeaderBackground),
            Positioned(top: 18, right: 20,
                child: Text('☁️', style: TextStyle(fontSize: 38, color: Colors.white.withValues(alpha: 0.18)))),
            Positioned(top: 50, left: 8,
                child: Text('☁️', style: TextStyle(fontSize: 24, color: Colors.white.withValues(alpha: 0.12)))),
            Positioned(bottom: 120, right: 55,
                child: Text('⭐', style: TextStyle(fontSize: 16, color: Colors.white.withValues(alpha: 0.30)))),
            Positioned(bottom: 134, left: 28,
                child: Text('🌈', style: TextStyle(fontSize: 18, color: Colors.white.withValues(alpha: 0.22)))),

            SafeArea(
              child: Padding(
                // bottom: 56 = 48px tabs + 8px folga
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 56),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: AppDecorations.dreamHeaderIconBox,
                          child: const Text('🌠', style: TextStyle(fontSize: 22)),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Meus Sonhos',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.backgroundColor)),
                            Text('Realize seus desejos! ✨',
                                style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        StreamBuilder<List<DreamModel>>(
                          stream: dreamCtrl.watchDreams(),
                          builder: (_, snap) => _StatBubble(
                            emoji: '💭',
                            value: '${snap.data?.length ?? 0}',
                            label: 'Sonhos',
                            color: AppTheme.accentPurple,
                          ),
                        ),
                        const SizedBox(width: 10),
                        StreamBuilder<List<DonationModel>>(
                          stream: donationCtrl.watchMyDonations(),
                          builder: (_, snap) => _StatBubble(
                            emoji: '🎁',
                            value: '${snap.data?.length ?? 0}',
                            label: 'Doações',
                            color: AppTheme.accentPink,
                            glow: (snap.data?.length ?? 0) > 0,
                          ),
                        ),
                        const SizedBox(width: 10),
                        if (myUid != null)
                          StreamBuilder<List<DonationHistoryEntry>>(
                            stream: _HistoryRepository.watch(myUid),
                            builder: (_, snap) {
                              final n = snap.data?.length ?? 0;
                              return _StatBubble(
                                emoji: '🏆',
                                value: '$n',
                                label: 'Histórico',
                                color: AppTheme.accentGreen,
                                glow: n > 0,
                              );
                            },
                          )
                        else
                          StreamBuilder<List<RequestModel>>(
                            stream: requestCtrl.watchMyRequests(),
                            builder: (_, snap) {
                              final n = (snap.data ?? []).where((r) => r.status == 'fulfilled').length;
                              return _StatBubble(emoji: '🎉', value: '$n', label: 'Recebidas', color: AppTheme.accentGreen, glow: n > 0);
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBubble extends StatelessWidget {
  final String emoji, value, label;
  final Color color;
  final bool glow;
  const _StatBubble({required this.emoji, required this.value, required this.label, required this.color, this.glow = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: glow ? AppDecorations.dreamStatBubbleActive(color) : AppDecorations.dreamStatBubble,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 15)),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.backgroundColor)),
              Text(label, style: TextStyle(fontSize: 8, color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ABA 1 — SONHOS
// ══════════════════════════════════════════════════════════════════════════════

class _TabSonhos extends StatelessWidget {
  final UserModel? currentUser;
  const _TabSonhos({this.currentUser});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.read<DreamController>();
    return StreamBuilder<List<DreamModel>>(
      stream: ctrl.watchDreams(),
      builder: (context, snapshot) {
        final dreams = snapshot.data ?? [];
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          children: [
            if (dreams.isEmpty)
              _EmptyState(
                emoji: '🌙',
                title: 'Que sonho você tem?',
                subtitle: 'Toque no botão ✨ para adicionar seu primeiro sonho!',
                borderColor: AppTheme.accentPurple,
              )
            else
              ...dreams.map((d) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: DreamCardWidget(
                      dream: d,
                      editable: true,
                      onEdit: currentUser == null
                          ? null
                          : () => showDreamFormSheet(context, currentUser: currentUser!, dream: d),
                    ),
                  )),
          ],
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ABA 2 — DOAÇÕES
// ══════════════════════════════════════════════════════════════════════════════

class _TabDoacoes extends StatelessWidget {
  final UserModel? currentUser;
  const _TabDoacoes({this.currentUser});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.read<DonationController>();
    return StreamBuilder<List<DonationModel>>(
      stream: ctrl.watchMyDonations(),
      builder: (context, snapshot) {
        final donations = snapshot.data ?? [];
        if (donations.isEmpty) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            children: [
              _EmptyState(
                emoji: '🧸',
                title: 'Nenhuma doação ainda!',
                subtitle: 'Compartilhe brinquedos e itens que você não usa 💕',
                borderColor: AppTheme.accentPink,
              ),
            ],
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,      // era 3 — muito apertado para imagem + texto
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.82, // mais altura por card para título e categoria
          ),
          itemCount: donations.length,
          itemBuilder: (_, i) => DonationCardWidget(
            donation: donations[i],
            onEdit: () {
              if (currentUser == null) return;
              showDonationItemFormSheet(context, currentUser: currentUser!, donation: donations[i]);
            },
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ABA 3 — HISTÓRICO
// ══════════════════════════════════════════════════════════════════════════════

class _TabHistorico extends StatelessWidget {
  final String? myUid;
  const _TabHistorico({this.myUid});

  @override
  Widget build(BuildContext context) {
    if (myUid == null) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.accentPurple, strokeWidth: 2));
    }

    return StreamBuilder<List<DonationHistoryEntry>>(
      stream: _HistoryRepository.watch(myUid!),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.accentPurple, strokeWidth: 2));
        }

        final all      = snap.data ?? [];
        final donated  = all.where((e) => e.isDonated).toList();
        final received = all.where((e) => e.isReceived).toList();

        if (all.isEmpty) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
            children: [
              _EmptyState(
                emoji: '📋',
                title: 'Histórico vazio',
                subtitle: 'Quando você concluir uma doação, ela aparecerá aqui para ambos os participantes.',
                borderColor: AppTheme.accentTeal,
              ),
            ],
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 100),
          children: [
            // ── Resumo ──────────────────────────────────────────────
            _HistoricoResumo(total: all.length, donated: donated.length, received: received.length),

            // ── Itens Recebidos ──────────────────────────────────────
            if (received.isNotEmpty) ...[
              _HistoricoSectionHeader(
                emoji: '🎁',
                label: 'Recebi',
                count: received.length,
                color: AppTheme.accentGreen,
              ),
              ...received.map((e) => _HistoricoCard(entry: e)),
            ],

            // ── Doações Feitas ───────────────────────────────────────
            if (donated.isNotEmpty) ...[
              _HistoricoSectionHeader(
                emoji: '💝',
                label: 'Doei',
                count: donated.length,
                color: AppTheme.accentPink,
              ),
              ...donated.map((e) => _HistoricoCard(entry: e)),
            ],
          ],
        );
      },
    );
  }
}

// ── Resumo do histórico ───────────────────────────────────────────────────────

class _HistoricoResumo extends StatelessWidget {
  final int total, donated, received;
  const _HistoricoResumo({required this.total, required this.donated, required this.received});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryBlue, AppTheme.primaryBlueMid],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.30),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(child: _ResumoItem(emoji: '🏆', value: '$total', label: 'Total', color: Colors.white)),
          _ResumoDivider(),
          Expanded(child: _ResumoItem(emoji: '💝', value: '$donated', label: 'Doei', color: const Color(0xFFFF9EBC))),
          _ResumoDivider(),
          Expanded(child: _ResumoItem(emoji: '🎁', value: '$received', label: 'Recebi', color: const Color(0xFF9EF7A1))),
        ],
      ),
    );
  }
}

class _ResumoItem extends StatelessWidget {
  final String emoji, value, label;
  final Color color;
  const _ResumoItem({required this.emoji, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.70))),
      ],
    );
  }
}

class _ResumoDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 1, height: 48,
        color: Colors.white.withValues(alpha: 0.15),
      );
}

// ── Section header ────────────────────────────────────────────────────────────

class _HistoricoSectionHeader extends StatelessWidget {
  final String emoji, label;
  final int count;
  final Color color;
  const _HistoricoSectionHeader({required this.emoji, required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 17))),
          ),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.primaryBlue)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('$count', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: color)),
          ),
        ],
      ),
    );
  }
}

// ── Card de histórico ─────────────────────────────────────────────────────────

class _HistoricoCard extends StatelessWidget {
  final DonationHistoryEntry entry;
  const _HistoricoCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final isDonated = entry.isDonated;
    final accent    = isDonated ? AppTheme.accentPink : AppTheme.accentGreen;
    final bgColor   = isDonated
        ? AppTheme.accentPink.withValues(alpha: 0.04)
        : AppTheme.accentGreen.withValues(alpha: 0.04);

    final typeLabel = entry.itemType == 'dream' ? 'Sonho' : 'Doação';
    final dt   = DateTime.fromMillisecondsSinceEpoch(entry.timestamp);
    final day   = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final hour  = dt.hour.toString().padLeft(2, '0');
    final min   = dt.minute.toString().padLeft(2, '0');
    final date  = '$day/$month/${dt.year} às $hour:$min';

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.20)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Faixa lateral colorida
          Container(
            width: 4,
            height: 80,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
            ),
          ),

          // Foto ou emoji
          Padding(
            padding: const EdgeInsets.all(12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: entry.itemPhotoUrl != null && entry.itemPhotoUrl!.isNotEmpty
                  ? Image.network(
                      entry.itemPhotoUrl!,
                      width: 52, height: 52, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _fallbackPhoto(accent),
                    )
                  : _fallbackPhoto(accent),
            ),
          ),

          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tipo + badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          typeLabel.toUpperCase(),
                          style: TextStyle(
                            fontSize: 8.5, fontWeight: FontWeight.w800,
                            color: accent, letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDonated
                              ? AppTheme.accentPink.withValues(alpha: 0.10)
                              : AppTheme.accentGreen.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isDonated ? '💝 Doei' : '🎁 Recebi',
                          style: TextStyle(
                            fontSize: 9, fontWeight: FontWeight.w700,
                            color: accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    entry.itemTitle ?? 'Item',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.primaryBlue, height: 1.2),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    date,
                    style: TextStyle(fontSize: 10.5, color: AppTheme.textSecondary.withValues(alpha: 0.65)),
                  ),
                ],
              ),
            ),
          ),

          // Ícone de status
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Text(isDonated ? '💝' : '🎉', style: const TextStyle(fontSize: 22)),
          ),
        ],
      ),
    );
  }

  Widget _fallbackPhoto(Color accent) => Container(
        width: 52, height: 52,
        color: accent.withValues(alpha: 0.10),
        child: Center(
          child: Text(
            entry.itemType == 'dream' ? '💭' : '📦',
            style: const TextStyle(fontSize: 24),
          ),
        ),
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// WIDGETS UTILITÁRIOS COMUNS
// ══════════════════════════════════════════════════════════════════════════════

class _EmptyState extends StatelessWidget {
  final String emoji, title, subtitle;
  final Color borderColor;
  const _EmptyState({required this.emoji, required this.title, required this.subtitle, required this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: AppDecorations.dreamEmptyState(borderColor),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.primaryBlue)),
          const SizedBox(height: 8),
          Text(subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500, height: 1.5)),
        ],
      ),
    );
  }
}
