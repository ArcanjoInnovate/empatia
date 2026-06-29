// functions/src/notifications.ts

import { onValueCreated, onValueUpdated } from 'firebase-functions/v2/database';
import { onSchedule }                     from 'firebase-functions/v2/scheduler';
import * as logger                         from 'firebase-functions/logger';
import { initializeApp, getApps }         from 'firebase-admin/app';
import { getDatabase }                     from 'firebase-admin/database';
import { getMessaging }                    from 'firebase-admin/messaging';

if (getApps().length === 0) {
  initializeApp();
}

// ══════════════════════════════════════════════════════════════
// HELPERS LOCAIS
// ══════════════════════════════════════════════════════════════

function getDB() {
  return getDatabase();
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
    if (!snap.exists()) return { name: 'Alguém', emoji: '👤' };
    const data = snap.val();
    return {
      name:  data.name         ?? 'Alguém',
      emoji: data.profileEmoji ?? '👤',
    };
  } catch {
    return { name: 'Alguém', emoji: '👤' };
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

    // Conta notificações não lidas para o badge real no iOS
    const notifsSnap = await db.ref(`Notifications/${uid}`).get();
    let unreadCount = 0;
    if (notifsSnap.exists()) {
      const notifs = notifsSnap.val() as Record<string, any>;
      unreadCount = Object.values(notifs).filter(
        (n: any) => n && n.read === false
      ).length;
    }

    const result = await getMessaging().send({
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

// ══════════════════════════════════════════════════════════════
// HELPER — detecta primeiro contato no contexto atual do item
//
// Lógica:
//   • O Flutter grava `item_changed_at` (timestamp) no nó Chats/{chatId}
//     sempre que o item muda (updateContext) ou ao criar o chat (valor 0).
//   • "Primeiro contato no contexto" = ainda não existe nenhuma mensagem
//     de texto com timestamp > item_changed_at enviada pelo RECEIVER
//     (ou por qualquer um, dependendo da semântica desejada).
//   • Não usa orderByChild('timestamp') → sem necessidade de index extra.
//     Lê todas as mensagens e filtra em memória. Aceitável porque:
//       – A query só roda uma vez por mensagem enviada.
//       – Chats com muitas mensagens já terão item_changed_at recente,
//         então msgCount será > 0 quase imediatamente.
// ══════════════════════════════════════════════════════════════
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
      if (ts === currentMsgTimestamp) continue;            // é a própria mensagem atual
      countInContext++;
    }

    return countInContext === 0; // nenhuma outra mensagem neste contexto → é a primeira
  } catch (err) {
    logger.warn('[isFirstMessageInContext] erro ao contar mensagens', { chatId, err });
    return false; // em caso de erro, trata como não-primeira (seguro)
  }
}

// ══════════════════════════════════════════════════════════════
// 1. MENSAGEM NOVA NO CHAT
// ══════════════════════════════════════════════════════════════

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
    // item_changed_at = 0 em chats novos (toda mensagem é "primeiro contato")
    // item_changed_at = ServerValue.timestamp quando o item mudou
    const itemChangedAt: number  = (chatData.item_changed_at as number) ?? 0;

    const receiverId = senderId === user1 ? user2 : user1;
    if (!receiverId) return;

    const sender = await getUserPublic(db, senderId);

    // ── Notificação para delivery_request ────────────────────
    if (msgType === 'delivery_request') {
      const isDonor   = (msgData.is_donor as boolean | undefined) ?? true;
      const actionMsg = isDonor
        ? `${sender.emoji} ${sender.name} confirmou que entregou o item!`
        : `${sender.emoji} ${sender.name} confirmou que buscou o item!`;

      await writeNotification(db, receiverId, {
        type:       'delivery_request',
        title:      '📦 Confirmação de entrega pendente',
        body:       actionMsg,
        chatId,
        senderUid:  senderId,
        senderName: sender.name,
        itemTitle,
        itemType,
      });

      logger.info(`[onNewChatMessage] delivery_request notif → ${receiverId}`, { chatId, senderId });
      return;
    }

    // ── Notificação para delivery_confirmed ──────────────────
    if (msgType === 'delivery_confirmed') {
      await writeNotification(db, receiverId, {
        type:       'delivery_confirmed',
        title:      '✅ Entrega confirmada!',
        body:       `${sender.emoji} ${sender.name} confirmou o recebimento${itemTitle ? ` de "${itemTitle}"` : ''}.`,
        chatId,
        senderUid:  senderId,
        senderName: sender.name,
        itemTitle,
        itemType,
      });

      logger.info(`[onNewChatMessage] delivery_confirmed notif → ${receiverId}`, { chatId, senderId });
      return;
    }

    // ── Notificação para delivery_denied ─────────────────────
    if (msgType === 'delivery_denied') {
      await writeNotification(db, receiverId, {
        type:       'delivery_denied',
        title:      '❌ Entrega não confirmada',
        body:       `${sender.emoji} ${sender.name} indicou que o item ainda não chegou.`,
        chatId,
        senderUid:  senderId,
        senderName: sender.name,
        itemTitle,
        itemType,
      });

      logger.info(`[onNewChatMessage] delivery_denied notif → ${receiverId}`, { chatId, senderId });
      return;
    }

    // ── Notificação para mensagens de texto normais ───────────
    if (msgType && msgType !== 'text') return; // ignora outros tipos

    // ── Detecta primeiro contato NO CONTEXTO DO ITEM ATUAL ───
    // Usa item_changed_at gravado pelo Flutter para ignorar mensagens
    // de itens anteriores entre os mesmos dois usuários.
    const isFirstMessage = await isFirstMessageInContext(
      db, chatId, itemChangedAt, msgTs,
    );

    let title: string;
    let body:  string;

    if (isFirstMessage) {
      const itemLabel = itemType === 'dream' ? 'sonho' : 'doação';
      const article   = itemType === 'dream' ? 'o' : 'a';
      title = itemTitle
        ? `${sender.emoji} ${sender.name} quer realizar ${article} "${itemTitle}"!`
        : `${sender.emoji} ${sender.name} tem interesse em sua publicação!`;
      body = msgText.length > 80 ? `${msgText.slice(0, 80)}…` : msgText;
      if (!body) body = `Toque para ver a mensagem sobre ${article} ${itemLabel}.`;
    } else {
      title = `${sender.emoji} ${sender.name}`;
      body  = msgText.length > 100 ? `${msgText.slice(0, 100)}…` : msgText;
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

    logger.info(`[onNewChatMessage] notif → ${receiverId}`, {
      chatId, isFirstMessage, itemChangedAt, senderId,
    });
  }
);

