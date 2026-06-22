# refactor_theme.py
import os
import re

print("=" * 70)
print("EMPATIA — Refactor de Theme, Icons e Decorations (Python)")
print("=" * 70)

# Detecta a raiz do projeto (procura por pubspec.yaml)
root = None
current = os.getcwd()
for _ in range(10):  # sobe até 10 níveis
    if os.path.exists(os.path.join(current, "pubspec.yaml")):
        root = current
        break
    parent = os.path.dirname(current)
    if parent == current:
        break
    current = parent

if not root:
    print("❌ Não foi possível encontrar a raiz do projeto (pubspec.yaml)")
    exit(1)

print(f"Raiz do projeto detectada: {root}\n")

def replace_in_file(rel_path, replacements):
    full_path = os.path.join(root, rel_path)
    if not os.path.exists(full_path):
        print(f"❌ Arquivo não encontrado: {rel_path}")
        return False
    
    with open(full_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original = content
    changed = False
    
    for old, new in replacements.items():
        if old in content:
            content = content.replace(old, new)
            changed = True
    
    if changed:
        with open(full_path, 'w', encoding='utf-8', newline='') as f:
            f.write(content)
        print(f"✅ {rel_path}")
        return True
    else:
        print(f"-- {rel_path} (sem alterações)")
        return False


# ====================== 1. verification_block_dialog.dart ======================
print("\n[1/12] verification_block_dialog.dart")
replace_in_file("lib/features/dream/presentation/pages/verification_block_dialog.dart", {
    "import 'package:flutter/material.dart';": """import 'package:empatia/core/theme/app_theme.dart';
import 'package:empatia/core/theme/app_decorations.dart';
import 'package:flutter/material.dart';""",
    "_pink": "AppTheme.kidsPink",
    "_navy": "AppTheme.primaryBlue",
    "_purple": "AppTheme.kidsPurple",
    "color: Color(0xFF374151)": "color: AppTheme.textCharcoal",
})

# Substituições complexas com regex
path1 = os.path.join(root, "lib/features/dream/presentation/pages/verification_block_dialog.dart")
if os.path.exists(path1):
    with open(path1, 'r', encoding='utf-8') as f:
        content = f.read()

    content = re.sub(r'decoration: BoxDecoration\(\s*color: Colors\.white,[\s\S]*?offset:\s*const Offset\(0,\s*24\),\s*\),\s*\],', 
                     'decoration: AppDecorations.verificationBlockDialog,', content)
    content = re.sub(r'decoration: const BoxDecoration\(\s*gradient: LinearGradient\(\s*colors:\s*\[_pink,\s*_purple\][\s\S]*?bottomRight,', 
                     'decoration: AppDecorations.verificationBlockBanner,', content)
    content = re.sub(r'color:\s*AppTheme\.kidsPink\.withOpacity\(0\.08\),\s*borderRadius:\s*BorderRadius\.circular\(10\),', 
                     'decoration: AppDecorations.verificationBlockInfoBadge,', content)
    content = re.sub(r'decoration: BoxDecoration\(\s*gradient:\s*const LinearGradient\(\s*colors:\s*\[_pink,\s*_purple\],', 
                     'decoration: AppDecorations.verificationBlockButton,', content)

    with open(path1, 'w', encoding='utf-8', newline='') as f:
        f.write(content)
    print(f"✅ verification_block_dialog.dart (blocos grandes)")


# ====================== Outros arquivos ======================
files_to_refactor = [
    ("lib/features/home/presentation/pages/home_page.dart", {
        "import 'package:flutter/material.dart';": """import 'package:empatia/core/theme/app_theme.dart';
import 'package:empatia/core/theme/app_decorations.dart';
import 'package:empatia/core/theme/app_icons.dart';
import 'package:flutter/material.dart';""",
        "backgroundColor: const Color(0xFFF5F5F5)": "backgroundColor: AppTheme.backgroundColor",
        "Icons.notifications_outlined": "AppIcons.notificationsOutline",
        "icon: Icons.favorite,": "icon: AppIcons.favorite,",
        "icon: Icons.chat_bubble_outline,": "icon: AppIcons.chat,",
        "color: Color(0xFF1E3A8A)": "color: AppTheme.primaryBlue",
        "color: const Color(0xFF2563EB)": "color: AppTheme.primaryBlueMid",
        "color: const Color(0xFFFF6B9D)": "color: AppTheme.kidsPink",
    }),
    ("lib/features/settings/presentation/pages/settings_page.dart", {
        "Icons.arrow_back_ios_new_rounded": "AppIcons.back",
        "Icons.arrow_forward_ios_rounded": "AppIcons.forward",
        "iconColor: const Color(0xFFFF6B9D)": "iconColor: AppTheme.kidsPink",
        "iconColor: const Color(0xFF2563EB)": "iconColor: AppTheme.primaryBlueMid",
    }),
]

for i, (rel_path, replacements) in enumerate(files_to_refactor, 2):
    print(f"[{i}/12] {os.path.basename(rel_path)}")
    replace_in_file(rel_path, replacements)

# Arquivos restantes
remaining = [
    "lib/features/settings/features/account_information/presentation/pages/account_information_page.dart",
    "lib/features/settings/features/account_information/presentation/pages/email_changed_page.dart",
    "lib/features/settings/features/account_information/presentation/widgets/change_email_sheet.dart",
    "lib/features/settings/features/account_information/presentation/widgets/change_phone_sheet.dart",
    "lib/features/settings/features/account_information/presentation/widgets/sheet_components.dart",
    "lib/features/settings/features/account_information/presentation/widgets/info_card.dart",
    "lib/features/settings/features/account_verification/presentation/pages/account_settings_page.dart",
    "lib/features/settings/features/account_verification/presentation/pages/email_verification_page.dart",
    "lib/features/settings/features/change_password/presentation/pages/change_password_page.dart",
]

for i, rel_path in enumerate(remaining, 4):
    print(f"[{i}/12] {os.path.basename(rel_path)}")
    replace_in_file(rel_path, {
        "import 'package:flutter/material.dart';": """import 'package:empatia/core/theme/app_theme.dart';
import 'package:empatia/core/theme/app_decorations.dart';
import 'package:empatia/core/theme/app_icons.dart';
import 'package:flutter/material.dart';""",
    })

# EXTRAS
print("\n[EXTRA] dream_card_widget.dart")
replace_in_file("lib/features/dream/presentation/widgets/dream_card_widget.dart", {
    "Icons.edit_rounded": "AppIcons.edit",
    "Icons.delete_outline_rounded": "AppIcons.delete",
})

print("\n" + "="*70)
print("✅ REFACTOR FINALIZADO!")
print("="*70)
print("Agora rode:")
print("   git diff")
print("   flutter analyze")