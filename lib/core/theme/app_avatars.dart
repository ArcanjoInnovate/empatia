/// 🖼️ APP AVATARS
///
/// Substitui o antigo sistema de emoji como avatar por ilustrações reais
/// (WebP otimizados) armazenadas em `assets/children` e `assets/parents`.
///
/// Os campos do banco (`profileEmoji`, `emoji`, `childEmoji`,
/// `userProfileEmoji`) continuam com o mesmo nome por compatibilidade,
/// mas agora guardam o CAMINHO DO ASSET (ex:
/// "assets/parents/woman/avatar_01.webp") em vez de um caractere emoji.
///
/// [AvatarRender] (em avatar_render.dart) sabe renderizar tanto o novo
/// formato (caminho de asset) quanto, por segurança, um emoji legado caso
/// algum dado antigo ainda não tenha sido migrado.
library app_avatars;

class AppAvatars {
  AppAvatars._();

  // ── Crianças ──────────────────────────────────────────────────
  static List<String> boy = [
    for (final n in [
      1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13,
      14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25,
    ])
      'assets/children/boy/$n.webp',
  ];

  static List<String> girl = [
    for (final n in [
      1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13,
      14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25,
    ])
      'assets/children/girl/$n.webp',
  ];

  /// Todos os avatares de crianças (usado quando não sabemos o gênero).
  static List<String> get allChildren => [...boy, ...girl];

  // ── Responsáveis (pais/mães) ─────────────────────────────────
  static const List<String> man = [
    'assets/parents/man/avatar_02.webp',
    'assets/parents/man/avatar_04.webp',
    'assets/parents/man/avatar_07.webp',
    'assets/parents/man/avatar_09.webp',
    'assets/parents/man/avatar_11.webp',
    'assets/parents/man/avatar_15.webp',
    'assets/parents/man/avatar_17.webp',
    'assets/parents/man/avatar_20.webp',
    'assets/parents/man/avatar_22.webp',
    'assets/parents/man/avatar_24.webp',
    'assets/parents/man/avatar_27.webp',
    'assets/parents/man/avatar_29.webp',
    'assets/parents/man/avatar_31.webp',
    'assets/parents/man/avatar_34.webp',
    'assets/parents/man/avatar_36.webp',
    'assets/parents/man/avatar_38.webp',
    'assets/parents/man/avatar_42.webp',
    'assets/parents/man/avatar_44.webp',
  ];

  static const List<String> woman = [
    'assets/parents/woman/avatar_01.webp',
    'assets/parents/woman/avatar_03.webp',
    'assets/parents/woman/avatar_05.webp',
    'assets/parents/woman/avatar_08.webp',
    'assets/parents/woman/avatar_10.webp',
    'assets/parents/woman/avatar_12.webp',
    'assets/parents/woman/avatar_14.webp',
    'assets/parents/woman/avatar_16.webp',
    'assets/parents/woman/avatar_18.webp',
    'assets/parents/woman/avatar_21.webp',
    'assets/parents/woman/avatar_23.webp',
    'assets/parents/woman/avatar_25.webp',
    'assets/parents/woman/avatar_28.webp',
    'assets/parents/woman/avatar_30.webp',
    'assets/parents/woman/avatar_32.webp',
    'assets/parents/woman/avatar_35.webp',
    'assets/parents/woman/avatar_37.webp',
    'assets/parents/woman/avatar_39.webp',
    'assets/parents/woman/avatar_43.webp',
    'assets/parents/woman/avatar_45.webp',
  ];

  static const List<String> other = [
    'assets/parents/other/avatar_06.webp',
    'assets/parents/other/avatar_13.webp',
    'assets/parents/other/avatar_19.webp',
    'assets/parents/other/avatar_26.webp',
    'assets/parents/other/avatar_33.webp',
    'assets/parents/other/avatar_40.webp',
  ];

  /// Lista de avatares de responsável de acordo com o campo `sexo`
  /// ('masculino' | 'feminino' | 'outro').
  static List<String> forSexo(String? sexo) {
    switch (sexo) {
      case 'masculino':
        return man;
      case 'outro':
        return other;
      case 'feminino':
      default:
        return woman;
    }
  }

  /// Lista de avatares de criança de acordo com o gênero
  /// ('menino' | 'menina').
  static List<String> forGenero(String? genero) {
    return genero == 'menino' ? boy : girl;
  }

  static const String defaultParentAvatar = 'assets/parents/woman/avatar_01.webp';
  static const String defaultChildAvatar = 'assets/children/girl/1.webp';

  /// Um valor é considerado "caminho de asset" (novo formato) se começar
  /// com "assets/". Qualquer outra coisa (ex: um emoji legado "👩") cai
  /// no fallback de compatibilidade do [AvatarRender].
  static bool isAssetPath(String? value) =>
      value != null && value.startsWith('assets/');
}