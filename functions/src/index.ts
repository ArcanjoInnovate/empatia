import { setGlobalOptions } from "firebase-functions/v2";
import { onRequest } from "firebase-functions/v2/https";
import { defineString} from "firebase-functions/params";
import * as logger from "firebase-functions/logger";
import { Request, Response } from "express";

const axios = require("axios") as any;
const cloudinary = require("cloudinary").v2;

setGlobalOptions({
  maxInstances: 10,
  region: "southamerica-east1",
});

// ══════════════════════════════════════════════════════════════
// DEFINIÇÃO DE PARÂMETROS
// ══════════════════════════════════════════════════════════════

const googlePlacesApiKey  = defineString("GOOGLE_PLACES_API_KEY");
const cloudinaryCloudName = defineString("CLOUDINARY_CLOUD_NAME");
const cloudinaryApiKey    = defineString("CLOUDINARY_API_KEY");
const cloudinaryApiSecret = defineString("CLOUDINARY_API_SECRET");

// ══════════════════════════════════════════════════════════════
// HELPERS
// ══════════════════════════════════════════════════════════════

function applyCors(res: Response): void {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");
}

function extractNeighborhood(fullDescription: string): string {
  const parts = fullDescription.split(",");
  return parts.length > 0 ? parts[0].trim() : fullDescription;
}

// ══════════════════════════════════════════════════════════════
// DELETAR IMAGEM DO CLOUDINARY
// ══════════════════════════════════════════════════════════════

export const deleteCloudinaryImage = onRequest(
  {
    region: "southamerica-east1",
    cors: false,
  },
  async (req: Request, res: Response) => {
    applyCors(res);

    if (req.method === "OPTIONS") {
      res.status(204).send("");
      return;
    }

    if (req.method !== "POST") {
      res.status(405).json({ error: "Método não permitido" });
      return;
    }

    try {
      const { publicId } = req.body;

      if (!publicId) {
        res.status(400).json({ error: "publicId não fornecido" });
        return;
      }

      // ✅ CORRIGIDO: usa .value() em todos os parâmetros, não process.env
      const cloudName = cloudinaryCloudName.value();
      const apiKey    = cloudinaryApiKey.value();
      const apiSecret = cloudinaryApiSecret.value();

      logger.info("🔧 Configurando Cloudinary...", {
        hasCloudName: !!cloudName,
        hasApiKey:    !!apiKey,
        hasApiSecret: !!apiSecret,
      });

      cloudinary.config({
        cloud_name: cloudName,
        api_key:    apiKey,
        api_secret: apiSecret,
      });

      logger.info(`🗑️ Deletando imagem: ${publicId}`);

      const result = await cloudinary.uploader.destroy(publicId);

      logger.info("✅ Resultado da deleção:", JSON.stringify(result));

      if (result.result === "ok") {
        res.status(200).json({
          success: true,
          message: "Imagem deletada com sucesso",
          publicId,
          result: result.result,
        });
      } else if (result.result === "not found") {
        // ✅ Também retorna 200 — imagem ausente não é erro do servidor
        res.status(200).json({
          success: true,
          message: "Imagem não encontrada (pode já ter sido deletada)",
          publicId,
          result: result.result,
        });
      } else {
        res.status(400).json({
          success: false,
          message: "Erro ao deletar imagem",
          result: result.result,
        });
      }
    } catch (error: unknown) {
      logger.error("❌ Erro ao deletar imagem:", error);
      const errorMessage =
        error instanceof Error ? error.message : String(error);
      res.status(500).json({
        error: "Erro interno do servidor",
        details: errorMessage,
      });
    }
  }
);

// ══════════════════════════════════════════════════════════════
// BUSCAR BAIRROS
// ══════════════════════════════════════════════════════════════

export const searchNeighborhoods = onRequest(
  {
    region: "southamerica-east1",
    cors: false,
  },
  async (req: Request, res: Response) => {
    applyCors(res);

    if (req.method === "OPTIONS") {
      res.status(204).send("");
      return;
    }

    if (req.method !== "POST") {
      res.status(405).json({ error: "Método não permitido" });
      return;
    }

    const body = (req.body as any)?.data ?? req.body;
    const { query, city, state, lat, lng } = body ?? {};

    if (!query || !city || !state) {
      res.status(400).json({ error: "Query, city e state são obrigatórios" });
      return;
    }

    const apiKey = googlePlacesApiKey.value();
    if (!apiKey) {
      logger.error("API Key não configurada!");
      res.status(500).json({ error: "API Key não configurada" });
      return;
    }

    try {
      const params: Record<string, string | number> = {
        input: `${query}, ${city}, ${state}, Brasil`,
        types: "sublocality|neighborhood|political",
        components: "country:br",
        language: "pt-BR",
        key: apiKey,
      };

      if (lat && lng) {
        params.location = `${lat},${lng}`;
        params.radius = 20000;
      }

      logger.info("Buscando bairros:", { query, city, state });

      const response = await axios.get(
        "https://maps.googleapis.com/maps/api/place/autocomplete/json",
        { params }
      );

      if (response.data.status === "OK") {
        const predictions = response.data.predictions
          .filter((pred: any) =>
            pred.description.toLowerCase().includes(city.toLowerCase())
          )
          .map((pred: any) => ({
            place_id: pred.place_id,
            description: pred.description,
            neighborhood: extractNeighborhood(pred.description),
          }));

        logger.info(`Encontrados ${predictions.length} bairros`);
        res.status(200).json({ status: "OK", predictions });
        return;
      }

      res.status(200).json(response.data);
    } catch (error: unknown) {
      logger.error("Erro ao buscar bairros:", error);
      const errorMessage =
        error instanceof Error ? error.message : "Erro ao buscar bairros";
      res.status(500).json({ error: errorMessage });
    }
  }
);

// ══════════════════════════════════════════════════════════════
// BUSCAR COORDENADAS DA CIDADE
// ══════════════════════════════════════════════════════════════

export const getCityCoordinates = onRequest(
  {
    region: "southamerica-east1",
    cors: false,
  },
  async (req: Request, res: Response) => {
    applyCors(res);

    if (req.method === "OPTIONS") {
      res.status(204).send("");
      return;
    }

    if (req.method !== "POST") {
      res.status(405).json({ error: "Método não permitido" });
      return;
    }

    const body = (req.body as any)?.data ?? req.body;
    const { city, state } = body ?? {};

    if (!city || !state) {
      res.status(400).json({ error: "City e state são obrigatórios" });
      return;
    }

    const apiKey = googlePlacesApiKey.value();
    if (!apiKey) {
      res.status(500).json({ error: "API Key não configurada" });
      return;
    }

    try {
      logger.info("Buscando coordenadas:", { city, state });

      const response = await axios.get(
        "https://maps.googleapis.com/maps/api/geocode/json",
        {
          params: {
            address: `${city}, ${state}, Brasil`,
            key: apiKey,
          },
        }
      );

      if (response.data.status === "OK" && response.data.results.length > 0) {
        const location = response.data.results[0].geometry.location;
        logger.info("Coordenadas encontradas:", location);
        res.status(200).json({ lat: location.lat, lng: location.lng });
        return;
      }

      res.status(200).json(null);
    } catch (error: unknown) {
      logger.error("Erro ao buscar coordenadas:", error);
      const errorMessage =
        error instanceof Error
          ? error.message
          : "Erro ao buscar coordenadas";
      res.status(500).json({ error: errorMessage });
    }
  }
);
