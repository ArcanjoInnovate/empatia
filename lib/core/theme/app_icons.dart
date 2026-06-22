import 'package:flutter/material.dart';

/// Centraliza os [IconData] reutilizados nas telas de perfil/edição.
/// Evita `Icons.xxx` espalhado direto nos widgets — qualquer troca de ícone
/// (ex.: trocar o ícone de câmera em todo o app) passa a ser feita aqui.
///
/// Uso: `Icon(AppIcons.edit, color: ..., size: ...)` no lugar de
/// `Icon(Icons.edit_rounded, ...)`.
class AppIcons {
  AppIcons._();

  // ─── Navegação / ações gerais ────────────────────────────────────────────
  static const IconData back = Icons.arrow_back_ios_new_rounded;
  static const IconData edit = Icons.edit_rounded;
  static const IconData settings = Icons.settings_rounded;
  static const IconData delete = Icons.delete_outline_rounded;
  static const IconData add = Icons.add_circle_rounded;
  static const IconData close = Icons.clear_rounded;
  static const IconData chevronRight = Icons.chevron_right_rounded;
  static const IconData dropdownArrow = Icons.expand_more_rounded;
  static const IconData check = Icons.check_rounded;
  static const IconData checkCircle = Icons.check_circle_rounded;

  // ─── Foto de perfil ───────────────────────────────────────────────────────
  static const IconData camera = Icons.camera_alt_rounded;
  static const IconData gallery = Icons.photo_library_rounded;
  static const IconData person = Icons.person_rounded;

  // ─── Localização ──────────────────────────────────────────────────────────
  static const IconData locationPin = Icons.location_on_rounded;
  static const IconData locationPinOutline = Icons.location_on_outlined;

  // ─── Verificação / segurança ──────────────────────────────────────────────
  static const IconData verified = Icons.verified_rounded;
  static const IconData shieldOutline = Icons.shield_outlined;
  static const IconData email = Icons.email_rounded;

  // ─── Doação ───────────────────────────────────────────────────────────────
  static const IconData donate = Icons.volunteer_activism_rounded;
}