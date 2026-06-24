import 'package:empatia/core/data/models/user_model.dart';
import 'package:empatia/core/theme/app_theme.dart';
import 'package:empatia/features/search/controller/search_controller.dart';
import 'package:empatia/features/search/controller/search_filter_controller.dart';
import 'package:empatia/features/search/presentation/widgets/location_filter_section.dart';
import 'package:empatia/features/search/presentation/widgets/search_result_card.dart';
import 'package:flutter/material.dart' hide SearchController;
import 'package:provider/provider.dart';

// ── Opções de tipo ─────────────────────────────────────────────────────────────

const _types = [
  (null, '🔍', 'Todos'),
  ('donation', '🎁', 'Doações'),
  ('dream', '⭐', 'Sonhos'),
];

/// 🔍 SEARCH PAGE
///
/// Layout via CustomScrollView com slivers:
///   - SliverToBoxAdapter  → header fixo (busca + filtros + chips + tipo)
///   - SliverPadding/Grid  → resultados roláveis que sempre ficam visíveis
///
/// Quando os filtros estão expandidos o usuário rola a tela para baixo
/// e chega nos cards normalmente — sem nada ser cortado ou empurrado
/// para fora da viewport.
class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late final TextEditingController _searchCtrl;
  late final FocusNode _focusNode;
  bool _filtersExpanded = false;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
    _focusNode = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final user = context.read<UserModel?>();
      final fc = context.read<SearchFilterController>();

      await fc.loadEstados();

      if (user?.state != null || user?.city != null) {
        await fc.prefillFromUser(
          stateSigla: user?.state,
          cityName: user?.city,
        );
        if (mounted) _onFiltersChanged();
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFiltersChanged() {
    final fc = context.read<SearchFilterController>();
    context.read<SearchController>().applyLocationFilters(
          stateSigla: fc.selectedEstado?.sigla,
          cityName: fc.selectedCidade?.nome,
          userLat: fc.userLocation?.latitude,
          userLng: fc.userLocation?.longitude,
          radiusKm: fc.radiusKm,
        );
  }

  void _clearAll() {
    _searchCtrl.clear();
    context.read<SearchController>().clearFilters();
    context.read<SearchFilterController>().clearAll();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppTheme.profileBackground,
        body: SafeArea(
          child: _SearchScrollView(
            searchCtrl: _searchCtrl,
            focusNode: _focusNode,
            filtersExpanded: _filtersExpanded,
            onToggleFilters: () =>
                setState(() => _filtersExpanded = !_filtersExpanded),
            onFiltersChanged: _onFiltersChanged,
            onClearAll: _clearAll,
          ),
        ),
      ),
    );
  }
}

// ── ScrollView principal ──────────────────────────────────────────────────────
//
// Toda a tela vive num único CustomScrollView.
// - Header (busca, filtros, chips, tipo) → SliverToBoxAdapter
// - Resultados → SliverPadding + SliverGrid  OU  SliverFillRemaining
//
// Isso garante que, não importa o tamanho do header, os resultados
// sempre ficam acessíveis via scroll — nunca cortados.

class _SearchScrollView extends StatelessWidget {
  final TextEditingController searchCtrl;
  final FocusNode focusNode;
  final bool filtersExpanded;
  final VoidCallback onToggleFilters;
  final VoidCallback onFiltersChanged;
  final VoidCallback onClearAll;

  const _SearchScrollView({
    required this.searchCtrl,
    required this.focusNode,
    required this.filtersExpanded,
    required this.onToggleFilters,
    required this.onFiltersChanged,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<SearchController>();

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // ── Header: tudo acima dos resultados ────────────────────────
        SliverToBoxAdapter(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Barra de busca + botão de filtros
              _SearchBar(
                searchCtrl: searchCtrl,
                focusNode: focusNode,
                filtersExpanded: filtersExpanded,
                onToggleFilters: onToggleFilters,
                onClearAll: onClearAll,
              ),

              // Painel de filtros de localização (colapsável)
              AnimatedSize(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeInOut,
                child: filtersExpanded
                    ? LocationFilterSection(
                        onFiltersChanged: onFiltersChanged,
                      )
                    : const SizedBox.shrink(),
              ),

              // Chips de filtros ativos (aparecem independente do painel)
              const _ActiveFilterChips(),
              SizedBox(height: 8),

              // Barra de tipo (Todos / Doações / Sonhos)
              const _TypeFilterBar(),

              // Contador de resultados — fica no header para não rolar sozinho
              if (ctrl.state == SearchState.success)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                  child: Text(
                    '${ctrl.results.length} '
                    '${ctrl.results.length == 1 ? 'resultado' : 'resultados'}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // ── Resultados ────────────────────────────────────────────────
        _ResultsSliver(state: ctrl.state, results: ctrl.results,
            errorMessage: ctrl.errorMessage),
      ],
    );
  }
}

// ── Barra de busca ────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController searchCtrl;
  final FocusNode focusNode;
  final bool filtersExpanded;
  final VoidCallback onToggleFilters;
  final VoidCallback onClearAll;

