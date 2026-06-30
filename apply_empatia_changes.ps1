<#
.SYNOPSIS
    Aplica todas as alteracoes combinadas no chat ao repositorio empatia,
    sobrescrevendo os arquivos finais diretamente (nao depende de "git apply",
    entao funciona mesmo se voce ja tiver alterado alguns desses arquivos
    manualmente antes):
      - Force refresh (pull-to-refresh) nas 3 abas da DreamPage
      - Correcao da sincronizacao de filho -> sonhos (no privado Users/{uid}/dreams)
      - Reducao de 25% nos icones de redes sociais (SocialLinksRow)
      - Migracao completa Cloudinary -> Firebase Storage

.PARAMETER RepoPath
    Caminho local do repositorio "empatia" ja clonado.

.EXAMPLE
    .\apply_empatia_changes.ps1 -RepoPath "D:\XProjects\empatia"
#>

[CmdletBinding()]
param(
    [string]$RepoPath = (Get-Location).Path
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host ""
    Write-Host ("==> " + $Message) -ForegroundColor Cyan
}

function Write-Ok {
    param([string]$Message)
    Write-Host ("OK: " + $Message) -ForegroundColor Green
}

function Write-Fail {
    param([string]$Message)
    Write-Host ("ERRO: " + $Message) -ForegroundColor Red
}

# Escreve um arquivo em UTF-8 SEM BOM, criando pastas intermediarias se preciso.
function Write-FileUtf8NoBom {
    param(
        [string]$Path,
        [string]$Content
    )
    $dir = Split-Path -Parent $Path
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    # Normaliza quebras de linha para LF (padrao do repo original)
    $normalized = $Content -replace "`r`n", "`n"
    [System.IO.File]::WriteAllText($Path, $normalized, $utf8NoBom)
}

Write-Step "Verificando pre-requisitos"

$gitCmd = Get-Command git -ErrorAction SilentlyContinue
if (-not $gitCmd) {
    Write-Fail "Git nao encontrado no PATH. Instale o Git for Windows (https://git-scm.com/download/win) e tente novamente."
    exit 1
}
Write-Ok ("Git encontrado: " + $gitCmd.Source)

if (-not (Test-Path $RepoPath)) {
    Write-Fail ("Caminho do repositorio nao encontrado: " + $RepoPath)
    exit 1
}

Push-Location $RepoPath
try {
    if (-not (Test-Path (Join-Path $RepoPath "pubspec.yaml"))) {
        Write-Fail ("Nao encontrei 'pubspec.yaml' em '" + $RepoPath + "'. Confirme se este e o caminho correto do projeto Flutter 'empatia'.")
        exit 1
    }
    Write-Ok ("Repositorio valido: " + $RepoPath)

    $statusOutput = git status --porcelain 2>$null
    if ($statusOutput) {
        Write-Host ""
        Write-Host "AVISO: existem alteracoes no repositorio. Este script vai SOBRESCREVER os arquivos abaixo com a versao final combinada no chat:" -ForegroundColor Yellow
        Write-Host "  (recomendado: faca um commit ou backup antes de continuar, caso queira poder comparar/desfazer depois)" -ForegroundColor Yellow
        $answer = Read-Host "Deseja continuar? (s/N)"
        if ($answer -notin @("s", "S", "sim", "Sim", "y", "Y", "yes")) {
            Write-Host "Cancelado pelo usuario."
            exit 0
        }
    }

    Write-Step "Removendo arquivos antigos do Cloudinary"
    $p = Join-Path $RepoPath "lib/features/profile/data/repository/cloudinary_repository.dart"
    if (Test-Path $p) {
        Remove-Item $p -Force
        Write-Ok "Removido: lib/features/profile/data/repository/cloudinary_repository.dart"
    }
    $p = Join-Path $RepoPath "lib/features/profile/data/service/cloudinary_service.dart"
    if (Test-Path $p) {
        Remove-Item $p -Force
        Write-Ok "Removido: lib/features/profile/data/service/cloudinary_service.dart"
    }

    Write-Step "Escrevendo arquivos atualizados"
    $content_4 = @'
import 'package:empatia/core/auth_guard/auth_guard.dart';
import 'package:empatia/core/data/models/user_model.dart';
import 'package:empatia/core/data/repositories/user_repository.dart';
import 'package:empatia/features/auth/presentation/pages/login_page.dart';
import 'package:empatia/features/donation/controller/donation_controller.dart';
import 'package:empatia/features/donation/data/repository/donation_repository.dart';
import 'package:empatia/features/donation/data/service/donation_service.dart';
import 'package:empatia/features/dream/controller/dream_controller.dart';
import 'package:empatia/features/dream/data/repository/dream_repository.dart';
import 'package:empatia/features/dream/data/repository/dreams_feed_repository.dart';
import 'package:empatia/features/dream/data/service/dream_service.dart';
import 'package:empatia/features/profile/controller/profile_controller.dart';
import 'package:empatia/features/profile/data/repository/storage_repository.dart';
import 'package:empatia/features/profile/data/repository/location_repository.dart';
import 'package:empatia/features/profile/data/repository/profile_repository.dart';
import 'package:empatia/features/profile/data/service/storage_service.dart';
import 'package:empatia/features/profile/data/service/location_service.dart';
import 'package:empatia/features/profile/data/service/profile_service.dart';
import 'package:empatia/features/request/controller/request_controller.dart';
import 'package:empatia/features/request/data/repository/request_repository.dart';
import 'package:empatia/features/request/data/service/request_service.dart';
import 'package:empatia/features/search/controller/search_controller.dart';
import 'package:empatia/features/search/controller/search_filter_controller.dart';
import 'package:empatia/features/search/data/repositories/search_location_repository.dart';
import 'package:empatia/features/search/data/repositories/search_repository.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart' hide SearchController;
import 'package:provider/provider.dart';

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ── 1. Repositórios ──────────────────────────────────
        Provider<ProfileRepository>(create: (_) => ProfileRepository()),
        Provider<LocationRepository>(create: (_) => LocationRepository()),
        Provider<StorageRepository>(create: (_) => StorageRepository()),
        Provider<DonationRepository>(create: (_) => DonationRepository()),
        Provider<RequestRepository>(create: (_) => RequestRepository()),
        Provider<DreamRepository>(create: (_) => DreamRepository()),
        Provider<DreamsFeedRepository>(create: (_) => DreamsFeedRepository()),
        Provider<UserRepository>(create: (_) => UserRepository()),
        Provider<SearchRepository>(create: (_) => SearchRepository()),
        Provider<SearchLocationRepository>(
            create: (_) => SearchLocationRepository()),

        // ── 2. Services ──────────────────────────────────────
        ProxyProvider<StorageRepository, StorageService>(
          update: (_, repo, __) => StorageService(repo),
        ),
        ProxyProvider2<ProfileRepository, StorageService, ProfileService>(
          update: (_, profileRepo, storage, __) =>
              ProfileService(profileRepo, storage),
        ),
        ProxyProvider<LocationRepository, LocationService>(
          update: (_, repo, __) => LocationService(repo),
        ),
        ProxyProvider2<DonationRepository, StorageService, DonationService>(
          update: (_, repo, storage, __) =>
              DonationService(repo, storage),
        ),
        ProxyProvider<RequestRepository, RequestService>(
          update: (_, repo, __) => RequestService(repo),
        ),
        ProxyProvider3<DreamRepository, StorageService, DreamsFeedRepository, DreamService>(
          update: (_, repo, storage, feedRepo, __) =>
              DreamService(repo, storage, feedRepo),
        ),

        // ── 3. Stream do UserModel ───────────────────────────
        StreamProvider<UserModel?>(
          create: (context) => context.read<UserRepository>().watchCurrentUser(),
          initialData: null,
          catchError: (_, __) => null,
        ),

        // ── 4. Controllers ───────────────────────────────────
        ChangeNotifierProxyProvider2<ProfileService, LocationService,
            ProfileController>(
          create: (_) => ProfileController(
            ProfileService(
              ProfileRepository(),
              StorageService(StorageRepository()),
            ),
            LocationService(LocationRepository()),
          ),
          update: (_, profileService, locationService, __) =>
              ProfileController(profileService, locationService),
        ),
        ChangeNotifierProxyProvider2<DonationRepository, StorageService,
            DonationController>(
          create: (_) => DonationController(
            DonationService(
              DonationRepository(),
              StorageService(StorageRepository()),
            ),
          ),
          update: (_, repo, storage, __) =>
              DonationController(DonationService(repo, storage)),
        ),
        ChangeNotifierProxyProvider<RequestService, RequestController>(
          create: (_) =>
              RequestController(RequestService(RequestRepository())),
          update: (_, service, __) => RequestController(service),
        ),
        ChangeNotifierProxyProvider3<DreamRepository, StorageService,
            DreamsFeedRepository, DreamController>(
          create: (_) => DreamController(
            DreamService(
              DreamRepository(),
              StorageService(StorageRepository()),
              DreamsFeedRepository(),
            ),
          ),
          update: (_, repo, storage, feedRepo, __) =>
              DreamController(DreamService(repo, storage, feedRepo)),
        ),
        ChangeNotifierProxyProvider<SearchRepository, SearchController>(
          create: (_) => SearchController(SearchRepository()),
          update: (_, repo, __) => SearchController(repo),
        ),
        ChangeNotifierProxyProvider<SearchLocationRepository,
            SearchFilterController>(
          create: (_) => SearchFilterController(SearchLocationRepository()),
          update: (_, repo, __) => SearchFilterController(repo),
        ),
      ],
      child: MaterialApp(
        title: 'Empatia',
        theme: ThemeData(fontFamily: 'Poppins'),
        home: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: Color(0xFF2563EB),
                body: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
              );
            }

            if (snapshot.data != null) {
              return const AuthGuard();
            }

            return const LoginPage();
          },
        ),
      ),
    );
  }
}
'@
    Write-FileUtf8NoBom -Path (Join-Path $RepoPath "lib\app.dart") -Content $content_4
    Write-Ok "Escrito: lib/app.dart"

    $content_5 = @'
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// 🌐 SOCIAL LINKS ROW
///
/// Fileira de ícones de redes sociais (Facebook, Instagram, X) — usada
/// tanto no próprio perfil (ProfileHeaderWidget) quanto no perfil
/// público de outros usuários (PublicProfilePage).
///
/// Cada ícone só aparece se o link correspondente estiver preenchido.
/// Ao tocar, abre o link no navegador/app correspondente via
/// [url_launcher] — se o app nativo (Facebook/Instagram/X) estiver
/// instalado, o sistema operacional abre ele direto.
class SocialLinksRow extends StatelessWidget {
  final String? facebook;
  final String? instagram;
  final String? x;

