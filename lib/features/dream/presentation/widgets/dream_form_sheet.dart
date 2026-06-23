import 'dart:io';

import 'package:empatia/core/data/models/child_model.dart';
import 'package:empatia/core/data/models/dream_model.dart';
import 'package:empatia/core/data/models/user_model.dart';
import 'package:empatia/core/theme/app_decorations.dart';
import 'package:empatia/core/theme/app_theme.dart';
import 'package:empatia/features/dream/controller/dream_controller.dart';
import 'package:empatia/features/profile/data/service/profile_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

// ── Cores locais removidas — use AppTheme ─────────────────────────────────────
// _pink   → AppTheme.kidsPink
// _navy   → AppTheme.primaryBlue
// _purple → AppTheme.kidsPurple
//
// Lista de emojis movida para AppTheme.dreamEmojiOptions

/// 📝 DREAM FORM SHEET
///
/// Bottom sheet compartilhado para adicionar e editar sonhos.
/// Suporta adição de imagem de inspiração via câmera ou galeria.
///
/// Requer [currentUser] para repassar ao [DreamController.addDream].
/// A verificação de elegibilidade deve ser feita ANTES de abrir o sheet,
/// via [showDreamFormSheet], que exibe um dialog explicativo se necessário.
class DreamFormSheet extends StatefulWidget {
  /// null = modo adicionar, não-null = modo editar
  final DreamModel? dream;

  /// Usuário logado — obrigatório para criação de sonho.
  final UserModel currentUser;

  const DreamFormSheet({Key? key, required this.currentUser, this.dream})
      : super(key: key);

  @override
  State<DreamFormSheet> createState() => _DreamFormSheetState();
}

