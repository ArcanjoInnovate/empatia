// lib/features/search/presentation/pages/search_page.dart

import 'package:empatia/core/data/models/user_model.dart';
import 'package:empatia/core/theme/app_theme.dart';
import 'package:empatia/features/search/controller/search_controller.dart';
import 'package:empatia/features/search/controller/search_filter_controller.dart';
import 'package:empatia/features/search/presentation/widgets/location_filter_section.dart';
import 'package:empatia/features/search/presentation/widgets/search_result_card.dart';
import 'package:flutter/material.dart' hide SearchController;
import 'package:provider/provider.dart';

const _types = [
  (null,       '🔍', 'Todos'),
  ('donation', '🎁', 'Doações'),
  ('dream',    '⭐', 'Sonhos'),
];

const _categories = [
  (null,        '✨', 'Todos'),
  ('clothes',   '👕', 'Roupas'),
  ('toys',      '🧸', 'Brinquedos'),
  ('books',     '📚', 'Livros'),
  ('food',      '🍎', 'Alimentos'),
  ('furniture', '🛋️', 'Móveis'),
  ('others',    '📦', 'Outros'),
];

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
    _focusNode  = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final user = context.read<UserModel?>();
      final fc   = context.read<SearchFilterController>();
      final sc   = context.read<SearchController>();

      sc.loadInitial();

      await fc.loadEstados();

      if (!mounted) return;
      if (user?.state != null || user?.city != null) {
        await fc.prefillFromUser(
          stateSigla: user?.state,
          cityName:   user?.city,
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
          cityName:   fc.selectedCidade?.nome,
          userLat:    fc.userLocation?.latitude,
          userLng:    fc.userLocation?.longitude,
          radiusKm:   fc.radiusKm,
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
            searchCtrl:      _searchCtrl,
            focusNode:       _focusNode,
            filtersExpanded: _filtersExpanded,
            onToggleFilters: () =>
                setState(() => _filtersExpanded = !_filtersExpanded),
            onFiltersChanged: _onFiltersChanged,
            onClearAll:      _clearAll,
          ),
        ),
      ),
    );
  }
}

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
        SliverToBoxAdapter(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SearchBar(
                searchCtrl:      searchCtrl,
                focusNode:       focusNode,
                filtersExpanded: filtersExpanded,
                onToggleFilters: onToggleFilters,
                onClearAll:      onClearAll,
              ),

              AnimatedSize(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeInOut,
                child: filtersExpanded
                    ? LocationFilterSection(
                        onFiltersChanged: onFiltersChanged)
                    : const SizedBox.shrink(),
              ),

              const _ActiveFilterChips(),
              const SizedBox(height: 6),

              const _TypeFilterBar(),
              const SizedBox(height: 6),

              const _CategoryFilterBar(),
              const SizedBox(height: 2),

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

        // ✅ currentUserId passado para o _ResultsSliver
        _ResultsSliver(
          state:         ctrl.state,
          results:       ctrl.results,
          errorMessage:  ctrl.errorMessage,
          currentUserId: context.read<UserModel?>()?.id,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BARRA DE BUSCA
// ─────────────────────────────────────────────────────────────────────────────

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
          Row(
            children: [
              Expanded(
                child: _SearchTextField(
                  searchCtrl: searchCtrl,
                  focusNode:  focusNode,
                ),
              ),
              const SizedBox(width: 10),
              _FilterToggleButton(
                expanded:   filtersExpanded,
                hasFilters: fc.hasAnyLocationFilter,
                onTap:      onToggleFilters,
              ),
            ],
          ),
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
        focusNode:  focusNode,
        onChanged:  context.read<SearchController>().onQueryChanged,
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
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 13),
        ),
      ),
    );
  }
}

class _FilterToggleButton extends StatelessWidget {
  final bool expanded;
  final bool hasFilters;
  final VoidCallback onTap;
  const _FilterToggleButton({
    required this.expanded,
    required this.hasFilters,
    required this.onTap,
  });

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

// ─────────────────────────────────────────────────────────────────────────────
// CHIPS DE FILTROS ATIVOS
// ─────────────────────────────────────────────────────────────────────────────

class _ActiveFilterChips extends StatelessWidget {
  const _ActiveFilterChips();

