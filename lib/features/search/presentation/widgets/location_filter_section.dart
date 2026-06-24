import 'package:empatia/core/data/models/user_model.dart';
import 'package:empatia/core/theme/app_theme.dart';
import 'package:empatia/features/search/controller/search_controller.dart';
import 'package:empatia/features/search/controller/search_filter_controller.dart';
import 'package:flutter/material.dart' hide SearchController;
import 'package:provider/provider.dart';

/// 📍 LOCATION FILTER SECTION
///
/// Dropdowns hierárquicos Estado → Cidade + toggle "Próximo de mim".
/// Quando proximidade está ativa, exibe slider de raio (1–100 km, 1 km/passo).
///
/// O toggle usa lat/lng do perfil (UserModel), não GPS físico.
class LocationFilterSection extends StatelessWidget {
  final VoidCallback onFiltersChanged;

  const LocationFilterSection({Key? key, required this.onFiltersChanged})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fc = context.watch<SearchFilterController>();

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.kidsPink.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColor,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Cabeçalho ──────────────────────────────────────────────
          _Header(hasFilters: fc.hasAnyLocationFilter),

          Divider(
              height: 1,
              thickness: 1,
              color: AppTheme.kidsPink.withValues(alpha: 0.1)),

          // ── Estado ─────────────────────────────────────────────────
          _EstadoDropdown(onChanged: onFiltersChanged),

          // ── Cidade (só aparece após selecionar estado) ──────────────
          if (fc.selectedEstado != null) ...[
            Divider(
                height: 1,
                thickness: 1,
                indent: 16,
                endIndent: 16,
                color: AppTheme.kidsPink.withValues(alpha: 0.08)),
            _CidadeDropdown(onChanged: onFiltersChanged),
          ],

          Divider(
              height: 1,
              thickness: 1,
              color: AppTheme.kidsPink.withValues(alpha: 0.1)),

          // ── Próximo de mim ──────────────────────────────────────────
          _ProximityToggle(onChanged: onFiltersChanged),

          // ── Slider de raio (visível apenas quando proximidade ativa) ─
          if (fc.isProximityActive) ...[
            Divider(
                height: 1,
                thickness: 1,
                indent: 16,
                endIndent: 16,
                color: AppTheme.kidsPink.withValues(alpha: 0.08)),
            _RadiusSlider(onChanged: onFiltersChanged),
          ],

          // ── Erro de proximidade ─────────────────────────────────────
          if (fc.proximityState == ProximityState.error)
            const _ProximityErrorBanner(),
        ],
      ),
    );
  }
}

// ── Cabeçalho ─────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final bool hasFilters;
  const _Header({required this.hasFilters});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppTheme.kidsPink.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child:
                const Center(child: Text('📍', style: TextStyle(fontSize: 14))),
          ),
          const SizedBox(width: 8),
          const Text('Localização',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryBlue)),
          const Spacer(),
          if (hasFilters)
            GestureDetector(
              onTap: () => context.read<SearchFilterController>().clearAll(),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.kidsPink.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.close_rounded,
                        size: 12, color: AppTheme.kidsPink),
                    const SizedBox(width: 3),
                    Text('Limpar',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.kidsPink)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Dropdown Estado ───────────────────────────────────────────────────────────

class _EstadoDropdown extends StatelessWidget {
  final VoidCallback onChanged;
  const _EstadoDropdown({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final fc = context.watch<SearchFilterController>();

    Widget content;
    if (fc.estadosState == FilterLoadState.loading) {
      content = const _LoadingRow();
    } else if (fc.estadosState == FilterLoadState.error) {
      content = _ErrorRow(
        message: fc.estadosError ?? 'Erro',
        onRetry: () => context.read<SearchFilterController>().loadEstados(),
      );
    } else {
      content = DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: fc.selectedEstado?.sigla,
          hint: Text('Selecione',
              style: TextStyle(
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.w500,
                  fontSize: 14)),
          isExpanded: true,
          borderRadius: BorderRadius.circular(16),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppTheme.kidsPink, size: 20),
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryBlue),
          items: fc.estados.map((e) {
            return DropdownMenuItem<String>(
              value: e.sigla,
              child: Text('${e.sigla} — ${e.nome}'),
            );
          }).toList(),
          onChanged: (sigla) {
            if (sigla == null) return;
            final estado =
                fc.estados.where((e) => e.sigla == sigla).firstOrNull;
            if (estado != null) {
              context.read<SearchFilterController>().selectEstado(estado);
              onChanged();
            }
          },
        ),
      );
    }

    return _FilterRow(icon: '🗺️', label: 'Estado', child: content);
  }
}

// ── Dropdown Cidade ───────────────────────────────────────────────────────────

class _CidadeDropdown extends StatelessWidget {
  final VoidCallback onChanged;
  const _CidadeDropdown({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final fc = context.watch<SearchFilterController>();

    Widget content;
    if (fc.cidadesState == FilterLoadState.loading) {
      content = const _LoadingRow();
    } else if (fc.cidadesState == FilterLoadState.error) {
      content = _ErrorRow(
        message: fc.cidadesError ?? 'Erro',
        onRetry: () {
          final sigla = fc.selectedEstado?.sigla;
          if (sigla != null) {
            context
                .read<SearchFilterController>()
                .selectEstadoBySigla(sigla);
          }
        },
      );
    } else if (fc.cidades.isEmpty) {
      content = Text('Nenhuma cidade encontrada',
          style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 13,
              fontWeight: FontWeight.w500));
    } else {
      content = DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: fc.selectedCidade?.nome,
          hint: Text('Selecione',
              style: TextStyle(
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.w500,
                  fontSize: 14)),
          isExpanded: true,
          borderRadius: BorderRadius.circular(16),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppTheme.kidsPink, size: 20),
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryBlue),
          items: fc.cidades.map((c) {
            return DropdownMenuItem<String>(
              value: c.nome,
              child: Text(c.nome),
            );
          }).toList(),
          onChanged: (nome) {
            if (nome == null) return;
            final cidade =
                fc.cidades.where((c) => c.nome == nome).firstOrNull;
            if (cidade != null) {
              context.read<SearchFilterController>().selectCidade(cidade);
              onChanged();
            }
          },
        ),
      );
    }

    return _FilterRow(icon: '🏙️', label: 'Cidade', child: content);
  }
}