class _DreamFormSheetState extends State<DreamFormSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _dateCtrl;
  late String _selectedEmoji;
  late double _progress;

  ChildModel? _selectedChild;

  XFile? _newPhoto;
  bool _removeCurrentImage = false;
  bool _loading = false;

  bool get _isEditing => widget.dream != null;

  /// URL da imagem existente, respeitando o flag de remoção
  String? get _existingImageUrl =>
      _removeCurrentImage ? null : widget.dream?.imageUrl;

  /// Mostra preview: nova foto local ou URL existente
  bool get _hasImage => _newPhoto != null || _existingImageUrl != null;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.dream?.title);
    _dateCtrl  = TextEditingController(text: widget.dream?.date);
    _selectedEmoji = widget.dream?.emoji ?? '💭';
    _progress = widget.dream?.progress ?? 0.0;

    // Em modo edição, pré-seleciona o filho já vinculado ao sonho
    if (widget.dream?.childId != null) {
      _selectedChild = widget.currentUser.children?.firstWhere(
        (c) => c.id == widget.dream!.childId,
        orElse: () => ChildModel(
          id: widget.dream!.childId,
          name: widget.dream!.childName,
          emoji: widget.dream!.childEmoji,
        ),
      );
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  // ─── Picker ─────────────────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (picked != null) {
      setState(() {
        _newPhoto = picked;
        _removeCurrentImage = false;
      });
    }
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: AppDecorations.imageSourceHandle, // era: BoxDecoration inline
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded,
                  color: AppTheme.kidsPurple), // era: _purple
              title: const Text('Câmera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded,
                  color: AppTheme.kidsPurple), // era: _purple
              title: const Text('Galeria'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_hasImage) ...[
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded,
                    color: Colors.red),
                title: const Text('Remover imagem',
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _newPhoto = null;
                    _removeCurrentImage = true;
                  });
                },
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ─── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: AppDecorations.dreamFormHandle, // era: BoxDecoration inline
              ),
            ),
            const SizedBox(height: 18),

            Text(
              _isEditing ? 'Editar sonho' : 'Novo sonho',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppTheme.primaryBlue, // era: _navy
              ),
            ),
            const SizedBox(height: 20),

            // ── Imagem de inspiração ──────────────────────────────────
            _ImagePicker(
              newPhoto: _newPhoto,
              existingImageUrl: _existingImageUrl,
              onTap: _showPickerOptions,
            ),
            const SizedBox(height: 16),

            // ── Emoji picker ─────────────────────────────────────────
            Text(
              'Emoji',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              // era: lista local _dreamEmojis → agora AppTheme.dreamEmojiOptions
              children: AppTheme.dreamEmojiOptions.map((emoji) {
                final sel = emoji == _selectedEmoji;
                return GestureDetector(
                  onTap: () => setState(() => _selectedEmoji = emoji),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 44, height: 44,
                    // era: BoxDecoration inline com _purple
                    decoration: sel
                        ? AppDecorations.dreamEmojiSelected
                        : AppDecorations.dreamEmojiUnselected,
                    child: Center(
                      child: Text(emoji,
                          style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // ── Título ───────────────────────────────────────────────
            _field(_titleCtrl, 'Título do sonho'),
            const SizedBox(height: 12),

            // ── Data meta ────────────────────────────────────────────
            _fieldDescription(_dateCtrl, 'Descrição do sonho'),
            const SizedBox(height: 20),

            // ── Seletor de filho ─────────────────────────────────────
            _ChildSelector(
              children: widget.currentUser.children ?? [],
              selected: _selectedChild,
              onSelected: (child) => setState(() => _selectedChild = child),
            ),
            const SizedBox(height: 20),

            // ── Botão salvar ─────────────────────────────────────────
            GestureDetector(
              onTap: _loading ? null : _submit,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                // era: BoxDecoration inline com _purple + Color(0xFFBB86FC)
                decoration: AppDecorations.dreamSaveButtonActive,
                child: Center(
                  child: _loading
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                            color: AppTheme.backgroundColor,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _isEditing ? 'Salvar alterações' : 'Adicionar sonho',
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
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppTheme.surfaceLight, // era: const Color(0xFFF8F8FF)
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
              color: AppTheme.kidsPurple.withOpacity(0.3)), // era: _purple
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
              color: AppTheme.kidsPurple, width: 2), // era: _purple
        ),
      ),
    );
  }

  Widget _fieldDescription(TextEditingController ctrl, String label) {
    return TextField(
      controller: ctrl,
      maxLines: null,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppTheme.surfaceLight, // era: const Color(0xFFF8F8FF)
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
              color: AppTheme.kidsPurple.withOpacity(0.3)), // era: _purple
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
              color: AppTheme.kidsPurple, width: 2), // era: _purple
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_selectedChild == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione para qual filho é este sonho'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(14))),
        ),
      );
      return;
    }

    setState(() => _loading = true);
    final ctrl = context.read<DreamController>();
    bool ok;

    if (_isEditing) {
      ok = await ctrl.updateDream(
        dreamId: widget.dream!.id!,
        title: _titleCtrl.text,
        emoji: _selectedEmoji,
        date: _dateCtrl.text,
        progress: _progress,
        currentImageUrl: widget.dream?.imageUrl,
        newPhoto: _newPhoto,
        removeImage: _removeCurrentImage,
        childId: _selectedChild!.id!,
        childName: _selectedChild!.name ?? '',
        childEmoji: _selectedChild!.emoji ?? '👶',
        currentUser: widget.currentUser,
      );
    } else {
      ok = await ctrl.addDream(
        title: _titleCtrl.text,
        emoji: _selectedEmoji,
        date: _dateCtrl.text,
        progress: _progress,
        photo: _newPhoto,
        currentUser: widget.currentUser,
        childId: _selectedChild!.id!,
        childName: _selectedChild!.name ?? '',
        childEmoji: _selectedChild!.emoji ?? '👶',
      );
    }

    if (mounted) setState(() => _loading = false);
    if (ok && mounted) Navigator.pop(context);
  }
}

// ── Widget de seleção de imagem ───────────────────────────────────────────────

class _ImagePicker extends StatelessWidget {
  final XFile? newPhoto;
  final String? existingImageUrl;
  final VoidCallback onTap;

  const _ImagePicker({
    required this.newPhoto,
    required this.existingImageUrl,
    required this.onTap,
  });