  @override
  Widget build(BuildContext context) {
    final fc   = context.watch<SearchFilterController>();
    final sc   = context.watch<SearchController>();
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
      final sig  = fc.selectedEstado?.sigla;
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

    if (sc.selectedCategory != null) {
      final cat = _categories.firstWhere(
        (c) => c.$1 == sc.selectedCategory,
        orElse: () => (sc.selectedCategory, '🏷️', sc.selectedCategory!),
      );
      chips.add(_ChipData(
        icon: cat.$2,
        label: cat.$3,
        isCategory: true,
        onRemove: () =>
            context.read<SearchController>().selectCategory(null),
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
  final bool isCategory;
  const _ChipData({
    required this.icon,
    required this.label,
    required this.onRemove,
    this.isSpecial  = false,
    this.isCategory = false,
  });
}

class _Chip extends StatelessWidget {
  final _ChipData data;
  const _Chip({required this.data});

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final Color border;

    if (data.isCategory) {
      bg     = const Color(0xFFF3F0FF);
      fg     = const Color(0xFF6D28D9);
      border = const Color(0xFFDDD6FE);
    } else if (data.isSpecial) {
      bg     = AppTheme.kidsGreen.withValues(alpha: 0.13);
      fg     = AppTheme.kidsGreenDark;
      border = AppTheme.kidsGreen;
    } else {
      bg     = AppTheme.kidsPink;
      fg     = Colors.white;
      border = AppTheme.kidsPink;
    }

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
                size: 12, color: fg.withValues(alpha: 0.70)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BARRAS DE FILTRO
// ─────────────────────────────────────────────────────────────────────────────

class _TypeFilterBar extends StatelessWidget {
  const _TypeFilterBar();

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<SearchController>();

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _types.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final t        = _types[i];
          final selected = ctrl.selectedType == t.$1;
          return _FilterPill(
            emoji:    t.$2,
            label:    t.$3,
            selected: selected,
            color:    AppTheme.kidsPink,
            onTap:    () => context
                .read<SearchController>()
                .selectType(selected ? null : t.$1),
          );
        },
      ),
    );
  }
}

class _CategoryFilterBar extends StatelessWidget {
  const _CategoryFilterBar();

  static const _color = Color(0xFF7C3AED);

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<SearchController>();

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final c        = _categories[i];
          final selected = ctrl.selectedCategory == c.$1;
          return _FilterPill(
            emoji:    c.$2,
            label:    c.$3,
            selected: selected,
            color:    _color,
            onTap:    () => context
                .read<SearchController>()
                .selectCategory(selected ? null : c.$1),
          );
        },
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String emoji;
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _FilterPill({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? color : AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? color : color.withValues(alpha: 0.22),
            width: 1.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.22),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RESULTS SLIVER
// ─────────────────────────────────────────────────────────────────────────────

class _ResultsSliver extends StatelessWidget {
  final SearchState state;
  final List<SearchResult> results;
  final String? errorMessage;

  /// UID do usuário logado — repassado para cada SearchResultCard.
  final String? currentUserId;

  const _ResultsSliver({
    required this.state,
    required this.results,
    required this.errorMessage,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case SearchState.idle:
      case SearchState.loading:
        return const SliverPadding(
          padding: EdgeInsets.fromLTRB(20, 4, 20, 32),
          sliver: _SkeletonGrid(),
        );

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
              mainAxisExtent: 220,
            ),
            delegate: SliverChildBuilderDelegate(
              // ✅ currentUserId passado para cada card
              (_, i) => SearchResultCard(
                result: results[i],
                currentUserId: currentUserId,
              ),
              childCount: results.length,
            ),
          ),
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SKELETON GRID
// ─────────────────────────────────────────────────────────────────────────────

class _SkeletonGrid extends StatelessWidget {
  const _SkeletonGrid();

  @override
  Widget build(BuildContext context) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 220,
      ),
      delegate: SliverChildBuilderDelegate(
        (_, __) => const _SkeletonCard(),
        childCount: 6,
      ),
    );
  }
}

class _SkeletonCard extends StatefulWidget {
  const _SkeletonCard();

  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final opacity = 0.06 + (_anim.value * 0.10);
        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.kidsPink.withValues(alpha: opacity),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 0, left: 0, right: 0, height: 140,
                  child: Container(
                    color: AppTheme.kidsPink.withValues(alpha: opacity + 0.04),
                  ),
                ),
                Positioned(
                  left: 12, right: 30, bottom: 42, height: 12,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.kidsPink.withValues(alpha: opacity + 0.06),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                Positioned(
                  left: 12, right: 60, bottom: 22, height: 10,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.kidsPink.withValues(alpha: opacity + 0.03),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY / ERROR STATE
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72, height: 72,
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