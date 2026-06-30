import 'dart:io'; // ← NOVO
import 'package:flutter/foundation.dart'; // kIsWeb
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:empatia/core/theme/app_decorations.dart';
import 'package:empatia/core/theme/app_icons.dart';
import 'package:empatia/core/theme/app_theme.dart';
import 'package:empatia/core/widget/avatar_render.dart';

/// 📸 PROFILE PHOTO SECTION
///
/// Widget para escolher foto de perfil OU avatar ilustrado (substituiu
/// o antigo seletor de emoji). `currentEmoji`/`availableEmojis` mantêm o
/// nome por compatibilidade, mas agora carregam caminhos de asset
/// (ex: "assets/parents/woman/avatar_01.webp").
/// Usa [XFile] em vez de [File] para funcionar no web e no mobile.
class ProfilePhotoSection extends StatefulWidget {
  final String? currentPhotoUrl;
  final String currentEmoji;
  final Function(XFile? photo, String emoji, bool usePhoto) onPhotoChanged;
  final List<String> availableEmojis;

  const ProfilePhotoSection({
    Key? key,
    this.currentPhotoUrl,
    required this.currentEmoji,
    required this.onPhotoChanged,
    required this.availableEmojis,
  }) : super(key: key);

  @override
  State<ProfilePhotoSection> createState() => _ProfilePhotoSectionState();
}

