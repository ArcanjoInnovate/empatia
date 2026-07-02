import 'package:empatia/core/widget/avatar_render.dart';
import 'package:empatia/core/widget/social_links_row.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import 'package:empatia/core/theme/app_theme.dart';
import 'package:empatia/features/chat/data/models/chat_model.dart';
import 'package:empatia/features/chat/presentation/pages/chat_page.dart';
// Use SearchResult model shared with the search presentation layer
import 'package:empatia/features/search/controller/search_controller.dart' show SearchResult;
import 'package:empatia/features/search/presentation/widgets/search_result_card.dart';

/// 👤 PUBLIC PROFILE
///
/// Versão pública e somente-leitura do perfil de OUTRO usuário — usada
/// quando você toca no avatar/nome de alguém em telas como o ranking,
/// busca, chat, etc.
///
/// Só usa o nó `UsersPublic/{uid}` do Firebase (o mesmo já lido pelo
/// ranking), nunca o nó privado `Users/{uid}` — então não expõe e-mail,
/// telefone, filhos ou qualquer outro dado sensível de terceiros.
///
/// Aceita dados "de fallback" (geralmente já disponíveis na tela de
/// origem, como um [RankingEntry]) para exibir algo instantaneamente
/// enquanto busca a versão mais atual no banco.
class PublicProfilePage extends StatefulWidget {
  final String uid;
  final String? fallbackName;
  final String? fallbackAvatar; // profileEmoji (asset path) ou emoji legado
  final String? fallbackImage;  // foto de perfil (URL)
  final String? fallbackCity;
  final String? fallbackState;

  /// Dados extras opcionais (ex: vindos do ranking) — só exibição,
  /// não são buscados aqui.
  final int? score;
  final int? donationsCount;
  final int? position;

  const PublicProfilePage({
    Key? key,
    required this.uid,
    this.fallbackName,
    this.fallbackAvatar,
    this.fallbackImage,
    this.fallbackCity,
    this.fallbackState,
    this.score,
    this.donationsCount,
    this.position,
  }) : super(key: key);

  static Route<void> route({
    required String uid,
    String? fallbackName,
    String? fallbackAvatar,
    String? fallbackImage,
    String? fallbackCity,
    String? fallbackState,
    int? score,
    int? donationsCount,
    int? position,
  }) =>
      MaterialPageRoute(
        builder: (_) => PublicProfilePage(
          uid: uid,
          fallbackName: fallbackName,
          fallbackAvatar: fallbackAvatar,
          fallbackImage: fallbackImage,
          fallbackCity: fallbackCity,
          fallbackState: fallbackState,
          score: score,
          donationsCount: donationsCount,
          position: position,
        ),
      );

  @override
  State<PublicProfilePage> createState() => _PublicProfilePageState();
}

class _PublicChild {
  final String id;
  final String name;
  final String? avatar;
  final int? age;
  const _PublicChild({required this.id, required this.name, this.avatar, this.age});
}

class _PublicProfilePageState extends State<PublicProfilePage> {
  late String? _name = widget.fallbackName;
  late String? _avatar = widget.fallbackAvatar;
  late String? _image = widget.fallbackImage;
  late String? _city = widget.fallbackCity;
  late String? _state = widget.fallbackState;
  String? _sexo;
  String? _status;
  int? _age;
  bool _fullyVerified = false;
  String? _facebook;
  String? _instagram;
  String? _x;
  bool _loading = true;
  bool _notFound = false;

  List<_PublicChild> _children = [];
  List<SearchResult> _dreams = [];
  List<SearchResult> _availableDonations = [];
  bool _loadingGallery = true;

  /// 0 = Sonhos dos filhos · 1 = Doações disponíveis
  int _galleryTab = 0;

