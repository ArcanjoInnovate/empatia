// functions/src/media.ts
//
// Funções relacionadas a mídia e assets:
//   - deleteCloudinaryImage — remove imagem do Cloudinary
// ─────────────────────────────────────────────────────────────

import { onRequest }         from 'firebase-functions/v2/https';
import { defineString }      from 'firebase-functions/params';
import * as logger           from 'firebase-functions/logger';
import { Request, Response } from 'express';
import { applyCors }         from './shared';

const cloudinaryCloudName = defineString('CLOUDINARY_CLOUD_NAME');
const cloudinaryApiKey    = defineString('CLOUDINARY_API_KEY');
const cloudinaryApiSecret = defineString('CLOUDINARY_API_SECRET');

// ══════════════════════════════════════════════════════════════
// DELETAR IMAGEM DO CLOUDINARY
// ══════════════════════════════════════════════════════════════

export const deleteCloudinaryImage = onRequest(
  { region: 'southamerica-east1', cors: false },
  async (req: Request, res: Response) => {
    const cloudinary = require('cloudinary').v2;

    applyCors(res);
    if (req.method === 'OPTIONS') { res.status(204).send(''); return; }
    if (req.method !== 'POST')    { res.status(405).json({ error: 'Método não permitido' }); return; }

    try {
      const { publicId } = req.body;
      if (!publicId) { res.status(400).json({ error: 'publicId não fornecido' }); return; }

      cloudinary.config({
        cloud_name: cloudinaryCloudName.value(),
        api_key:    cloudinaryApiKey.value(),
        api_secret: cloudinaryApiSecret.value(),
      });

      logger.info(`🗑️ Deletando imagem: ${publicId}`);
      const result = await cloudinary.uploader.destroy(publicId);

      if (result.result === 'ok') {
        res.status(200).json({ success: true, message: 'Imagem deletada com sucesso', publicId, result: result.result });
      } else if (result.result === 'not found') {
        res.status(200).json({ success: true, message: 'Imagem não encontrada', publicId, result: result.result });
      } else {
        res.status(400).json({ success: false, message: 'Erro ao deletar imagem', result: result.result });
      }
    } catch (error: unknown) {
      logger.error('❌ Erro ao deletar imagem:', error);
      const errorMessage = error instanceof Error ? error.message : String(error);
      res.status(500).json({ error: 'Erro interno do servidor', details: errorMessage });
    }
  }
);