// functions/src/geo.ts
//
// Funções relacionadas a geolocalização:
//   - searchNeighborhoods — autocomplete de bairros via Google Places
//   - getCityCoordinates  — coordenadas lat/lng de uma cidade
// ─────────────────────────────────────────────────────────────

import { onRequest }         from 'firebase-functions/v2/https';
import { defineString }      from 'firebase-functions/params';
import { Request, Response } from 'express';
import { applyCors, extractNeighborhood } from './shared';

const googlePlacesApiKey = defineString('GOOGLE_PLACES_API_KEY');

// ══════════════════════════════════════════════════════════════
// BUSCAR BAIRROS
// ══════════════════════════════════════════════════════════════

export const searchNeighborhoods = onRequest(
  { region: 'southamerica-east1', cors: false },
  async (req: Request, res: Response) => {
    const axios = require('axios') as any;

    applyCors(res);
    if (req.method === 'OPTIONS') { res.status(204).send(''); return; }
    if (req.method !== 'POST')    { res.status(405).json({ error: 'Método não permitido' }); return; }

    const body = (req.body as any)?.data ?? req.body;
    const { query, city, state, lat, lng } = body ?? {};

    if (!query || !city || !state) {
      res.status(400).json({ error: 'Query, city e state são obrigatórios' });
      return;
    }

    const apiKey = googlePlacesApiKey.value();
    if (!apiKey) { res.status(500).json({ error: 'API Key não configurada' }); return; }

    try {
      const params: Record<string, string | number> = {
        input:      `${query}, ${city}, ${state}, Brasil`,
        types:      'sublocality|neighborhood|political',
        components: 'country:br',
        language:   'pt-BR',
        key:        apiKey,
      };

      if (lat && lng) {
        params.location = `${lat},${lng}`;
        params.radius   = 20000;
      }

      const response = await axios.get(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json',
        { params }
      );

      if (response.data.status === 'OK') {
        const predictions = response.data.predictions
          .filter((pred: any) => pred.description.toLowerCase().includes(city.toLowerCase()))
          .map((pred: any) => ({
            place_id:     pred.place_id,
            description:  pred.description,
            neighborhood: extractNeighborhood(pred.description),
          }));

        res.status(200).json({ status: 'OK', predictions });
        return;
      }

      res.status(200).json(response.data);
    } catch (error: unknown) {
      const errorMessage = error instanceof Error ? error.message : 'Erro ao buscar bairros';
      res.status(500).json({ error: errorMessage });
    }
  }
);

// ══════════════════════════════════════════════════════════════
// BUSCAR COORDENADAS DA CIDADE
// ══════════════════════════════════════════════════════════════

export const getCityCoordinates = onRequest(
  { region: 'southamerica-east1', cors: false },
  async (req: Request, res: Response) => {
    const axios = require('axios') as any;

    applyCors(res);
    if (req.method === 'OPTIONS') { res.status(204).send(''); return; }
    if (req.method !== 'POST')    { res.status(405).json({ error: 'Método não permitido' }); return; }

    const body = (req.body as any)?.data ?? req.body;
    const { city, state } = body ?? {};

    if (!city || !state) {
      res.status(400).json({ error: 'City e state são obrigatórios' });
      return;
    }

    const apiKey = googlePlacesApiKey.value();
    if (!apiKey) { res.status(500).json({ error: 'API Key não configurada' }); return; }

    try {
      const response = await axios.get(
        'https://maps.googleapis.com/maps/api/geocode/json',
        { params: { address: `${city}, ${state}, Brasil`, key: apiKey } }
      );

      if (response.data.status === 'OK' && response.data.results.length > 0) {
        const location = response.data.results[0].geometry.location;
        res.status(200).json({ lat: location.lat, lng: location.lng });
        return;
      }

      res.status(200).json(null);
    } catch (error: unknown) {
      const errorMessage = error instanceof Error ? error.message : 'Erro ao buscar coordenadas';
      res.status(500).json({ error: errorMessage });
    }
  }
);