  /// Cor de fundo dos círculos quando usados sobre fundo claro.
  /// Sobre o header gradiente (rosa/roxo), passe `light: true`.
  final bool light;

  const SocialLinksRow({
    Key? key,
    this.facebook,
    this.instagram,
    this.x,
    this.light = false,
  }) : super(key: key);

  /// Facebook está temporariamente fora da exibição (o domínio não é
  /// padronizável como instagram.com/x.com — ver SocialConfirmCard).
  /// Mantemos o campo no modelo/banco para reativar facilmente depois.
  bool get hasAny =>
      (instagram?.trim().isNotEmpty ?? false) ||
      (x?.trim().isNotEmpty ?? false);

  Future<void> _open(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível abrir o link.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!hasAny) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Facebook temporariamente desativado — ver comentário em hasAny.
        if (instagram?.trim().isNotEmpty ?? false)
          _SocialIcon(
            icon: Icons.camera_alt_rounded,
            gradient: const LinearGradient(
              colors: [Color(0xFFFEDA77), Color(0xFFE1306C), Color(0xFF833AB4)],
            ),
            light: light,
            onTap: () => _open(context, instagram!.trim()),
          ),
        if (x?.trim().isNotEmpty ?? false) ...[
          if (instagram?.trim().isNotEmpty ?? false)
            const SizedBox(width: 12),
          _SocialIcon(
            label: '𝕏',
            color: Colors.black,
            light: light,
            onTap: () => _open(context, x!.trim()),
          ),
        ],
      ],
    );
  }
}

/// 🔎 SOCIAL CONFIRM CARD
///
/// Card que aparece embaixo de um campo de rede social assim que o
/// usuário digita algo — mostra um preview do link e um botão "Abrir e
/// conferir" para a pessoa visualmente confirmar que é o perfil dela
/// mesma antes de salvar (não há como validar isso automaticamente).
class SocialConfirmCard extends StatelessWidget {
  final String platform; // 'Instagram' | 'X'
  final String rawValue; // só o @usuario, sem domínio

  const SocialConfirmCard({
    Key? key,
    required this.platform,
    required this.rawValue,
  }) : super(key: key);

  static const Map<String, String> _domains = {
    'Instagram': 'instagram.com',
    'X': 'x.com',
  };

  /// Limpa o que a pessoa digitou: remove @ na frente, espaços, e se
  /// colar sem querer um link completo, extrai só o último pedaço (o
  /// nome de usuário em si).
  String get _cleanUsername {
    var v = rawValue.trim();
    if (v.contains('/')) {
      final parts = v.split('/').where((p) => p.trim().isNotEmpty).toList();
      if (parts.isNotEmpty) v = parts.last;
    }
    v = v.replaceAll('@', '').trim();
    return v;
  }

  String get _normalizedUrl {
    final domain = _domains[platform] ?? '';
    return 'https://$domain/$_cleanUsername';
  }

