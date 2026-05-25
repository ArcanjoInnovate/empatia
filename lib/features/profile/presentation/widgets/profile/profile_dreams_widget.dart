import 'package:empatia/core/models/dream_model.dart';
import 'package:empatia/features/profile/presentation/widgets/profile/profile_shared_widgets.dart';
import 'package:flutter/material.dart';

// ─── Design tokens ────────────────────────────────────────────────────────
const _pink   = Color(0xFFFF6B9D);
const _navy   = Color(0xFF1E3A8A);
const _amber  = Color(0xFFFFC837);
const _purple = Color(0xFF8B5CF6);
const _green  = Color(0xFF4ADE80);

/// 💭 PROFILE DREAMS WIDGET
///
/// Lista de sonhos com barra de progresso e empty state.
class ProfileDreamsWidget extends StatelessWidget {
  final List<DreamModel>? dreams;
  const ProfileDreamsWidget({Key? key, required this.dreams}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (dreams == null || dreams!.isEmpty) {
      return ProfileEmptyStateWidget(
        emoji: '💭',
        message: 'Nenhum sonho cadastrado',
        sub: 'Compartilhe seus sonhos e objetivos!',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: dreams!.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => DreamCardWidget(dream: dreams![i]),
    );
  }
}

// ── Dream card ───────────────────────────────────────────────────────────────

class DreamCardWidget extends StatelessWidget {
  final DreamModel dream;
  const DreamCardWidget({Key? key, required this.dream}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final progress = dream.progress;

    Color progressColor = _pink;
    String progressLabel = '🚀 Começando!';
    if (progress != null) {
      if (progress >= 0.7) {
        progressColor = _green;
        progressLabel = '🌟 Quase lá!';
      } else if (progress >= 0.4) {
        progressColor = _amber;
        progressLabel = '💪 No caminho!';
      }
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0E6FF), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: _purple.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [_purple, Color(0xFFBB86FC)]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(dream.emoji ?? '💭',
                      style: const TextStyle(fontSize: 26)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dream.title ?? 'Sem título',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _navy,
                      ),
                    ),
                    if (dream.date != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        '📅  ${dream.date}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (progress != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: progressColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${(progress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: progressColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Progresso',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade500)),
                Text(progressLabel,
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.shade100,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                minHeight: 8,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