  bool get _hasImage => newPhoto != null || existingImageUrl != null;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: _hasImage ? 180 : 100,
        // era: BoxDecoration inline com Color(0xFFF5F0FF) + _purple
        decoration: _hasImage
            ? AppDecorations.dreamImagePickerFilled
            : AppDecorations.dreamImagePickerEmpty,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(17),
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    // Preview de nova foto local
    if (newPhoto != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.file(File(newPhoto!.path), fit: BoxFit.cover),
          Positioned(
            right: 10, bottom: 10,
            child: _editBadge(),
          ),
        ],
      );
    }

    // Imagem existente via URL
    if (existingImageUrl != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            existingImageUrl!,
            fit: BoxFit.cover,
            loadingBuilder: (_, child, progress) =>
                progress == null ? child : _placeholder(),
            errorBuilder: (_, __, ___) => _placeholder(),
          ),
          Positioned(
            right: 10, bottom: 10,
            child: _editBadge(),
          ),
        ],
      );
    }

    // Estado vazio
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate_rounded,
            size: 32,
            color: AppTheme.kidsPurple.withOpacity(0.6)), // era: _purple
        const SizedBox(height: 8),
        Text(
          'Adicionar imagem de inspiração',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.kidsPurple.withOpacity(0.7), // era: _purple
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'opcional',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade400,
          ),
        ),
      ],
    );
  }

  Widget _editBadge() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: AppDecorations.dreamImageEditBadge, // era: BoxDecoration inline
      child: const Icon(Icons.edit_rounded, size: 14, color: AppTheme.backgroundColor),
    );
  }

  Widget _placeholder() {
    return Container(
      decoration: AppDecorations.dreamImagePickerPlaceholder, // era: BoxDecoration inline
      child: Center(
        child: Icon(Icons.broken_image_rounded,
            size: 40, color: Colors.grey.shade300),
      ),
    );
  }
}

// ── Seletor de filho ──────────────────────────────────────────────────────────

class _ChildSelector extends StatelessWidget {
  final List<ChildModel> children;
  final ChildModel? selected;
  final void Function(ChildModel) onSelected;

  const _ChildSelector({
    required this.children,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Para qual filho?',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        if (children.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.kidsPurple.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.child_care_rounded,
                    color: Colors.grey.shade400, size: 20),
                const SizedBox(width: 10),
                Text(
                  'Nenhum filho cadastrado no perfil',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: children.map((child) {
              final isSel = child.id == selected?.id;
              return GestureDetector(
                onTap: () => onSelected(child),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSel
                        ? AppTheme.kidsPurple
                        : AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: isSel
                          ? AppTheme.kidsPurple
                          : AppTheme.kidsPurple.withOpacity(0.3),
                      width: isSel ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        child.emoji ?? '👶',
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        child.name ?? '',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isSel
                              ? Colors.white
                              : AppTheme.primaryBlue,
                        ),
                      ),
                      if (child.age != null) ...[
                        const SizedBox(width: 4),
                        Text(
                          '${child.age}a',
                          style: TextStyle(
                            fontSize: 11,
                            color: isSel
                                ? Colors.white70
                                : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}

// ── Helper público ────────────────────────────────────────────────────────────

/// Abre o sheet de criação/edição de sonho.
///
/// Para **criação** ([dream] == null) exige que o [currentUser] seja
/// totalmente verificado; caso contrário, exibe um snackbar com
/// "Termine a verificação para continuar" — o sheet NÃO é aberto.
///
/// Para **edição** ([dream] != null) o sheet abre diretamente, pois o
/// registro já existe e a guarda de verificação está no [DreamService].
void showDreamFormSheet(
  BuildContext context, {
  required UserModel currentUser,
  DreamModel? dream,
}) {
  // Bloqueia criação de novos sonhos por usuários não verificados
  if (dream == null && !ProfileService.isFullyVerified(currentUser)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Termine a verificação para continuar'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(14))),
      ),
    );
    return;
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => DreamFormSheet(currentUser: currentUser, dream: dream),
  );
}