// ── Toggle Próximo de mim ─────────────────────────────────────────────────────

class _ProximityToggle extends StatelessWidget {
  final VoidCallback onChanged;
  const _ProximityToggle({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final fc = context.watch<SearchFilterController>();
    final isLoading = fc.proximityState == ProximityState.loading;
    final isActive = fc.isProximityActive;

    return InkWell(
      onTap: isLoading
          ? null
          : () {
              // Passa o UserModel para o controller usar lat/lng do perfil
              final user = context.read<UserModel?>();
              context
                  .read<SearchFilterController>()
                  .toggleProximity(user: user);
              onChanged();
            },
      borderRadius: BorderRadius.only(
        bottomLeft: isActive ? Radius.zero : const Radius.circular(16),
        bottomRight: isActive ? Radius.zero : const Radius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 12, 12),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isActive
                    ? AppTheme.kidsGreen.withValues(alpha: 0.15)
                    : AppTheme.kidsPink.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: isLoading
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppTheme.kidsPink))
                    : Text(isActive ? '✅' : '📍',
                        style: const TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Próximo de mim',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isActive
                              ? AppTheme.kidsGreenDark
                              : AppTheme.primaryBlue)),
                  Text(
                    isActive
                        ? 'Usando localização do seu perfil ✓'
                        : 'Buscar na sua cidade cadastrada',
                    style: TextStyle(
                        fontSize: 11,
                        color: isActive
                            ? AppTheme.kidsGreenDark
                            : AppTheme.textMuted),
                  ),
                ],
              ),
            ),
            // Switch visual
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 42,
              height: 24,
              decoration: BoxDecoration(
                color: isActive ? AppTheme.kidsGreen : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment:
                    isActive ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Color(0x22000000), blurRadius: 4)
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Slider de raio ────────────────────────────────────────────────────────────

class _RadiusSlider extends StatelessWidget {
  final VoidCallback onChanged;
  const _RadiusSlider({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final fc = context.watch<SearchFilterController>();
    final radius = fc.radiusKm.round();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rótulo + valor atual
          Row(
            children: [
              const Text('📏', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 6),
              Text(
                'Raio de busca',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade500,
                ),
              ),
              const Spacer(),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                transitionBuilder: (child, anim) =>
                    FadeTransition(opacity: anim, child: child),
                child: Text(
                  '$radius km',
                  key: ValueKey(radius),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.kidsGreenDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppTheme.kidsGreen,
              inactiveTrackColor: AppTheme.kidsGreen.withValues(alpha: 0.18),
              thumbColor: AppTheme.kidsGreenDark,
              overlayColor: AppTheme.kidsGreen.withValues(alpha: 0.15),
              trackHeight: 4,
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape:
                  const RoundSliderOverlayShape(overlayRadius: 18),
              showValueIndicator: ShowValueIndicator.never,
            ),
            child: Slider(
              value: fc.radiusKm,
              min: 1,
              max: 100,
              divisions: 99,
              onChanged: (value) {
                context.read<SearchFilterController>().setRadiusKm(value);
              },
              onChangeEnd: (value) {
                // Dispara a re-filtragem apenas ao soltar o dedo
                context.read<SearchController>().updateRadius(value);
                onChanged();
              },
            ),
          ),
          // Rótulos de escala
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('1 km',
                  style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w600)),
              Text('50 km',
                  style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w600)),
              Text('100 km',
                  style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Banner de erro de proximidade ─────────────────────────────────────────────

class _ProximityErrorBanner extends StatelessWidget {
  const _ProximityErrorBanner();

  @override
  Widget build(BuildContext context) {
    final fc = context.watch<SearchFilterController>();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.alertAmberBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.alertAmberBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 15)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              fc.proximityErrorMessage ?? 'Erro ao obter localização.',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.kidsAmberDark),
            ),
          ),
          GestureDetector(
            onTap: () =>
                context.read<SearchFilterController>().dismissProximityError(),
            child:
                Icon(Icons.close_rounded, size: 16, color: AppTheme.kidsAmber),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _FilterRow extends StatelessWidget {
  final String icon;
  final String label;
  final Widget child;
  const _FilterRow(
      {required this.icon, required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          SizedBox(
            width: 54,
            child: Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade500)),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _LoadingRow extends StatelessWidget {
  const _LoadingRow();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppTheme.kidsPink),
          ),
          const SizedBox(width: 8),
          Text('Carregando...',
              style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
        ],
      ),
    );
  }
}

class _ErrorRow extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorRow({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(message,
              style: TextStyle(fontSize: 12, color: AppTheme.errorRed)),
        ),
        TextButton(
          onPressed: onRetry,
          child: Text('Tentar novamente',
              style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.kidsPink,
                  fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}