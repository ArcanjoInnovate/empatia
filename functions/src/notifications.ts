// functions/src/notifications.ts
//
// âš ï¸  Assim como em index.ts: NÃƒO chame initializeApp()/getDatabase() no
//     topo do mÃ³dulo. O Firebase CLI carrega este arquivo para descobrir
//     as funÃ§Ãµes exportadas; I/O no topo (initializeApp sÃ­ncrono tentando
//     detectar credenciais/projeto) pode travar essa descoberta e gerar
//     o erro "Cannot determine backend specification. Timeout after 10000".
//     Por isso a inicializaÃ§Ã£o do Admin SDK Ã© sempre lazy, dentro de getDB().
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

import { onValueCreated, onValueUpdated } from 'firebase-functions/v2/database';
import { onSchedule }                     from 'firebase-functions/v2/scheduler';
import * as logger                         from 'firebase-functions/logger';
import { getAdminApp }                     from './shared';

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// HELPERS LOCAIS
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

function getDB() {
  getAdminApp();
  const { getDatabase } = require('firebase-admin/database');
  return getDatabase();
}

function getFCM() {
  getAdminApp();
  const { getMessaging } = require('firebase-admin/messaging');
  return getMessaging();
}

function weekKey(): string {
  const now   = new Date();
  const year  = now.getFullYear();
  const start = new Date(year, 0, 1);
  const week  = Math.ceil(((now.getTime() - start.getTime()) / 86400000 + 1) / 7);
  return `${year}-W${String(week).padStart(2, '0')}`;
}

async function getUserPublic(db: any, uid: string): Promise<{name: string; emoji: string}> {
  try {
    const snap = await db.ref(`UsersPublic/${uid}`).get();
    if (!snap.exists()) return { name: 'AlguÃ©m', emoji: 'ðŸ‘¤' };
    const data = snap.val();
    return {
      name:  data.name         ?? 'AlguÃ©m',
      emoji: data.profileEmoji ?? 'ðŸ‘¤',
    };
  } catch {
    return { name: 'AlguÃ©m', emoji: 'ðŸ‘¤' };
  }
}