  ({IconData? icon, String? label, Color? color, Gradient? gradient}) get _style {
    switch (platform) {
      case 'Facebook':
        return (icon: Icons.facebook, label: null, color: const Color(0xFF1877F2), gradient: null);
      case 'Instagram':
        return (
          icon: Icons.camera_alt_rounded,
          label: null,
          color: null,
          gradient: const LinearGradient(
            colors: [Color(0xFFFEDA77), Color(0xFFE1306C), Color(0xFF833AB4)],
          ),
        );
      case 'X':
      default:
        return (icon: null, label: '𝕏', color: Colors.black, gradient: null);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (rawValue.trim().isEmpty) return const SizedBox.shrink();

    final s = _style;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE3ECFF), width: 1.2),
      ),
      child: Row(
        children: [
          _SocialIcon(
            icon: s.icon,
            label: s.label,
            color: s.color,
            gradient: s.gradient,
            light: false,
            onTap: () {},
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Confira se é o link certo',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _normalizedUrl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () async {
              final uri = Uri.tryParse(_normalizedUrl);
              if (uri == null) return;
              final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
              if (!ok && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Não foi possível abrir o link.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A8A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.open_in_new_rounded, size: 13, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'Abrir',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialIcon extends StatelessWidget {
  final IconData? icon;
  final String? label;
  final Color? color;
  final Gradient? gradient;
  final bool light;
  final VoidCallback onTap;

  const _SocialIcon({
    this.icon,
    this.label,
    this.color,
    this.gradient,
    required this.light,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Responsivo (baseado na largura da tela, funciona em qualquer
    // dispositivo). Reduzido em 25% em relação à versão anterior
    // (que ia de ~64px a 102px) — agora vai de ~48px a 76.5px.
    final screenWidth = MediaQuery.of(context).size.width;
    // Reduzido 25% (era: 0.19 / clamp 64–102) a pedido do usuário.
    final circleSize = (screenWidth * 0.1425).clamp(48.0, 76.5);
    final iconSize = circleSize * 0.5;
    final labelSize = circleSize * 0.46;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: circleSize,
        height: circleSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: gradient == null ? color : null,
          gradient: gradient,
          border: light
              ? Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: icon != null
              ? Icon(icon, size: iconSize, color: Colors.white)
              : Text(
                  label ?? '',
                  style: TextStyle(
                    fontSize: labelSize,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}
'@
    Write-FileUtf8NoBom -Path (Join-Path $RepoPath "lib\core\widget\social_links_row.dart") -Content $content_5
    Write-Ok "Escrito: lib/core/widget/social_links_row.dart"

    $content_6 = @'
/// 🎁 DONATION MODEL
///
/// Representa um item que o usuário está OFERECENDO para doação.
/// Fica na coleção raiz /Donations/{id} no Firebase.
///
/// Firebase structure:
/// /Donations/{pushId}
///   userId, title, description, photoUrl, emoji, category, status,
///   city, state, latitude, longitude, ownerName, ownerPhotoUrl,
///   createdAt, updatedAt
class DonationModel {
  final String? id;
  final String? userId;

  /// Título curto — ex: "Roupas 4–6 anos"
  final String? title;

  /// Descrição detalhada do item (obrigatória)
  final String? description;

  /// URL da foto do item no Firebase Storage (obrigatória)
  final String? photoUrl;

  /// Emoji representativo do item
  final String? emoji;

  /// Categoria do item
  /// Valores: 'clothes' | 'toys' | 'books' | 'food' | 'furniture' | 'other'
  final String? category;

  /// Status atual da oferta
  /// Valores: 'available' | 'reserved' | 'donated'
  final String status;

  final String? city;
  final String? state;
  final double? latitude;
  final double? longitude;

  /// Nome do doador no momento da criação — snapshot, não atualiza
  /// retroativamente se o usuário mudar o nome depois.
  final String? ownerName;

  /// Foto de perfil do doador no momento da criação — mesmo raciocínio
  /// do [ownerName].
  final String? ownerPhotoUrl;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DonationModel({
    this.id,
    this.userId,
    this.title,
    this.description,
    this.photoUrl,
    this.emoji,
    this.category,
    this.status = 'available',
    this.city,
    this.state,
    this.latitude,
    this.longitude,
    this.ownerName,
    this.ownerPhotoUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory DonationModel.fromMap(Map<dynamic, dynamic> map, String id) {
    return DonationModel(
      id: id,
      userId: map['userId']?.toString(),
      title: map['title']?.toString(),
      description: map['description']?.toString(),
      photoUrl: map['photoUrl']?.toString(),
      emoji: map['emoji']?.toString(),
      category: map['category']?.toString(),
      status: map['status']?.toString() ?? 'available',
      city: map['city']?.toString(),
      state: map['state']?.toString(),
      latitude: map['latitude'] != null
          ? double.tryParse(map['latitude'].toString())
          : null,
      longitude: map['longitude'] != null
          ? double.tryParse(map['longitude'].toString())
          : null,
      ownerName: map['ownerName']?.toString(),
      ownerPhotoUrl: map['ownerPhotoUrl']?.toString(),
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              int.parse(map['createdAt'].toString()))
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              int.parse(map['updatedAt'].toString()))
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (userId != null) 'userId': userId,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (emoji != null) 'emoji': emoji,
      if (category != null) 'category': category,
      'status': status,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (ownerName != null) 'ownerName': ownerName,
      if (ownerPhotoUrl != null) 'ownerPhotoUrl': ownerPhotoUrl,
      'createdAt': createdAt?.millisecondsSinceEpoch ??
          DateTime.now().millisecondsSinceEpoch,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };
  }

  DonationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? photoUrl,
    String? emoji,
    String? category,
    String? status,
    String? city,
    String? state,
    double? latitude,
    double? longitude,
    String? ownerName,
    String? ownerPhotoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DonationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      photoUrl: photoUrl ?? this.photoUrl,
      emoji: emoji ?? this.emoji,
      category: category ?? this.category,
      status: status ?? this.status,
      city: city ?? this.city,
      state: state ?? this.state,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      ownerName: ownerName ?? this.ownerName,
      ownerPhotoUrl: ownerPhotoUrl ?? this.ownerPhotoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static String categoryLabel(String? category) {
    switch (category) {
      case 'clothes':   return 'Roupas';
      case 'toys':      return 'Brinquedos';
      case 'books':     return 'Livros';
      case 'food':      return 'Alimentos';
      case 'furniture': return 'Móveis / Utensílios';
      default:          return 'Outros';
    }
  }

  static String categoryEmoji(String? category) {
    switch (category) {
      case 'clothes':   return '👕';
      case 'toys':      return '🧸';
      case 'books':     return '📚';
      case 'food':      return '🥫';
      case 'furniture': return '🪑';
      default:          return '📦';
    }
  }

  static String statusLabel(String status) {
    switch (status) {
      case 'reserved': return 'Reservado';
      case 'donated':  return 'Doado';
      default:         return 'Disponível';
    }
  }
}
'@
    Write-FileUtf8NoBom -Path (Join-Path $RepoPath "lib\features\donation\data\model\donation_model.dart") -Content $content_6
    Write-Ok "Escrito: lib/features/donation/data/model/donation_model.dart"

    $content_7 = @'
import 'package:empatia/core/data/models/user_model.dart';
import 'package:empatia/features/donation/data/repository/donation_repository.dart';
import 'package:empatia/features/donation/data/model/donation_model.dart';
import 'package:empatia/features/profile/data/service/storage_service.dart';
import 'package:empatia/features/profile/data/service/profile_service.dart';
import 'package:image_picker/image_picker.dart'; // XFile

/// 🎁 DONATION SERVICE
///
/// Valida dados, faz upload da foto e salva no Firebase.
/// Usa [XFile] em vez de [File] para funcionar no web e no mobile.
class DonationService {
  final DonationRepository _repository;
  final StorageService _storageService;

  DonationService(this._repository, this._storageService);

  Stream<List<DonationModel>> watchMyDonations() =>
      _repository.watchMyDonations();

  Stream<List<DonationModel>> watchDonationsByCity(String city) =>
      _repository.watchDonationsByCity(city);

  Future<String> createDonation({
    required String? title,
    required String? category,
    required String? description,
    required XFile photo,
    required UserModel currentUser,
    String? emoji,
  }) async {
    // ── Guarda: apenas usuários verificados podem criar ofertas ────────────
    if (!ProfileService.isFullyVerified(currentUser)) {
      throw Exception(
        '❌ Verifique seu e-mail e complete seu perfil antes de criar uma oferta.',
      );
    }
    // ────────────────────────────────────────────────────────────────────────

    final trimmedTitle = title?.trim() ?? '';
    if (trimmedTitle.isEmpty) {
      throw Exception('❌ O nome do item não pode ficar em branco.');
    }
    if (trimmedTitle.length < 3) {
      throw Exception('❌ O nome precisa ter pelo menos 3 caracteres.');
    }

    final trimmedDesc = description?.trim() ?? '';
    if (trimmedDesc.isEmpty) {
      throw Exception('❌ A descrição não pode ficar em branco.');
    }
    if (trimmedDesc.length < 10) {
      throw Exception('❌ A descrição precisa ter pelo menos 10 caracteres.');
    }

    final validCategories = [
      'clothes', 'toys', 'books', 'food', 'furniture', 'other',
    ];
    if (category == null || !validCategories.contains(category)) {
      throw Exception('❌ Selecione uma categoria.');
    }

    if (!ProfileService.isFullyVerified(currentUser)) {
      throw Exception(
        '❌ Verifique seu e-mail e complete seu perfil antes de criar uma oferta.',
      );
    }
    if (currentUser.city == null || currentUser.state == null) {
      throw Exception(
          '❌ Complete sua localização no perfil antes de criar uma oferta.');
    }

    final photoUrl = await _storageService.uploadProfileImage(photo);

    final donation = DonationModel(
      title: trimmedTitle,
      description: trimmedDesc,
      photoUrl: photoUrl,
      emoji: emoji ?? DonationModel.categoryEmoji(category),
      category: category,
      status: 'available',
      city: currentUser.city,
      state: currentUser.state,
      latitude: currentUser.latitude,
      longitude: currentUser.longitude,
      ownerName: currentUser.name,
      ownerPhotoUrl: currentUser.profileImage,
      createdAt: DateTime.now(),
    );

    return await _repository.createDonation(donation);
  }

  Future<void> updateDonation({
    required String donationId,
    required String? title,
    required String? category,
    required String? description,
    required String? currentPhotoUrl,
    XFile? newPhoto,
    String? emoji,
  }) async {
    final trimmedTitle = title?.trim() ?? '';
    if (trimmedTitle.isEmpty) {
      throw Exception('❌ O nome do item não pode ficar em branco.');
    }

    final trimmedDesc = description?.trim() ?? '';
    if (trimmedDesc.isEmpty) {
      throw Exception('❌ A descrição não pode ficar em branco.');
    }

    String? photoUrl = currentPhotoUrl;
    if (newPhoto != null) {
      photoUrl = await _storageService.uploadProfileImage(
        newPhoto,
        oldImageUrl: currentPhotoUrl,
      );
    }

    final donation = DonationModel(
      id: donationId,
      title: trimmedTitle,
      description: trimmedDesc,
      photoUrl: photoUrl,
      emoji: emoji ?? DonationModel.categoryEmoji(category),
      category: category,
    );

    await _repository.updateDonation(donation);
  }

  Future<void> updateStatus(String donationId, String newStatus) async {
    final valid = ['available', 'reserved', 'donated'];
    if (!valid.contains(newStatus)) {
      throw Exception('❌ Status inválido: $newStatus');
    }
    await _repository.updateStatus(donationId, newStatus);
  }

  Future<void> deleteDonation(String donationId, {String? photoUrl}) async {
    if (photoUrl != null && photoUrl.isNotEmpty) {
      await _storageService.deleteProfileImage(photoUrl);
    }
    await _repository.deleteDonation(donationId);
  }
}
'@
    Write-FileUtf8NoBom -Path (Join-Path $RepoPath "lib\features\donation\data\service\donation_service.dart") -Content $content_7
    Write-Ok "Escrito: lib/features/donation/data/service/donation_service.dart"

    $content_8 = @'
import 'package:empatia/core/data/models/dream_model.dart';
import 'package:empatia/core/data/models/user_model.dart';
import 'package:empatia/features/profile/data/service/storage_service.dart';
import 'package:empatia/features/profile/data/service/profile_service.dart';
import 'package:image_picker/image_picker.dart';
import '../repository/dream_repository.dart';
import '../repository/dreams_feed_repository.dart';

/// 💭 DREAM SERVICE
///
/// Orquestra criação e edição de sonhos.
/// Ao receber uma [category], deriva automaticamente o [emoji] correspondente
/// — o usuário nunca seleciona emoji diretamente.
///
/// Grava em dois nós simultaneamente:
///   • Users/{uid}/dreams/{id}  — perfil do usuário
///   • Dreams/{id}              — feed global (denormalizado)
class DreamService {
  final DreamRepository _repository;
  final StorageService _storageService;
  final DreamsFeedRepository _feedRepository;

  DreamService(this._repository, this._storageService, this._feedRepository);

  Stream<List<DreamModel>> watchDreams() => _repository.watchDreams();

  // ── Mapeamento categoria → emoji ───────────────────────────────────────────
  //
  // Mantido centralizado aqui para que qualquer parte do app que precise
  // do emoji a partir da categoria use um único ponto de verdade.
  // Deve estar em sincronia com _kDreamCategories em dream_form_sheet.dart
  // e com _categoryMatchesEmoji em search_repository.dart.

  static String emojiForCategory(String? category) {
    switch (category) {
      case 'clothes':   return '👕';
      case 'toys':      return '🧸';
      case 'books':     return '📚';
      case 'food':      return '🍎';
      case 'furniture': return '🛋️';
      default:          return '📦'; // 'others' e valores desconhecidos
    }
  }

  // ── Adicionar ──────────────────────────────────────────────────────────────

  Future<String> addDream({
    required String? title,
    required String category,   // ← substituiu emoji
    required UserModel currentUser,
    required String childId,
    required String childName,
    required String childEmoji,
    int? childAge,
    String? date,
    double? progress,
    XFile? photo,
  }) async {
    if (!ProfileService.isFullyVerified(currentUser)) {
      throw Exception(
        '❌ Verifique seu e-mail e complete seu perfil antes de criar um sonho.',
      );
    }

    final trimmed = title?.trim() ?? '';
    if (trimmed.isEmpty) {
      throw Exception('❌ O título do sonho não pode ficar em branco.');
    }
    if (trimmed.length < 3) {
      throw Exception('❌ O título precisa ter pelo menos 3 caracteres.');
    }
    if (progress != null && (progress < 0 || progress > 1)) {
      throw Exception('❌ Progresso deve ser entre 0 e 100%.');
    }

    String? imageUrl;
    if (photo != null) {
      imageUrl = await _storageService.uploadProfileImage(photo);
    }

    // Deriva o emoji da categoria — o usuário não escolhe mais o emoji
    final emoji = emojiForCategory(category);

    final dream = DreamModel(
      title:      trimmed,
      emoji:      emoji,
      category:   category,
      date:       date?.trim().isEmpty == true ? null : date?.trim(),
      progress:   progress,
      imageUrl:   imageUrl,
      childId:    childId,
      childName:  childName,
      childEmoji: childEmoji,
      childAge:   childAge,
      createdAt:  DateTime.now(),
    );

    final dreamId = await _repository.addDream(dream);

    await _feedRepository.createDreamWithId(
      dreamId:          dreamId,
      userId:           currentUser.id ?? '',
      userName:         currentUser.name ?? '',
      userProfileImage: currentUser.profileImage,
      userProfileEmoji: currentUser.profileEmoji,
      title:            trimmed,
      date:             date?.trim().isEmpty == true ? null : date?.trim(),
      emoji:            emoji,
      category:         category,
      imageUrl:         imageUrl,
      progress:         progress ?? 0.0,
      childId:          childId,
      childName:        childName,
      childEmoji:       childEmoji,
      childAge:         childAge,
      city:             currentUser.city,
      state:            currentUser.state,
      latitude:         currentUser.latitude,
      longitude:        currentUser.longitude,
    );

    return dreamId;
  }

  // ── Editar ─────────────────────────────────────────────────────────────────

  Future<void> updateDream({
    required String dreamId,
    required String? title,
    required String category,   // ← substituiu emoji
    required String childId,
    required String childName,
    required String childEmoji,
    required UserModel currentUser,
    int? childAge,
    String? date,
    double? progress,
    String? currentImageUrl,
    XFile? newPhoto,
    bool removeImage = false,
  }) async {
    final trimmed = title?.trim() ?? '';
    if (trimmed.isEmpty) {
      throw Exception('❌ O título do sonho não pode ficar em branco.');
    }
    if (progress != null && (progress < 0 || progress > 1)) {
      throw Exception('❌ Progresso deve ser entre 0 e 100%.');
    }

    String? imageUrl = currentImageUrl;

    if (removeImage) {
      if (currentImageUrl != null && currentImageUrl.isNotEmpty) {
        await _storageService.deleteProfileImage(currentImageUrl);
      }
      imageUrl = null;
    } else if (newPhoto != null) {
      imageUrl = await _storageService.uploadProfileImage(
        newPhoto,
        oldImageUrl: currentImageUrl,
      );
    }

    final cleanDate = date?.trim().isEmpty == true ? null : date?.trim();
    final emoji     = emojiForCategory(category);

    final dream = DreamModel(
      id:         dreamId,
      title:      trimmed,
      emoji:      emoji,
      category:   category,
      date:       cleanDate,
      progress:   progress,
      imageUrl:   imageUrl,
      childId:    childId,
      childName:  childName,
      childEmoji: childEmoji,
      childAge:   childAge,
    );

    await Future.wait([
      _repository.updateDream(dream),
      _feedRepository.updateDream(
        dreamId:    dreamId,
        title:      trimmed,
        emoji:      emoji,
        category:   category,
        date:       cleanDate,
        imageUrl:   imageUrl,
        progress:   progress,
        childId:    childId,
        childName:  childName,
        childEmoji: childEmoji,
        childAge:   childAge,
        city:       currentUser.city,
        state:      currentUser.state,
        latitude:   currentUser.latitude,
        longitude:  currentUser.longitude,
      ),
    ]);
  }

  Future<void> updateProgress(String dreamId, double progress) async {
    if (progress < 0 || progress > 1) {
      throw Exception('❌ Progresso deve ser entre 0 e 100%.');
    }
    await _repository.updateProgress(dreamId, progress);
  }

  Future<void> deleteDream(String dreamId, {String? imageUrl}) async {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      await _storageService.deleteProfileImage(imageUrl);
    }
    await Future.wait([
      _repository.deleteDream(dreamId),
      _feedRepository.deleteDream(dreamId),
    ]);
  }
}
'@
    Write-FileUtf8NoBom -Path (Join-Path $RepoPath "lib\features\dream\data\service\dream_service.dart") -Content $content_8
    Write-Ok "Escrito: lib/features/dream/data/service/dream_service.dart"

    $content_9 = @'
// lib/features/dream/presentation/pages/dream_page.dart

import 'dart:async';

import 'package:empatia/core/data/models/dream_model.dart';
import 'package:empatia/core/data/models/user_model.dart';
import 'package:empatia/core/theme/app_decorations.dart';
import 'package:empatia/core/theme/app_theme.dart';
import 'package:empatia/core/widget/verification_block_dialog.dart';
import 'package:empatia/features/donation/controller/donation_controller.dart';
import 'package:empatia/features/donation/data/model/donation_model.dart';
import 'package:empatia/features/donation/presentation/widgets/donation_item_form_sheet.dart';
import 'package:empatia/features/dream/controller/dream_controller.dart';
import 'package:empatia/features/dream/presentation/widgets/donation_card_widget.dart';
import 'package:empatia/features/dream/presentation/widgets/dream_card_widget.dart';
import 'package:empatia/features/dream/presentation/widgets/dream_form_sheet.dart';
import 'package:empatia/features/profile/data/service/profile_service.dart';
import 'package:empatia/features/request/controller/request_controller.dart';
import 'package:empatia/features/request/data/model/request_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ══════════════════════════════════════════════════════════════════════════════
// MODEL
// ══════════════════════════════════════════════════════════════════════════════

class DonationHistoryEntry {
  final String id;
  final String type; // 'donated' | 'received'
  final String? itemId;
  final String? itemType; // 'dream' | 'donation'
  final String? itemTitle;
  final String? itemPhotoUrl;
  final String? itemCategory;
  final String? otherUid;
  final String? chatId;
  final int timestamp;

  const DonationHistoryEntry({
    required this.id,
    required this.type,
    this.itemId,
    this.itemType,
    this.itemTitle,
    this.itemPhotoUrl,
    this.itemCategory,
    this.otherUid,
    this.chatId,
    required this.timestamp,
  });

  factory DonationHistoryEntry.fromMap(Map map, String id) => DonationHistoryEntry(
        id:           id,
        type:         map['type']?.toString() ?? 'donated',
        itemId:       map['itemId']?.toString(),
        itemType:     map['itemType']?.toString(),
        itemTitle:    map['itemTitle']?.toString(),
        itemPhotoUrl: map['itemPhotoUrl']?.toString(),
        itemCategory: map['itemCategory']?.toString(),
        otherUid:     map['otherUid']?.toString(),
        chatId:       map['chatId']?.toString(),
        timestamp:    (map['timestamp'] as num?)?.toInt() ??
            DateTime.now().millisecondsSinceEpoch,
      );

  bool get isDonated  => type == 'donated';
  bool get isReceived => type == 'received';
}

// ══════════════════════════════════════════════════════════════════════════════
// REPOSITORY — leitura do DonationHistory
// ══════════════════════════════════════════════════════════════════════════════

class _HistoryRepository {
  static Stream<List<DonationHistoryEntry>> watch(String uid) {
    return FirebaseDatabase.instance
        .ref('DonationHistory/$uid')
        .orderByChild('timestamp')
        .onValue
        .map((event) {
      final data = event.snapshot.value;
      if (data == null || data is! Map) return <DonationHistoryEntry>[];
      final list = <DonationHistoryEntry>[];
      (data as Map).forEach((key, val) {
        if (val is Map) {
          list.add(DonationHistoryEntry.fromMap(val, key.toString()));
        }
      });
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    });
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// PAGE
// ══════════════════════════════════════════════════════════════════════════════

class DreamPage extends StatefulWidget {
  const DreamPage({Key? key}) : super(key: key);

  @override
  State<DreamPage> createState() => _DreamPageState();
}

class _DreamPageState extends State<DreamPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<UserModel?>();
    final myUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppTheme.dreamBackground,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          _DreamHeader(tab: _tab),
        ],
        body: TabBarView(
          controller: _tab,
          children: [
            _TabSonhos(currentUser: currentUser),
            _TabDoacoes(currentUser: currentUser),
            _TabHistorico(myUid: myUid),
          ],
        ),
      ),
      floatingActionButton: _tab.index == 0 && currentUser != null
          ? FloatingActionButton.extended(
              onPressed: () {
                if (!ProfileService.isFullyVerified(currentUser)) {
                  showVerificationRequiredDialog(context, feature: 'publicar um sonho');
                  return;
                }
                showDreamFormSheet(context, currentUser: currentUser);
              },
              backgroundColor: AppTheme.accentPurple,
              elevation: 6,
              icon: const Text('✨', style: TextStyle(fontSize: 18)),
              label: const Text(
                'Novo sonho!',
                style: TextStyle(
                  color: AppTheme.backgroundColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            )
          : _tab.index == 1 && currentUser != null
              ? FloatingActionButton.extended(
                  onPressed: () {
                    if (!ProfileService.isFullyVerified(currentUser)) {
                      showVerificationRequiredDialog(context, feature: 'criar uma doação');
                      return;
                    }
                    showDonationItemFormSheet(context, currentUser: currentUser);
                  },
                  backgroundColor: AppTheme.accentPink,
                  elevation: 6,
                  icon: const Text('🎁', style: TextStyle(fontSize: 18)),
                  label: const Text(
                    'Nova doação!',
                    style: TextStyle(
                      color: AppTheme.backgroundColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                )
              : null,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// HEADER COM TABS
// ══════════════════════════════════════════════════════════════════════════════

class _DreamHeader extends StatelessWidget {
  final TabController tab;
  const _DreamHeader({required this.tab});

  @override
  Widget build(BuildContext context) {
    final dreamCtrl    = context.read<DreamController>();
    final donationCtrl = context.read<DonationController>();
    final requestCtrl  = context.read<RequestController>();
    final myUid        = FirebaseAuth.instance.currentUser?.uid;

    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      stretch: true,
      automaticallyImplyLeading: false,
      backgroundColor: AppTheme.primaryBlue,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          color: AppTheme.primaryBlue,
          child: TabBar(
            controller: tab,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            tabs: const [
              Tab(text: '💭  Sonhos'),
              Tab(text: '🎁  Doações'),
              Tab(text: '📋  Histórico'),
            ],
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.blurBackground],
        background: Stack(
          children: [
            Container(decoration: AppDecorations.dreamHeaderBackground),
            Positioned(top: 18, right: 20,
                child: Text('☁️', style: TextStyle(fontSize: 38, color: Colors.white.withValues(alpha: 0.18)))),
            Positioned(top: 50, left: 8,
                child: Text('☁️', style: TextStyle(fontSize: 24, color: Colors.white.withValues(alpha: 0.12)))),
            Positioned(bottom: 120, right: 55,
                child: Text('⭐', style: TextStyle(fontSize: 16, color: Colors.white.withValues(alpha: 0.30)))),
            Positioned(bottom: 134, left: 28,
                child: Text('🌈', style: TextStyle(fontSize: 18, color: Colors.white.withValues(alpha: 0.22)))),

            SafeArea(
              child: Padding(
                // bottom: 56 = 48px tabs + 8px folga
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 56),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: AppDecorations.dreamHeaderIconBox,
                          child: const Text('🌠', style: TextStyle(fontSize: 22)),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Meus Sonhos',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.backgroundColor)),
                            Text('Realize seus desejos! ✨',
                                style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        StreamBuilder<List<DreamModel>>(
                          stream: dreamCtrl.watchDreams(),
                          builder: (_, snap) => _StatBubble(
                            emoji: '💭',
                            value: '${snap.data?.length ?? 0}',
                            label: 'Sonhos',
                            color: AppTheme.accentPurple,
                          ),
                        ),
                        const SizedBox(width: 10),
                        StreamBuilder<List<DonationModel>>(
                          stream: donationCtrl.watchMyDonations(),
                          builder: (_, snap) => _StatBubble(
                            emoji: '🎁',
                            value: '${snap.data?.length ?? 0}',
                            label: 'Doações',
                            color: AppTheme.accentPink,
                            glow: (snap.data?.length ?? 0) > 0,
                          ),
                        ),
                        const SizedBox(width: 10),
                        if (myUid != null)
                          StreamBuilder<List<DonationHistoryEntry>>(
                            stream: _HistoryRepository.watch(myUid),
                            builder: (_, snap) {
                              final n = snap.data?.length ?? 0;
                              return _StatBubble(
                                emoji: '🏆',
                                value: '$n',
                                label: 'Histórico',
                                color: AppTheme.accentGreen,
                                glow: n > 0,
                              );
                            },
                          )
                        else
                          StreamBuilder<List<RequestModel>>(
                            stream: requestCtrl.watchMyRequests(),
                            builder: (_, snap) {
                              final n = (snap.data ?? []).where((r) => r.status == 'fulfilled').length;
                              return _StatBubble(emoji: '🎉', value: '$n', label: 'Recebidas', color: AppTheme.accentGreen, glow: n > 0);
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBubble extends StatelessWidget {
  final String emoji, value, label;
  final Color color;
  final bool glow;
  const _StatBubble({required this.emoji, required this.value, required this.label, required this.color, this.glow = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: glow ? AppDecorations.dreamStatBubbleActive(color) : AppDecorations.dreamStatBubble,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 15)),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.backgroundColor)),
              Text(label, style: TextStyle(fontSize: 8, color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ABA 1 — SONHOS
// ══════════════════════════════════════════════════════════════════════════════

class _TabSonhos extends StatefulWidget {
  final UserModel? currentUser;
  const _TabSonhos({this.currentUser});

  @override
  State<_TabSonhos> createState() => _TabSonhosState();
}

class _TabSonhosState extends State<_TabSonhos> {
  // Trocar a key força o StreamBuilder a recriar a subscription,
  // ou seja, faz um "force refresh" mesmo a stream sendo realtime.
  Key _streamKey = UniqueKey();

  Future<void> _onRefresh() async {
    setState(() => _streamKey = UniqueKey());
    // pequeno delay para o RefreshIndicator dar feedback visual
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.read<DreamController>();
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppTheme.accentPurple,
      child: StreamBuilder<List<DreamModel>>(
        key: _streamKey,
        stream: ctrl.watchDreams(),
        builder: (context, snapshot) {
          final dreams = snapshot.data ?? [];
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            children: [
              if (dreams.isEmpty)
                _EmptyState(
                  emoji: '🌙',
                  title: 'Que sonho você tem?',
                  subtitle: 'Toque no botão ✨ para adicionar seu primeiro sonho!',
                  borderColor: AppTheme.accentPurple,
                )
              else
                ...dreams.map((d) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: DreamCardWidget(
                        dream: d,
                        editable: true,
                        onEdit: widget.currentUser == null
                            ? null
                            : () => showDreamFormSheet(context, currentUser: widget.currentUser!, dream: d),
                      ),
                    )),
            ],
          );
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ABA 2 — DOAÇÕES
// ══════════════════════════════════════════════════════════════════════════════

class _TabDoacoes extends StatefulWidget {
  final UserModel? currentUser;
  const _TabDoacoes({this.currentUser});

  @override
  State<_TabDoacoes> createState() => _TabDoacoesState();
}

class _TabDoacoesState extends State<_TabDoacoes> {
  Key _streamKey = UniqueKey();

  Future<void> _onRefresh() async {
    setState(() => _streamKey = UniqueKey());
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.read<DonationController>();
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppTheme.accentPink,
      child: StreamBuilder<List<DonationModel>>(
        key: _streamKey,
        stream: ctrl.watchMyDonations(),
        builder: (context, snapshot) {
          final donations = snapshot.data ?? [];
          if (donations.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              children: [
                _EmptyState(
                  emoji: '🧸',
                  title: 'Nenhuma doação ainda!',
                  subtitle: 'Compartilhe brinquedos e itens que você não usa 💕',
                  borderColor: AppTheme.accentPink,
                ),
              ],
            );
          }
          return GridView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,      // era 3 — muito apertado para imagem + texto
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.82, // mais altura por card para título e categoria
            ),
            itemCount: donations.length,
            itemBuilder: (_, i) => DonationCardWidget(
              donation: donations[i],
              onEdit: () {
                if (widget.currentUser == null) return;
                showDonationItemFormSheet(context, currentUser: widget.currentUser!, donation: donations[i]);
              },
            ),
          );
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ABA 3 — HISTÓRICO
// ══════════════════════════════════════════════════════════════════════════════

class _TabHistorico extends StatefulWidget {
  final String? myUid;
  const _TabHistorico({this.myUid});

  @override
  State<_TabHistorico> createState() => _TabHistoricoState();
}

class _TabHistoricoState extends State<_TabHistorico> {
  Key _streamKey = UniqueKey();

  Future<void> _onRefresh() async {
    setState(() => _streamKey = UniqueKey());
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.myUid == null) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.accentPurple, strokeWidth: 2));
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppTheme.accentTeal,
      child: StreamBuilder<List<DonationHistoryEntry>>(
        key: _streamKey,
        stream: _HistoryRepository.watch(widget.myUid!),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.accentPurple, strokeWidth: 2));
          }

          final all      = snap.data ?? [];
          final donated  = all.where((e) => e.isDonated).toList();
          final received = all.where((e) => e.isReceived).toList();

          if (all.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
              children: [
                _EmptyState(
                  emoji: '📋',
                  title: 'Histórico vazio',
                  subtitle: 'Quando você concluir uma doação, ela aparecerá aqui para ambos os participantes.',
                  borderColor: AppTheme.accentTeal,
                ),
              ],
            );
          }

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 100),
            children: [
              // ── Resumo ──────────────────────────────────────────────
              _HistoricoResumo(total: all.length, donated: donated.length, received: received.length),

              // ── Itens Recebidos ──────────────────────────────────────
              if (received.isNotEmpty) ...[
                _HistoricoSectionHeader(
                  emoji: '🎁',
                  label: 'Recebi',
                  count: received.length,
                  color: AppTheme.accentGreen,
                ),
                ...received.map((e) => _HistoricoCard(entry: e)),
              ],

              // ── Doações Feitas ───────────────────────────────────────
              if (donated.isNotEmpty) ...[
                _HistoricoSectionHeader(
                  emoji: '💝',
                  label: 'Doei',
                  count: donated.length,
                  color: AppTheme.accentPink,
                ),
                ...donated.map((e) => _HistoricoCard(entry: e)),
              ],
            ],
          );
        },
      ),
    );
  }
}

// ── Resumo do histórico ───────────────────────────────────────────────────────

class _HistoricoResumo extends StatelessWidget {
  final int total, donated, received;
  const _HistoricoResumo({required this.total, required this.donated, required this.received});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryBlue, AppTheme.primaryBlueMid],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.30),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(child: _ResumoItem(emoji: '🏆', value: '$total', label: 'Total', color: Colors.white)),
          _ResumoDivider(),
          Expanded(child: _ResumoItem(emoji: '💝', value: '$donated', label: 'Doei', color: const Color(0xFFFF9EBC))),
          _ResumoDivider(),
          Expanded(child: _ResumoItem(emoji: '🎁', value: '$received', label: 'Recebi', color: const Color(0xFF9EF7A1))),
        ],
      ),
    );
  }
}

class _ResumoItem extends StatelessWidget {
  final String emoji, value, label;
  final Color color;
  const _ResumoItem({required this.emoji, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.70))),
      ],
    );
  }
}

class _ResumoDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 1, height: 48,
        color: Colors.white.withValues(alpha: 0.15),
      );
}

// ── Section header ────────────────────────────────────────────────────────────

class _HistoricoSectionHeader extends StatelessWidget {
  final String emoji, label;
  final int count;
  final Color color;
  const _HistoricoSectionHeader({required this.emoji, required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 17))),
          ),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.primaryBlue)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('$count', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: color)),
          ),
        ],
      ),
    );
  }
}

