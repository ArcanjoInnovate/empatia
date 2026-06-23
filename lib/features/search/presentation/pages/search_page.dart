import 'package:empatia/core/data/models/user_model.dart';
import 'package:empatia/core/theme/app_theme.dart';
import 'package:empatia/features/search/controller/search_controller.dart';
import 'package:empatia/features/search/presentation/widgets/search_result_card.dart';
import 'package:flutter/material.dart' hide SearchController;
import 'package:provider/provider.dart';

// ── Opções de tipo ─────────────────────────────────────────────────────────────

const _types = [
  (null,       '🔍', 'Todos'),
  ('donation', '🎁', 'Doações'),
  ('dream',    '⭐', 'Sonhos'),
];

/// 🔍 SEARCH PAGE
///
/// Tela de busca unificada (donations + dreams).
/// Filtros: texto livre, estado, cidade, tipo.
/// Cidade e estado são pré-preenchidos com os dados do usuário logado.
class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late final TextEditingController _searchCtrl;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
    _focusNode = FocusNode();

    // Pré-seleciona estado e cidade do usuário logado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<UserModel?>();
      final ctrl = context.read<SearchController>();
      if (user?.state != null) ctrl.selectState(user!.state);
      if (user?.city != null) ctrl.selectCity(user!.city);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _clearAll() {
    _searchCtrl.clear();
    context.read<SearchController>().clearFilters();
    // Repõe localização do usuário após limpar
    final user = context.read<UserModel?>();
    final ctrl = context.read<SearchController>();
    if (user?.state != null) ctrl.selectState(user!.state);
    if (user?.city != null) ctrl.selectCity(user!.city);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppTheme.profileBackground,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SearchHeader(
                searchCtrl: _searchCtrl,
                focusNode: _focusNode,
                onClearAll: _clearAll,
              ),
              const _TypeFilterBar(),
              const Expanded(child: _ResultsArea()),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _SearchHeader extends StatelessWidget {
  final TextEditingController searchCtrl;
  final FocusNode focusNode;
  final VoidCallback onClearAll;

  const _SearchHeader({
    required this.searchCtrl,
    required this.focusNode,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<SearchController>();
    final user = context.watch<UserModel?>();

    return Container(
      color: AppTheme.profileBackground,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
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
          const SizedBox(height: 4),
          Text(
            'Encontre doações e sonhos perto de você',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),

          // Barra de busca
          Container(
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.kidsPink.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.kidsPink.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
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
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppTheme.kidsPink,
                  size: 22,
                ),
                suffixIcon: ctrl.query.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close_rounded,
                            color: Colors.grey.shade400, size: 18),
                        onPressed: () {
                          searchCtrl.clear();
                          context.read<SearchController>().onQueryChanged('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Chips: estado · cidade · limpar
          Row(
            children: [
              // Chip estado
              _LocationChip(
                icon: Icons.map_rounded,
                label: ctrl.selectedState ?? (user?.state ?? 'Estado'),
                isActive: ctrl.selectedState != null,
                onTap: () {
                  final isActive = ctrl.selectedState != null;
                  context.read<SearchController>().selectState(
                        isActive ? null : user?.state,
                      );
                },
              ),
              const SizedBox(width: 8),

              // Chip cidade
              _LocationChip(
                icon: Icons.location_on_rounded,
                label: ctrl.selectedCity ?? (user?.city ?? 'Cidade'),
                isActive: ctrl.selectedCity != null,
                onTap: () {
                  final isActive = ctrl.selectedCity != null;
                  context.read<SearchController>().selectCity(
                        isActive ? null : user?.city,
                      );
                },
              ),

              const Spacer(),

              // Limpar filtros
              if (ctrl.hasActiveFilters)
                GestureDetector(
                  onTap: onClearAll,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.kidsPink.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.filter_alt_off_rounded,
                            size: 13, color: AppTheme.kidsPink),
                        const SizedBox(width: 4),
                        Text(
                          'Limpar',
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
          ),
        ],
      ),
    );
  }
}

// ── Chip de localização (estado / cidade) ─────────────────────────────────────

class _LocationChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _LocationChip({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.kidsPink : AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? AppTheme.kidsPink
                : AppTheme.kidsPink.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12,
              color: isActive ? Colors.white : AppTheme.kidsPink,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isActive ? Colors.white : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Barra de filtro de tipo ───────────────────────────────────────────────────

class _TypeFilterBar extends StatelessWidget {
  const _TypeFilterBar();

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<SearchController>();

    return Container(
      height: 44,
      color: AppTheme.profileBackground,
      padding: const EdgeInsets.only(bottom: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _types.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final t = _types[i];
          final isSelected = ctrl.selectedType == t.$1;

          return GestureDetector(
            onTap: () => context
                .read<SearchController>()
                .selectType(isSelected ? null : t.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.kidsPink : AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.kidsPink
                      : AppTheme.kidsPink.withValues(alpha: 0.25),
                  width: 1.5,
                ),
                boxShadow: isSelected
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
                  Text(t.$2, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(
                    t.$3,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? AppTheme.backgroundColor
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

// ── Área de resultados ────────────────────────────────────────────────────────

class _ResultsArea extends StatelessWidget {
  const _ResultsArea();

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<SearchController>();

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: switch (ctrl.state) {
        SearchState.idle    => const _IdleState(),
        SearchState.loading => const _LoadingState(),
        SearchState.empty   => const _EmptyState(),
        SearchState.error   => _ErrorState(message: ctrl.errorMessage),
        SearchState.success => _ResultsGrid(results: ctrl.results),
      },
    );
  }
}

// ── Grid de resultados ────────────────────────────────────────────────────────

class _ResultsGrid extends StatelessWidget {
  final List<SearchResult> results;
  const _ResultsGrid({required this.results});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
          child: Text(
            '${results.length} ${results.length == 1 ? 'resultado' : 'resultados'}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.72,
            ),
            itemCount: results.length,
            itemBuilder: (_, i) => SearchResultCard(result: results[i]),
          ),
        ),
      ],
    );
  }
}

// ── Estados vazios / loading / erro / idle ────────────────────────────────────

class _IdleState extends StatelessWidget {
  const _IdleState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.kidsPink.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('🔍', style: TextStyle(fontSize: 36)),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'O que você procura?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Digite um item, sonho ou use os filtros',
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
        color: AppTheme.kidsPink,
        strokeWidth: 2.5,
      ),
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
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('📭', style: TextStyle(fontSize: 36)),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nenhum resultado encontrado',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tente outro termo ou ajuste os filtros',
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
            const Text('⚠️', style: TextStyle(fontSize: 36)),
            const SizedBox(height: 12),
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