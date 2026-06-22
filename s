warning: in the working copy of 'lib/features/dream/presentation/pages/verification_block_dialog.dart', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'lib/features/dream/presentation/widgets/dream_card_widget.dart', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'lib/features/home/presentation/pages/home_page.dart', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'lib/features/settings/features/account_information/presentation/pages/account_information_page.dart', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'lib/features/settings/features/account_information/presentation/pages/email_changed_page.dart', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'lib/features/settings/features/account_information/presentation/widgets/change_email_sheet.dart', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'lib/features/settings/features/account_information/presentation/widgets/change_phone_sheet.dart', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'lib/features/settings/features/account_information/presentation/widgets/info_card.dart', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'lib/features/settings/features/account_information/presentation/widgets/sheet_components.dart', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'lib/features/settings/features/account_verification/presentation/pages/account_settings_page.dart', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'lib/features/settings/features/account_verification/presentation/pages/email_verification_page.dart', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'lib/features/settings/features/change_password/presentation/pages/change_password_page.dart', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'lib/features/settings/presentation/pages/settings_page.dart', LF will be replaced by CRLF the next time Git touches it
[1mdiff --git a/lib/core/theme/app_decorations.dart b/lib/core/theme/app_decorations.dart[m
[1mindex a94ac96..2adaf80 100644[m
[1m--- a/lib/core/theme/app_decorations.dart[m
[1m+++ b/lib/core/theme/app_decorations.dart[m
[36m@@ -1416,4 +1416,384 @@[m [mclass AppDecorations {[m
         colors: colors,[m
       ).createShader(Rect.fromLTWH(0, 0, width, 70));[m
   }[m
[32m+[m
[32m+[m[32m  // ═══════════════════════════════════════════════════════════════════════════════[m
[32m+[m[32m  // ADIÇÕES — HomePage, SettingsPage, AccountInformation, EmailVerification,[m
[32m+[m[32m  //           VerificationBlockDialog, ChangePassword[m
[32m+[m[32m  // ═══════════════════════════════════════════════════════════════════════════════[m
[32m+[m
[32m+[m[32m  // ─── HomePage ─────────────────────────────────────────────────────────────────[m
[32m+[m
[32m+[m[32m  /// Header azul da HomePage (EMPATIA + saudação)[m
[32m+[m[32m  static const BoxDecoration homeHeader = BoxDecoration([m
[32m+[m[32m    gradient: AppTheme.homeHeaderGradient,[m
[32m+[m[32m  );[m
[32m+[m
[32m+[m[32m  /// Container do indicador de notificação no header da HomePage[m
[32m+[m[32m  static BoxDecoration homeNotificationBadge = BoxDecoration([m
[32m+[m[32m    color: Colors.white.withOpacity(0.2),[m
[32m+[m[32m    borderRadius: BorderRadius.circular(12),[m
[32m+[m[32m  );[m
[32m+[m
[32m+[m[32m  /// Card de ad do carrossel da HomePage (cor dinâmica via parâmetro)[m
[32m+[m[32m  static BoxDecoration homeAdCard(List<Color> colors) => BoxDecoration([m
[32m+[m[32m    gradient: LinearGradient([m
[32m+[m[32m      colors: colors,[m
[32m+[m[32m      begin: Alignment.topLeft,[m
[32m+[m[32m      end: Alignment.bottomRight,[m
[32m+[m[32m    ),[m
[32m+[m[32m    borderRadius: BorderRadius.circular(20),[m
[32m+[m[32m    boxShadow: [[m
[32m+[m[32m      BoxShadow([m
[32m+[m[32m        color: colors[0].withOpacity(0.3),[m
[32m+[m[32m        blurRadius: 15,[m
[32m+[m[32m        offset: const Offset(0, 8),[m
[32m+[m[32m      ),[m
[32m+[m[32m    ],[m
[32m+[m[32m  );[m
[32m+[m
[32m+[m[32m  /// Indicador de página ativo do carrossel[m
[32m+[m[32m  static BoxDecoration homePageIndicatorActive = BoxDecoration([m
[32m+[m[32m    color: AppTheme.primaryBlueMid,[m
[32m+[m[32m    borderRadius: BorderRadius.circular(4),[m
[32m+[m[32m  );[m
[32m+[m
[32m+[m[32m  /// Card de sonho na HomePage (branco com sombra suave)[m
[32m+[m[32m  static BoxDecoration homeDreamCard = BoxDecoration([m
[32m+[m[32m    color: Colors.white,[m
[32m+[m[32m    borderRadius: BorderRadius.circular(20),[m
[32m+[m[32m    boxShadow: [[m
[32m+[m[32m      BoxShadow([m
[32m+[m[32m        color: Colors.black.withOpacity(0.05),[m
[32m+[m[32m        blurRadius: 10,[m
[32m+[m[32m        offset: const Offset(0, 4),[m
[32m+[m[32m      ),[m
[32m+[m[32m    ],[m
[32m+[m[32m  );[m
[32m+[m
[32m+[m[32m  /// Avatar do sonho na HomePage (gradiente pink → deep pink)[m
[32m+[m[32m  static const BoxDecoration homeDreamAvatar = BoxDecoration([m
[32m+[m[32m    gradient: AppTheme.homeDreamAvatarGradient,[m
[32m+[m[32m    borderRadius: BorderRadius.all(Radius.circular(15)),[m
[32m+[m[32m  );[m
[32m+[m
[32m+[m[32m  /// Área de imagem/emoji do sonho na HomePage[m
[32m+[m[32m  static BoxDecoration homeDreamImageArea = BoxDecoration([m
[32m+[m[32m    gradient: LinearGradient([m
[32m+[m[32m      colors: [AppTheme.childCardBg, const Color(0xFFFFF9E6)],[m
[32m+[m[32m    ),[m
[32m+[m[32m    borderRadius: BorderRadius.circular(16),[m
[32m+[m[32m    border: Border.all([m
[32m+[m[32m      color: AppTheme.primaryBlueMid.withOpacity(0.2),[m
[32m+[m[32m      width: 2,[m
[32m+[m[32m    ),[m
[32m+[m[32m  );[m
[32m+[m
[32m+[m[32m  /// Badge de progresso do sonho (cor dinâmica por nível)[m
[32m+[m[32m  static BoxDecoration homeDreamProgressBadge(List<Color> colors) =>[m
[32m+[m[32m      BoxDecoration([m
[32m+[m[32m        gradient: LinearGradient(colors: colors),[m
[32m+[m[32m        borderRadius: BorderRadius.circular(15),[m
[32m+[m[32m      );[m
[32m+[m
[32m+[m[32m  /// Botão "Salvar" na HomePage[m
[32m+[m[32m  static BoxDecoration homeSaveButton = BoxDecoration([m
[32m+[m[32m    gradient: AppTheme.homeSaveButtonGradient,[m
[32m+[m[32m    borderRadius: BorderRadius.circular(20),[m
[32m+[m[32m    boxShadow: [[m
[32m+[m[32m      BoxShadow([m
[32m+[m[32m        color: AppTheme.kidsYellow.withOpacity(0.3),[m
[32m+[m[32m        blurRadius: 10,[m
[32m+[m[32m        offset: const Offset(0, 4),[m
[32m+[m[32m      ),[m
[32m+[m[32m    ],[m
[32m+[m[32m  );[m
[32m+[m
[32m+[m[32m  // ─── SettingsPage ─────────────────────────────────────────────────────────────[m
[32m+[m
[32m+[m[32m  /// Header da SettingsPage (pink → yellow → purple)[m
[32m+[m[32m  static const BoxDecoration settingsHeader = BoxDecoration([m
[32m+[m[32m    gradient: AppTheme.settingsHeaderGradient,[m
[32m+[m[32m  );[m
[32m+[m
[32m+[m[32m  /// Card genérico de seção na SettingsPage (branco com sombra)[m