// ── Card de histórico ─────────────────────────────────────────────────────────

class _HistoricoCard extends StatelessWidget {
  final DonationHistoryEntry entry;
  const _HistoricoCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final isDonated = entry.isDonated;
    final accent    = isDonated ? AppTheme.accentPink : AppTheme.accentGreen;
    final bgColor   = isDonated
        ? AppTheme.accentPink.withValues(alpha: 0.04)
        : AppTheme.accentGreen.withValues(alpha: 0.04);

    final typeLabel = entry.itemType == 'dream' ? 'Sonho' : 'Doação';
    final dt   = DateTime.fromMillisecondsSinceEpoch(entry.timestamp);
    final day   = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final hour  = dt.hour.toString().padLeft(2, '0');
    final min   = dt.minute.toString().padLeft(2, '0');
    final date  = '$day/$month/${dt.year} às $hour:$min';

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.20)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Faixa lateral colorida
          Container(
            width: 4,
            height: 80,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
            ),
          ),

          // Foto ou emoji
          Padding(
            padding: const EdgeInsets.all(12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: entry.itemPhotoUrl != null && entry.itemPhotoUrl!.isNotEmpty
                  ? Image.network(
                      entry.itemPhotoUrl!,
                      width: 52, height: 52, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _fallbackPhoto(accent),
                    )
                  : _fallbackPhoto(accent),
            ),
          ),

          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tipo + badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          typeLabel.toUpperCase(),
                          style: TextStyle(
                            fontSize: 8.5, fontWeight: FontWeight.w800,
                            color: accent, letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDonated
                              ? AppTheme.accentPink.withValues(alpha: 0.10)
                              : AppTheme.accentGreen.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isDonated ? '💝 Doei' : '🎁 Recebi',
                          style: TextStyle(
                            fontSize: 9, fontWeight: FontWeight.w700,
                            color: accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    entry.itemTitle ?? 'Item',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.primaryBlue, height: 1.2),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    date,
                    style: TextStyle(fontSize: 10.5, color: AppTheme.textSecondary.withValues(alpha: 0.65)),
                  ),
                ],
              ),
            ),
          ),

          // Ícone de status
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Text(isDonated ? '💝' : '🎉', style: const TextStyle(fontSize: 22)),
          ),
        ],
      ),
    );
  }

  Widget _fallbackPhoto(Color accent) => Container(
        width: 52, height: 52,
        color: accent.withValues(alpha: 0.10),
        child: Center(
          child: Text(
            entry.itemType == 'dream' ? '💭' : '📦',
            style: const TextStyle(fontSize: 24),
          ),
        ),
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// WIDGETS UTILITÁRIOS COMUNS
// ══════════════════════════════════════════════════════════════════════════════

class _EmptyState extends StatelessWidget {
  final String emoji, title, subtitle;
  final Color borderColor;
  const _EmptyState({required this.emoji, required this.title, required this.subtitle, required this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: AppDecorations.dreamEmptyState(borderColor),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.primaryBlue)),
          const SizedBox(height: 8),
          Text(subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500, height: 1.5)),
        ],
      ),
    );
  }
}