  /// Referências à rota e à animação — armazenadas no didChangeDependencies
  /// para que possam ser consultadas de dentro de Futures sem usar context.
  ModalRoute<dynamic>? _route;
  Animation<double>? _routeAnimation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_route == null) {
      _route          = ModalRoute.of(context);
      _routeAnimation = _route?.animation;
    }
  }

  /// setState seguro para callbacks assíncronos.
  ///
  /// Bloqueia a chamada se:
  ///   • o widget foi desmontado (mounted == false), ou
  ///   • a animação da rota está em reverse ou dismissed — o que acontece
  ///     IMEDIATAMENTE ao iniciar o pop, antes mesmo do primeiro frame da
  ///     transição ser desenhado.
  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    final status = _routeAnimation?.status;
    if (status == AnimationStatus.reverse ||
        status == AnimationStatus.dismissed) return;
    setState(fn);
  }

  @override
  void initState() {
    super.initState();
    _fetchPublicData();
    _fetchGallery();
  }

  Future<void> _fetchPublicData() async {
    try {
      final snap = await FirebaseDatabase.instance
          .ref('UsersPublic/${widget.uid}')
          .get();


      if (!snap.exists || snap.value is! Map) {
        _safeSetState(() {
          _loading = false;
          _notFound = _name == null; // só marca "não encontrado" se nem o fallback existe
        });
        return;
      }

      final m = Map<dynamic, dynamic>.from(snap.value as Map);
      _safeSetState(() {
        _name = m['name']?.toString() ?? _name;
        _avatar = m['profileEmoji']?.toString() ?? _avatar;
        _image = m['profileImage']?.toString() ?? _image;
        _city = m['city']?.toString() ?? _city;
        _state = m['state']?.toString() ?? _state;
        _sexo = m['sexo']?.toString();
        _status = m['status']?.toString();
        _age = (m['age'] as num?)?.toInt();
        _fullyVerified = m['fullyVerified'] == true;
        _facebook = m['socialFacebook']?.toString();
        _instagram = m['socialInstagram']?.toString();
        _x = m['socialX']?.toString();
        _loading = false;
      });
    } catch (_) {
      _safeSetState(() => _loading = false);
    }
  }

  /// Busca, em paralelo, os sonhos dos filhos e as doações disponíveis
  /// publicadas por esse usuário — ambos já são dados públicos (visíveis
  /// normalmente na busca/feed), então é seguro exibi-los aqui também.
  /// Os filhos são derivados dos próprios sonhos (childId/childName/
  /// childEmoji), sem precisar ler o nó privado `Users/{uid}/children`.
  Future<void> _fetchGallery() async {
    try {
      final db = FirebaseDatabase.instance.ref();

      final dreamsSnap = await db
          .child('Dreams')
          .orderByChild('userId')
          .equalTo(widget.uid)
          .get();
      final donationsSnap = await db
          .child('Donations')
          .orderByChild('userId')
          .equalTo(widget.uid)
          .get();


      final dreams = <SearchResult>[];
      final childrenMap = <String, _PublicChild>{};

      if (dreamsSnap.exists && dreamsSnap.value is Map) {
        (dreamsSnap.value as Map).forEach((key, val) {
          if (val is! Map) return;
          final id = key.toString();
          final status = val['status']?.toString();
          // Só mostra na vitrine pública sonhos ainda EM ABERTO — um sonho
          // já realizado não precisa mais de ajuda, então não faz sentido
          // continuar aparecendo como se estivesse esperando doação.
          final isFulfilled = status == 'fulfilled';
          if (!isFulfilled) {
            dreams.add(SearchResult.fromMap(val, id, 'dream'));
          }

          // A lista de filhos é derivada de TODOS os sonhos (mesmo os já
          // realizados) — assim a seção "Filhos" continua mostrando todo
          // mundo, só a galeria de sonhos é que esconde os concluídos.
          final childId = val['childId']?.toString();
          final childName = val['childName']?.toString();
          if (childId != null && childId.isNotEmpty &&
              childName != null && childName.isNotEmpty) {
            childrenMap[childId] = _PublicChild(
              id: childId,
              name: childName,
              avatar: val['childEmoji']?.toString(),
              age: (val['childAge'] as num?)?.toInt(),
            );
          }
        });
      }

      final donations = <SearchResult>[];
      if (donationsSnap.exists && donationsSnap.value is Map) {
        (donationsSnap.value as Map).forEach((key, val) {
          if (val is! Map) return;
          final status = val['status']?.toString();
          // Só mostra doações ainda disponíveis (não doadas/reservadas)
          // na vitrine pública.
          final isAvailable = status == null || status == 'available';
          if (!isAvailable) return;
          donations.add(SearchResult.fromMap(val, key.toString(), 'donation'));
        });
      }

      dreams.sort((a, b) =>
          (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
      donations.sort((a, b) =>
          (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));

      _safeSetState(() {
        _dreams = dreams;
        _availableDonations = donations;
        _children = childrenMap.values.toList();
        _loadingGallery = false;
      });
    } catch (_) {
      _safeSetState(() => _loadingGallery = false);
    }
  }

  String get _location {
    if (_city != null && _state != null) return '$_city, $_state';
    return _city ?? _state ?? '';
  }

  String _generoIcon(String? sexo) {
    switch (sexo) {
      case 'masculino':
        return '♂️';
      case 'outro':
        return '⚧️';
      case 'feminino':
      default:
        return '♀️';
    }
  }

  String _generoLabel(String? sexo) {
    switch (sexo) {
      case 'masculino':
        return 'Masculino';
      case 'outro':
        return 'Outro';
      case 'feminino':
      default:
        return 'Feminino';
    }
  }

  bool get _isMyself => FirebaseAuth.instance.currentUser?.uid == widget.uid;

  /// 🧒 MINI PERFIL DO FILHO
  ///
  /// Bottom sheet simples mostrando só avatar, nome e idade — nada além
  /// disso é exibido (sem dados sensíveis, sem localização exata).
  void _showChildMiniProfile(_PublicChild child) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
        decoration: const BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
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
            const SizedBox(height: 24),
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.kidsPink.withValues(alpha: 0.35),
                  width: 2.5,
                ),
              ),
              child: ClipOval(
                child: AvatarRender(value: child.avatar, size: 96),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              child.name,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: AppTheme.primaryBlue,
              ),
              textAlign: TextAlign.center,
            ),
            if (child.age != null) ...[
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.kidsPink.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${child.age} ${child.age == 1 ? 'ano' : 'anos'}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.kidsPinkDeep,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openChat() async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null || _isMyself) return;

    final chatId = ChatModel.buildId(myUid, widget.uid);
    final sorted = ([myUid, widget.uid]..sort());
    final chat = ChatModel(
      chatId: chatId,
      user1: sorted[0],
      user2: sorted[1],
      otherUid: widget.uid,
      origin: ChatOrigin.direct,
      otherName: _name,
      otherAvatar: _image,
      otherEmoji: _avatar,
    );

    Navigator.push(context, ChatPage.route(myUid: myUid, chat: chat));
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceNeutral,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 340,
            pinned: true,
            backgroundColor: AppTheme.primaryBlue,
            iconTheme: const IconThemeData(color: AppTheme.backgroundColor),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.kidsPink, AppTheme.kidsPurple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.backgroundColor,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: (_image != null && _image!.isNotEmpty)
                                  ? Image.network(
                                      _image!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          AvatarRender(value: _avatar, size: 96),
                                    )
                                  : AvatarRender(value: _avatar, size: 96),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _name ?? 'Usuário',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.backgroundColor,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          // ── Badge de verificação ──
                          if (!_loading)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: _fullyVerified
                                    ? AppTheme.kidsGreen.withValues(alpha: 0.18)
                                    : AppTheme.backgroundColor
                                        .withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _fullyVerified
                                        ? Icons.verified_rounded
                                        : Icons.shield_outlined,
                                    size: 13,
                                    color: _fullyVerified
                                        ? AppTheme.kidsGreen
                                        : AppTheme.backgroundColor,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    _fullyVerified
                                        ? 'Perfil Verificado'
                                        : 'Não verificado',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: _fullyVerified
                                          ? AppTheme.kidsGreen
                                          : AppTheme.backgroundColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          // ── Idade + gênero ──
                          if (_age != null || _sexo != null) ...[
                            const SizedBox(height: 6),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_age != null)
                                  Text(
                                    '🎂 $_age anos',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.backgroundColor
                                          .withValues(alpha: 0.9),
                                    ),
                                  ),
                                if (_age != null && _sexo != null)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 6),
                                    child: Text('·',
                                        style: TextStyle(
                                            color: AppTheme.backgroundColor)),
                                  ),
                                if (_sexo != null)
                                  Text(
                                    '${_generoIcon(_sexo)} ${_generoLabel(_sexo)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.backgroundColor
                                          .withValues(alpha: 0.9),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                          if (_location.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.location_on_rounded,
                                    size: 14, color: AppTheme.backgroundColor),
                                const SizedBox(width: 2),
                                Text(
                                  _location,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.backgroundColor
                                        .withValues(alpha: 0.9),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if ((_facebook?.isNotEmpty ?? false) ||
                              (_instagram?.isNotEmpty ?? false) ||
                              (_x?.isNotEmpty ?? false)) ...[
                            const SizedBox(height: 10),
                            SocialLinksRow(
                              facebook: _facebook,
                              instagram: _instagram,
                              x: _x,
                              light: true,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          SliverToBoxAdapter(
            // ── ModalRoute.of(context).isCurrent ──────────────────────────
            // Diferente de checar o status da AnimationController (que só
            // muda em um frame futuro, depois que a animação já começou),
            // `isCurrent` vira `false` de forma SÍNCRONA no exato instante
            // em que Navigator.pop() é chamado — antes mesmo do primeiro
            // frame da transição ser agendado. `ModalRoute.of(context)` usa
            // um InheritedWidget interno do Flutter que notifica os
            // widgets dependentes automaticamente quando isso muda, então
            // este builder é reconstruído imediatamente.
            //
            // Resultado: assim que você toca em voltar, o grid de sonhos/
            // doações (o conteúdo pesado) sai da árvore de widgets já no
            // próximo frame, então não existe mais nada pesado para
            // "vazar" visualmente durante a animação de saída — seja ela
            // qual for (zoom, fade, slide, com ou sem snapshot).
            child: !(ModalRoute.of(context)?.isCurrent ?? true)
                ? const SizedBox.shrink()
                : _loading
                    ? const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                            child: CircularProgressIndicator(
                                color: AppTheme.kidsPink)),
                      )
                    : _notFound
                        ? _buildNotFound()
                        : _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFound() {
    return const Padding(
      padding: EdgeInsets.all(40),
      child: Center(
        child: Text(
          'Não foi possível encontrar este perfil.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final hasStats = widget.score != null ||
        widget.donationsCount != null ||
        widget.position != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_status != null && _status!.trim().isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.kidsPink.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('💖', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _status!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.kidsPink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          if (hasStats) ...[
            Row(
              children: [
                if (widget.position != null)
                  Expanded(
                    child: _StatCard(
                      emoji: '🏆',
                      value: '${widget.position}°',
                      label: 'Posição',
                    ),
                  ),
                if (widget.position != null) const SizedBox(width: 10),
                if (widget.score != null)
                  Expanded(
                    child: _StatCard(
                      emoji: '⭐',
                      value: '${widget.score}',
                      label: 'Pontos',
                    ),
                  ),
                if (widget.score != null) const SizedBox(width: 10),
                if (widget.donationsCount != null)
                  Expanded(
                    child: _StatCard(
                      emoji: '🎁',
                      value: '${widget.donationsCount}',
                      label: 'Vidas\ntocadas',
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
          ],

          // ── Filhos (derivados dos sonhos públicos) ──────────────────
          if (_children.isNotEmpty) ...[
            const _SectionTitle(emoji: '👨‍👩‍👧‍👦', title: 'Filhos'),
            const SizedBox(height: 10),
            SizedBox(
              height: 86,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _children.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) {
                  final child = _children[i];
                  return GestureDetector(
                    onTap: () => _showChildMiniProfile(child),
                    child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppTheme.kidsPink.withValues(alpha: 0.3),
                              width: 1.5),
                        ),
                        child: ClipOval(
                          child: AvatarRender(value: child.avatar, size: 54),
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: 64,
                        child: Text(
                          child.name,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textCharcoal,
                          ),
                        ),
                      ),
                    ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],

          // ── Galeria: sonhos dos filhos / doações disponíveis ────────
          if (_loadingGallery)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                  child: CircularProgressIndicator(color: AppTheme.kidsPink)),
            )
          else if (_dreams.isNotEmpty || _availableDonations.isNotEmpty) ...[
            Row(
              children: [
                Expanded(
                  child: _GalleryToggleChip(
                    emoji: '✨',
                    label: 'Sonhos (${_dreams.length})',
                    selected: _galleryTab == 0,
                    onTap: () => setState(() => _galleryTab = 0),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _GalleryToggleChip(
                    emoji: '🎁',
                    label: 'Doações (${_availableDonations.length})',
                    selected: _galleryTab == 1,
                    onTap: () => setState(() => _galleryTab = 1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildGalleryGrid(
                _galleryTab == 0 ? _dreams : _availableDonations),
          ] else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Ainda não há sonhos ou doações públicas por aqui.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGalleryGrid(List<SearchResult> items) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          _galleryTab == 0
              ? 'Nenhum sonho publicado ainda.'
              : 'Nenhuma doação disponível no momento.',
          style: TextStyle(
            fontSize: 12.5,
            color: AppTheme.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    // ── RepaintBoundary isolado com Key própria ─────────────────────────
    // O glitch reportado (grid da galeria "vazando" sobre a Home por 1-2
    // frames durante o pop) é consistente com reuso indevido, pelo engine,
    // de uma camada de composição (picture layer) já rasterizada desse
    // GridView. Sem um RepaintBoundary dedicado aqui, essa subárvore
    // (GridView + Image.network + ClipRRect dos cards) tende a ser
    // "achatada" dentro da camada de composição do ancestral mais próximo
    // — e é essa camada ancestral, maior e de vida mais longa, que o
    // engine reaproveita incorretamente por engano.
    //
    // Dar a esse RepaintBoundary uma Key própria (amarrada ao uid e à aba
    // selecionada) força o Flutter a tratá-lo como um elemento distinto:
    // isso garante (1) uma camada de composição própria — que é destruída
    // junto com a rota ao invés de ficar "pendurada" dentro do layer do
    // pai — e (2) que trocar de aba (sonhos ↔ doações) também descarta o
    // layer antigo em vez de tentar reaproveitá-lo.
    return RepaintBoundary(
      key: ValueKey('gallery_grid_${widget.uid}_$_galleryTab'),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.78,
        ),
        itemBuilder: (_, i) => SearchResultCard(
          key: ValueKey('gallery_item_${items[i].id}'),
          result: items[i],
          currentUserId: FirebaseAuth.instance.currentUser?.uid,
        ),
      ),
    );
  }
}

// ── Título de seção ───────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String emoji;
  final String title;
  const _SectionTitle({required this.emoji, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: AppTheme.primaryBlue,
          ),
        ),
      ],
    );
  }
}

// ── Toggle da galeria (Sonhos / Doações) ────────────────────────────────────

class _GalleryToggleChip extends StatelessWidget {
  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _GalleryToggleChip({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [AppTheme.kidsPink, AppTheme.kidsPurple])
              : null,
          color: selected ? null : AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: selected
                    ? AppTheme.backgroundColor
                    : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Card de estatística ──────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;

  const _StatCard({
    required this.emoji,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMuted,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}