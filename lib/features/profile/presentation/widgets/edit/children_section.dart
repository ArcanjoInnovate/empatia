import 'package:empatia/core/data/models/child_model.dart';
import 'package:empatia/features/profile/controller/profile_controller.dart';
import 'package:empatia/core/theme/app_decorations.dart';
import 'package:empatia/core/theme/app_icons.dart';
import 'package:empatia/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _childEmojis = ['👦', '👧', '👶', '🧒', '👦🏽', '👧🏽'];

/// 👨‍👩‍👧‍👦 CHILDREN SECTION
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
            child: const Text('Remover', style: TextStyle(color: Colors.red)),
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
      decoration: AppDecorations.childEditCard,
      child: Row(
        children: [
          GestureDetector(
            onTap: onEdit,
            child: Container(
              width: 54,
              height: 54,
              decoration: AppDecorations.childEditAvatar,
              child: Center(
                child: Text(child.emoji ?? '👶',
                    style: const TextStyle(fontSize: 30)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  child.name ?? 'Filho',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primaryBlue,
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
          IconButton(
            onPressed: onEdit,
            icon: const Icon(AppIcons.edit,
                color: AppTheme.childCardAccent, size: 20),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(AppIcons.delete,
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
        decoration: AppDecorations.addChildButton,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(AppIcons.add, color: AppTheme.kidsPink, size: 22),
            SizedBox(width: 8),
            Text(
              'Adicionar filho',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppTheme.kidsPink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// FORMULÁRIO DE FILHO
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

  // ── Erros inline ─────────────────────────────────────────────
  String? _nameError;
  String? _ageError;
  bool    _loading = false;

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

  // ── Validação ─────────────────────────────────────────────────

  /// Retorna true se tudo estiver válido.
  bool _validate() {
    final name = _nameCtrl.text.trim();
    final ageRaw = _ageCtrl.text.trim();

    String? nameErr;
    String? ageErr;

    // Nome obrigatório
    if (name.isEmpty) {
      nameErr = 'Informe o nome da criança';
    } else if (name.length < 2) {
      nameErr = 'Mínimo de 2 caracteres';
    }

    // Idade obrigatória
    if (ageRaw.isEmpty) {
      ageErr = 'Informe a idade';
    } else {
      final parsed = int.tryParse(ageRaw);
      if (parsed == null) {
        ageErr = 'Apenas números';
      } else if (parsed < 0 || parsed > 17) {
        // ── Erro inline de idade — não usa SnackBar ───────────────
        ageErr = 'A criança deve ter entre 0 e 17 anos';
      }
    }

    setState(() {
      _nameError = nameErr;
      _ageError  = ageErr;
    });

    return nameErr == null && ageErr == null;
  }

  Future<void> _submit() async {
    if (!_validate()) return;

    setState(() => _loading = true);
    final ok = await widget.onConfirm(
      _nameCtrl.text.trim(),
      _ageCtrl.text.trim(),
      _selectedEmoji,
    );
    if (mounted) setState(() => _loading = false);
    if (ok && mounted) Navigator.pop(context);
  }

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Center(
            child: Text(
              widget.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppTheme.primaryBlue,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              'Nome e idade são obrigatórios',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ),
          const SizedBox(height: 20),

          // ── Emoji picker ──────────────────────────────────────────
          Center(
            child: Wrap(
              spacing: 10,
              children: _childEmojis.map((e) {
                final sel = e == _selectedEmoji;
                return GestureDetector(
                  onTap: () => setState(() => _selectedEmoji = e),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 50, height: 50,
                    decoration: AppDecorations.childEmojiOption(selected: sel),
                    child: Center(
                      child: Text(e, style: const TextStyle(fontSize: 28)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // ── Campo nome ────────────────────────────────────────────
          _FieldLabel(label: '👦 Nome', error: _nameError),
          const SizedBox(height: 6),
          _InputField(
            controller: _nameCtrl,
            hint: 'Ex: Lucas, Maria...',
            hasError: _nameError != null,
            onChanged: (_) {
              if (_nameError != null) setState(() => _nameError = null);
            },
          ),
          const SizedBox(height: 16),

          // ── Campo idade ───────────────────────────────────────────
          _FieldLabel(label: '🎂 Idade', error: _ageError),
          const SizedBox(height: 6),
          _InputField(
            controller: _ageCtrl,
            hint: 'Ex: 5',
            hasError: _ageError != null,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) {
              if (_ageError != null) setState(() => _ageError = null);
            },
          ),

          // ── Banner de erro de faixa etária ────────────────────────
          if (_ageError != null &&
              _ageError!.contains('entre 0 e 17')) ...[
            const SizedBox(height: 10),
            _AgeBanner(message: _ageError!),
          ],

          const SizedBox(height: 24),

          // ── Botão confirmar ───────────────────────────────────────
          GestureDetector(
            onTap: _loading ? null : _submit,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: AppDecorations.childFormSubmitButton(loading: _loading),
              child: Center(
                child: _loading
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(
                          color: AppTheme.kidsPink, strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        widget.confirmLabel,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.backgroundColor,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Label com erro inline ─────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String label;
  final String? error;

  const _FieldLabel({required this.label, this.error});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppTheme.primaryBlue,
          ),
        ),
        if (error != null && !error!.contains('entre 0 e 17')) ...[
          const SizedBox(height: 3),
          Text(
            error!,
            style: const TextStyle(fontSize: 11, color: Colors.red),
          ),
        ],
      ],
    );
  }
}

// ── Campo de texto ────────────────────────────────────────────────────────────

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool hasError;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final void Function(String) onChanged;

  const _InputField({
    required this.controller,
    required this.hint,
    required this.hasError,
    required this.onChanged,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
        filled: true,
        fillColor: hasError ? Colors.red.shade50 : AppTheme.surfaceBlueTint,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: hasError ? Colors.red : AppTheme.kidsPink.withOpacity(0.3),
            width: hasError ? 2 : 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: hasError ? Colors.red : AppTheme.kidsPink,
            width: 2,
          ),
        ),
      ),
    );
  }
}

// ── Banner de erro de faixa etária ────────────────────────────────────────────

class _AgeBanner extends StatelessWidget {
  final String message;
  const _AgeBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.shade200, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text('🚸', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Faixa etária inválida',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.4,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}