'@
    Write-FileUtf8NoBom -Path (Join-Path $RepoPath "lib\features\dream\presentation\pages\dream_page.dart") -Content $content_9
    Write-Ok "Escrito: lib/features/dream/presentation/pages/dream_page.dart"

    $content_10 = @'
import 'package:empatia/core/data/models/child_model.dart';
import 'package:empatia/core/data/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

/// 👤 PROFILE REPOSITORY
///
/// Conversa diretamente com o Firebase.
class ProfileRepository {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('❌ Usuário não está logado.');
    return uid;
  }

  DatabaseReference get _userRef => _db.ref('Users/$_uid');

  /// 📺 Stream do usuário — atualiza em tempo real
  Stream<UserModel?> watchUser() {
    return _userRef.onValue.map((event) {
      final snapshot = event.snapshot;
      if (!snapshot.exists || snapshot.value == null) return null;
      return UserModel.fromMap(
        Map<dynamic, dynamic>.from(snapshot.value as Map),
        _uid,
      );
    });
  }

  /// 💾 Salva dados do perfil (merge) e espelha dados públicos em UsersPublic
  Future<void> updateProfile(UserModel user) async {
    final map = user.toMap();
    debugPrint('📦 Salvando perfil: $map');

    // Grava dados completos em Users (privado)
    await _userRef.update(map);

    // Espelha campos públicos em UsersPublic (legível por qualquer autenticado)
    final publicData = <String, dynamic>{
      'uid': _uid,
      if (user.name != null) 'name': user.name,
      if (user.profileEmoji != null) 'profileEmoji': user.profileEmoji,
      // Sempre incluído (mesmo null): mantém UsersPublic em sincronia
      // quando o usuário remove a foto e volta para o avatar.
      'profileImage': user.profileImage,
      if (user.city != null) 'city': user.city,
      if (user.state != null) 'state': user.state,
      if (user.sexo != null) 'sexo': user.sexo,
      if (user.age != null) 'age': user.age,
      // Status pode ser limpo (ficar null) — sempre incluído para refletir
      // a remoção no perfil público também.
      'status': user.status,
      // Sempre incluídos (mesmo null): permite remover um link salvo
      // também no perfil público.
      'socialFacebook': user.socialFacebook,
      'socialInstagram': user.socialInstagram,
      'socialX': user.socialX,
      // Verificação: espelha os dois booleans + o resultado calculado
      // (mais simples de ler direto no perfil público sem reimplementar
      // a regra de negócio lá).
      'emailVerified': user.emailVerified == true,
      'profileCompleted': user.profileCompleted == true,
      'fullyVerified':
          (user.emailVerified == true) && (user.profileCompleted == true),
    };
    await _db.ref('UsersPublic/$_uid').update(publicData);
  }

  /// 🔄 ALTERNA MODO: "donor" ↔ "receiver"
  Future<void> toggleMode(String newMode) async {
    assert(
      newMode == 'donor' || newMode == 'receiver',
      '❌ newMode deve ser "donor" ou "receiver"',
    );
    debugPrint('🔄 Alternando modo para: $newMode');
    await _userRef.update({
      'activeMode': newMode,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// ✅ Marca perfil como completo no banco de dados
  ///
  /// Chamado automaticamente pelo [ProfileService] quando todos os
  /// campos obrigatórios estão preenchidos ao salvar.
  Future<void> markProfileCompleted() async {
    debugPrint('✅ Marcando perfil como completo');
    await _userRef.update({
      'profileCompleted': true,
      'profileCompletedAt': DateTime.now().millisecondsSinceEpoch,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });

    // ── Cross-check: e-mail também verificado? → isVerified ─────────────
    final emailSnap = await _userRef.child('emailVerified').get();
    final emailVerified = emailSnap.value == true;
    if (emailVerified) {
      await _userRef.update({
        'isVerified':   true,
        'isVerifiedAt': DateTime.now().millisecondsSinceEpoch,
        'updatedAt':    DateTime.now().millisecondsSinceEpoch,
      });
      debugPrint('✅ isVerified = true gravado no Firebase');
    }
    // ─────────────────────────────────────────────────────────────────────

    // Mantém UsersPublic em sincronia — sem isso, o perfil público
    // continuaria mostrando "não verificado" até o próximo saveProfile().
    await _db.ref('UsersPublic/$_uid').update({
      'profileCompleted': true,
      'emailVerified': emailVerified,
      'fullyVerified': emailVerified, // profileCompleted já é true aqui
    });
  }

  /// ➕ Adiciona filho
  Future<String> addChild(ChildModel child) async {
    final ref = _userRef.child('children').push();
    await ref.set(child.toMap());
    return ref.key!;
  }

  /// ✏️ Edita filho
  ///
  /// Após salvar, sincroniza os campos denormalizados (childName/
  /// childEmoji/childAge) em todos os sonhos já cadastrados desse filho
  /// — eles vivem em `Dreams/{dreamId}` (nó público, separado de Users)
  /// e são usados pela vitrine pública (PublicProfilePage) sem precisar
  /// ler o nó privado do filho. Sem isso, editar nome/idade/avatar do
  /// filho deixaria os sonhos já criados com dados antigos.
  Future<void> updateChild(ChildModel child) async {
    if (child.id == null) {
      throw Exception('❌ Filho sem ID não pode ser atualizado.');
    }
    await _userRef.child('children/${child.id}').update(child.toMap());
    await _syncChildDreams(child);
  }

  /// 🔄 Atualiza childName/childEmoji/childAge em todos os sonhos
  /// vinculados a [child], nos DOIS nós onde eles vivem:
  ///
  ///   • Users/{uid}/dreams/{id} — nó PRIVADO, lido pela DreamPage
  ///     (tela "Meus Sonhos" do próprio usuário)
  ///   • Dreams/{id}             — nó PÚBLICO/feed, lido pela vitrine
  ///     pública (PublicProfilePage) e pela busca
  ///
  /// IMPORTANTE: antes só sincronizávamos o nó público `Dreams`. Isso
  /// fazia o feed público refletir a edição do filho, mas a própria
  /// DreamPage do usuário continuava mostrando nome/idade/avatar antigos
  /// — porque ela lê de `Users/{uid}/dreams`, que nunca era tocado aqui.
  ///
  /// Requer índice em `childId` em ambos os nós (regras do Realtime
  /// Database):
  ///   "Dreams": { ".indexOn": ["userId", "childId"] }
  ///   "Users/$uid/dreams": { ".indexOn": ["childId"] }  (ou ".indexOn": ["$uid"]... ajustar conforme regras)
  Future<void> _syncChildDreams(ChildModel child) async {
    if (child.id == null) return;

    final updates = <String, dynamic>{};

    // ── 1) Nó privado: Users/{uid}/dreams ───────────────────────────────────
    try {
      final privateSnap = await _userRef
          .child('dreams')
          .orderByChild('childId')
          .equalTo(child.id)
          .get();

      if (privateSnap.exists && privateSnap.value is Map) {
        final privateMap = Map<dynamic, dynamic>.from(privateSnap.value as Map);
        for (final dreamId in privateMap.keys) {
          updates['Users/$_uid/dreams/$dreamId/childName']  = child.name;
          updates['Users/$_uid/dreams/$dreamId/childEmoji'] = child.emoji;
          updates['Users/$_uid/dreams/$dreamId/childAge']   = child.age;
        }
        debugPrint(
            '✅ ${privateMap.length} sonho(s) privado(s) sincronizado(s) para o filho ${child.name}');
      }
    } catch (e) {
      debugPrint('⚠️ Erro ao sincronizar sonhos privados do filho (continuando): $e');
    }

    // ── 2) Nó público: Dreams (feed) ─────────────────────────────────────────
    try {
      final dreamsSnap = await _db
          .ref('Dreams')
          .orderByChild('childId')
          .equalTo(child.id)
          .get();

      if (dreamsSnap.exists && dreamsSnap.value is Map) {
        final dreamsMap = Map<dynamic, dynamic>.from(dreamsSnap.value as Map);
        for (final dreamId in dreamsMap.keys) {
          updates['Dreams/$dreamId/childName']  = child.name;
          updates['Dreams/$dreamId/childEmoji'] = child.emoji;
          updates['Dreams/$dreamId/childAge']   = child.age;
        }
        debugPrint(
            '✅ ${dreamsMap.length} sonho(s) público(s) sincronizado(s) para o filho ${child.name}');
      }
    } catch (e) {
      debugPrint('⚠️ Erro ao sincronizar sonhos públicos do filho (continuando): $e');
    }

    if (updates.isEmpty) return;

    try {
      // Multi-path update: grava em ambos os nós numa única chamada
      // atômica, em vez de um await por sonho.
      await _db.ref().update(updates);
    } catch (e) {
      // Não falha a edição do filho se a sincronização dos sonhos der
      // erro — os dados do filho já foram salvos corretamente acima.
      debugPrint('⚠️ Erro ao gravar sincronização dos sonhos do filho (continuando): $e');
    }
  }

  /// 🗑️ Remove filho
  Future<void> removeChild(String childId) async {
    await _userRef.child('children/$childId').remove();
  }
}
'@
    Write-FileUtf8NoBom -Path (Join-Path $RepoPath "lib\features\profile\data\repository\profile_repository.dart") -Content $content_10
    Write-Ok "Escrito: lib/features/profile/data/repository/profile_repository.dart"

    $content_11 = @'
import 'package:empatia/core/data/models/child_model.dart';
import 'package:empatia/core/data/models/user_model.dart';
import 'package:image_picker/image_picker.dart'; // XFile
import '../repository/profile_repository.dart';
import 'storage_service.dart';

/// 👤 PROFILE SERVICE
///
/// Valida dados e orquestra chamadas ao Repository.
/// Usa [XFile] em vez de [File] para funcionar no web e no mobile.
class ProfileService {
  final ProfileRepository _repository;
  final StorageService _storageService;

  ProfileService(this._repository, this._storageService);

  Stream<UserModel?> watchUser() => _repository.watchUser();

  /// Constrói a URL completa de uma rede social a partir do que a pessoa
  /// digitou no campo (só o "@usuario", sem domínio):
  ///   • vazio/em branco → null (remove o link salvo)
  ///   • remove @ e barras que tenham sobrado
  ///   • monta "https://{domain}/{usuario}"
  ///
  /// O domínio NUNCA vem do usuário (evita link incorreto/malicioso) —
  /// é sempre o fixo da própria plataforma, escolhido por código.
  static String? _buildSocialUrl(String? rawUsername, String domain) {
    var v = rawUsername?.trim();
    if (v == null || v.isEmpty) return null;
    if (v.contains('/')) {
      final parts = v.split('/').where((p) => p.trim().isNotEmpty).toList();
      if (parts.isNotEmpty) v = parts.last;
    }
    v = v.replaceAll('@', '').trim();
    if (v.isEmpty) return null;
    return 'https://$domain/$v';
  }

  // ── Campos obrigatórios para o perfil ser considerado completo ──────────────
  //
  // Para [isProfileComplete] retornar true, o usuário precisa ter:
  //   • name        — nome preenchido
  //   • age         — idade válida
  //   • sexo        — sexo selecionado
  //   • city        — cidade preenchida
  //   • state       — estado preenchido
  //   • neighborhood — bairro preenchido
  //   • profileEmoji ou profileImage — avatar definido
  //
  static bool isProfileComplete(UserModel user) {
    final hasName  = (user.name?.trim().isNotEmpty ?? false);
    final hasAge   = user.age != null;
    final hasSexo  = (user.sexo?.trim().isNotEmpty ?? false);
    final hasCity  = (user.city?.trim().isNotEmpty ?? false);
    final hasState = (user.state?.trim().isNotEmpty ?? false);
    final hasNeighborhood = (user.neighborhood?.trim().isNotEmpty ?? false);
    final hasAvatar = (user.profileEmoji?.trim().isNotEmpty ?? false) ||
        (user.profileImage?.trim().isNotEmpty ?? false);

    return hasName &&
        hasAge &&
        hasSexo &&
        hasCity &&
        hasState &&
        hasNeighborhood &&
        hasAvatar;
  }

  /// Retorna true quando as duas verificações estão concluídas:
  ///   1. E-mail verificado     (emailVerified == true)
  ///   2. Perfil completo       (profileCompleted == true)
  static bool isFullyVerified(UserModel user) {
    return (user.emailVerified == true) &&
        (user.profileCompleted == true);
  }

  /// Salva perfil COM VALIDAÇÃO.
  ///
  /// Após salvar, verifica automaticamente se o perfil foi completado
  /// e, em caso positivo, escreve [profileCompleted = true] no banco.
  Future<void> saveProfile({
    required String? name,
    required String? age,
    required String? status,
    required String? city,
    required String? state,
    required String? neighborhood,
    required String? profileEmoji,
    required String? sexo,
    required UserModel currentUser,
    String? socialFacebook,
    String? socialInstagram,
    String? socialX,
    double? latitude,
    double? longitude,
    XFile? profilePhoto,
    bool usePhoto = true,
  }) async {
    final trimmedName = name?.trim() ?? '';
    if (trimmedName.isEmpty) {
      throw Exception('❌ O nome não pode ficar em branco.');
    }
    if (trimmedName.length < 2) {
      throw Exception('❌ O nome precisa ter pelo menos 2 letras.');
    }

    int? parsedAge;
    if (age != null && age.trim().isNotEmpty) {
      parsedAge = int.tryParse(age.trim());
      if (parsedAge == null) {
        throw Exception('❌ Idade inválida. Digite só números.');
      }
      if (parsedAge < 18 || parsedAge > 99) {
        throw Exception('❌ Idade deve ser entre 18 e 99 anos.');
      }
    }

    String? profileImageUrl = currentUser.profileImage;
    bool clearPhoto = false;

    if (profilePhoto != null) {
      profileImageUrl = await _storageService.uploadProfileImage(
        profilePhoto,
        oldImageUrl: currentUser.profileImage,
      );
    } else if (!usePhoto) {
      // Usuário trocou explicitamente para o modo "Avatar" (sem foto nova
      // selecionada) — limpa a foto antiga para o avatar prevalecer.
      profileImageUrl = null;
      clearPhoto = true;
    }

    final updatedUser = currentUser.copyWith(
      name: trimmedName,
      age: parsedAge,
      status: status?.trim().isEmpty == true ? null : status?.trim(),
      city: city?.trim().isEmpty == true ? null : city?.trim(),
      state: state?.trim().isEmpty == true ? null : state?.trim(),
      neighborhood:
          neighborhood?.trim().isEmpty == true ? null : neighborhood?.trim(),
      profileEmoji: profileEmoji,
      sexo: sexo,
      // Facebook: sem campo de edição ativo no momento — não enviamos
      // socialFacebook aqui, então o UserModel.copyWith preserva o que
      // já estava salvo (ver comentário no copyWith).
      socialInstagram: _buildSocialUrl(socialInstagram, 'instagram.com'),
      socialX: _buildSocialUrl(socialX, 'x.com'),
      latitude: latitude,
      longitude: longitude,
      profileImage: profileImageUrl,
      clearProfileImage: clearPhoto,
    );

    await _repository.updateProfile(updatedUser);

    // ── Verifica automaticamente se o perfil foi completado ─────────────────
    // Só marca se ainda não estava marcado (evita writes desnecessários).
    if (updatedUser.profileCompleted != true && isProfileComplete(updatedUser)) {
      await _repository.markProfileCompleted();
    }
  }

  /// 🔄 ALTERNA MODO do usuário: "donor" ↔ "receiver"
  Future<void> toggleMode(String newMode) async {
    if (newMode != 'donor' && newMode != 'receiver') {
      throw Exception('❌ Modo inválido: $newMode');
    }
    await _repository.toggleMode(newMode);
  }

  /// Adiciona filho COM VALIDAÇÃO
  Future<void> addChild({
    required String? name,
    required String? age,
    required String emoji,
  }) async {
    final trimmedName = name?.trim() ?? '';
    if (trimmedName.isEmpty) {
      throw Exception('❌ O nome do filho não pode ficar em branco.');
    }

    int? parsedAge;
    if (age != null && age.trim().isNotEmpty) {
      parsedAge = int.tryParse(age.trim());
      if (parsedAge == null || parsedAge < 0 || parsedAge > 18) {
        throw Exception('❌ Idade do filho deve ser entre 0 e 18 anos.');
      }
    }

    final child = ChildModel(name: trimmedName, age: parsedAge, emoji: emoji);
    await _repository.addChild(child);
  }

  /// Atualiza filho
  Future<void> updateChild({
    required String childId,
    required String? name,
    required String? age,
    required String emoji,
  }) async {
    final trimmedName = name?.trim() ?? '';
    if (trimmedName.isEmpty) {
      throw Exception('❌ O nome do filho não pode ficar em branco.');
    }
    int? parsedAge;
    if (age != null && age.trim().isNotEmpty) {
      parsedAge = int.tryParse(age.trim());
    }
    final child = ChildModel(
      id: childId,
      name: trimmedName,
      age: parsedAge,
      emoji: emoji,
    );
    await _repository.updateChild(child);
  }

  /// Remove filho
  Future<void> removeChild(String childId) async {
    await _repository.removeChild(childId);
  }
}
'@
    Write-FileUtf8NoBom -Path (Join-Path $RepoPath "lib\features\profile\data\service\profile_service.dart") -Content $content_11
    Write-Ok "Escrito: lib/features/profile/data/service/profile_service.dart"

    $content_12 = @'
import 'dart:math';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

/// 📤 STORAGE REPOSITORY
///
/// É o CARTEIRO que envia fotos para a nuvem.
/// Conversa diretamente com o Firebase Storage (substitui o antigo
/// CloudinaryRepository).
///
/// Usa [Uint8List] em vez de [File] para funcionar no web e no mobile.
///
/// RESPONSABILIDADES:
/// - Fazer upload de imagens
/// - Retornar URL pública (download URL) da imagem
/// - Deletar imagens a partir da própria URL pública
class StorageRepository {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  static final Random _random = Random();

  /// Pasta raiz dentro do bucket onde as imagens enviadas pelo app
  /// são armazenadas (perfis, filhos, sonhos, doações — tudo cai aqui,
  /// separado por um nome de arquivo único).
  static const String _rootFolder = 'uploads';

  /// Faz upload de uma imagem para o Firebase Storage
  ///
  /// [bytes]    = bytes da imagem (lidos via XFile.readAsBytes())
  /// [fileName] = nome do arquivo com extensão (ex: "foto.jpg") — usado
  ///              apenas para derivar a extensão e o content-type.
  ///
  /// Retorna a URL pública (download URL) da imagem ou lança exceção
  /// em caso de erro.
  Future<String> uploadImage(Uint8List bytes, {String fileName = 'image.jpg'}) async {
    try {
      final extension = _extensionFromFileName(fileName);
      final uniqueName =
          '${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(1000000)}$extension';

      final ref = _storage.ref().child(_rootFolder).child(uniqueName);

      final metadata = SettableMetadata(
        contentType: _contentTypeFromFileName(fileName),
      );

      await ref.putData(bytes, metadata);
      final imageUrl = await ref.getDownloadURL();

      debugPrint('✅ Upload concluído: $imageUrl');
      return imageUrl;
    } catch (e) {
      debugPrint('❌ Erro no upload: $e');
      throw Exception('Não foi possível enviar a imagem. Tente novamente.');
    }
  }

  /// Detecta a extensão do arquivo a partir do nome (com o ponto incluído)
  String _extensionFromFileName(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png'))  return '.png';
    if (lower.endsWith('.webp')) return '.webp';
    if (lower.endsWith('.jpeg')) return '.jpeg';
    return '.jpg'; // fallback
  }

  /// Detecta o content-type pelo nome do arquivo
  String _contentTypeFromFileName(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png'))  return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg'; // .jpg / .jpeg / fallback
  }

  /// Remove uma imagem do Firebase Storage a partir da sua URL pública
  /// (download URL). Diferente do Cloudinary, o Storage permite
  /// reconstruir a referência (`Reference`) direto a partir da URL —
  /// não precisamos extrair nenhum "public_id" manualmente nem passar
  /// por uma Cloud Function.
  Future<void> deleteImageByUrl(String imageUrl) async {
    try {
      debugPrint('🗑️ Solicitando deleção de: $imageUrl');

      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();

      debugPrint('✅ Imagem deletada: ${ref.fullPath}');
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        debugPrint('⚠️ Imagem não encontrada (pode já ter sido deletada)');
        return;
      }
      debugPrint('⚠️ Erro ao deletar: ${e.code} — ${e.message}');
      // Não lança exceção — falha na deleção não deve bloquear o fluxo
      // que está chamando (ex: upload de uma nova foto).
    } catch (e) {
      debugPrint('❌ Erro ao deletar imagem: $e');
    }
  }
}

'@
    Write-FileUtf8NoBom -Path (Join-Path $RepoPath "lib\features\profile\data\repository\storage_repository.dart") -Content $content_12
    Write-Ok "Escrito: lib/features/profile/data/repository/storage_repository.dart"

    $content_13 = @'
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // XFile
import '../repository/storage_repository.dart';

/// 📸 STORAGE SERVICE
///
/// É o GERENTE de fotos.
/// Valida imagens antes de enviar para o Firebase Storage (substitui o
/// antigo CloudinaryService).
///
/// Usa [XFile] em vez de [File] para funcionar no web e no mobile.
///
/// RESPONSABILIDADES:
/// - Validar tamanho e formato de imagens
/// - Chamar o Repository para upload
/// - Deletar imagens antigas antes de fazer novo upload
/// - Garantir que dados estão corretos
///
/// Mantém os mesmos nomes de método do antigo CloudinaryService
/// (uploadProfileImage / deleteProfileImage) para que ProfileService,
/// DonationService e DreamService não precisem mudar nada além do
/// import e do tipo da dependência injetada.
class StorageService {
  final StorageRepository _repository;

  StorageService(this._repository);

  /// Tamanho máximo: 5MB
  static const int _maxSizeBytes = 5 * 1024 * 1024;

  /// Formatos aceitos
  static const List<String> _allowedExtensions = [
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
  ];

  /// Faz upload de uma imagem COM VALIDAÇÃO
  ///
  /// [file] = XFile (funciona no web e no mobile)
  /// [oldImageUrl] = URL da imagem antiga (será deletada se fornecida)
  ///
  /// Retorna URL pública da nova imagem
  Future<String> uploadProfileImage(
    XFile file, {
    String? oldImageUrl,
  }) async {
    // Lê os bytes uma vez — funciona no web (blob URL) e no mobile
    final bytes = await file.readAsBytes();

    // VALIDAÇÃO: Arquivo tem conteúdo
    if (bytes.isEmpty) {
      throw Exception('❌ Arquivo de imagem não encontrado ou vazio.');
    }

    // VALIDAÇÃO: Tamanho do arquivo
    final fileSize = bytes.length;
    if (fileSize > _maxSizeBytes) {
      final sizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(1);
      throw Exception(
        '❌ Imagem muito grande ($sizeMB MB). Máximo permitido: 5 MB.',
      );
    }

    // VALIDAÇÃO: Extensão do arquivo
    final fileName = file.name.toLowerCase();
    final hasValidExtension = _allowedExtensions.any(
      (ext) => fileName.endsWith(ext),
    );

    if (!hasValidExtension) {
      throw Exception(
        '❌ Formato inválido. Use: ${_allowedExtensions.join(", ")}',
      );
    }

    debugPrint(
        '📤 Enviando imagem (${(fileSize / 1024).toStringAsFixed(0)} KB)...');

    // 1️⃣ Deleta imagem antiga ANTES de fazer upload
    if (oldImageUrl != null && oldImageUrl.isNotEmpty) {
      await _deleteOldImage(oldImageUrl);
    }

    // 2️⃣ Faz upload passando os bytes (web + mobile safe)
    final imageUrl = await _repository.uploadImage(bytes, fileName: fileName);

    return imageUrl;
  }

  /// Deleta uma imagem antiga do Firebase Storage
  Future<void> _deleteOldImage(String imageUrl) async {
    try {
      debugPrint('🗑️ Tentando deletar imagem antiga...');
      await _repository.deleteImageByUrl(imageUrl);
    } catch (e) {
      // Não falha se deleção não funcionar
      debugPrint('⚠️ Erro ao deletar imagem antiga (continuando): $e');
    }
  }

  /// Remove uma imagem (quando o usuário remove a foto)
  Future<void> deleteProfileImage(String imageUrl) async {
    await _deleteOldImage(imageUrl);
  }
}

'@
    Write-FileUtf8NoBom -Path (Join-Path $RepoPath "lib\features\profile\data\service\storage_service.dart") -Content $content_13
    Write-Ok "Escrito: lib/features/profile/data/service/storage_service.dart"

    $content_14 = @'
name: empatia
description: "A new Flutter project."
publish_to: 'none'

version: 1.0.2+3

environment:
  sdk: ^3.11.5

dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  
  # Firebase - VERSÕES COMPATÍVEIS
  firebase_core: ^3.15.0
  firebase_auth: ^5.3.4
  firebase_storage: ^12.4.7
  
  google_sign_in: ^6.2.1
  firebase_database: ^11.3.10
  geolocator: ^13.0.1
  provider: ^6.1.5+1
  cloud_functions: ^5.6.2
  image_picker: ^1.2.2
  permission_handler: ^12.0.1
  http: ^1.2.2
  intl: ^0.20.2
  firebase_messaging: ^15.2.5
  url_launcher: ^6.3.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0

flutter:
  uses-material-design: true
  assets:
    - assets/children/boy/
    - assets/children/girl/
    - assets/parents/man/
    - assets/parents/woman/
    - assets/parents/other/
'@
    Write-FileUtf8NoBom -Path (Join-Path $RepoPath "pubspec.yaml") -Content $content_14
    Write-Ok "Escrito: pubspec.yaml"


    Write-Step "Resumo (git status)"
    git status --short

    Write-Step "Proximos passos manuais"
    Write-Host "1) Rode 'flutter pub get' para baixar a dependencia firebase_storage." -ForegroundColor Yellow
    Write-Host "2) Configure as regras do Firebase Storage (storage.rules), nao incluidas neste script." -ForegroundColor Yellow
    Write-Host "3) (Opcional) Limpe a Cloud Function 'deleteCloudinaryImage' em functions/src/media.ts, que ficou orfa apos a migracao." -ForegroundColor Yellow
    Write-Host "4) Revise (git diff) e faca commit das mudancas." -ForegroundColor Yellow

    Write-Host ""
    Write-Ok "Concluido!"
}
finally {
    Pop-Location
}