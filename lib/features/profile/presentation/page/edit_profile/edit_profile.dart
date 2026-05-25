import 'dart:io';
import 'package:empatia/core/models/user_model.dart';
import 'package:empatia/features/profile/controller/profile_controller.dart';
import 'package:empatia/features/profile/data/service/location_service.dart';
import 'package:empatia/features/profile/presentation/widgets/edit/children_section.dart';
import 'package:empatia/features/profile/presentation/widgets/edit/location_section.dart';
import 'package:empatia/features/profile/presentation/widgets/edit/profile_photo_section.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ── Design tokens ─────────────────────────────────────────────
const _pink   = Color(0xFFFF6B9D);
const _navy   = Color(0xFF1E3A8A);
const _purple = Color(0xFF8B5CF6);

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({Key? key}) : super(key: key);

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  // ── Controllers ────────────────────────────────────────────
  final _nameController         = TextEditingController();
  final _ageController          = TextEditingController();
  final _statusController       = TextEditingController();
  final _neighborhoodController = TextEditingController();

  // ── Estado de seleção ──────────────────────────────────────
  String  _selectedEmoji      = '👩';
  String? _selectedSexo;
  String? _selectedEstado;
  String? _selectedCidade;
  double? _cityLat;
  double? _cityLng;
  File?   _selectedProfilePhoto; // ← NOVO: foto de perfil selecionada

  /// true = usuário selecionou bairro da lista (ou veio do banco)
  bool _neighborhoodConfirmed = false;

  bool       _fieldsInitialized = false;
  UserModel? _currentUser;
  ProfileController? _profileController;

  // ── Listas de emojis ───────────────────────────────────────
  static const _emojisFemininos = [
    '👩','👩‍🦰','👩‍🦱','👩‍🦳','👩‍🦲','👱‍♀️','🧕','👸',
    '🧝‍♀️','🧚‍♀️','🧜‍♀️','🧙‍♀️','👩‍🎤','👩‍🏫','👩‍⚕️',
    '👩‍💼','👩‍🍳','🥷','👩‍🦸','🙍‍♀️',
  ];
  static const _emojisMasculinos = [
    '👨','👨‍🦰','👨‍🦱','👨‍🦳','👨‍🦲','👱‍♂️','🧔','🧔‍♂️',
    '🤴','🧝‍♂️','🧙‍♂️','👨‍🎤','👨‍🏫','👨‍⚕️','👨‍💼',
    '👨‍🍳','👨‍🦸','🙍‍♂️','👲','🕵️‍♂️',
  ];
  static const _emojisNeutros = [
    '🧑','🧑‍🦰','🧑‍🦱','🧑‍🦳','🧑‍🦲','🧏','🧛','🧟','👤','🫥',
  ];

  List<String> get _emojisAtivos {
    if (_selectedSexo == 'masculino') return _emojisMasculinos;
    if (_selectedSexo == 'outro')     return _emojisNeutros;
    return _emojisFemininos;
  }

  // ══════════════════════════════════════════════════════════
  // LIFECYCLE
  // ══════════════════════════════════════════════════════════

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ctrl = context.read<ProfileController>();
    if (_profileController != ctrl) {
      _profileController?.removeListener(_onControllerChange);
      _profileController = ctrl;
      _profileController!.addListener(_onControllerChange);
    }
  }

  @override
  void dispose() {
    _profileController?.removeListener(_onControllerChange);
    _nameController.dispose();
    _ageController.dispose();
    _statusController.dispose();
    _neighborhoodController.dispose();
    super.dispose();
  }

  void _onControllerChange() {
    if (!mounted) return;
    final ctrl = _profileController!;
    if (ctrl.saveState == SaveState.success) {
      _showSnackBar('✅ Perfil atualizado!', const Color(0xFF4ADE80));
      ctrl.resetState();
    } else if (ctrl.saveState == SaveState.error) {
      _showSnackBar('❌ ${ctrl.errorMessage}', Colors.redAccent);
      ctrl.resetState();
    }
  }

  void _initFields(UserModel user) {
    if (_fieldsInitialized) return;
    _fieldsInitialized = true;

    _nameController.text         = user.name ?? '';
    _ageController.text          = user.age?.toString() ?? '';
    _statusController.text       = user.status ?? '';
    _neighborhoodController.text = user.neighborhood ?? '';

    if (user.profileEmoji != null) _selectedEmoji = user.profileEmoji!;
    _selectedSexo   = user.sexo ?? 'feminino';
    _selectedEstado = user.state;
    _selectedCidade = user.city;

    // Bairro que veio do banco é considerado confirmado
    if ((user.neighborhood ?? '').trim().isNotEmpty) {
      _neighborhoodConfirmed = true;
    }
  }

  // ══════════════════════════════════════════════════════════
  // SALVAR
  // ══════════════════════════════════════════════════════════

  void _onSave(ProfileController controller) {
    if (_currentUser == null) return;

    // Valida bairro: se digitou mas não selecionou da lista, bloqueia
    final bairroDigitado = _neighborhoodController.text.trim();
    if (bairroDigitado.isNotEmpty && !_neighborhoodConfirmed) {
      _showSnackBar(
        '⚠️ Selecione o bairro na lista de sugestões.',
        const Color(0xFFF59E0B),
      );
      return;
    }

    controller.saveProfile(
      name:         _nameController.text,
      age:          _ageController.text,
      status:       _statusController.text,
      city:         _selectedCidade,
      state:        _selectedEstado,
      neighborhood: bairroDigitado.isEmpty ? null : bairroDigitado,
      profileEmoji: _selectedEmoji,
      currentUser:  _currentUser!,
      sexo:         _selectedSexo,
      latitude:     _cityLat,
      longitude:    _cityLng,
      profilePhoto: _selectedProfilePhoto, // ← NOVO
    );
    Navigator.pop(context);
  }

  // ══════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final controller      = context.watch<ProfileController>();
    final locationService = context.read<LocationService>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: StreamBuilder<UserModel?>(
              stream: controller.userStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !_fieldsInitialized) {
                  return const Center(
                    child: CircularProgressIndicator(color: _pink),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Erro ao carregar perfil:\n${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                final user = snapshot.data;
                if (user != null) {
                  _currentUser = user;
                  _initFields(user);
                }

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildSection(
                        emoji: '✨',
                        title: 'Editar Perfil',
                        child: _buildProfileSection(locationService),
                      ),
                      _buildSection(
                        emoji: '👨‍👩‍👧‍👦',
                        title: 'Meus Filhos',
                        child: ChildrenSection(
                          children: user?.children ?? [],
                          controller: controller,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSaveButton(controller),
                      const SizedBox(height: 32),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // SEÇÃO DE PERFIL
  // ══════════════════════════════════════════════════════════

  Widget _buildProfileSection(LocationService locationService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Foto de Perfil OU Emoji ──
        _buildFieldLabel('📸', 'Foto de Perfil'),
        const SizedBox(height: 12),
        ProfilePhotoSection(
          currentPhotoUrl: _currentUser?.profileImage,
          currentEmoji: _selectedEmoji,
          availableEmojis: _emojisAtivos,
          onPhotoChanged: (photo, emoji) {
            setState(() {
              _selectedProfilePhoto = photo;
              _selectedEmoji = emoji;
            });
          },
        ),
        const SizedBox(height: 24),

        // Sexo
        _buildFieldLabel('⚧️', 'Sexo'),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildSexoChip('feminino',  '♀️', 'Feminino'),
            const SizedBox(width: 8),
            _buildSexoChip('masculino', '♂️', 'Masculino'),
            const SizedBox(width: 8),
            _buildSexoChip('outro',     '⚧',  'Outro'),
          ],
        ),
        const SizedBox(height: 16),

        // Campos de texto
        _buildField(label: 'Nome completo', emoji: '👤',
            controller: _nameController),
        const SizedBox(height: 14),
        _buildField(label: 'Status', emoji: '💖',
            controller: _statusController,
            hint: 'Ex: Mãe feliz, Super mãe...'),
        const SizedBox(height: 20),

        // Localização — widget separado
        LocationSection(
          locationService: locationService,
          selectedState: _selectedEstado,
          selectedCity: _selectedCidade,
          neighborhoodController: _neighborhoodController,
          onStateChanged: (sigla) => setState(() {
            _selectedEstado        = sigla;
            _selectedCidade        = null;
            _cityLat               = null;
            _cityLng               = null;
            _neighborhoodConfirmed = false;
          }),
          onCityChanged: (cidade) => setState(() {
            _selectedCidade        = cidade;
            _cityLat               = null;
            _cityLng               = null;
            _neighborhoodConfirmed = false;
          }),
          onCoordinatesChanged: (lat, lng) => setState(() {
            _cityLat = lat;
            _cityLng = lng;
          }),
          onNeighborhoodConfirmed: (confirmed) => setState(() {
            _neighborhoodConfirmed = confirmed;
          }),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════
  // WIDGETS INTERNOS
  // ══════════════════════════════════════════════════════════

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_pink, Color(0xFFFFC837), _purple],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 16),
              const Text('EDITAR PERFIL',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.5)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String emoji,
    required String title,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 6))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_pink, _purple]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(emoji, style: const TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 12),
                Text(title,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: _navy)),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Divider(color: Colors.grey.shade100, thickness: 1.5),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildSexoChip(String valor, String icone, String label) {
    final sel = _selectedSexo == valor;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _selectedSexo  = valor;
          _selectedEmoji = _emojisAtivos.first;
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: sel
                ? const LinearGradient(colors: [_pink, _purple])
                : null,
            color: sel ? null : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: sel ? Colors.transparent : _pink.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Text(icone, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 2),
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: sel ? Colors.white : Colors.grey.shade600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String emoji, String label) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildField({
    required String label,
    required String emoji,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(emoji, label),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w700, color: _navy),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
                color: Colors.grey.shade400, fontWeight: FontWeight.w500),
            filled: true,
            fillColor: const Color(0xFFF8F8FF),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  BorderSide(color: _pink.withOpacity(0.2), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: _pink, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(ProfileController controller) {
    final isLoading = controller.saveState == SaveState.loading;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: isLoading ? null : () => _onSave(controller),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isLoading
                  ? [Colors.grey.shade400, Colors.grey.shade500]
                  : const [_pink, Color(0xFFFFC837), _purple],
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: isLoading
                ? []
                : [
                    BoxShadow(
                        color: _pink.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8))
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5))
              else
                const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 24),
              const SizedBox(width: 10),
              Text(
                isLoading ? 'Salvando...' : 'SALVAR ALTERAÇÕES',
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message,
          style: const TextStyle(
              fontWeight: FontWeight.w700, color: Colors.white)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ));
  }
}