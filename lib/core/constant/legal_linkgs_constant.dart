import 'package:url_launcher/url_launcher.dart';

/// 📜 LINKS LEGAIS
///
/// Centraliza as URLs dos Termos de Uso e da Política de Privacidade
/// do Empatia — Sonhos de Criança, evitando strings duplicadas pelo app.
abstract final class LegalLinks {
  static const String termsOfUse = 'https://empatiapage-easftwkk.manus.space/terms';
  static const String privacyPolicy = 'https://empatiapage-easftwkk.manus.space/privacy';

  /// Abre uma URL no navegador externo do dispositivo.
  static Future<void> open(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static Future<void> openTerms() => open(termsOfUse);
  static Future<void> openPrivacyPolicy() => open(privacyPolicy);
}