async function writeNotification(
  db: any,
  uid: string,
  payload: Record<string, unknown>,
): Promise<void> {
  const ref = db.ref(`Notifications/${uid}`).push();
  await ref.set({ ...payload, timestamp: Date.now(), read: false });

  try {
    const tokenSnap = await db.ref(`Users/${uid}/fcmToken`).get();
    const token = tokenSnap.val() as string | null;

    logger.info('[writeNotification] token lookup', {
      uid,
      hasToken: !!token,
      tokenPrefix: token ? token.slice(0, 20) : null,
    });

    if (!token) return;

    // Conta notificaÃ§Ãµes nÃ£o lidas para o badge real no iOS
    const notifsSnap = await db.ref(`Notifications/${uid}`).get();
    let unreadCount = 0;
    if (notifsSnap.exists()) {
      const notifs = notifsSnap.val() as Record<string, any>;
      unreadCount = Object.values(notifs).filter(
        (n: any) => n && n.read === false
      ).length;
    }

    const result = await getFCM().send({
      token,
      notification: {
        title: payload['title'] as string,
        body:  payload['body']  as string,
      },
      android: {
        priority: 'high',
        notification: { sound: 'default' },
      },
      apns: {
        payload: { aps: { sound: 'default', badge: unreadCount } },
      },
      data: {
        type:         String(payload['type']   ?? ''),
        chatId:       String(payload['chatId'] ?? ''),
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
    });

    logger.info('[writeNotification] FCM sent', { uid, result });
  } catch (fcmErr) {
    logger.error('[writeNotification] FCM push falhou', { uid, fcmErr });
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// HELPER â€” detecta primeiro contato no contexto atual do item
//
// LÃ³gica:
//   â€¢ O Flutter grava `item_changed_at` (timestamp) no nÃ³ Chats/{chatId}
//     sempre que o item muda (updateContext) ou ao criar o chat (valor 0).
//   â€¢ "Primeiro contato no contexto" = ainda nÃ£o existe nenhuma mensagem
//     de texto com timestamp > item_changed_at enviada pelo RECEIVER
//     (ou por qualquer um, dependendo da semÃ¢ntica desejada).
//   â€¢ NÃ£o usa orderByChild('timestamp') â†’ sem necessidade de index extra.
//     LÃª todas as mensagens e filtra em memÃ³ria. AceitÃ¡vel porque:
//       â€“ A query sÃ³ roda uma vez por mensagem enviada.
//       â€“ Chats com muitas mensagens jÃ¡ terÃ£o item_changed_at recente,
//         entÃ£o msgCount serÃ¡ > 0 quase imediatamente.
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
async function isFirstMessageInContext(
  db: any,
  chatId: string,
  itemChangedAt: number,
  currentMsgTimestamp: number,
): Promise<boolean> {
  try {
    const snap = await db.ref(`ChatMessages/${chatId}`).get();
    if (!snap.exists()) return true;

    const msgs = snap.val() as Record<string, any>;

    // Conta mensagens de texto com timestamp >= item_changed_at
    // excluindo a mensagem atual (que acabou de ser criada).
    let countInContext = 0;
    for (const [, m] of Object.entries(msgs)) {
      if (!m || typeof m !== 'object') continue;
      if (m.type && m.type !== 'text') continue;           // ignora eventos de entrega
      const ts = (m.timestamp as number) ?? 0;
      if (ts < itemChangedAt) continue;                    // pertence a item anterior
      if (ts === currentMsgTimestamp) continue;            // Ã© a prÃ³pria mensagem atual
      countInContext++;
    }

    return countInContext === 0; // nenhuma outra mensagem neste contexto â†’ Ã© a primeira
  } catch (err) {
    logger.warn('[isFirstMessageInContext] erro ao contar mensagens', { chatId, err });
    return false; // em caso de erro, trata como nÃ£o-primeira (seguro)
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// 1. MENSAGEM NOVA NO CHAT
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

export const onNewChatMessage = onValueCreated(
  {
    ref:      '/ChatMessages/{chatId}/{msgId}',
    instance: 'empatia-34400-default-rtdb',
    region:   'us-central1',
  },
  async (event) => {
    const db = getDB();

    const chatId  = event.params.chatId;
    const msgData = event.data.val();
    if (!msgData) return;

    const senderId = msgData.sender_id as string | undefined;
    const msgType  = msgData.type      as string | undefined;
    const msgText  = (msgData.text     as string | undefined) ?? '';
    const msgTs    = (msgData.timestamp as number | undefined) ?? Date.now();

    if (!senderId) return;

    const chatSnap = await db.ref(`Chats/${chatId}`).get();
    if (!chatSnap.exists()) return;
    const chatData = chatSnap.val();

    const user1:          string = chatData.user1         ?? '';
    const user2:          string = chatData.user2         ?? '';
    const itemTitle:      string = chatData.item_title    ?? '';
    const itemType:       string = chatData.item_type     ?? '';
    // item_changed_at = 0 em chats novos (toda mensagem Ã© "primeiro contato")
    // item_changed_at = ServerValue.timestamp quando o item mudou
    const itemChangedAt: number  = (chatData.item_changed_at as number) ?? 0;

    const receiverId = senderId === user1 ? user2 : user1;
    if (!receiverId) return;

    const sender = await getUserPublic(db, senderId);

    // â”€â”€ NotificaÃ§Ã£o para delivery_request â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    if (msgType === 'delivery_request') {
      const isDonor   = (msgData.is_donor as boolean | undefined) ?? true;
      const actionMsg = isDonor
        ? `${sender.emoji} ${sender.name} confirmou que entregou o item!`
        : `${sender.emoji} ${sender.name} confirmou que buscou o item!`;

      await writeNotification(db, receiverId, {
        type:       'delivery_request',
        title:      'ðŸ“¦ ConfirmaÃ§Ã£o de entrega pendente',
        body:       actionMsg,
        chatId,
        senderUid:  senderId,
        senderName: sender.name,
        itemTitle,
        itemType,
      });

      logger.info(`[onNewChatMessage] delivery_request notif â†’ ${receiverId}`, { chatId, senderId });
      return;
    }

    // â”€â”€ NotificaÃ§Ã£o para delivery_confirmed â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    if (msgType === 'delivery_confirmed') {
      await writeNotification(db, receiverId, {
        type:       'delivery_confirmed',
        title:      'âœ… Entrega confirmada!',
        body:       `${sender.emoji} ${sender.name} confirmou o recebimento${itemTitle ? ` de "${itemTitle}"` : ''}.`,
        chatId,
        senderUid:  senderId,
        senderName: sender.name,
        itemTitle,
        itemType,
      });

      logger.info(`[onNewChatMessage] delivery_confirmed notif â†’ ${receiverId}`, { chatId, senderId });
      return;
    }

    // â”€â”€ NotificaÃ§Ã£o para delivery_denied â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    if (msgType === 'delivery_denied') {
      await writeNotification(db, receiverId, {
        type:       'delivery_denied',
        title:      'âŒ Entrega nÃ£o confirmada',
        body:       `${sender.emoji} ${sender.name} indicou que o item ainda nÃ£o chegou.`,
        chatId,
        senderUid:  senderId,
        senderName: sender.name,
        itemTitle,
        itemType,
      });

      logger.info(`[onNewChatMessage] delivery_denied notif â†’ ${receiverId}`, { chatId, senderId });
      return;
    }

    // â”€â”€ NotificaÃ§Ã£o para mensagens de texto normais â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    if (msgType && msgType !== 'text') return; // ignora outros tipos

    // â”€â”€ Detecta primeiro contato NO CONTEXTO DO ITEM ATUAL â”€â”€â”€
    // Usa item_changed_at gravado pelo Flutter para ignorar mensagens
    // de itens anteriores entre os mesmos dois usuÃ¡rios.
    const isFirstMessage = await isFirstMessageInContext(
      db, chatId, itemChangedAt, msgTs,
    );

    let title: string;
    let body:  string;

    if (isFirstMessage) {
      const itemLabel = itemType === 'dream' ? 'sonho' : 'doaÃ§Ã£o';
      const article   = itemType === 'dream' ? 'o' : 'a';
      title = itemTitle
        ? `${sender.emoji} ${sender.name} quer realizar ${article} "${itemTitle}"!`
        : `${sender.emoji} ${sender.name} tem interesse em sua publicaÃ§Ã£o!`;
      body = msgText.length > 80 ? `${msgText.slice(0, 80)}â€¦` : msgText;
      if (!body) body = `Toque para ver a mensagem sobre ${article} ${itemLabel}.`;
    } else {
      title = `${sender.emoji} ${sender.name}`;
      body  = msgText.length > 100 ? `${msgText.slice(0, 100)}â€¦` : msgText;
    }

    await writeNotification(db, receiverId, {
      type:       isFirstMessage ? 'first_message' : 'message',
      title,
      body,
      chatId,
      senderUid:  senderId,
      senderName: sender.name,
      itemTitle,
      itemType,
    });

    logger.info(`[onNewChatMessage] notif â†’ ${receiverId}`, {
      chatId, isFirstMessage, itemChangedAt, senderId,
    });
  }
);

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// 2. DOAÃ‡ÃƒO CONCLUÃDA
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

export const onDonationCompleted = onValueUpdated(
  {
    ref:      '/Chats/{chatId}/completed',
    instance: 'empatia-34400-default-rtdb',
    region:   'us-central1',
  },
  async (event) => {
    const db = getDB();

    const before = event.data.before.val();
    const after  = event.data.after.val();
    if (after !== true || before === true) return;

    const chatId = event.params.chatId;

    const chatSnap = await db.ref(`Chats/${chatId}`).get();
    if (!chatSnap.exists()) return;
    const chatData = chatSnap.val();

    const user1:     string = chatData.user1      ?? '';
    const user2:     string = chatData.user2      ?? '';
    const itemTitle: string = chatData.item_title ?? '';
    const itemType:  string = chatData.item_type  ?? '';

    let donorUid    = user1;
    let receiverUid = user2;
    try {
      const histSnap = await db
        .ref(`DonationHistory/${user1}`)
        .orderByChild('chatId')
        .equalTo(chatId)
        .limitToLast(1)
        .get();
      if (histSnap.exists()) {
        const entries = Object.values(histSnap.val() as Record<string, any>);
        if (entries[0]?.type === 'donated') {
          donorUid    = user1;
          receiverUid = user2;
        } else {
          donorUid    = user2;
          receiverUid = user1;
        }
      }
    } catch { /* mantÃ©m default */ }

    const [donor, receiver] = await Promise.all([
      getUserPublic(db, donorUid),
      getUserPublic(db, receiverUid),
    ]);

    const itemLabel = itemType === 'dream' ? 'sonho' : 'doaÃ§Ã£o';
    const article   = itemType === 'dream' ? 'o'     : 'a';

    await writeNotification(db, donorUid, {
      type:       'donation_done',
      title:      `ðŸŽ‰ ${article.toUpperCase().charAt(0) + article.slice(1)} "${itemTitle}" foi entregue${itemType === 'dream' ? ' â€” sonho realizado!' : '!'}`,
      body:       `${receiver.emoji} ${receiver.name} confirmou o recebimento. Obrigado por fazer a diferenÃ§a! ðŸ’›`,
      chatId,
      senderUid:  receiverUid,
      senderName: receiver.name,
      itemTitle,
      itemType,
    });

    await writeNotification(db, receiverUid, {
      type:       'donation_done',
      title:      `ðŸŽ‰ ${itemTitle ? `"${itemTitle}" chegou!` : `${itemLabel.charAt(0).toUpperCase() + itemLabel.slice(1)} concluÃ­d${itemType === 'dream' ? 'o' : 'a'}!`}`,
      body:       `${donor.emoji} ${donor.name} realizou ${article} ${itemLabel}. Aproveite muito! ðŸŒŸ`,
      chatId,
      senderUid:  donorUid,
      senderName: donor.name,
      itemTitle,
      itemType,
    });

    logger.info(`[onDonationCompleted] notifs â†’ ${donorUid}, ${receiverUid}`, {
      chatId, itemTitle,
    });
  }
);

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// 3. RESET SEMANAL DO RANKING
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

export const weeklyRankingReset = onSchedule(
  {
    schedule:       'every monday 03:10',
    timeZone:       'America/Sao_Paulo',
    region:         'southamerica-east1',
    timeoutSeconds: 120,
  },
  async () => {
    const db = getDB();

    const now          = new Date();
    const prevWeekDate = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
    const year         = prevWeekDate.getFullYear();
    const start        = new Date(year, 0, 1);
    const week         = Math.ceil(
      ((prevWeekDate.getTime() - start.getTime()) / 86400000 + 1) / 7
    );
    const prevWeekKey  = `${year}-W${String(week).padStart(2, '0')}`;
    const currentKey   = weekKey();

    logger.info(`[weeklyRankingReset] prev=${prevWeekKey} new=${currentKey}`);

    const rankSnap = await db.ref(`Rankings/weekly/${prevWeekKey}`).get();
    const rankData = rankSnap.exists() ? rankSnap.val() : null;

    let topNames: string[] = [];
    if (rankData && typeof rankData === 'object') {
      const sorted = Object.values(rankData as Record<string, any>)
        .sort((a: any, b: any) => (b.score ?? 0) - (a.score ?? 0))
        .slice(0, 3);
      topNames = sorted.map((e: any) => e.name ?? 'Desconhecido');
    }

    if (rankData) {
      await db.ref(`Rankings/archive/${prevWeekKey}`).set(rankData);
    }

    await db.ref(`Rankings/weekly/${currentKey}`).set(null);

    const podium = topNames.length > 0
      ? topNames.map((n, i) => `${['ðŸ¥‡','ðŸ¥ˆ','ðŸ¥‰'][i]} ${n}`).join(' Â· ')
      : 'Sem doadores esta semana';

    await db.ref('Notifications/broadcast').set({
      type:      'ranking_reset',
      title:     'ðŸ† Ranking semanal reiniciado!',
      body:      `A semana terminou! ${podium}. Seja o prÃ³ximo GuardiÃ£o desta semana!`,
      timestamp: Date.now(),
      read:      false,
      weekKey:   prevWeekKey,
    });

    logger.info(`[weeklyRankingReset] done. Top: ${podium}`);
  }
);

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// 4. LIMPEZA SEMANAL DE NOTIFICAÃ‡Ã•ES
//
// Roda toda segunda-feira Ã s 03:30 (BRT), 20 min apÃ³s o reset
// do ranking para nÃ£o disputar I/O com ele.
//
// Regras de retenÃ§Ã£o:
//   â€¢ NotificaÃ§Ãµes lidas   â†’ removidas apÃ³s 7 dias
//   â€¢ NotificaÃ§Ãµes nÃ£o lidas â†’ removidas apÃ³s 30 dias (failsafe)
//   â€¢ Broadcast            â†’ nÃ£o mexe (jÃ¡ tem TTL de 7 dias no
//                            broadcastStream do Flutter)
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

export const weeklyNotificationCleanup = onSchedule(
  {
    schedule:       'every monday 03:30',
    timeZone:       'America/Sao_Paulo',
    region:         'southamerica-east1',
    timeoutSeconds: 300,
    memory:         '256MiB',
  },
  async () => {
    const db  = getDB();
    const now = Date.now();

    const READ_TTL   = 7  * 24 * 60 * 60 * 1000; // 7 dias
    const UNREAD_TTL = 30 * 24 * 60 * 60 * 1000; // 30 dias

    logger.info('[weeklyNotificationCleanup] iniciando limpeza');

    try {
      // Lista todos os UIDs com notificaÃ§Ãµes (exclui o nÃ³ broadcast)
      const rootSnap = await db.ref('Notifications').get();
      if (!rootSnap.exists()) {
        logger.info('[weeklyNotificationCleanup] nenhuma notificaÃ§Ã£o encontrada');
        return;
      }

      const rootData = rootSnap.val() as Record<string, any>;
      const uids     = Object.keys(rootData).filter((k) => k !== 'broadcast');

      let totalRemoved = 0;
      const batchUpdates: Record<string, null> = {};

      for (const uid of uids) {
        const userNotifs = rootData[uid];
        if (!userNotifs || typeof userNotifs !== 'object') continue;

        for (const [notifId, notif] of Object.entries(userNotifs)) {
          if (!notif || typeof notif !== 'object') continue;

          const n         = notif as Record<string, any>;
          const timestamp = (n['timestamp'] as number) ?? 0;
          const isRead    = n['read'] === true;
          const age       = now - timestamp;
          const ttl       = isRead ? READ_TTL : UNREAD_TTL;

          if (age > ttl) {
            batchUpdates[`Notifications/${uid}/${notifId}`] = null;
            totalRemoved++;
          }
        }
      }

      if (Object.keys(batchUpdates).length > 0) {
        // Firebase limita multi-path updates a ~1000 nÃ³s por chamada
        const entries = Object.entries(batchUpdates);
        const CHUNK   = 500;
        for (let i = 0; i < entries.length; i += CHUNK) {
          const chunk = Object.fromEntries(entries.slice(i, i + CHUNK));
          await db.ref().update(chunk);
        }
      }

      logger.info('[weeklyNotificationCleanup] concluÃ­do', {
        usersProcessed: uids.length,
        totalRemoved,
      });
    } catch (err) {
      logger.error('[weeklyNotificationCleanup] erro', { err });
    }
  }
);