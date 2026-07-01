import 'dart:io';

import 'package:empatia/core/data/models/child_model.dart';
import 'package:empatia/core/data/models/dream_model.dart';
import 'package:empatia/core/data/models/user_model.dart';
import 'package:empatia/core/widget/avatar_render.dart';
import 'package:empatia/core/theme/app_decorations.dart';
import 'package:empatia/core/theme/app_theme.dart';
import 'package:empatia/features/dream/controller/dream_controller.dart';
import 'package:empatia/features/profile/data/service/profile_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CATEGORIAS
// ─────────────────────────────────────────────────────────────────────────────

const _kDreamCategories = [
  ('clothes',   '👕', 'Roupas'),
  ('toys',      '🧸', 'Brinquedos'),
  ('books',     '📚', 'Livros'),
  ('food',      '🍎', 'Alimentos'),
  ('furniture', '🛋️', 'Móveis'),
  ('others',    '📦', 'Outros'),
];

/// 📝 DREAM FORM SHEET
class DreamFormSheet extends StatefulWidget {
  final DreamModel? dream;
  final UserModel currentUser;

  const DreamFormSheet({Key? key, required this.currentUser, this.dream})
      : super(key: key);

  @override
  State<DreamFormSheet> createState() => _DreamFormSheetState();
}

class _DreamFormSheetState extends State<DreamFormSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _dateCtrl;

  String? _selectedCategory;
  ChildModel? _selectedChild;
  XFile? _newPhoto;
  bool _removeCurrentImage = false;
  bool _loading = false;

  /// Mensagem de erro inline — null = sem erro visível
  String? _errorMessage;

  bool get _isEditing => widget.dream != null;
  String? get _existingImageUrl =>
      _removeCurrentImage ? null : widget.dream?.imageUrl;
  bool get _hasImage => _newPhoto != null || _existingImageUrl != null;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.dream?.title);
    _dateCtrl  = TextEditingController(text: widget.dream?.date);
    _selectedCategory = widget.dream?.category;

    if (widget.dream?.childId != null) {
      _selectedChild = widget.currentUser.children?.firstWhere(
        (c) => c.id == widget.dream!.childId,
        orElse: () => ChildModel(
          id:    widget.dream!.childId,
          name:  widget.dream!.childName,
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

  void _setError(String msg) {
    setState(() => _errorMessage = msg);
  }

  void _clearError() {
    if (_errorMessage != null) setState(() => _errorMessage = null);
  }

  // ── Image picker ───────────────────────────────────────────────────────────

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
                width: 36, height: 4,
                decoration: AppDecorations.imageSourceHandle,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded,
                  color: AppTheme.kidsPurple),
              title: const Text('Câmera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded,
                  color: AppTheme.kidsPurple),
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

  // ── Build ──────────────────────────────────────────────────────────────────

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
                width: 36, height: 4,
                decoration: AppDecorations.dreamFormHandle,
              ),
            ),
            const SizedBox(height: 18),

            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 20, color: AppTheme.primaryBlue),
                ),
                const SizedBox(width: 10),
                Text(
                  _isEditing ? 'Editar sonho' : 'Novo sonho',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Imagem de inspiração ────────────────────────────────
            _ImagePicker(
              newPhoto: _newPhoto,
              existingImageUrl: _existingImageUrl,
              onTap: _showPickerOptions,
            ),
            const SizedBox(height: 20),

            // ── Categoria ───────────────────────────────────────────
            _CategorySelector(
              selected: _selectedCategory,
              onSelected: (cat) {
                _clearError();
                setState(() => _selectedCategory = cat);
              },
            ),
            const SizedBox(height: 16),

            // ── Título ──────────────────────────────────────────────
            _field(_titleCtrl, 'Título do sonho'),
            const SizedBox(height: 12),

            // ── Descrição ───────────────────────────────────────────
            _fieldDescription(_dateCtrl, 'Descrição do sonho'),
            const SizedBox(height: 20),

            // ── Seletor de filho ────────────────────────────────────
            _ChildSelector(
              children: widget.currentUser.children ?? [],
              selected: _selectedChild,
              onSelected: (child) {
                _clearError();
                setState(() => _selectedChild = child);
              },
            ),
            const SizedBox(height: 16),

            // ── Feedback de erro inline ─────────────────────────────
            if (_errorMessage != null) ...[
              _InlineError(message: _errorMessage!),
              const SizedBox(height: 12),
            ],

            // ── Botão salvar ────────────────────────────────────────
            GestureDetector(
              onTap: _loading ? null : _submit,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
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

  Widget _field(TextEditingController ctrl, String label) => TextField(
        controller: ctrl,
        onChanged: (_) => _clearError(),
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: AppTheme.surfaceLight,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
                color: AppTheme.kidsPurple.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: AppTheme.kidsPurple, width: 2),
          ),
        ),
      );

  Widget _fieldDescription(TextEditingController ctrl, String label) =>
      TextField(
        controller: ctrl,
        maxLines: null,
        onChanged: (_) => _clearError(),
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: AppTheme.surfaceLight,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
                color: AppTheme.kidsPurple.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: AppTheme.kidsPurple, width: 2),
          ),
        ),
      );

  Future<void> _submit() async {
    if (_selectedCategory == null) {
      _setError('Selecione uma categoria para o sonho');
      return;
    }
    if (_selectedChild == null) {
      _setError('Selecione para qual filho é este sonho');
      return;
    }

    _clearError();
    setState(() => _loading = true);
    final ctrl = context.read<DreamController>();
    bool ok;

    if (_isEditing) {
      ok = await ctrl.updateDream(
        dreamId:         widget.dream!.id!,
        title:           _titleCtrl.text,
        category:        _selectedCategory!,
        date:            _dateCtrl.text,
        currentImageUrl: widget.dream?.imageUrl,
        newPhoto:        _newPhoto,
        removeImage:     _removeCurrentImage,
        childId:         _selectedChild!.id!,
        childName:       _selectedChild!.name ?? '',
        childEmoji:      _selectedChild!.emoji ?? '👶',
        childAge:        _selectedChild!.age,
        currentUser:     widget.currentUser,
      );
    } else {
      ok = await ctrl.addDream(
        title:       _titleCtrl.text,
        category:    _selectedCategory!,
        date:        _dateCtrl.text,
        photo:       _newPhoto,
        currentUser: widget.currentUser,
        childId:     _selectedChild!.id!,
        childName:   _selectedChild!.name ?? '',
        childEmoji:  _selectedChild!.emoji ?? '👶',
        childAge:    _selectedChild!.age,
      );
    }

    if (!mounted) return;
    setState(() => _loading = false);

    if (ok) {
      Navigator.pop(context);
    } else {
      final msg = ctrl.errorMessage ?? 'Não foi possível salvar o sonho.';
      ctrl.resetState();
      _setError(msg);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// INLINE ERROR WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class _InlineError extends StatelessWidget {
  final String message;
  const _InlineError({required this.message});

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEDED),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFFB3B3), width: 1.2),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('⚠️', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message.replaceAll('❌ ', ''),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFB00020),
                  height: 1.4,
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
// CATEGORY SELECTOR
// ─────────────────────────────────────────────────────────────────────────────

