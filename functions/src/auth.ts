// functions/src/auth.ts
//
// Funções relacionadas a autenticação e e-mail:
//   - syncEmailOnSignIn  — bloqueia login para sincronizar e-mail
//   - syncEmailNow       — endpoint HTTP para sync manual
//   - sendEmailVerification
//   - sendEmailChangeVerification
//   - sendPasswordResetEmail
// ─────────────────────────────────────────────────────────────

import { beforeUserSignedIn }  from 'firebase-functions/v2/identity';
import { onRequest }           from 'firebase-functions/v2/https';
import * as logger             from 'firebase-functions/logger';
import { Request, Response }   from 'express';
import {
  getAdminApp,
  applyCors,
  buildResetEmailHtml,
  buildEmailVerificationHtml,
  buildEmailChangeHtml,
} from './shared';

// ══════════════════════════════════════════════════════════════
// SYNC EMAIL — BLOCKING FUNCTION (beforeUserSignedIn)
// ══════════════════════════════════════════════════════════════

export const syncEmailOnSignIn = beforeUserSignedIn(
  { region: 'southamerica-east1', timeoutSeconds: 7 },
  async (event) => {
    getAdminApp();
    const { getDatabase } = require('firebase-admin/database');

    const user = event.data;
    if (!user) return;

    const uid       = user.uid;
    const authEmail = user.email;
    if (!authEmail || !uid) return;

    const syncPromise = (async () => {
      const db       = getDatabase();
      const userRef  = db.ref(`Users/${uid}`);
      const snapshot = await userRef.child('email').get();
      const dbEmail  = snapshot.val() as string | null;

      if (dbEmail !== authEmail) {
        await userRef.update({ email: authEmail, updatedAt: Date.now() });
        logger.info('✅ Email sincronizado via beforeUserSignedIn', {
          uid, de: dbEmail ?? '(vazio)', para: authEmail,
        });
      }
    })();

    const timeoutPromise = new Promise<void>((resolve) =>
      setTimeout(() => {
        logger.warn('⚠️ syncEmailOnSignIn: timeout de 5s atingido', { uid });
        resolve();
      }, 5000)
    );

    try {
      await Promise.race([syncPromise, timeoutPromise]);
    } catch (err) {
      logger.error('⚠️ Falha ao sincronizar email no RTDB (não crítico)', { uid, err });
    }
  }
);

// ══════════════════════════════════════════════════════════════
// SYNC EMAIL — HTTP ENDPOINT
// ══════════════════════════════════════════════════════════════

export const syncEmailNow = onRequest(
  { region: 'southamerica-east1', cors: false },
  async (req: Request, res: Response) => {
    getAdminApp();
    const { getAuth }     = require('firebase-admin/auth');
    const { getDatabase } = require('firebase-admin/database');

    applyCors(res);
    if (req.method === 'OPTIONS') { res.status(204).send(''); return; }
    if (req.method !== 'POST')    { res.status(405).json({ error: 'Método não permitido' }); return; }

    const authHeader = req.headers.authorization ?? '';
    if (!authHeader.startsWith('Bearer ')) {
      res.status(401).json({ error: 'Token não fornecido.' });
      return;
    }

    const idToken = authHeader.split('Bearer ')[1];

    try {
      const decoded   = await getAuth().verifyIdToken(idToken);
      const uid       = decoded.uid;
      const authEmail = decoded.email;

      if (!authEmail) {
        res.status(400).json({ error: 'Usuário não possui e-mail no Auth.' });
        return;
      }

      const db      = getDatabase();
      const userRef = db.ref(`Users/${uid}`);
      const snap    = await userRef.child('email').get();
      const dbEmail = snap.val() as string | null;

      if (dbEmail === authEmail) {
        res.status(200).json({ synced: false, message: 'E-mail já está atualizado.' });
        return;
      }

      await userRef.update({ email: authEmail, updatedAt: Date.now() });

      logger.info('✅ Email sincronizado via syncEmailNow', {
        uid, de: dbEmail ?? '(vazio)', para: authEmail,
      });

      res.status(200).json({ synced: true, email: authEmail });
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : String(err);
      logger.error('❌ Erro em syncEmailNow', { err });
      res.status(500).json({ error: 'Erro interno.', details: message });
    }
  }
);

// ══════════════════════════════════════════════════════════════
// SEND EMAIL CHANGE VERIFICATION
// ══════════════════════════════════════════════════════════════

