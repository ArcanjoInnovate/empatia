#!/usr/bin/env python3
"""
Migração de assets PNG -> WebP (otimizado) para o app Empatia.

O que o script faz:
  - Percorre recursivamente a pasta de assets (children/boy, children/girl,
    parents/man, parents/woman, parents/other, etc.)
  - Redimensiona cada imagem (mantendo proporção, com fundo transparente
    preservado) para um tamanho máximo configurável — avatares não
    precisam de 1024/1920px, isso só infla o APK.
  - Converte para WebP com qualidade configurável.
  - Salva em uma pasta de saída espelhando a mesma estrutura de pastas,
    SEM mexer nos arquivos originais (assets/ continua intacto até você
    decidir substituir).
  - Gera um relatório (assets_webp_manifest.json) listando todos os
    arquivos convertidos com caminho antigo (.png) e novo (.webp), útil
    para depois fazer o find&replace nos dados do app/Firebase.

Requisitos:
    pip install Pillow --break-system-packages   (ou em venv)

Uso básico:
    python3 migrate_assets_to_webp.py \
        --input assets \
        --output assets_webp \
        --max-size 512 \
        --quality 85

Depois de validar o resultado:
    1) Confira o tamanho final:  du -sh assets_webp
    2) Se estiver tudo certo, substitua a pasta antiga:
         rm -rf assets && mv assets_webp assets
    3) Atualize o pubspec.yaml (extensões .png -> .webp) se você referenciar
       arquivos individualmente, ou mantenha asset por diretório se já
       estiver assim configurado.
    4) Use o assets_webp_manifest.json para atualizar referências salvas
       no banco (ex: campo avatarPath de usuários/filhos).
"""

import argparse
import json
import sys
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    print("Pillow não instalado. Rode: pip install Pillow --break-system-packages")
    sys.exit(1)

VALID_EXT = {".png", ".jpg", ".jpeg", ".bmp", ".tiff"}


def convert_image(src: Path, dst: Path, max_size: int, quality: int) -> dict:
    with Image.open(src) as im:
        im = im.convert("RGBA") if im.mode != "RGBA" else im

        # Redimensiona mantendo proporção, só se for maior que max_size
        w, h = im.size
        scale = min(max_size / w, max_size / h, 1.0)
        if scale < 1.0:
            new_size = (max(1, round(w * scale)), max(1, round(h * scale)))
            im = im.resize(new_size, Image.LANCZOS)

        dst.parent.mkdir(parents=True, exist_ok=True)
        im.save(dst, "WEBP", quality=quality, method=6)

    return {
        "original": str(src),
        "converted": str(dst),
        "original_bytes": src.stat().st_size,
        "converted_bytes": dst.stat().st_size,
    }


def main():
    parser = argparse.ArgumentParser(description="Migra assets PNG para WebP otimizado.")
    parser.add_argument("--input", default="assets", help="Pasta de entrada (ex: assets)")
    parser.add_argument("--output", default="assets_webp", help="Pasta de saída")
    parser.add_argument("--max-size", type=int, default=512,
                         help="Tamanho máximo (px) da maior dimensão. Padrão: 512")
    parser.add_argument("--quality", type=int, default=85,
                         help="Qualidade WebP (0-100). Padrão: 85")
    parser.add_argument("--manifest", default="assets_webp_manifest.json",
                         help="Arquivo de relatório/mapeamento gerado")
    args = parser.parse_args()

    input_dir = Path(args.input)
    output_dir = Path(args.output)

    if not input_dir.exists():
        print(f"Pasta de entrada não encontrada: {input_dir}")
        sys.exit(1)

    files = [p for p in input_dir.rglob("*") if p.suffix.lower() in VALID_EXT]
    if not files:
        print("Nenhuma imagem encontrada para converter.")
        sys.exit(0)

    print(f"Encontradas {len(files)} imagens em '{input_dir}'. Convertendo para WebP...")

    results = []
    total_before = 0
    total_after = 0

    for i, src in enumerate(sorted(files), start=1):
        rel = src.relative_to(input_dir)
        dst = output_dir / rel.with_suffix(".webp")
        try:
            info = convert_image(src, dst, args.max_size, args.quality)
            results.append(info)
            total_before += info["original_bytes"]
            total_after += info["converted_bytes"]
            print(f"  [{i}/{len(files)}] {rel} "
                  f"({info['original_bytes']/1024:.0f}KB -> {info['converted_bytes']/1024:.0f}KB)")
        except Exception as e:
            print(f"  ERRO ao converter {src}: {e}")

    manifest_path = Path(args.manifest)
    manifest_path.write_text(json.dumps(results, indent=2, ensure_ascii=False), encoding="utf-8")

    print("\nConcluído.")
    print(f"  Total antes:  {total_before/1024/1024:.2f} MB")
    print(f"  Total depois: {total_after/1024/1024:.2f} MB")
    if total_before:
        print(f"  Redução:      {(1 - total_after/total_before)*100:.1f}%")
    print(f"  Saída:        {output_dir}/")
    print(f"  Manifesto:    {manifest_path}")


if __name__ == "__main__":
    main()