// ══════════════════════════════════════════════════════════════
// 2. DOAÇÃO CONCLUÍDA
// ══════════════════════════════════════════════════════════════

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
    } catch { /* mantém default */ }

    const [donor, receiver] = await Promise.all([
      getUserPublic(db, donorUid),
      getUserPublic(db, receiverUid),
    ]);

    const itemLabel = itemType === 'dream' ? 'sonho' : 'doação';
    const article   = itemType === 'dream' ? 'o'     : 'a';

    await writeNotification(db, donorUid, {
      type:       'donation_done',
      title:      `🎉 ${article.toUpperCase().charAt(0) + article.slice(1)} "${itemTitle}" foi entregue${itemType === 'dream' ? ' — sonho realizado!' : '!'}`,
      body:       `${receiver.emoji} ${receiver.name} confirmou o recebimento. Obrigado por fazer a diferença! 💛`,
      chatId,
      senderUid:  receiverUid,
      senderName: receiver.name,
      itemTitle,
      itemType,
    });

    await writeNotification(db, receiverUid, {
      type:       'donation_done',
      title:      `🎉 ${itemTitle ? `"${itemTitle}" chegou!` : `${itemLabel.charAt(0).toUpperCase() + itemLabel.slice(1)} concluíd${itemType === 'dream' ? 'o' : 'a'}!`}`,
      body:       `${donor.emoji} ${donor.name} realizou ${article} ${itemLabel}. Aproveite muito! 🌟`,
      chatId,
      senderUid:  donorUid,
      senderName: donor.name,
      itemTitle,
      itemType,
    });

    logger.info(`[onDonationCompleted] notifs → ${donorUid}, ${receiverUid}`, {
      chatId, itemTitle,
    });
  }
);

// ══════════════════════════════════════════════════════════════
// 3. RESET SEMANAL DO RANKING
// ══════════════════════════════════════════════════════════════

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
      ? topNames.map((n, i) => `${['🥇','🥈','🥉'][i]} ${n}`).join(' · ')
      : 'Sem doadores esta semana';

    await db.ref('Notifications/broadcast').set({
      type:      'ranking_reset',
      title:     '🏆 Ranking semanal reiniciado!',
      body:      `A semana terminou! ${podium}. Seja o próximo Guardião desta semana!`,
      timestamp: Date.now(),
      read:      false,
      weekKey:   prevWeekKey,
    });

    logger.info(`[weeklyRankingReset] done. Top: ${podium}`);
  }
);

// ══════════════════════════════════════════════════════════════
// 4. LIMPEZA SEMANAL DE NOTIFICAÇÕES
//
// Roda toda segunda-feira às 03:30 (BRT), 20 min após o reset
// do ranking para não disputar I/O com ele.
//
// Regras de retenção:
//   • Notificações lidas   → removidas após 7 dias
//   • Notificações não lidas → removidas após 30 dias (failsafe)
//   • Broadcast            → não mexe (já tem TTL de 7 dias no
//                            broadcastStream do Flutter)
// ══════════════════════════════════════════════════════════════

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
      // Lista todos os UIDs com notificações (exclui o nó broadcast)
      const rootSnap = await db.ref('Notifications').get();
      if (!rootSnap.exists()) {
        logger.info('[weeklyNotificationCleanup] nenhuma notificação encontrada');
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
        // Firebase limita multi-path updates a ~1000 nós por chamada
        const entries = Object.entries(batchUpdates);
        const CHUNK   = 500;
        for (let i = 0; i < entries.length; i += CHUNK) {
          const chunk = Object.fromEntries(entries.slice(i, i + CHUNK));
          await db.ref().update(chunk);
        }
      }

      logger.info('[weeklyNotificationCleanup] concluído', {
        usersProcessed: uids.length,
        totalRemoved,
      });
    } catch (err) {
      logger.error('[weeklyNotificationCleanup] erro', { err });
    }
  }
);