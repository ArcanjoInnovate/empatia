import 'package:empatia/core/data/models/child_model.dart';
import 'package:empatia/features/profile/presentation/widgets/profile/profile_shared_widgets.dart';
import 'package:flutter/material.dart';

// ─── Design tokens ────────────────────────────────────────────────────────
const _pink   = Color(0xFFFF6B9D);
const _navy   = Color(0xFF1E3A8A);
const _purple = Color(0xFF8B5CF6);

/// 👨‍👩‍👧‍👦 PROFILE CHILDREN WIDGET
///
/// Exibe lista de filhos com TabBar quando há mais de um,
/// card único quando há apenas um, e empty state quando nenhum.
class ProfileChildrenWidget extends StatefulWidget {
  final List<ChildModel>? children;

  const ProfileChildrenWidget({Key? key, required this.children})
      : super(key: key);

  @override
  State<ProfileChildrenWidget> createState() => _ProfileChildrenWidgetState();
}

class _ProfileChildrenWidgetState extends State<ProfileChildrenWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final len = (widget.children?.isNotEmpty == true)
        ? widget.children!.length
        : 1;
    _tabController = TabController(length: len, vsync: this);
  }

  @override
  void didUpdateWidget(ProfileChildrenWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newLen = (widget.children?.isNotEmpty == true)
        ? widget.children!.length
        : 1;
    if (_tabController.length != newLen) {
      _tabController.dispose();
      _tabController = TabController(length: newLen, vsync: this);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final children = widget.children;

    if (children == null || children.isEmpty) {
      return ProfileEmptyStateWidget(
        emoji: '👶',
        message: 'Nenhum filho cadastrado',
        sub: 'Adicione informações sobre seus filhos no perfil',
      );
    }

    if (children.length == 1) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ChildCardWidget(child: children.first),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEEEEEE),
              borderRadius: BorderRadius.circular(14),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: _pink,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: _pink.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3)),
                ],
              ),
              indicatorPadding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey.shade500,
              labelStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              dividerColor: Colors.transparent,
              tabs: children.map((c) {
                return Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(c.emoji ?? '👶'),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(c.name ?? 'Filho',
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 120,
          child: TabBarView(
            controller: _tabController,
            children: children.map((c) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ChildCardWidget(child: c),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ── Child card ───────────────────────────────────────────────────────────────

class ChildCardWidget extends StatelessWidget {
  final ChildModel child;
  const ChildCardWidget({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE3ECFF), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF2563EB).withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(child.emoji ?? '👶',
                  style: const TextStyle(fontSize: 30)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  child.name ?? 'Filho',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: _navy,
                  ),
                ),
                if (child.age != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _pink.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${child.age} anos',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _pink,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
