import 'package:empatia/core/data/models/dream_model.dart';
import 'package:empatia/features/profile/presentation/widgets/profile/profile_shared_widgets.dart';
import 'package:flutter/material.dart';
import 'package:empatia/core/theme/app_theme.dart';

/// 💭 PROFILE DREAMS WIDGET
///
/// Lista de sonhos com barra de progresso e empty state.
class ProfileDreamsWidget extends StatelessWidget {
  final List<DreamModel>? dreams;
  const ProfileDreamsWidget({Key? key, required this.dreams}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Filtra sonhos já realizados: status 'fulfilled' OU progress completo (1.0)
    final pendingDreams = dreams
        ?.where((d) => d.status != 'fulfilled' && (d.progress ?? 0) < 1.0)
        .toList();

    if (pendingDreams == null || pendingDreams.isEmpty) {
      return ProfileEmptyStateWidget(
        emoji: '💭',
        message: 'Nenhum sonho cadastrado',
        sub: 'Compartilhe seus sonhos e objetivos!',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: pendingDreams.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => DreamCardWidget(dream: pendingDreams[i]),
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

    Color progressColor = AppTheme.kidsPink;
    String progressLabel = '🚀 Começando!';
    if (progress != null) {
      if (progress >= 0.7) {
        progressColor = AppTheme.kidsGreen;
        progressLabel = '🌟 Quase lá!';
      } else if (progress >= 0.4) {
        progressColor = AppTheme.kidsYellow;
        progressLabel = '💪 No caminho!';
      }
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0E6FF), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: AppTheme.kidsPurple.withValues(alpha: 0.06),
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
                  gradient: LinearGradient(
                      colors: [AppTheme.kidsPurple, AppTheme.kidsPurpleLight]),
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
                        color: AppTheme.primaryBlue,
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


            ],
          ),

      ]),
    );
  }
}