// lib/features/home/presentation/widgets/filter_widgets.dart
//
// Widgets de filtro: chip rápido de tipo (Todos/Sonhos/Doações),
// chip de tipo dentro do bottom sheet, e o bottom sheet de filtro
// geográfico (estado/cidade via IBGE).
// ─────────────────────────────────────────────────────────────

import 'package:empatia/core/theme/app_theme.dart';
import 'package:empatia/features/home/controllers/feed_controller.dart';
import 'package:empatia/features/home/data/models/feed_filter.dart';
import 'package:empatia/features/home/data/models/feed_item_.dart';
import 'package:empatia/features/home/data/services/ibge_service.dart';
import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════
// FILTER CHIP — chip rápido com animação de toque (scroll horizontal)
// ═══════════════════════════════════════════════════════════════

class FilterChip extends StatefulWidget {
  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const FilterChip({
    super.key,
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<FilterChip> createState() => _FilterChipState();
}

class _FilterChipState extends State<FilterChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.93,
      upperBound: 1.0,
      value: 1.0,
    );
    _scale = _ctrl;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _handleTap() async {
    await _ctrl.reverse();
    widget.onTap();
    await _ctrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTap: _handleTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            gradient: widget.selected
                ? const LinearGradient(
                    colors: [AppTheme.kidsPurple, Color(0xFFBB86FC)],
                  )
                : null,
            color: widget.selected ? null : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: widget.selected
                  ? Colors.transparent
                  : AppTheme.kidsPurple.withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: widget.selected
                ? [
                    BoxShadow(
                      color: AppTheme.kidsPurple.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 7),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: widget.selected ? Colors.white : AppTheme.kidsPurple,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// TYPE CHIP — usado dentro do bottom sheet de filtros
// ═══════════════════════════════════════════════════════════════

class TypeChip extends StatelessWidget {
  final String label;
  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  const TypeChip({
    super.key,
    required this.label,
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(colors: [AppTheme.kidsPurple, Color(0xFFBB86FC)])
              : null,
          color: selected ? null : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : AppTheme.kidsPurple.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppTheme.kidsPurple,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// FILTER SHEET — bottom sheet de filtro geográfico (estado/cidade)
// ═══════════════════════════════════════════════════════════════

class FilterSheet extends StatefulWidget {
  final FeedController controller;
  const FilterSheet({super.key, required this.controller});

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late FeedItemType? _type;
  IbgeEstado? _selectedEstado;
  String? _selectedCity;

  FeedController get ctrl => widget.controller;

  @override
  void initState() {
    super.initState();
    _type = ctrl.filter.type;
    // Tenta restaurar estado/cidade previamente selecionados
    if (ctrl.filter.stateCode != null) {
      try {
        _selectedEstado = ctrl.estados.firstWhere(
          (e) => e.sigla == ctrl.filter.stateCode,
        );
      } catch (_) {}
    }
    _selectedCity = ctrl.filter.city;
  }

  InputDecoration _dropdownDecoration() => InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppTheme.kidsPurple.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppTheme.kidsPurple.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.kidsPurple),
        ),
        filled: true,
        fillColor: AppTheme.surfaceLight,
      );

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),

            const Text(
              'Filtrar por',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppTheme.primaryBlue,
              ),
            ),

            const SizedBox(height: 22),

            // ── Tipo ──────────────────────────────────────────
            const Text(
              'Tipo',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                TypeChip(
                  label: 'Todos',
                  emoji: '🌟',
                  selected: _type == null,
                  onTap: () => setState(() => _type = null),
                ),
                const SizedBox(width: 8),
                TypeChip(
                  label: 'Sonhos',
                  emoji: '💭',
                  selected: _type == FeedItemType.dream,
                  onTap: () => setState(() => _type = FeedItemType.dream),
                ),
                const SizedBox(width: 8),
                TypeChip(
                  label: 'Doações',
                  emoji: '🎁',
                  selected: _type == FeedItemType.donation,
                  onTap: () => setState(() => _type = FeedItemType.donation),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Estado ────────────────────────────────────────
            Row(
              children: [
                const Text(
                  'Estado',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary,
                  ),
                ),
                if (ctrl.loadingEstados) ...[
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: AppTheme.kidsPurple,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),

            if (ctrl.ibgeError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  ctrl.ibgeError!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.errorRed.withValues(alpha: 0.9),
                  ),
                ),
              )
            else
              DropdownButtonFormField<IbgeEstado>(
                value: _selectedEstado,
                isExpanded: true,
                hint: const Text('Selecione um estado', style: TextStyle(fontSize: 13)),
                decoration: _dropdownDecoration(),
                menuMaxHeight: 320,
                items: [
                  const DropdownMenuItem<IbgeEstado>(
                    value: null,
                    child: Text('Todos os estados', style: TextStyle(fontSize: 13)),
                  ),
                  ...ctrl.estados.map(
                    (e) => DropdownMenuItem<IbgeEstado>(
                      value: e,
                      child: Text(
                        '${e.sigla} — ${e.nome}',
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: (estado) {
                  setState(() {
                    _selectedEstado = estado;
                    _selectedCity = null;
                  });
                  if (estado != null) {
                    ctrl.fetchCidadesByEstado(estado.sigla);
                  } else {
                    ctrl.clearCidades();
                  }
                },
              ),

            // ── Cidade ────────────────────────────────────────
            if (_selectedEstado != null) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  const Text(
                    'Cidade',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  if (ctrl.loadingCidades) ...[
                    const SizedBox(width: 8),
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: AppTheme.kidsPurple,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              if (ctrl.loadingCidades)
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppTheme.kidsPurple.withValues(alpha: 0.3),
                    ),
                  ),
                )
              else if (ctrl.cidades.isEmpty)
                Text(
                  'Nenhuma cidade encontrada.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                )
              else
                DropdownButtonFormField<String>(
                  value: _selectedCity,
                  isExpanded: true,
                  hint: const Text('Selecione uma cidade', style: TextStyle(fontSize: 13)),
                  decoration: _dropdownDecoration(),
                  menuMaxHeight: 320,
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Todas as cidades', style: TextStyle(fontSize: 13)),
                    ),
                    ...ctrl.cidades.map(
                      (c) => DropdownMenuItem<String>(
                        value: c,
                        child: Text(c,
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                  onChanged: (city) => setState(() => _selectedCity = city),
                ),
            ],

            const SizedBox(height: 28),

            // ── Botão aplicar ─────────────────────────────────
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                ctrl.applyFilter(
                  FeedFilter(
                    type: _type,
                    stateCode: _selectedEstado?.sigla,
                    stateName: _selectedEstado?.nome,
                    city: _selectedCity,
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.kidsPurple, Color(0xFFBB86FC)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.kidsPurple.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'Aplicar filtros',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
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