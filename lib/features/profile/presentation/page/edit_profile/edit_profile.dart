import 'dart:ui';

import 'package:empatia/core/data/models/user_model.dart';
import 'package:empatia/core/widget/social_links_row.dart';
import 'package:empatia/features/profile/controller/profile_controller.dart';
import 'package:empatia/features/profile/data/service/location_service.dart';
import 'package:empatia/features/profile/presentation/widgets/edit/children_section.dart';
import 'package:empatia/features/profile/presentation/widgets/edit/location_section.dart';
import 'package:empatia/features/profile/presentation/widgets/edit/profile_photo_section.dart';
import 'package:empatia/core/theme/app_avatars.dart';
import 'package:empatia/core/theme/app_decorations.dart';
import 'package:empatia/core/theme/app_icons.dart';
import 'package:empatia/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class EditProfilePage extends StatefulWidget {
  /// Usuário já carregado na tela anterior.
  /// Elimina o StreamBuilder e o lag de ~3s na abertura.
  final UserModel currentUser;

  const EditProfilePage({Key? key, required this.currentUser}) : super(key: key);

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  // ── Controllers ────────────────────────────────────────────
  final _nameController         = TextEditingController();
  final _ageController          = TextEditingController();
  final _statusController       = TextEditingController();
  final _neighborhoodController = TextEditingController();
  final _instagramController    = TextEditingController();
  final _xController            = TextEditingController();

  // ── Estado de seleção ──────────────────────────────────────
  String  _selectedEmoji      = AppAvatars.defaultParentAvatar;
  String? _selectedSexo;
  String? _selectedEstado;
  String? _selectedCidade;
  double? _cityLat;
  double? _cityLng;
  XFile?   _selectedProfilePhoto; // ← NOVO: foto de perfil selecionada
  bool _usePhoto = false; // true = manter/usar foto; false = usar avatar

  /// true = usuário selecionou bairro da lista (ou veio do banco)
  bool _neighborhoodConfirmed = false;

  ProfileController? _profileController;

  // ── Listas de avatares (ilustrações, não emojis) ────────────
  List<String> get _emojisAtivos => AppAvatars.forSexo(_selectedSexo);

  // ══════════════════════════════════════════════════════════
  // LIFECYCLE
  // ══════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    // Inicializa campos imediatamente — sem esperar stream do Firebase.
    _initFields(widget.currentUser);
  }

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
    _instagramController.dispose();
    _xController.dispose();
    super.dispose();
  }

  void _onControllerChange() {
    // Listener mantido apenas para erros que ocorram fora do fluxo de _onSave
    if (!mounted) return;
    final ctrl = _profileController!;
    if (ctrl.saveState == SaveState.error) {
      _showSnackBar('❌ ${ctrl.errorMessage}', Colors.redAccent);
      ctrl.resetState();
    }
  }

  void _initFields(UserModel user) {

    _nameController.text         = user.name ?? '';
    _ageController.text          = user.age?.toString() ?? '';
    _statusController.text       = user.status ?? '';
    _neighborhoodController.text = user.neighborhood ?? '';
    _instagramController.text    = user.socialInstagram ?? '';
    _xController.text            = user.socialX ?? '';

    if (user.profileEmoji != null) _selectedEmoji = user.profileEmoji!;
    _usePhoto = (user.profileImage?.trim().isNotEmpty ?? false);
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

  Future<void> _onSave(ProfileController controller) async {
    // Valida bairro: se digitou mas não selecionou da lista, bloqueia
    final bairroDigitado = _neighborhoodController.text.trim();
    if (bairroDigitado.isNotEmpty && !_neighborhoodConfirmed) {
      _showSnackBar(
        '⚠️ Selecione o bairro na lista de sugestões.',
        AppTheme.donationReservedColor,
      );
      return;
    }

    // Exibe overlay de carregando — bloqueia interação e cobre a tela
    _showLoadingOverlay();

    await controller.saveProfile(
      name:         _nameController.text,
      age:          _ageController.text,
      status:       _statusController.text,
      city:         _selectedCidade,
      state:        _selectedEstado,
      neighborhood: bairroDigitado.isEmpty ? null : bairroDigitado,
      profileEmoji: _selectedEmoji,
      currentUser:  widget.currentUser,
      sexo:         _selectedSexo,
      socialInstagram: _instagramController.text,
      socialX:         _xController.text,
      latitude:     _cityLat,
      longitude:    _cityLng,
      profilePhoto: _selectedProfilePhoto,
      usePhoto:     _usePhoto,
    );

    // Remove o overlay
    if (mounted) Navigator.of(context, rootNavigator: true).pop();

    if (!mounted) return;

    if (controller.saveState == SaveState.success) {
      controller.resetState();
      Navigator.pop(context); // volta para o ProfilePage
    } else if (controller.saveState == SaveState.error) {
      _showSnackBar('❌ ${controller.errorMessage}', Colors.redAccent);
      controller.resetState();
    }
  }

  void _showLoadingOverlay() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (_) => const _SavingOverlay(),
    );
  }

  // ══════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final locationService = context.read<LocationService>();

    // context.watch escopo estreito: apenas o botão salvar recria.
    // O restante da tela usa context.read para evitar rebuilds desnecessários.
    return Scaffold(
      backgroundColor: AppTheme.surfaceNeutral,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
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
                    child: StreamBuilder<UserModel?>(
                      stream: context.read<ProfileController>().userStream,
                      initialData: widget.currentUser, // evita flicker/loading no primeiro frame
                      builder: (context, snapshot) {
                        final children = snapshot.data?.children ?? widget.currentUser.children ?? [];
                        return ChildrenSection(
                          children: children,
                          controller: context.read<ProfileController>(),
                        );
                      },
                  )),
                  const SizedBox(height: 16),
                  // Selector: só o botão salvar recria quando saveState muda
                  Selector<ProfileController, SaveState>(
                    selector: (_, c) => c.saveState,
                    builder: (_, state, ___) => _buildSaveButton(
                        context.read<ProfileController>(), state),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
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
          currentPhotoUrl: widget.currentUser.profileImage,
          currentEmoji: _selectedEmoji,
          availableEmojis: _emojisAtivos,
          onPhotoChanged: (photo, emoji, usePhoto) {
            setState(() {
              _selectedProfilePhoto = photo;
              _selectedEmoji = emoji;
              _usePhoto = usePhoto;
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

        // ── Redes sociais ──
        _buildFieldLabel('🌐', 'Redes Sociais (opcional)'),
        const SizedBox(height: 4),
        Text(
          'Digite só o seu nome de usuário — sem o link completo.',
          style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 10),
        _buildHandleField(
          label: 'Instagram',
          emoji: '📷',
          domain: 'instagram.com/',
          controller: _instagramController,
          hint: 'seu_usuario',
        ),
        ListenableBuilder(
          listenable: _instagramController,
          builder: (_, __) => SocialConfirmCard(
            platform: 'Instagram',
            rawValue: _instagramController.text,
          ),
        ),
        const SizedBox(height: 14),
        _buildHandleField(
          label: 'X (Twitter)',
          emoji: '✖️',
          domain: 'x.com/',
          controller: _xController,
          hint: 'seu_usuario',
        ),
        ListenableBuilder(
          listenable: _xController,
          builder: (_, __) => SocialConfirmCard(
            platform: 'X',
            rawValue: _xController.text,
          ),
        ),
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
      decoration: AppDecorations.editProfileHeader,
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
                  decoration: AppDecorations.editProfileBackButton,
                  child: const Icon(AppIcons.back,
                      color: AppTheme.backgroundColor, size: 20),
                ),
              ),
              const SizedBox(width: 16),
              const Text('EDITAR PERFIL',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.backgroundColor,
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
      decoration: AppDecorations.editProfileSectionCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: AppDecorations.editProfileSectionIcon,
                  child: Text(emoji, style: const TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 12),
                Text(title,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primaryBlue)),
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
          decoration: AppDecorations.editProfileSexoChip(selected: sel),
          child: Column(
            children: [
              Text(icone, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 2),
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: sel ? AppTheme.backgroundColor : Colors.grey.shade600)),
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

  /// Campo de rede social: domínio fixo (não-editável) + a pessoa digita
  /// só o nome de usuário. Sanitiza automaticamente se ela colar @ ou um
  /// link completo sem querer.
  Widget _buildHandleField({
    required String label,
    required String emoji,
    required String domain,
    required TextEditingController controller,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(emoji, label),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.text,
          autocorrect: false,
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.primaryBlue),
          inputFormatters: [
            // Remove espaços e barras enquanto digita — só o usuário,
            // sem domínio nem caminho.
            FilteringTextInputFormatter.deny(RegExp(r'[\s/]')),
          ],
          decoration: InputDecoration(
            prefixText: domain,
            prefixStyle: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
            hintText: hint,
            hintStyle: TextStyle(
                color: Colors.grey.shade400, fontWeight: FontWeight.w500),
            filled: true,
            fillColor: AppTheme.surfaceBlueTint,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: AppDecorations.editProfileFieldBorder(focused: false),
            focusedBorder: AppDecorations.editProfileFieldBorder(focused: true),
          ),
        ),
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
              fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.primaryBlue),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
                color: Colors.grey.shade400, fontWeight: FontWeight.w500),
            filled: true,
            fillColor: AppTheme.surfaceBlueTint,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: AppDecorations.editProfileFieldBorder(focused: false),
            focusedBorder: AppDecorations.editProfileFieldBorder(focused: true),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(ProfileController controller, SaveState state) {
    final isLoading = state == SaveState.loading;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: isLoading ? null : () => _onSave(controller),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: AppDecorations.editProfileSaveButton(loading: isLoading),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(
                        color: AppTheme.backgroundColor, strokeWidth: 2.5))
              else
                const Icon(AppIcons.checkCircle,
                    color: AppTheme.backgroundColor, size: 24),
              const SizedBox(width: 10),
              Text(
                isLoading ? 'Salvando...' : 'SALVAR ALTERAÇÕES',
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.backgroundColor,
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
              fontWeight: FontWeight.w700, color: AppTheme.backgroundColor)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ));
  }
}

// ── Overlay de salvando ───────────────────────────────────────────────────────

class _SavingOverlay extends StatelessWidget {
  const _SavingOverlay();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Fundo desfocado
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Container(color: Colors.black.withOpacity(0.25)),
        ),
        Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.85, end: 1),
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutBack,
            builder: (context, scale, child) {
              return Transform.scale(scale: scale, child: child);
            },
            child: Container(
              width: 260,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.backgroundColor,
                    AppTheme.backgroundColor.withOpacity(0.95),
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withOpacity(0.4),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.kidsPink.withOpacity(0.18),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                    spreadRadius: -4,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.kidsPink.withOpacity(0.15),
                          AppTheme.primaryBlue.withOpacity(0.15),
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: CircularProgressIndicator(
                        strokeWidth: 3.5,
                        strokeCap: StrokeCap.round,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.kidsPink,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Salvando perfil...',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryBlue,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Aguarde enquanto enviamos sua foto 📸',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}