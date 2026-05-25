import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

// ── Design tokens ────────────────────────────────────────────
const _pink = Color(0xFFFF6B9D);
const _navy = Color(0xFF1E3A8A);
const _purple = Color(0xFF8B5CF6);

/// 📸 PROFILE PHOTO SECTION
///
/// Widget para escolher foto de perfil OU emoji.
///
/// MODOS:
/// - Foto: usuário pode tirar foto ou escolher da galeria
/// - Emoji: usuário escolhe emoji como avatar
class ProfilePhotoSection extends StatefulWidget {
  final String? currentPhotoUrl;
  final String currentEmoji;
  final Function(File? photo, String emoji) onPhotoChanged;
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
  File? _selectedPhoto;
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
    bool hasPermission = false;

    if (source == ImageSource.camera) {
      hasPermission = await _requestCameraPermission();
    } else {
      hasPermission = await _requestGalleryPermission();
    }

    if (!hasPermission) return;

    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedPhoto = File(image.path);
          _usePhoto = true;
        });
        widget.onPhotoChanged(_selectedPhoto, _selectedEmoji);
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
    widget.onPhotoChanged(null, _selectedEmoji);
  }

  void _showImageSourceSheet() {
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
              width: 36,
              height: 4,
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
                color: _navy,
              ),
            ),
            const SizedBox(height: 20),
            _buildSourceOption(
              icon: Icons.camera_alt_rounded,
              label: 'Tirar foto',
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            const SizedBox(height: 12),
            _buildSourceOption(
              icon: Icons.photo_library_rounded,
              label: 'Escolher da galeria',
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_selectedPhoto != null || widget.currentPhotoUrl != null) ...[
              const SizedBox(height: 12),
              _buildSourceOption(
                icon: Icons.delete_outline_rounded,
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
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: (color ?? _pink).withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color ?? _pink, size: 24),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: color ?? _navy,
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
        // Toggle: Foto vs Emoji
        Row(
          children: [
            _buildModeChip(
              icon: '📸',
              label: 'Foto',
              selected: _usePhoto,
              onTap: () {
                if (!_usePhoto) {
                  _showImageSourceSheet();
                }
              },
            ),
            const SizedBox(width: 12),
            _buildModeChip(
              icon: '😀',
              label: 'Emoji',
              selected: !_usePhoto,
              onTap: () {
                setState(() => _usePhoto = false);
                widget.onPhotoChanged(null, _selectedEmoji);
              },
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Preview
        Center(
          child: _usePhoto ? _buildPhotoPreview() : _buildEmojiPicker(),
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
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(colors: [_pink, _purple])
                : null,
            color: selected ? null : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? Colors.transparent : _pink.withOpacity(0.2),
              width: 1.5,
            ),
          ),
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
                  color: selected ? Colors.white : Colors.grey.shade600,
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
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: _pink.withOpacity(0.3), width: 3),
              boxShadow: [
                BoxShadow(
                  color: _pink.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipOval(
              child: _selectedPhoto != null
                  ? Image.file(_selectedPhoto!, fit: BoxFit.cover)
                  : widget.currentPhotoUrl != null
                      ? Image.network(
                          widget.currentPhotoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _emptyPhotoPlaceholder(),
                        )
                      : _emptyPhotoPlaceholder(),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_pink, _purple]),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: const Icon(Icons.camera_alt_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyPhotoPlaceholder() {
    return Container(
      color: const Color(0xFFF8F8FF),
      child: const Center(
        child: Icon(Icons.person_rounded, size: 60, color: Color(0xFFD1D5DB)),
      ),
    );
  }

  Widget _buildEmojiPicker() {
    return Column(
      children: [
        // Emoji selecionado (grande)
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: _pink.withOpacity(0.3), width: 3),
            boxShadow: [
              BoxShadow(
                color: _pink.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Text(_selectedEmoji, style: const TextStyle(fontSize: 60)),
          ),
        ),
        const SizedBox(height: 20),

        // Grid de emojis
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.availableEmojis.map((emoji) {
            final selected = emoji == _selectedEmoji;
            return GestureDetector(
              onTap: () {
                setState(() => _selectedEmoji = emoji);
                widget.onPhotoChanged(null, _selectedEmoji);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: selected
                      ? _pink.withOpacity(0.15)
                      : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? _pink : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 28)),
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
        content: Text(
          message,
          style:
              const TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}