r"""
Remove qualquer area verde (circulo decorativo de fundo, fundo solido, etc)
de avatares PNG, incluindo limpeza de spill verde residual nas bordas finas
(cabelo, contorno). Funciona tanto com imagens que ja tem alpha quanto com
imagens com fundo verde solido sem transparencia.

Como usar:
1. pip install pillow numpy scipy
2. python limpar_avatares.py "C:\caminho\para\pasta\npcs"
3. Resultado salvo na subpasta "limpas"

Parametros opcionais:
   --forca 1.5     -> intensidade da correcao de spill nas bordas (padrao 1.5)
   --raio 4        -> raio em pixels para deteccao de borda/fio fino (padrao 4)
   --matiz 35      -> tolerancia de matiz para classificar "verde" (padrao 35 graus)
"""

import sys
import argparse
from pathlib import Path

try:
    from PIL import Image
    import numpy as np
    from scipy import ndimage
except ImportError:
    print("Faltam dependencias. Rode: pip install pillow numpy scipy")
    sys.exit(1)

EXTENSOES_VALIDAS = {".png", ".webp", ".jpg", ".jpeg"}


def rgb_para_hsv(rgb):
    arr = rgb.astype(float) / 255.0
    r, g, b = arr[..., 0], arr[..., 1], arr[..., 2]
    maxc = np.max(arr, axis=-1)
    minc = np.min(arr, axis=-1)
    v = maxc
    delta = maxc - minc
    s = np.where(maxc == 0, 0, delta / np.where(maxc == 0, 1, maxc))

    h = np.zeros_like(maxc)
    mask = delta != 0
    r_is_max = (maxc == r) & mask
    g_is_max = (maxc == g) & mask
    b_is_max = (maxc == b) & mask

    h[r_is_max] = (60 * ((g[r_is_max] - b[r_is_max]) / delta[r_is_max]) + 360) % 360
    h[g_is_max] = (60 * ((b[g_is_max] - r[g_is_max]) / delta[g_is_max]) + 120) % 360
    h[b_is_max] = (60 * ((r[b_is_max] - g[b_is_max]) / delta[b_is_max]) + 240) % 360

    return h, s, v


def processar(caminho_entrada, caminho_saida, forca=1.5, raio=4, tolerancia_matiz=35):
    img = Image.open(caminho_entrada).convert("RGBA")
    arr = np.array(img).astype(float)
    r, g, b, a = arr[:, :, 0], arr[:, :, 1], arr[:, :, 2], arr[:, :, 3]

    # ---- Passo 1: remover grandes areas verdes opacas (ex: circulo decorativo) ----
    h, s, v = rgb_para_hsv(arr[:, :, :3])
    matiz_verde = 120.0
    dist_matiz = np.minimum(np.abs(h - matiz_verde), 360 - np.abs(h - matiz_verde))
    e_verde_forte = (dist_matiz < tolerancia_matiz) & (s > 0.15) & (v > 0.1) & (a > 0)

    # conecta regioes verdes; mantem so as que tocam a borda da imagem OU sao grandes
    # (assim nao mexe em pequenos detalhes verdes legitimos do personagem, tipo um botao verde)
    estrutura, n = ndimage.label(e_verde_forte)
    altura, largura = e_verde_forte.shape

    remover_fundo_grande = np.zeros_like(e_verde_forte)
    for i in range(1, n + 1):
        comp = estrutura == i
        area = comp.sum()
        # remove qualquer regiao verde conectada que seja razoavelmente grande
        # (fundo solido, circulo decorativo, etc). Mantem so detalhes pequenos
        # (ex: um botao verde, um acessorio verde minusculo)
        if area > 0.005 * altura * largura:
            remover_fundo_grande |= comp

    a = np.where(remover_fundo_grande, 0, a)

    # suaviza a transicao: aplica blur leve no alpha perto dessas bordas recem-criadas
    alpha_suave = ndimage.gaussian_filter(a, sigma=1.0)
    transicao = ndimage.binary_dilation(remover_fundo_grande, iterations=3) & (~remover_fundo_grande)
    a = np.where(transicao, alpha_suave, a)

    arr[:, :, 3] = a

    # ---- Passo 2: limpar spill verde residual nas bordas finas (cabelo etc) ----
    transparente = a < 250
    dilatada = ndimage.binary_dilation(transparente, iterations=raio)
    regiao_borda = dilatada & (~transparente)

    excesso_verde = np.clip(g - np.maximum(r, b), 0, None)

    escuro_vizinho = ndimage.minimum_filter(np.maximum(r, np.maximum(g, b)), size=2 * raio + 1) < 60
    regiao_fio_fino = escuro_vizinho & (excesso_verde > 15)

    regiao_aplicavel = regiao_borda | regiao_fio_fino
    aplicar = (excesso_verde > 4) & regiao_aplicavel

    fator = np.where(aplicar, forca, 0.0)
    arr[:, :, 1] = np.clip(g - excesso_verde * fator, 0, 255)

    reducao_alpha = np.clip(excesso_verde * fator * 1.5, 0, 255)
    arr[:, :, 3] = np.where(aplicar, np.clip(arr[:, :, 3] - reducao_alpha, 0, 255), arr[:, :, 3])

    resultado = Image.fromarray(arr.astype(np.uint8), "RGBA")
    resultado.save(caminho_saida, "PNG")

    pct_fundo_removido = 100 * remover_fundo_grande.sum() / (altura * largura)
    return pct_fundo_removido


def main():
    parser = argparse.ArgumentParser(description="Remove fundo/circulo verde e spill residual de avatares.")
    parser.add_argument("pasta", help="Caminho da pasta com as imagens")
    parser.add_argument("--forca", type=float, default=1.5, help="Intensidade da correcao de spill (padrao: 1.5)")
    parser.add_argument("--raio", type=int, default=4, help="Raio em pixels para deteccao de borda (padrao: 4)")
    parser.add_argument("--matiz", type=float, default=35, help="Tolerancia de matiz verde em graus (padrao: 35)")
    args = parser.parse_args()

    pasta_entrada = Path(args.pasta)
    if not pasta_entrada.is_dir():
        print(f"Pasta nao encontrada: {pasta_entrada}")
        sys.exit(1)

    pasta_saida = pasta_entrada / "limpas"
    pasta_saida.mkdir(exist_ok=True)

    arquivos = [f for f in pasta_entrada.iterdir() if f.is_file() and f.suffix.lower() in EXTENSOES_VALIDAS]

    if not arquivos:
        print("Nenhuma imagem encontrada nessa pasta.")
        sys.exit(0)

    print(f"Encontradas {len(arquivos)} imagens. Processando...\n")

    sucesso = 0
    falhas = []

    for arquivo in arquivos:
        nome_saida = arquivo.stem + ".png"
        caminho_saida = pasta_saida / nome_saida
        try:
            pct = processar(arquivo, caminho_saida, forca=args.forca, raio=args.raio, tolerancia_matiz=args.matiz)
            print(f"OK  {arquivo.name} -> limpas/{nome_saida}  ({pct:.1f}% da imagem era fundo verde removido)")
            sucesso += 1
        except Exception as e:
            print(f"ERRO  {arquivo.name}: {e}")
            falhas.append(arquivo.name)

    print(f"\nConcluido: {sucesso}/{len(arquivos)} imagens processadas.")
    print(f"Salvas em: {pasta_saida}")
    if falhas:
        print(f"Falharam: {', '.join(falhas)}")


if __name__ == "__main__":
    main()
