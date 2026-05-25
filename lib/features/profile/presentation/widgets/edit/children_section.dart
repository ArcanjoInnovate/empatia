import 'package:empatia/core/models/child_model.dart';
import 'package:empatia/features/profile/controller/profile_controller.dart';
import 'package:flutter/material.dart';

// ── Design tokens ────────────────────────────────────────────
const _pink   = Color(0xFFFF6B9D);
const _navy   = Color(0xFF1E3A8A);
const _purple = Color(0xFF8B5CF6);

const _childEmojis = ['👦', '👧', '👶', '🧒', '👦🏽', '👧🏽'];

/// 👨‍👩‍👧‍👦 CHILDREN SECTION
///
/// Exibe a lista de filhos, botão de adicionar,
/// e gerencia os modais de add/edit/remover.
class ChildrenSection extends StatelessWidget {
  final List<ChildModel> children;
  final ProfileController controller;

  const ChildrenSection({
    Key? key,
    required this.children,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...children.map((child) => _ChildCard(
              child: child,
              onEdit: () => _showEditSheet(context, child),
              onRemove: () => _confirmRemove(context, child),
            )),
        const SizedBox(height: 8),
        _AddChildButton(onTap: () => _showAddSheet(context)),
      ],
    );
  }

  // ── Modais ─────────────────────────────────────────────────

  void _confirmRemove(BuildContext context, ChildModel child) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Remover ${child.name ?? "filho"}?'),
        content: const Text('Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              controller.removeChild(child.id!);
            },
            child: const Text('Remover',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ChildFormSheet(
        title: 'Adicionar filho',
        confirmLabel: 'Adicionar',
        onConfirm: (name, age, emoji) async {
          return controller.addChild(name: name, age: age, emoji: emoji);
        },
      ),
    );
  }

  void _showEditSheet(BuildContext context, ChildModel child) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ChildFormSheet(
        title: 'Editar filho',
        confirmLabel: 'Salvar',
        initialName: child.name,
        initialAge: child.age?.toString(),
        initialEmoji: child.emoji ?? '👶',
        onConfirm: (name, age, emoji) async {
          return controller.updateChild(
            childId: child.id!,
            name: name,
            age: age,
            emoji: emoji,
          );
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// CARD DE FILHO
// ══════════════════════════════════════════════════════════════

class _ChildCard extends StatelessWidget {
  final ChildModel child;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  const _ChildCard({
    required this.child,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFE0F2FE),
            const Color(0xFFFFF9E6).withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF2563EB).withOpacity(0.15),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          // Emoji clicável
          GestureDetector(
            onTap: onEdit,
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF2563EB).withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(child.emoji ?? '👶',
                    style: const TextStyle(fontSize: 30)),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Nome e idade
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  child.name ?? 'Filho',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: _navy,
                  ),
                ),
                if (child.age != null)
                  Text(
                    '${child.age} anos',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),

          // Ações
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_rounded,
                color: Color(0xFF2563EB), size: 20),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline_rounded,
                color: Colors.red, size: 20),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// BOTÃO ADICIONAR FILHO
// ══════════════════════════════════════════════════════════════

class _AddChildButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddChildButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _pink.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_rounded, color: _pink, size: 22),
            SizedBox(width: 8),
            Text(
              'Adicionar filho',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: _pink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// FORMULÁRIO DE FILHO (add e edit compartilham o mesmo sheet)
// ══════════════════════════════════════════════════════════════

class _ChildFormSheet extends StatefulWidget {
  final String title;
  final String confirmLabel;
  final String? initialName;
  final String? initialAge;
  final String initialEmoji;
  final Future<bool> Function(String? name, String? age, String emoji) onConfirm;

  const _ChildFormSheet({
    required this.title,
    required this.confirmLabel,
    required this.onConfirm,
    this.initialName,
    this.initialAge,
    this.initialEmoji = '👶',
  });

  @override
  State<_ChildFormSheet> createState() => _ChildFormSheetState();
}

class _ChildFormSheetState extends State<_ChildFormSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _ageCtrl;
  late String _selectedEmoji;

  @override
  void initState() {
    super.initState();
    _nameCtrl      = TextEditingController(text: widget.initialName);
    _ageCtrl       = TextEditingController(text: widget.initialAge);
    _selectedEmoji = widget.initialEmoji;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 20),

          Text(widget.title,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: _navy)),
          const SizedBox(height: 20),

          // Emoji picker
          Wrap(
            spacing: 10,
            children: _childEmojis.map((e) {
              final sel = e == _selectedEmoji;
              return GestureDetector(
                onTap: () => setState(() => _selectedEmoji = e),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                    color: sel
                        ? _pink.withOpacity(0.15)
                        : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: sel ? _pink : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(e, style: const TextStyle(fontSize: 28)),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Campos nome + idade
          Row(
            children: [
              Expanded(flex: 2, child: _field(_nameCtrl, 'Nome')),
              const SizedBox(width: 10),
              Expanded(
                child: _field(_ageCtrl, 'Idade',
                    keyboardType: TextInputType.number),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Botão confirmar
          GestureDetector(
            onTap: () async {
              final ok = await widget.onConfirm(
                _nameCtrl.text,
                _ageCtrl.text,
                _selectedEmoji,
              );
              if (ok && context.mounted) Navigator.pop(context);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [_pink, _purple]),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: Text(widget.confirmLabel,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF8F8FF),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: _pink.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _pink, width: 2),
        ),
      ),
    );
  }
}