class _CategorySelector extends StatelessWidget {
  final String? selected;
  final void Function(String) onSelected;

  const _CategorySelector({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categoria do sonho',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 2.8,
          children: _kDreamCategories.map((cat) {
            final isSel = cat.$1 == selected;
            return GestureDetector(
              onTap: () => onSelected(cat.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isSel
                      ? AppTheme.kidsPurple
                      : AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSel
                        ? AppTheme.kidsPurple
                        : AppTheme.kidsPurple.withOpacity(0.25),
                    width: isSel ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(cat.$2, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        cat.$3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isSel
                              ? Colors.white
                              : AppTheme.primaryBlue,
                        ),
                      ),
                    ),
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

// ─────────────────────────────────────────────────────────────────────────────
// IMAGE PICKER
// ─────────────────────────────────────────────────────────────────────────────

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
    if (newPhoto != null) {
      return Stack(fit: StackFit.expand, children: [
        Image.file(File(newPhoto!.path), fit: BoxFit.cover),
        Positioned(right: 10, bottom: 10, child: _editBadge()),
      ]);
    }
    if (existingImageUrl != null) {
      return Stack(fit: StackFit.expand, children: [
        Image.network(
          existingImageUrl!,
          fit: BoxFit.cover,
          loadingBuilder: (_, child, progress) =>
              progress == null ? child : _placeholder(),
          errorBuilder: (_, __, ___) => _placeholder(),
        ),
        Positioned(right: 10, bottom: 10, child: _editBadge()),
      ]);
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate_rounded,
            size: 32, color: AppTheme.kidsPurple.withOpacity(0.6)),
        const SizedBox(height: 8),
        Text(
          'Adicionar imagem de inspiração',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.kidsPurple.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 2),
        Text('opcional',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
      ],
    );
  }

  Widget _editBadge() => Container(
        padding: const EdgeInsets.all(6),
        decoration: AppDecorations.dreamImageEditBadge,
        child: const Icon(Icons.edit_rounded,
            size: 14, color: AppTheme.backgroundColor),
      );

  Widget _placeholder() => Container(
        decoration: AppDecorations.dreamImagePickerPlaceholder,
        child: Center(
          child: Icon(Icons.broken_image_rounded,
              size: 40, color: Colors.grey.shade300),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// CHILD SELECTOR
// ─────────────────────────────────────────────────────────────────────────────

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
              border: Border.all(
                  color: AppTheme.kidsPurple.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.child_care_rounded,
                    color: Colors.grey.shade400, size: 20),
                const SizedBox(width: 10),
                Text(
                  'Nenhum filho cadastrado no perfil',
                  style: TextStyle(
                      fontSize: 13, color: Colors.grey.shade500),
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
                      ClipOval(
                        child: AvatarRender(value: child.emoji, size: 18),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        child.name ?? '',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isSel ? Colors.white : AppTheme.primaryBlue,
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

// ─────────────────────────────────────────────────────────────────────────────
// HELPER PÚBLICO
// ─────────────────────────────────────────────────────────────────────────────

void showDreamFormSheet(
  BuildContext context, {
  required UserModel currentUser,
  DreamModel? dream,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => DreamFormSheet(currentUser: currentUser, dream: dream),
  );
}