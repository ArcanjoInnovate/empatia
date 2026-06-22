import 'package:flutter/material.dart';

/// Centraliza os [IconData] reutilizados em todo o app.
/// Evita `Icons.xxx` espalhado direto nos widgets — qualquer troca de ícone
/// passa a ser feita aqui.
///
/// Uso: `Icon(AppIcons.edit, color: ..., size: ...)` no lugar de
/// `Icon(Icons.edit_rounded, ...)`
class AppIcons {
  AppIcons._();

  // ─── Navegação / ações gerais ────────────────────────────────────────────
  static const IconData back = Icons.arrow_back_ios_new_rounded;
  static const IconData forward = Icons.arrow_forward_ios_rounded;   // <<NOVO>>
  static const IconData edit = Icons.edit_rounded;
  static const IconData settings = Icons.settings_rounded;
  static const IconData delete = Icons.delete_outline_rounded;
  static const IconData deleteForever = Icons.delete_forever_rounded; // <<NOVO>>
  static const IconData add = Icons.add_circle_rounded;
  static const IconData close = Icons.clear_rounded;
  static const IconData closeRound = Icons.close_rounded;            // <<NOVO>> close sem clear
  static const IconData chevronRight = Icons.chevron_right_rounded;
  static const IconData dropdownArrow = Icons.expand_more_rounded;
  static const IconData check = Icons.check_rounded;
  static const IconData checkCircle = Icons.check_circle_rounded;
  static const IconData checkCircleOutline = Icons.check_circle_outline; // <<NOVO>>
  static const IconData moreVert = Icons.more_vert_rounded;           // <<NOVO>> menu de 3 pontos
  static const IconData refresh = Icons.refresh_rounded;              // <<NOVO>>
  static const IconData info = Icons.info_rounded;                    // <<NOVO>>
  static const IconData zoomOut = Icons.zoom_out_map_rounded;         // <<NOVO>> fullscreen/zoom

  // ─── Foto de perfil ───────────────────────────────────────────────────────
  static const IconData camera = Icons.camera_alt_rounded;
  static const IconData photoCamera = Icons.photo_camera_rounded;     // <<NOVO>> alias foto
  static const IconData gallery = Icons.photo_library_rounded;
  static const IconData addPhoto = Icons.add_photo_alternate_rounded; // <<NOVO>>
  static const IconData person = Icons.person_rounded;
  static const IconData brokenImage = Icons.broken_image_rounded;     // <<NOVO>> imagem quebrada

  // ─── Localização ──────────────────────────────────────────────────────────
  static const IconData locationPin = Icons.location_on_rounded;
  static const IconData locationPinOutline = Icons.location_on_outlined;

  // ─── Verificação / segurança ──────────────────────────────────────────────
  static const IconData verified = Icons.verified_rounded;
  static const IconData shieldOutline = Icons.shield_outlined;
  static const IconData privacy = Icons.privacy_tip_rounded;          // <<NOVO>>
  static const IconData block = Icons.block_rounded;                  // <<NOVO>>
  static const IconData lock = Icons.lock_rounded;                    // <<NOVO>>
  static const IconData lockOutline = Icons.lock_outline_rounded;     // <<NOVO>>
  static const IconData lockReset = Icons.lock_reset_rounded;         // <<NOVO>>

  // ─── E-mail / comunicação ────────────────────────────────────────────────
  static const IconData email = Icons.email_rounded;
  static const IconData alternateEmail = Icons.alternate_email_rounded; // <<NOVO>> @ (campo e-mail)
  static const IconData markEmailRead = Icons.mark_email_read_rounded;  // <<NOVO>> e-mail lido
  static const IconData markEmailUnread = Icons.mark_email_unread_rounded; // <<NOVO>> e-mail não lido
  static const IconData phone = Icons.phone_rounded;                  // <<NOVO>>

  // ─── Visibilidade / senha ─────────────────────────────────────────────────
  static const IconData visibility = Icons.visibility_rounded;        // <<NOVO>>
  static const IconData visibilityOff = Icons.visibility_off_rounded; // <<NOVO>>

  // ─── Interações sociais ───────────────────────────────────────────────────
  static const IconData favorite = Icons.favorite;                    // <<NOVO>> coração preenchido
  static const IconData favoriteRounded = Icons.favorite_rounded;     // <<NOVO>> coração rounded
  static const IconData chat = Icons.chat_bubble_outline;             // <<NOVO>>

  // ─── Conta / sessão ───────────────────────────────────────────────────────
  static const IconData logout = Icons.logout_rounded;                // <<NOVO>>
  static const IconData login = Icons.login_rounded;                  // <<NOVO>>

  // ─── Notificações ─────────────────────────────────────────────────────────
  static const IconData notifications = Icons.notifications_rounded;  // <<NOVO>>
  static const IconData notificationsOutline = Icons.notifications_outlined; // <<NOVO>>

  // ─── Calendário / data ────────────────────────────────────────────────────
  static const IconData calendar = Icons.calendar_month_rounded;      // <<NOVO>>
  static const IconData dateRange = Icons.date_range_rounded;         // <<NOVO>>
  static const IconData schedule = Icons.schedule_rounded;            // <<NOVO>>

  // ─── Informações / documentos ────────────────────────────────────────────
  static const IconData description = Icons.description_rounded;      // <<NOVO>> termos de uso
  static const IconData bugReport = Icons.bug_report_rounded;         // <<NOVO>>
  static const IconData tipsAndUpdates = Icons.tips_and_updates_rounded; // <<NOVO>>

  // ─── Erros ───────────────────────────────────────────────────────────────
  static const IconData errorOutline = Icons.error_outline_rounded;   // <<NOVO>>

  // ─── Doação ───────────────────────────────────────────────────────────────
  static const IconData donate = Icons.volunteer_activism_rounded;
}