  const _SearchBar({
    required this.searchCtrl,
    required this.focusNode,
    required this.filtersExpanded,
    required this.onToggleFilters,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    final sc = context.watch<SearchController>();
    final fc = context.watch<SearchFilterController>();
    final hasAnything = sc.hasActiveFilters || fc.hasAnyLocationFilter;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          const Text(
            'Buscar',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Encontre doações e sonhos perto de você',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),

          // Campo de texto + botão de filtros lado a lado
          Row(
            children: [
              Expanded(
                child: _SearchTextField(
                  searchCtrl: searchCtrl,
                  focusNode: focusNode,
                ),
              ),
              const SizedBox(width: 10),
              _FilterToggleButton(
                expanded: filtersExpanded,
                hasFilters: fc.hasAnyLocationFilter,
                onTap: onToggleFilters,
              ),
            ],
          ),

          // Botão limpar tudo — aparece compacto abaixo do campo
          if (hasAnything) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: onClearAll,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.filter_alt_off_rounded,
                        size: 13, color: AppTheme.kidsPink),
                    const SizedBox(width: 3),
                    Text(
                      'Limpar tudo',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.kidsPink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SearchTextField extends StatelessWidget {
  final TextEditingController searchCtrl;
  final FocusNode focusNode;
  const _SearchTextField(
      {required this.searchCtrl, required this.focusNode});

  @override
  Widget build(BuildContext context) {
    final sc = context.watch<SearchController>();
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.kidsPink.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.kidsPink.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: searchCtrl,
        focusNode: focusNode,
        onChanged: context.read<SearchController>().onQueryChanged,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.primaryBlue,
        ),
        decoration: InputDecoration(
          hintText: 'Buscar item ou sonho...',
          hintStyle: TextStyle(
            fontSize: 13,
            color: AppTheme.textMuted,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: const Icon(Icons.search_rounded,
              color: AppTheme.kidsPink, size: 20),
          suffixIcon: sc.query.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close_rounded,
                      color: Colors.grey.shade400, size: 17),
                  onPressed: () {
                    searchCtrl.clear();
                    context.read<SearchController>().onQueryChanged('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        ),
      ),
    );
  }
}

class _FilterToggleButton extends StatelessWidget {
  final bool expanded;
  final bool hasFilters;
  final VoidCallback onTap;
  const _FilterToggleButton(
      {required this.expanded,
      required this.hasFilters,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: expanded ? AppTheme.kidsPink : AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppTheme.kidsPink
                .withValues(alpha: expanded ? 1 : 0.35),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.kidsPink
                  .withValues(alpha: expanded ? 0.28 : 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.tune_rounded,
              color: expanded ? Colors.white : AppTheme.kidsPink,
              size: 21,
            ),
            if (hasFilters && !expanded)
              Positioned(
                top: 9,
                right: 9,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppTheme.kidsGreen,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Chips de filtros ativos ───────────────────────────────────────────────────

class _ActiveFilterChips extends StatelessWidget {
  const _ActiveFilterChips();

  @override
  Widget build(BuildContext context) {
    final fc = context.watch<SearchFilterController>();
    final chips = <_ChipData>[];

    if (fc.selectedEstado != null) {
      chips.add(_ChipData(
        icon: '🗺️',
        label: fc.selectedEstado!.sigla,
        onRemove: () {
          fc.selectEstado(null);
          context.read<SearchController>().applyLocationFilters();
        },
      ));
    }

    if (fc.selectedCidade != null) {
      final sig = fc.selectedEstado?.sigla;
      chips.add(_ChipData(
        icon: '🏙️',
        label: fc.selectedCidade!.nome,
        onRemove: () {
          fc.selectCidade(null);
          context
              .read<SearchController>()
              .applyLocationFilters(stateSigla: sig);
        },
      ));
    }

    if (fc.isProximityActive) {
      final sig = fc.selectedEstado?.sigla;
      final city = fc.selectedCidade?.nome;
      chips.add(_ChipData(
        icon: '📍',
        label: 'Próximo de mim · ${fc.radiusKm.round()} km',
        isSpecial: true,
        onRemove: () {
          fc.toggleProximity();
          context.read<SearchController>().applyLocationFilters(
              stateSigla: sig, cityName: city);
        },
      ));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) => _Chip(data: chips[i]),
      ),
    );
  }
}

class _ChipData {
  final String icon;
  final String label;
  final VoidCallback onRemove;
  final bool isSpecial;
  const _ChipData(
      {required this.icon,
      required this.label,
      required this.onRemove,
      this.isSpecial = false});
}

class _Chip extends StatelessWidget {
  final _ChipData data;
  const _Chip({required this.data});

  @override
  Widget build(BuildContext context) {
    final bg = data.isSpecial
        ? AppTheme.kidsGreen.withValues(alpha: 0.13)
        : AppTheme.kidsPink;
    final fg = data.isSpecial ? AppTheme.kidsGreenDark : Colors.white;
    final border = data.isSpecial ? AppTheme.kidsGreen : AppTheme.kidsPink;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(data.icon, style: const TextStyle(fontSize: 11)),
          const SizedBox(width: 4),
          Text(
            data.label,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700, color: fg),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: data.onRemove,
            child: Icon(Icons.close_rounded,
                size: 12,
                color: data.isSpecial ? AppTheme.kidsGreenDark : Colors.white70),
          ),
        ],
      ),
    );
  }
}

// ── Barra de tipo ─────────────────────────────────────────────────────────────

class _TypeFilterBar extends StatelessWidget {
  const _TypeFilterBar();

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<SearchController>();

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        itemCount: _types.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final t = _types[i];
          final selected = ctrl.selectedType == t.$1;
          return GestureDetector(
            onTap: () => context
                .read<SearchController>()
                .selectType(selected ? null : t.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: selected ? AppTheme.kidsPink : AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: selected
                      ? AppTheme.kidsPink
                      : AppTheme.kidsPink.withValues(alpha: 0.25),
                  width: 1.5,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: AppTheme.kidsPink.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(t.$2, style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 5),
                  Text(
                    t.$3,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? Colors.white
                          : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Resultados como Slivers ───────────────────────────────────────────────────
//
// Usa SliverFillRemaining para estados vazios/idle/loading/error
// (ocupa o resto da tela sem encolher).
// Usa SliverGrid para resultados reais (rola naturalmente junto com o header).

class _ResultsSliver extends StatelessWidget {
  final SearchState state;
  final List<SearchResult> results;
  final String? errorMessage;

  const _ResultsSliver({
    required this.state,
    required this.results,
    required this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case SearchState.idle:
        return const SliverFillRemaining(
            hasScrollBody: false, child: _IdleState());

      case SearchState.loading:
        return const SliverFillRemaining(
            hasScrollBody: false, child: _LoadingState());

      case SearchState.empty:
        return const SliverFillRemaining(
            hasScrollBody: false, child: _EmptyState());

      case SearchState.error:
        return SliverFillRemaining(
            hasScrollBody: false,
            child: _ErrorState(message: errorMessage));

      case SearchState.success:
        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          sliver: SliverGrid(
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.72,
            ),
            delegate: SliverChildBuilderDelegate(
              (_, i) => SearchResultCard(result: results[i]),
              childCount: results.length,
            ),
          ),
        );
    }
  }
}

// ── Estados ───────────────────────────────────────────────────────────────────

class _IdleState extends StatelessWidget {
  const _IdleState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.kidsPink.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Center(
                child: Text('🔍', style: TextStyle(fontSize: 32))),
          ),
          const SizedBox(height: 14),
          const Text(
            'O que você procura?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Digite algo ou use os filtros de localização',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
          color: AppTheme.kidsPink, strokeWidth: 2.5),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: const Center(
                child: Text('📭', style: TextStyle(fontSize: 32))),
          ),
          const SizedBox(height: 14),
          const Text(
            'Nenhum resultado encontrado',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Tente outro termo ou ajuste os filtros',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String? message;
  const _ErrorState({this.message});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('⚠️', style: TextStyle(fontSize: 34)),
            const SizedBox(height: 10),
            Text(
              message ?? 'Erro ao buscar itens',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}