import 'dart:io';

import 'package:empatia/core/data/models/user_model.dart';
import 'package:empatia/core/widget/verification_block_dialog.dart';
import 'package:empatia/features/donation/controller/donation_controller.dart';
import 'package:empatia/features/donation/data/model/donation_model.dart';
import 'package:empatia/features/profile/data/service/profile_service.dart';
import 'package:empatia/core/theme/app_decorations.dart';
import 'package:empatia/core/theme/app_theme.dart';
import 'package:flutter/foundation.dart'; // kIsWeb
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';


const _categories = [
  ('clothes',   '👕', 'Roupas'),
  ('toys',      '🧸', 'Brinquedos'),
  ('books',     '📚', 'Livros'),
  ('food',      '🥫', 'Alimentos'),
  ('furniture', '🪑', 'Móveis'),
  ('other',     '📦', 'Outros'),
];

/// 📸 DONATION ITEM FORM SHEET
///
/// Bottom sheet para cadastrar um item na vitrine do doador.
/// Todos os campos são obrigatórios: nome, categoria, descrição e foto.
///
/// Usa [XFile] em vez de [File] para funcionar tanto no mobile quanto no web.
///
/// Uso:
///   showDonationItemFormSheet(context, currentUser: user);
///   showDonationItemFormSheet(context, currentUser: user, donation: item); // editar
class DonationItemFormSheet extends StatefulWidget {
  final UserModel currentUser;
  final DonationModel? donation; // null = novo, não-null = editar

  const DonationItemFormSheet({
    Key? key,
    required this.currentUser,
    this.donation,
  }) : super(key: key);

  @override
  State<DonationItemFormSheet> createState() => _DonationItemFormSheetState();
}

