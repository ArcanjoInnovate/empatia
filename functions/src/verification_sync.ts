// functions/src/verification_sync.ts
//
// Reconciliação centralizada do campo `isVerified`.
//
// Problema que esta função resolve:
//   `isVerified` era gravado só pelo client (Flutter), em dois lugares
//   diferentes (email_controller.dart / profile_repository.dart), cada
//   um fazendo um cross-check pontual no momento do próprio evento.
//   Se o app fechasse, perdesse rede, ou o usuário saísse da tela entre
//   os dois `await`, o `isVerified` ficava travado em `false` para
//   sempre — mesmo com emailVerified e profileCompleted true.
//
// Solução: um RTDB trigger que observa `Users/{uid}` e recalcula
// `isVerified` sempre que `emailVerified` ou `profileCompleted` mudam,
// de forma centralizada e idempotente. Não depende de nenhum client
// terminar uma sequência de escritas — cada escrita individual já
// dispara a reconciliação.
// ─────────────────────────────────────────────────────────────

import { onValueWritten } from 'firebase-functions/v2/database';
import * as logger        from 'firebase-functions/logger';
import { getAdminApp }    from './shared';

// ══════════════════════════════════════════════════════════════
// TRIGGER — Users/{uid}/emailVerified
// ══════════════════════════════════════════════════════════════

// RTDB triggers (Eventarc) precisam rodar na mesma região da instância
// do Realtime Database. A URL sem prefixo de região
// (empatia-34400-default-rtdb.firebaseio.com) indica us-central1 — por
// isso essas duas functions ficam em us-central1, diferente das demais
// functions HTTP do projeto, que seguem em southamerica-east1.
export const reconcileIsVerifiedOnEmail = onValueWritten(
  {
    ref:    'Users/{uid}/emailVerified',
    region: 'us-central1',
  },
  async (event) => {
    await reconcileIsVerified(event.params.uid);
  }
);

// ══════════════════════════════════════════════════════════════
// TRIGGER — Users/{uid}/profileCompleted
// ══════════════════════════════════════════════════════════════

export const reconcileIsVerifiedOnProfile = onValueWritten(
  {
    ref:    'Users/{uid}/profileCompleted',
    region: 'us-central1',
  },
  async (event) => {
    await reconcileIsVerified(event.params.uid);
  }
);

// ══════════════════════════════════════════════════════════════
// LÓGICA COMPARTILHADA — lê o estado atual e recalcula isVerified
// ══════════════════════════════════════════════════════════════

async function reconcileIsVerified(uid: string): Promise<void> {
  getAdminApp();
  const { getDatabase } = require('firebase-admin/database');
  const db      = getDatabase();
  const userRef = db.ref(`Users/${uid}`);

  try {
    // Lê o estado atual direto do banco (não confia no payload do
    // evento) — garante que ambos os campos estão consistentes mesmo
    // se os dois triggers dispararem quase ao mesmo tempo.
    const snap = await userRef.get();
    if (!snap.exists()) return;

    const data = snap.val() as Record<string, unknown>;
    const emailVerified   = data.emailVerified   === true;
    const profileCompleted = data.profileCompleted === true;
    const alreadyVerified  = data.isVerified       === true;

    const shouldBeVerified = emailVerified && profileCompleted;

    if (shouldBeVerified && !alreadyVerified) {
      await userRef.update({
        isVerified:   true,
        isVerifiedAt: Date.now(),
        updatedAt:    Date.now(),
      });
      // Mantém o perfil público em sincronia — mesmo campo que
      // markProfileCompleted() já atualiza no client.
      await db.ref(`UsersPublic/${uid}`).update({
        emailVerified,
        profileCompleted,
        fullyVerified: true,
      });
      logger.info('✅ isVerified reconciliado para true', { uid });
      return;
    }

    // Reversão defensiva: se por algum motivo emailVerified voltar a
    // false (ex.: troca de e-mail em andamento) e isVerified ainda diz
    // true, corrige para não deixar o selo de verificado mentindo.
    if (!shouldBeVerified && alreadyVerified) {
      await userRef.update({
        isVerified: false,
        updatedAt:  Date.now(),
      });
      await db.ref(`UsersPublic/${uid}`).update({
        emailVerified,
        profileCompleted,
        fullyVerified: false,
      });
      logger.info('↩️ isVerified revertido para false (pré-requisito perdido)', { uid });
    }
  } catch (err) {
    logger.error('❌ Erro ao reconciliar isVerified', { uid, err });
  }
}