# fix_imports_and_errors.py
import os
import re

print("=" * 70)
print("EMPATIA — Fix Imports + Errors")
print("=" * 70)

root = os.getcwd()

def fix_imports_and_references(rel_path):
    full_path = os.path.join(root, rel_path)
    if not os.path.exists(full_path):
        print(f"❌ Não encontrado: {rel_path}")
        return
    
    with open(full_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original = content
    
    # Garantir imports corretos
    if "AppTheme" in content or "AppDecorations" in content or "AppIcons" in content:
        imports = []
        if "AppTheme" in content and "app_theme.dart" not in content:
            imports.append("import 'package:empatia/core/theme/app_theme.dart';")
        if "AppDecorations" in content and "app_decorations.dart" not in content:
            imports.append("import 'package:empatia/core/theme/app_decorations.dart';")
        if "AppIcons" in content and "app_icons.dart" not in content:
            imports.append("import 'package:empatia/core/theme/app_icons.dart';")
        
        # Adicionar imports após o primeiro import do flutter/material
        if imports:
            import_block = "\n".join(imports)
            content = re.sub(
                r"(import 'package:flutter/material.dart';)",
                r"\1\n" + import_block,
                content
            )
    
    # withOpacity restantes
    content = re.sub(r'\.withOpacity\((\d*\.?\d+)\)', r'.withValues(alpha: \1)', content)
    
    if content != original:
        with open(full_path, 'w', encoding='utf-8', newline='') as f:
            f.write(content)
        print(f"✅ Corrigido: {rel_path}")
    else:
        print(f"-- Sem mudanças: {rel_path}")


# Arquivos com problemas
problem_files = [
    "lib/features/dream/presentation/pages/verification_block_dialog.dart",
    "lib/features/dream/presentation/widgets/dream_card_widget.dart",
    "lib/features/home/presentation/pages/home_page.dart",
    "lib/features/profile/presentation/widgets/profile/profile_children_widget.dart",
    "lib/features/profile/presentation/widgets/profile/profile_dreams_widget.dart",
    "lib/features/settings/presentation/pages/settings_page.dart",
    "lib/core/theme/app_decorations.dart",
]

for file in problem_files:
    fix_imports_and_references(file)

print("\n" + "="*70)
print("✅ Correções aplicadas!")
print("Agora teste:")
print("   flutter analyze")
print("   flutter run")