export const sendEmailChangeVerification = onRequest(
  { region: 'southamerica-east1', cors: false, secrets: ['GMAIL_USER', 'GMAIL_PASS'] },
  async (req: Request, res: Response) => {
    getAdminApp();
    const { getAuth }     = require('firebase-admin/auth');
    const { getDatabase } = require('firebase-admin/database');
    const nodemailer      = require('nodemailer');

    applyCors(res);
    if (req.method === 'OPTIONS') { res.status(204).send(''); return; }
    if (req.method !== 'POST')    { res.status(405).json({ error: 'Método não permitido' }); return; }

    const authHeader = req.headers.authorization ?? '';
    if (!authHeader.startsWith('Bearer ')) {
      res.status(401).json({ error: 'Token não fornecido.' });
      return;
    }

    const idToken          = authHeader.split('Bearer ')[1];
    const { newEmail }     = (req.body ?? {}) as { newEmail?: string };

    if (!newEmail || typeof newEmail !== 'string') {
      res.status(400).json({ error: 'newEmail não fornecido.' });
      return;
    }

    try {
      const decoded      = await getAuth().verifyIdToken(idToken);
      const uid          = decoded.uid;
      const currentEmail = decoded.email as string | undefined;

      if (!currentEmail) {
        res.status(400).json({ error: 'Usuário não possui e-mail cadastrado.' });
        return;
      }
      if (newEmail === currentEmail) {
        res.status(400).json({ error: 'O novo e-mail é igual ao atual.' });
        return;
      }

      const verificationLink = await getAuth().generateVerifyAndChangeEmailLink(
        currentEmail,
        newEmail,
      );

      const db = getDatabase();
      await db.ref(`Users/${uid}`).update({ emailVerified: false, updatedAt: Date.now() });

      const gmailUser   = process.env.GMAIL_USER!;
      const gmailPass   = process.env.GMAIL_PASS!;
      const transporter = nodemailer.createTransport({
        host: 'smtp.gmail.com', port: 465, secure: true,
        auth: { user: gmailUser, pass: gmailPass },
      });

      await transporter.sendMail({
        from:    `"Empatia 💖" <${gmailUser}>`,
        to:      newEmail,
        subject: '✉️ Confirme seu novo e-mail · Empatia',
        html:    buildEmailChangeHtml(verificationLink, newEmail),
      });

      logger.info('✅ E-mail de troca enviado', { uid, de: currentEmail, para: newEmail });
      res.status(200).json({ success: true });

    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : String(err);
      logger.error('❌ Erro em sendEmailChangeVerification', { err });
      res.status(500).json({ error: 'Erro ao enviar e-mail de verificação.', details: message });
    }
  }
);

// ══════════════════════════════════════════════════════════════
// SEND PASSWORD RESET EMAIL
// ══════════════════════════════════════════════════════════════

export const sendPasswordResetEmail = onRequest(
  { region: 'southamerica-east1', cors: false, secrets: ['GMAIL_USER', 'GMAIL_PASS'] },
  async (req: Request, res: Response) => {
    getAdminApp();
    const { getAuth } = require('firebase-admin/auth');
    const nodemailer  = require('nodemailer');

    applyCors(res);
    if (req.method === 'OPTIONS') { res.status(204).send(''); return; }
    if (req.method !== 'POST')    { res.status(405).json({ error: 'Método não permitido' }); return; }

    const { email } = req.body ?? {};
    if (!email || typeof email !== 'string') {
      res.status(400).json({ error: 'Email não fornecido.' });
      return;
    }

    try {
      const resetLink   = await getAuth().generatePasswordResetLink(email);
      const gmailUser   = process.env.GMAIL_USER!;
      const gmailPass   = process.env.GMAIL_PASS!;
      const transporter = nodemailer.createTransport({
        host: 'smtp.gmail.com', port: 465, secure: true,
        auth: { user: gmailUser, pass: gmailPass },
      });

      await transporter.sendMail({
        from:    `"Empatia 💖" <${gmailUser}>`,
        to:      email,
        subject: '🔑 Redefinir sua senha · Empatia',
        html:    buildResetEmailHtml(resetLink),
      });

      logger.info('✅ Email de redefinição enviado', { email });
      res.status(200).json({ success: true });

    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : String(err);
      if (message.includes('USER_NOT_FOUND') || message.includes('user-not-found')) {
        logger.warn('⚠️ Email não cadastrado (retornando 200 por segurança)', { email });
        res.status(200).json({ success: true });
        return;
      }
      logger.error('❌ Erro ao enviar email de redefinição', { err });
      res.status(500).json({ error: 'Erro ao enviar email.', details: message });
    }
  }
);

// ══════════════════════════════════════════════════════════════
// SEND EMAIL VERIFICATION
// ══════════════════════════════════════════════════════════════

export const sendEmailVerification = onRequest(
  { region: 'southamerica-east1', cors: false, secrets: ['GMAIL_USER', 'GMAIL_PASS'] },
  async (req: Request, res: Response) => {
    getAdminApp();
    const { getAuth } = require('firebase-admin/auth');
    const nodemailer  = require('nodemailer');

    applyCors(res);
    if (req.method === 'OPTIONS') { res.status(204).send(''); return; }
    if (req.method !== 'POST')    { res.status(405).json({ error: 'Método não permitido' }); return; }

    const authHeader = req.headers.authorization ?? '';
    if (!authHeader.startsWith('Bearer ')) {
      res.status(401).json({ error: 'Token não fornecido.' });
      return;
    }

    const idToken = authHeader.split('Bearer ')[1];

    try {
      const decoded    = await getAuth().verifyIdToken(idToken);
      const uid        = decoded.uid;
      const email      = decoded.email;

      if (!email) {
        res.status(400).json({ error: 'Usuário não possui e-mail cadastrado.' });
        return;
      }

      const userRecord = await getAuth().getUser(uid);
      if (userRecord.emailVerified) {
        res.status(200).json({ success: true, alreadyVerified: true });
        return;
      }

      const verificationLink = await getAuth().generateEmailVerificationLink(email);
      const gmailUser        = process.env.GMAIL_USER!;
      const gmailPass        = process.env.GMAIL_PASS!;
      const transporter      = nodemailer.createTransport({
        host: 'smtp.gmail.com', port: 465, secure: true,
        auth: { user: gmailUser, pass: gmailPass },
      });

      await transporter.sendMail({
        from:    `"Empatia 💖" <${gmailUser}>`,
        to:      email,
        subject: '✉️ Confirme seu e-mail · Empatia',
        html:    buildEmailVerificationHtml(verificationLink, email),
      });

      logger.info('✅ E-mail de verificação enviado', { uid, email });
      res.status(200).json({ success: true, alreadyVerified: false });

    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : String(err);
      logger.error('❌ Erro em sendEmailVerification', { err });
      res.status(500).json({ error: 'Erro ao enviar e-mail de verificação.', details: message });
    }
  }
);