class _DonationItemFormSheetState extends State<DonationItemFormSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();
  final _picker    = ImagePicker();

  String?  _category;
  XFile?   _photo;      // XFile funciona no web e no mobile
  bool     _loading = false;

  // Erros por campo
  String? _titleError;
  String? _categoryError;
  String? _descError;
  String? _photoError;

  // Erro geral de submit (ex: Storage, rede, verificação)
  String? _submitError;

  bool get _isEditing => widget.donation != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _titleCtrl.text = widget.donation!.title ?? '';
      _descCtrl.text  = widget.donation!.description ?? '';
      _category       = widget.donation!.category;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  // ── Foto ─────────────────────────────────────────────────────────────

  Future<void> _pickPhoto(ImageSource source) async {
    // No web o browser gerencia permissão sozinho — permission_handler
    // retorna denied imediatamente e impede a seleção.
    if (!kIsWeb) {
      final permission = source == ImageSource.camera
          ? await Permission.camera.request()
          : await Permission.photos.request();

      if (!permission.isGranted) return;
    }

    final file = await _picker.pickImage(
      // Câmera via browser é instável; força galeria (file picker) no web
      source: kIsWeb ? ImageSource.gallery : source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (file != null) {
      setState(() {
        _photo      = file; // XFile direto — sem File(file.path)
        _photoError = null;
      });
    }
  }

  void _showPhotoSourceSheet() {
    // No web não existe câmera confiável: abre o file picker direto
    if (kIsWeb) {
      _pickPhoto(ImageSource.gallery);
      return;
    }

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
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: AppTheme.dividerColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: AppTheme.kidsPink),
              title: const Text('Tirar foto',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              onTap: () {
                Navigator.pop(context);
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: AppTheme.kidsPink),
              title: const Text('Escolher da galeria',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              onTap: () {
                Navigator.pop(context);
                _pickPhoto(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Validação ─────────────────────────────────────────────────────────

  bool _validate() {
    bool ok = true;

    setState(() {
      _titleError = _titleCtrl.text.trim().isEmpty
          ? 'Informe o nome do item'
          : _titleCtrl.text.trim().length < 3
              ? 'Mínimo de 3 caracteres'
              : null;

      _categoryError = _category == null ? 'Selecione uma categoria' : null;

      _descError = _descCtrl.text.trim().isEmpty
          ? 'Informe uma descrição'
          : _descCtrl.text.trim().length < 10
              ? 'Mínimo de 10 caracteres'
              : null;

      // Foto obrigatória apenas no cadastro; na edição mantém a existente
      _photoError = (!_isEditing && _photo == null)
          ? 'Adicione uma foto do item'
          : null;

      ok = _titleError == null &&
          _categoryError == null &&
          _descError == null &&
          _photoError == null;
    });

    return ok;
  }

  // ── Submit ────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_validate()) return;

    setState(() => _loading = true);
    final ctrl = context.read<DonationController>();
    bool ok = false;

    try {
      if (_isEditing) {
        ok = await ctrl.updateDonation(
          donationId: widget.donation!.id!,
          title: _titleCtrl.text,
          category: _category,
          description: _descCtrl.text,
          currentPhotoUrl: widget.donation!.photoUrl,
          newPhoto: _photo, // XFile? — null = mantém foto atual
        );
      } else {
        ok = await ctrl.createDonation(
          title: _titleCtrl.text,
          category: _category,
          description: _descCtrl.text,
          photo: _photo!, // seguro: _validate() garantiu _photo != null
          currentUser: widget.currentUser,
        );
      }
    } catch (e) {
      ok = false;
    } finally {
      // Sempre reseta o spinner, independente de sucesso ou erro
      if (mounted) setState(() => _loading = false);
    }

    if (!mounted) return;

    if (ok) {
      Navigator.pop(context);
    } else {
      final message = ctrl.errorMessage ?? 'Erro ao salvar item';
      ctrl.resetState();

      final isVerificationError = message.contains('Verifique seu e-mail') ||
          message.contains('complete seu perfil');

      if (isVerificationError) {
        await showVerificationRequiredDialog(
          context,
          feature: 'criar uma doação',
        );
      } else {
        setState(() => _submitError = message.replaceAll('❌ ', ''));
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 20,
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
                decoration: AppDecorations.donationFormHandle,
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
                  _isEditing ? 'Editar item' : 'Adicionar item à vitrine',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Todos os campos são obrigatórios',
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 20),

            // ── Foto ──
            _SectionLabel(label: '📸 Foto do item', error: _photoError),
            const SizedBox(height: 8),
            _PhotoPicker(
              photo: _photo,
              existingUrl: _isEditing ? widget.donation!.photoUrl : null,
              hasError: _photoError != null,
              onTap: _showPhotoSourceSheet,
            ),
            const SizedBox(height: 18),

            // ── Nome ──
            _SectionLabel(label: '🏷️ Nome do item', error: _titleError),
            const SizedBox(height: 8),
            _Field(
              controller: _titleCtrl,
              hint: 'Ex: Casaco infantil, Brinquedo de montar...',
              hasError: _titleError != null,
              onChanged: (_) {
                if (_titleError != null) setState(() => _titleError = null);
                if (_submitError != null) setState(() => _submitError = null);
              },
            ),
            const SizedBox(height: 18),

            // ── Categoria ──
            _SectionLabel(label: '📂 Categoria', error: _categoryError),
            const SizedBox(height: 8),
            _CategoryGrid(
              selected: _category,
              hasError: _categoryError != null,
              onSelect: (cat) => setState(() {
                _category      = cat;
                _categoryError = null;
                _submitError   = null;
              }),
            ),
            const SizedBox(height: 18),

            // ── Descrição ──
            _SectionLabel(label: '📝 Descrição', error: _descError),
            const SizedBox(height: 8),
            _Field(
              controller: _descCtrl,
              hint: 'Descreva o estado do item, tamanho, quantidade...',
              maxLines: 3,
              hasError: _descError != null,
              onChanged: (_) {
                if (_descError != null) setState(() => _descError = null);
                if (_submitError != null) setState(() => _submitError = null);
              },
            ),
            const SizedBox(height: 24),

            // ── Erro de submit inline ──
            if (_submitError != null) ...[
              Container(
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
                        _submitError!,
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
              const SizedBox(height: 12),
            ],

            // ── Botão ──
            GestureDetector(
              onTap: _loading ? null : _submit,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: _loading
                    ? AppDecorations.donationSubmitLoading
                    : AppDecorations.donationSubmitActive,
                child: Center(
                  child: _loading
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(
                            color: AppTheme.kidsPink,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          _isEditing ? 'Salvar alterações' : 'Publicar na vitrine',
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
}

// ── Componentes internos ──────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final String? error;
  const _SectionLabel({required this.label, this.error});

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
        if (error != null) ...[
          const SizedBox(height: 3),
          Text(
            error!,
            style: const TextStyle(fontSize: 11, color: AppTheme.errorRed),
          ),
        ],
      ],
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  final XFile? photo;       // XFile para suporte web + mobile
  final String? existingUrl;
  final bool hasError;
  final VoidCallback onTap;

  const _PhotoPicker({
    required this.photo,
    required this.existingUrl,
    required this.hasError,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photo != null || existingUrl != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: AppDecorations.donationPhotoPicker(
          hasError: hasError,
          hasPhoto: hasPhoto,
        ),
        child: hasPhoto
            ? ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    photo != null
                        ? Image.file(File(photo!.path), fit: BoxFit.cover)
                        : Image.network(existingUrl!, fit: BoxFit.cover),
                    // Overlay de trocar
                    Positioned(
                      bottom: 10, right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.shadowDark,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.camera_alt_rounded,
                                color: AppTheme.backgroundColor, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'Trocar foto',
                              style: TextStyle(
                                color: AppTheme.backgroundColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      color: hasError
                          ? AppTheme.errorRed.withOpacity(0.12)
                          : AppTheme.kidsPink.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add_a_photo_rounded,
                      color: hasError ? AppTheme.errorRed : AppTheme.kidsPink,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Adicionar foto do item',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: hasError ? AppTheme.errorRed : AppTheme.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Toque para escolher ou tirar uma foto',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  final String? selected;
  final bool hasError;
  final void Function(String) onSelect;

  const _CategoryGrid({
    required this.selected,
    required this.hasError,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: hasError ? const EdgeInsets.all(8) : EdgeInsets.zero,
      decoration: hasError
          ? BoxDecoration(
              border: Border.all(color: AppTheme.errorRed, width: 1.5),
              borderRadius: BorderRadius.circular(14),
            )
          : null,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _categories.map((cat) {
          final sel = selected == cat.$1;
          return GestureDetector(
            onTap: () => onSelect(cat.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: sel
                    ? AppTheme.kidsPink.withOpacity(0.12)
                    : AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: sel ? AppTheme.kidsPink : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(cat.$2,
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(
                    cat.$3,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: sel ? AppTheme.kidsPink : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final bool hasError;
  final void Function(String) onChanged;

  const _Field({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    required this.hasError,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 13,
          color: AppTheme.textMuted,
        ),
        filled: true,
        fillColor: hasError ? AppTheme.errorRed.withOpacity(0.06) : AppTheme.surfaceLight,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: hasError ? AppTheme.errorRed : AppTheme.kidsPink.withOpacity(0.3),
            width: hasError ? 2 : 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: hasError ? AppTheme.errorRed : AppTheme.kidsPink,
            width: 2,
          ),
        ),
      ),
    );
  }
}

// ── Helper para abrir o sheet ─────────────────────────────────────────────────

/// Abre o sheet de cadastro/edição de item de doação.
///
/// Para **criação** ([donation] == null) exige que o [currentUser] seja
/// totalmente verificado; caso contrário, exibe um snackbar com
/// "Termine a verificação para continuar" — o sheet NÃO é aberto.
///
/// Para **edição** ([donation] != null) o sheet abre diretamente, pois o
/// registro já existe e a guarda de verificação está no [DonationService].
void showDonationItemFormSheet(
  BuildContext context, {
  required UserModel currentUser,
  DonationModel? donation,
}) {
  // Bloqueia criação por usuários não verificados
  if (donation == null && !ProfileService.isFullyVerified(currentUser)) {
    showVerificationRequiredDialog(
      context,
      feature: 'criar uma doação',
    );
    return;
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => DonationItemFormSheet(
      currentUser: currentUser,
      donation: donation,
    ),
  );
}