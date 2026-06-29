// functions/src/index.ts
//
// Ponto de entrada — apenas re-exporta as funções de cada módulo.
// Nenhuma lógica de negócio fica aqui.
//
// ⚠️  NÃO coloque initializeApp(), getDatabase() ou qualquer I/O
//     neste arquivo. O Firebase CLI executa o módulo para descobrir
//     as funções exportadas; I/O no topo causa o erro:
//     "Cannot determine backend specification".
// ─────────────────────────────────────────────────────────────

import { setGlobalOptions } from 'firebase-functions/v2';

// Configuração global — defineString é seguro no topo (sem I/O)
setGlobalOptions({
  maxInstances: 10,
  region:       'southamerica-east1',
});

// ── Autenticação e e-mail ─────────────────────────────────────
export {
  syncEmailOnSignIn,
  syncEmailNow,
  sendEmailVerification,
  sendEmailChangeVerification,
  sendPasswordResetEmail,
} from './auth';

// ── Geolocalização ────────────────────────────────────────────
export {
  searchNeighborhoods,
  getCityCoordinates,
} from './geo';

// ── Mídia ─────────────────────────────────────────────────────
export {
  deleteCloudinaryImage,
} from './media';

// ── Notificações ──────────────────────────────────────────────
export {
  onNewChatMessage,
  onDonationCompleted,
  weeklyRankingReset,
} from './notifications';