class _ProfilePhotoSectionState extends State<ProfilePhotoSection> {
  XFile?  _selectedPhoto;
  late String _selectedEmoji;
  bool _usePhoto = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _selectedEmoji = widget.currentEmoji;
    _usePhoto = widget.currentPhotoUrl != null;
  }

  // ══════════════════════════════════════════════════════════
  // PERMISSÕES
  // ══════════════════════════════════════════════════════════

  Future<bool> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      _showPermissionDialog(
        'Câmera',
        'Precisamos de acesso à câmera para tirar sua foto de perfil.',
      );
      return false;
    }
    return status.isGranted;
  }

  Future<bool> _requestGalleryPermission() async {
    final status = await Permission.photos.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      _showPermissionDialog(
        'Galeria',
        'Precisamos de acesso à galeria para você escolher uma foto.',
      );
      return false;
    }
    return status.isGranted;
  }

  void _showPermissionDialog(String type, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Permissão de $type'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Abrir Configurações'),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // SELEÇÃO DE FOTO
  // ══════════════════════════════════════════════════════════

  Future<void> _pickImage(ImageSource source) async {
    // No web o browser gerencia permissão — permission_handler não funciona
    if (!kIsWeb) {
      bool hasPermission = false;
      if (source == ImageSource.camera) {
        hasPermission = await _requestCameraPermission();
      } else {
        hasPermission = await _requestGalleryPermission();
      }
      if (!hasPermission) return;
    }

    try {
      final XFile? image = await _picker.pickImage(
        // Câmera via browser é instável; força galeria no web
        source: kIsWeb ? ImageSource.gallery : source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedPhoto = image;
          _usePhoto = true;
        });
        widget.onPhotoChanged(_selectedPhoto, _selectedEmoji, true);
      }
    } catch (e) {
      debugPrint('❌ Erro ao selecionar imagem: $e');
      _showSnackBar('Erro ao selecionar imagem');
    }
  }

  void _removePhoto() {
    setState(() {
      _selectedPhoto = null;
      _usePhoto = false;
    });
    widget.onPhotoChanged(null, _selectedEmoji, false);
  }

  void _showImageSourceSheet() {
    // No web abre o file picker direto, sem bottom sheet
    if (kIsWeb) {
      _pickImage(ImageSource.gallery);
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Escolher foto',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: 20),
            _buildSourceOption(
              icon: AppIcons.camera,
              label: 'Tirar foto',
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            const SizedBox(height: 12),
            _buildSourceOption(
              icon: AppIcons.gallery,
              label: 'Escolher da galeria',
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_selectedPhoto != null || widget.currentPhotoUrl != null) ...[
              const SizedBox(height: 12),
              _buildSourceOption(
                icon: AppIcons.delete,
                label: 'Remover foto',
                color: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  _removePhoto();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppDecorations.photoSourceOption(accentColor: color),
        child: Row(
          children: [
            Icon(icon, color: color ?? AppTheme.kidsPink, size: 24),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: color ?? AppTheme.primaryBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildModeChip(
              icon: '📸',
              label: 'Foto',
              selected: _usePhoto,
              onTap: () {
                if (!_usePhoto) _showImageSourceSheet();
              },
            ),
            const SizedBox(width: 12),
            _buildModeChip(
              icon: '🧑‍🎨',
              label: 'Avatar',
              selected: !_usePhoto,
              onTap: () {
                setState(() => _usePhoto = false);
                widget.onPhotoChanged(null, _selectedEmoji, false);
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        Center(
          child: _usePhoto ? _buildPhotoPreview() : _buildAvatarPicker(),
        ),
      ],
    );
  }

  Widget _buildModeChip({
    required String icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: AppDecorations.photoModeChip(selected: selected),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: selected ? AppTheme.backgroundColor : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoPreview() {
    return GestureDetector(
      onTap: _showImageSourceSheet,
      child: Stack(
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: AppDecorations.photoPreviewCircle,
            child: ClipOval(
              child: _buildPhotoWidget(),
            ),
          ),
          Positioned(
            bottom: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: AppDecorations.photoCameraBadge,
              child: const Icon(AppIcons.camera,
                  color: AppTheme.backgroundColor, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ FIX PRINCIPAL:
  /// - Foto nova selecionada no mobile  → Image.file (caminho local)
  /// - Foto nova selecionada no web     → Image.network (blob URL)
  /// - Foto salva no Firebase (https)   → Image.network
  /// - Sem foto                         → placeholder
  Widget _buildPhotoWidget() {
    // 1. Usuário acabou de selecionar uma foto nesta sessão
    if (_selectedPhoto != null) {
      if (kIsWeb) {
        // No web, XFile.path é um blob URL — funciona com Image.network
        return Image.network(
          _selectedPhoto!.path,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _emptyPhotoPlaceholder(),
        );
      } else {
        // No mobile, XFile.path é um caminho local — usa Image.file
        return Image.file(
          File(_selectedPhoto!.path),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _emptyPhotoPlaceholder(),
        );
      }
    }

    // 2. Foto já salva no Firebase (URL remota)
    if (widget.currentPhotoUrl != null &&
        widget.currentPhotoUrl!.startsWith('http')) {
      return Image.network(
        widget.currentPhotoUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _emptyPhotoPlaceholder(),
      );
    }

    // 3. Nenhuma foto disponível
    return _emptyPhotoPlaceholder();
  }

  Widget _emptyPhotoPlaceholder() {
    return Container(
      decoration: AppDecorations.photoEmptyPlaceholder,
      child: const Center(
        child: Icon(AppIcons.person, size: 60, color: AppTheme.placeholderIcon),
      ),
    );
  }

  Widget _buildAvatarPicker() {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: AppDecorations.photoPreviewCircle,
          child: ClipOval(
            child: AvatarRender(value: _selectedEmoji, size: 120),
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.availableEmojis.map((avatarPath) {
            final selected = avatarPath == _selectedEmoji;
            return GestureDetector(
              onTap: () {
                setState(() => _selectedEmoji = avatarPath);
                widget.onPhotoChanged(null, _selectedEmoji, false);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 50,
                height: 50,
                decoration: AppDecorations.childEmojiOption(selected: selected),
                child: ClipOval(
                  child: AvatarRender(value: avatarPath, size: 50),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: const TextStyle(
                fontWeight: FontWeight.w700, color: AppTheme.backgroundColor)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}