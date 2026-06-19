import { beforeUserSignedIn } from "firebase-functions/v2/identity";
import { onRequest } from "firebase-functions/v2/https";
import { setGlobalOptions } from "firebase-functions/v2";
import { defineString } from "firebase-functions/params";
import * as logger from "firebase-functions/logger";
import { Request, Response } from "express";

// ══════════════════════════════════════════════════════════════
// ATENÇÃO: NÃO coloque initializeApp() nem getDatabase() aqui
// no nível do módulo. O Firebase CLI executa este arquivo para
// descobrir as funções exportadas, e qualquer I/O no topo causa
// o timeout "Cannot determine backend specification".
//
// Padrão correto: lazy init — inicialize dentro de cada função.
// ══════════════════════════════════════════════════════════════

setGlobalOptions({
  maxInstances: 10,
  region: "southamerica-east1",
});

// ══════════════════════════════════════════════════════════════
// PARÂMETROS (defineString é seguro no topo — não faz I/O)
// ══════════════════════════════════════════════════════════════

const googlePlacesApiKey  = defineString("GOOGLE_PLACES_API_KEY");
const cloudinaryCloudName = defineString("CLOUDINARY_CLOUD_NAME");
const cloudinaryApiKey    = defineString("CLOUDINARY_API_KEY");
const cloudinaryApiSecret = defineString("CLOUDINARY_API_SECRET");

// ══════════════════════════════════════════════════════════════
// LAZY INIT — chame esta função dentro de cada handler
// ══════════════════════════════════════════════════════════════

function getAdminApp() {
  // dynamic import garante que o módulo só é carregado em runtime,
  // nunca durante a análise estática do deploy.
  const { getApps, initializeApp } = require("firebase-admin/app");
  if (!getApps().length) {
    initializeApp();
  }
}

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

function buildResetEmailHtml(resetLink: string): string {
  return `
<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Redefinir senha · Empatia</title>
</head>
<body style="margin:0;padding:0;background:#f5f0ff;font-family:Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#f5f0ff;padding:32px 0;">
    <tr>
      <td align="center">
        <table width="480" cellpadding="0" cellspacing="0"
               style="background:#ffffff;border-radius:24px;overflow:hidden;
                      box-shadow:0 8px 32px rgba(168,85,247,0.15);">
          <tr>
            <td align="center"
                style="background:linear-gradient(135deg,#FF6B9D,#A855F7);
                       padding:40px 32px 32px;">
              <div style="font-size:56px;line-height:1;">🔑</div>
              <h1 style="color:#ffffff;font-size:26px;font-weight:900;
                         margin:16px 0 6px;letter-spacing:1px;">
                Redefinir senha
              </h1>
              <p style="color:rgba(255,255,255,0.85);font-size:14px;margin:0;">
                🧸 Pingo Brinquedos · Empatia 💖
              </p>
            </td>
          </tr>
          <tr>
            <td style="padding:36px 36px 12px;">
              <p style="font-size:17px;color:#333;margin:0 0 12px;">Olá! 👋</p>
              <p style="font-size:15px;color:#555;line-height:1.7;margin:0 0 32px;">
                Recebemos um pedido para redefinir a senha da sua conta no
                <strong style="color:#A855F7;">Empatia</strong>.
                Clique no botão abaixo para criar uma nova senha:
              </p>
              <table width="100%" cellpadding="0" cellspacing="0">
                <tr>
                  <td align="center" style="padding-bottom:32px;">
                    <a href="${resetLink}"
                       style="display:inline-block;
                              background:linear-gradient(135deg,#FF6B9D,#A855F7);
                              color:#ffffff;text-decoration:none;
                              padding:18px 44px;border-radius:50px;
                              font-size:16px;font-weight:900;letter-spacing:0.5px;
                              box-shadow:0 8px 20px rgba(255,107,157,0.45);">
                      ✨ Criar nova senha
                    </a>
                  </td>
                </tr>
              </table>
              <table width="100%" cellpadding="0" cellspacing="0"
                     style="background:#fdf4ff;border-radius:16px;
                            border:2px solid rgba(168,85,247,0.2);margin-bottom:28px;">
                <tr>
                  <td style="padding:16px 20px;">
                    <p style="font-size:13px;color:#7c3aed;margin:0;line-height:1.6;">
                      ⏰ <strong>Este link expira em 1 hora.</strong>
                      Após isso, solicite um novo link na tela de login.
                    </p>
                  </td>
                </tr>
              </table>
              <p style="font-size:13px;color:#999;line-height:1.6;margin:0 0 28px;">
                🔒 Se você <strong>não solicitou</strong> a redefinição de senha,
                pode ignorar este email com segurança.
              </p>
            </td>
          </tr>
          <tr>
            <td align="center"
                style="background:#fdf4ff;padding:20px 32px;border-top:2px solid #f0e6ff;">
              <p style="font-size:13px;color:#a78bfa;margin:0;font-weight:700;">
                🧸 Pingo Brinquedos · Empatia 💖
              </p>
              <p style="font-size:11px;color:#c4b5fd;margin:6px 0 0;">
                Este é um email automático, não responda.
              </p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>`;
}

function buildEmailVerificationHtml(verificationLink: string, email: string): string {
  return `
<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Verificar e-mail · Empatia</title>
</head>
<body style="margin:0;padding:0;background:#fff0f7;font-family:Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#fff0f7;padding:32px 0;">
    <tr>
      <td align="center">
        <table width="480" cellpadding="0" cellspacing="0"
               style="background:#ffffff;border-radius:24px;overflow:hidden;
                      box-shadow:0 8px 32px rgba(255,107,157,0.18);">
          <tr>
            <td align="center"
                style="background:linear-gradient(135deg,#FF6B9D,#A855F7,#6366F1);
                       padding:44px 32px 36px;">
              <div style="width:90px;height:90px;border-radius:50%;
                          background:rgba(255,255,255,0.22);
                          margin:0 auto 20px;font-size:52px;line-height:90px;text-align:center;">
                ✉️
              </div>
              <h1 style="color:#ffffff;font-size:26px;font-weight:900;margin:0 0 8px;">
                Confirme seu e-mail
              </h1>
              <p style="color:rgba(255,255,255,0.88);font-size:14px;margin:0;">
                🧸 Pingo Brinquedos · Empatia 💖
              </p>
            </td>
          </tr>
          <tr>
            <td style="padding:36px 36px 0;">
              <p style="font-size:17px;color:#333;margin:0 0 10px;">Olá! 👋</p>
              <p style="font-size:15px;color:#555;line-height:1.75;margin:0 0 10px;">
                Recebemos seu cadastro no <strong style="color:#A855F7;">Empatia</strong>.
                Para ativar sua conta, confirme seu endereço de e-mail:
              </p>
              <table width="100%" cellpadding="0" cellspacing="0"
                     style="background:linear-gradient(135deg,rgba(255,107,157,0.08),rgba(168,85,247,0.08));
                            border-radius:14px;border:1.5px solid rgba(255,107,157,0.25);
                            margin-bottom:28px;">
                <tr>
                  <td style="padding:14px 20px;text-align:center;">
                    <span style="font-size:16px;">📧</span>
                    <strong style="font-size:15px;color:#A855F7;margin-left:8px;">${email}</strong>
                  </td>
                </tr>
              </table>
              <table width="100%" cellpadding="0" cellspacing="0" style="margin-top:28px;">
                <tr>
                  <td align="center" style="padding-bottom:28px;">
                    <a href="${verificationLink}"
                       style="display:inline-block;
                              background:linear-gradient(135deg,#FF6B9D,#A855F7);
                              color:#ffffff;text-decoration:none;
                              padding:18px 48px;border-radius:50px;
                              font-size:16px;font-weight:900;letter-spacing:0.5px;
                              box-shadow:0 8px 24px rgba(255,107,157,0.45);">
                      ✅ Confirmar meu e-mail
                    </a>
                  </td>
                </tr>
              </table>
              <table width="100%" cellpadding="0" cellspacing="0"
                     style="background:#fdf4ff;border-radius:16px;
                            border:2px solid rgba(168,85,247,0.2);margin-bottom:24px;">
                <tr>
                  <td style="padding:14px 20px;">
                    <p style="font-size:13px;color:#7c3aed;margin:0;line-height:1.6;">
                      ⏰ <strong>Este link expira em 24 horas.</strong>
                    </p>
                  </td>
                </tr>
              </table>
              <p style="font-size:13px;color:#999;line-height:1.6;margin:0 0 32px;">
                🔒 Se você <strong>não criou</strong> uma conta no Empatia, ignore este e-mail.
              </p>
            </td>
          </tr>
          <tr>
            <td align="center"
                style="background:#fdf4ff;padding:20px 32px;border-top:2px solid #f0e6ff;">
              <p style="font-size:13px;color:#a78bfa;margin:0;font-weight:700;">
                🧸 Pingo Brinquedos · Empatia 💖
              </p>
              <p style="font-size:11px;color:#c4b5fd;margin:6px 0 0;">
                Este é um e-mail automático, não responda.
              </p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>`;
}

function buildEmailChangeHtml(verificationLink: string, newEmail: string): string {
  return `
<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Confirmar novo e-mail · Empatia</title>
</head>
<body style="margin:0;padding:0;background:#f0f4ff;font-family:Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#f0f4ff;padding:32px 0;">
    <tr>
      <td align="center">
        <table width="480" cellpadding="0" cellspacing="0"
               style="background:#ffffff;border-radius:24px;overflow:hidden;
                      box-shadow:0 8px 32px rgba(37,99,235,0.15);">
          <tr>
            <td align="center"
                style="background:linear-gradient(135deg,#2563EB,#7C3AED);
                       padding:44px 32px 36px;">
              <div style="width:90px;height:90px;border-radius:50%;
                          background:rgba(255,255,255,0.20);
                          margin:0 auto 20px;font-size:52px;line-height:90px;text-align:center;">
                ✉️
              </div>
              <h1 style="color:#ffffff;font-size:26px;font-weight:900;margin:0 0 8px;">
                Confirme seu novo e-mail
              </h1>
              <p style="color:rgba(255,255,255,0.88);font-size:14px;margin:0;">
                🧸 Pingo Brinquedos · Empatia 💖
              </p>
            </td>
          </tr>
          <tr>
            <td style="padding:36px 36px 0;">
              <p style="font-size:17px;color:#333;margin:0 0 10px;">Olá! 👋</p>
              <p style="font-size:15px;color:#555;line-height:1.75;margin:0 0 20px;">
                Recebemos uma solicitação para alterar o e-mail da sua conta no
                <strong style="color:#7C3AED;">Empatia</strong>.
                Para confirmar, clique no botão abaixo:
              </p>
              <table width="100%" cellpadding="0" cellspacing="0"
                     style="background:linear-gradient(135deg,rgba(37,99,235,0.07),rgba(124,58,237,0.07));
                            border-radius:14px;border:1.5px solid rgba(37,99,235,0.20);
                            margin-bottom:28px;">
                <tr>
                  <td style="padding:14px 20px;text-align:center;">
                    <span style="font-size:16px;">📧</span>
                    <strong style="font-size:15px;color:#2563EB;margin-left:8px;">${newEmail}</strong>
                  </td>
                </tr>
              </table>
              <table width="100%" cellpadding="0" cellspacing="0" style="margin-bottom:28px;">
                <tr>
                  <td align="center">
                    <a href="${verificationLink}"
                       style="display:inline-block;
                              background:linear-gradient(135deg,#2563EB,#7C3AED);
                              color:#ffffff;text-decoration:none;
                              padding:18px 48px;border-radius:50px;
                              font-size:16px;font-weight:900;letter-spacing:0.5px;
                              box-shadow:0 8px 24px rgba(37,99,235,0.40);">
                      ✉️ Confirmar novo e-mail
                    </a>
                  </td>
                </tr>
              </table>
              <table width="100%" cellpadding="0" cellspacing="0"
                     style="background:#eff6ff;border-radius:16px;
                            border:2px solid rgba(37,99,235,0.20);margin-bottom:24px;">
                <tr>
                  <td style="padding:14px 20px;">
                    <p style="font-size:13px;color:#1d4ed8;margin:0;line-height:1.6;">
                      ⏰ <strong>Este link expira em 24 horas.</strong>
                      Após isso, acesse o app e solicite a troca novamente em
                      <em>Configurações → Informações Pessoais</em>.
                    </p>
                  </td>
                </tr>
              </table>
              <p style="font-size:13px;color:#999;line-height:1.6;margin:0 0 32px;">
                🔒 Se você <strong>não solicitou</strong> a alteração de e-mail,
                ignore esta mensagem. Seu e-mail atual continua ativo.
              </p>
            </td>
          </tr>
          <tr>
            <td align="center"
                style="background:#eff6ff;padding:20px 32px;border-top:2px solid #dbeafe;">
              <p style="font-size:13px;color:#3b82f6;margin:0;font-weight:700;">
                🧸 Pingo Brinquedos · Empatia 💖
              </p>
              <p style="font-size:11px;color:#93c5fd;margin:6px 0 0;">
                Este é um e-mail automático, não responda.
              </p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>`;
}

// ══════════════════════════════════════════════════════════════════════════════
// SYNC EMAIL — BLOCKING FUNCTION (beforeUserSignedIn)
// ══════════════════════════════════════════════════════════════════════════════

export const syncEmailOnSignIn = beforeUserSignedIn(
  { region: "southamerica-east1", timeoutSeconds: 7 },
  async (event) => {
    getAdminApp(); // lazy init
    const { getDatabase } = require("firebase-admin/database");

    const user = event.data;
    if (!user) return;

    const uid       = user.uid;
    const authEmail = user.email;
    if (!authEmail || !uid) return;

    const syncPromise = (async () => {
      const db       = getDatabase();
      const userRef  = db.ref(`Users/${uid}`);
      const snapshot = await userRef.child("email").get();
      const dbEmail  = snapshot.val() as string | null;

      if (dbEmail !== authEmail) {
        await userRef.update({ email: authEmail, updatedAt: Date.now() });
        logger.info("✅ Email sincronizado via beforeUserSignedIn", {
          uid, de: dbEmail ?? "(vazio)", para: authEmail,
        });
      }
    })();

    const timeoutPromise = new Promise<void>((resolve) =>
      setTimeout(() => {
        logger.warn("⚠️ syncEmailOnSignIn: timeout de 5s atingido", { uid });
        resolve();
      }, 5000)
    );

    try {
      await Promise.race([syncPromise, timeoutPromise]);
    } catch (err) {
      logger.error("⚠️ Falha ao sincronizar email no RTDB (não crítico)", { uid, err });
    }
  }
);

// ══════════════════════════════════════════════════════════════════════════════
// SYNC EMAIL — HTTP ENDPOINT
// ══════════════════════════════════════════════════════════════════════════════

export const syncEmailNow = onRequest(
  { region: "southamerica-east1", cors: false },
  async (req: Request, res: Response) => {
    getAdminApp(); // lazy init
    const { getAuth }     = require("firebase-admin/auth");
    const { getDatabase } = require("firebase-admin/database");

    applyCors(res);
    if (req.method === "OPTIONS") { res.status(204).send(""); return; }
    if (req.method !== "POST")    { res.status(405).json({ error: "Método não permitido" }); return; }

    const authHeader = req.headers.authorization ?? "";
    if (!authHeader.startsWith("Bearer ")) {
      res.status(401).json({ error: "Token não fornecido." });
      return;
    }

    const idToken = authHeader.split("Bearer ")[1];

    try {
      const decoded   = await getAuth().verifyIdToken(idToken);
      const uid       = decoded.uid;
      const authEmail = decoded.email;

      if (!authEmail) {
        res.status(400).json({ error: "Usuário não possui e-mail no Auth." });
        return;
      }

      const db      = getDatabase();
      const userRef = db.ref(`Users/${uid}`);
      const snap    = await userRef.child("email").get();
      const dbEmail = snap.val() as string | null;

      if (dbEmail === authEmail) {
        res.status(200).json({ synced: false, message: "E-mail já está atualizado." });
        return;
      }

      await userRef.update({ email: authEmail, updatedAt: Date.now() });

      logger.info("✅ Email sincronizado via syncEmailNow", {
        uid, de: dbEmail ?? "(vazio)", para: authEmail,
      });

      res.status(200).json({ synced: true, email: authEmail });
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : String(err);
      logger.error("❌ Erro em syncEmailNow", { err });
      res.status(500).json({ error: "Erro interno.", details: message });
    }
  }
);

// ══════════════════════════════════════════════════════════════════════════════
// SEND EMAIL CHANGE VERIFICATION (e-mail bonito via Nodemailer)
// ══════════════════════════════════════════════════════════════════════════════

export const sendEmailChangeVerification = onRequest(
  { region: "southamerica-east1", cors: false, secrets: ["GMAIL_USER", "GMAIL_PASS"] },
  async (req: Request, res: Response) => {
    getAdminApp(); // lazy init
    const { getAuth }     = require("firebase-admin/auth");
    const { getDatabase } = require("firebase-admin/database");
    const nodemailer      = require("nodemailer");

    applyCors(res);
    if (req.method === "OPTIONS") { res.status(204).send(""); return; }
    if (req.method !== "POST")    { res.status(405).json({ error: "Método não permitido" }); return; }

    const authHeader = req.headers.authorization ?? "";
    if (!authHeader.startsWith("Bearer ")) {
      res.status(401).json({ error: "Token não fornecido." });
      return;
    }

    const idToken              = authHeader.split("Bearer ")[1];
    const { newEmail }         = (req.body ?? {}) as { newEmail?: string };

    if (!newEmail || typeof newEmail !== "string") {
      res.status(400).json({ error: "newEmail não fornecido." });
      return;
    }

    try {
      const decoded      = await getAuth().verifyIdToken(idToken);
      const uid          = decoded.uid;
      const currentEmail = decoded.email as string | undefined;

      if (!currentEmail) {
        res.status(400).json({ error: "Usuário não possui e-mail cadastrado." });
        return;
      }

      if (newEmail === currentEmail) {
        res.status(400).json({ error: "O novo e-mail é igual ao atual." });
        return;
      }

      // Gera o link de troca via Admin SDK — mesma segurança do
      // verifyBeforeUpdateEmail no cliente, mas com template customizável.
      const verificationLink = await getAuth().generateVerifyAndChangeEmailLink(
        currentEmail,
        newEmail,
      );

      // Marca emailVerified = false no RTDB imediatamente
      const db = getDatabase();
      await db.ref(`Users/${uid}`).update({
        emailVerified: false,
        updatedAt:     Date.now(),
      });

      // Envia o e-mail bonito pelo Gmail / Nodemailer
      const gmailUser = process.env.GMAIL_USER!;
      const gmailPass = process.env.GMAIL_PASS!;

      const transporter = nodemailer.createTransport({
        host:   "smtp.gmail.com",
        port:   465,
        secure: true,
        auth:   { user: gmailUser, pass: gmailPass },
      });

      await transporter.sendMail({
        from:    `"Empatia 💖" <${gmailUser}>`,
        to:      newEmail,
        subject: "✉️ Confirme seu novo e-mail · Empatia",
        html:    buildEmailChangeHtml(verificationLink, newEmail),
      });

      logger.info("✅ E-mail de troca enviado", { uid, de: currentEmail, para: newEmail });
      res.status(200).json({ success: true });

    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : String(err);
      logger.error("❌ Erro em sendEmailChangeVerification", { err });
      res.status(500).json({ error: "Erro ao enviar e-mail de verificação.", details: message });
    }
  }
);

// ══════════════════════════════════════════════════════════════
// DELETAR IMAGEM DO CLOUDINARY
// ══════════════════════════════════════════════════════════════

export const deleteCloudinaryImage = onRequest(
  { region: "southamerica-east1", cors: false },
  async (req: Request, res: Response) => {
    // sem firebase-admin — não precisa de getAdminApp()
    const cloudinary = require("cloudinary").v2;

    applyCors(res);
    if (req.method === "OPTIONS") { res.status(204).send(""); return; }
    if (req.method !== "POST")    { res.status(405).json({ error: "Método não permitido" }); return; }

    try {
      const { publicId } = req.body;
      if (!publicId) { res.status(400).json({ error: "publicId não fornecido" }); return; }

      cloudinary.config({
        cloud_name: cloudinaryCloudName.value(),
        api_key:    cloudinaryApiKey.value(),
        api_secret: cloudinaryApiSecret.value(),
      });

      logger.info(`🗑️ Deletando imagem: ${publicId}`);
      const result = await cloudinary.uploader.destroy(publicId);

      if (result.result === "ok") {
        res.status(200).json({ success: true, message: "Imagem deletada com sucesso", publicId, result: result.result });
      } else if (result.result === "not found") {
        res.status(200).json({ success: true, message: "Imagem não encontrada", publicId, result: result.result });
      } else {
        res.status(400).json({ success: false, message: "Erro ao deletar imagem", result: result.result });
      }
    } catch (error: unknown) {
      logger.error("❌ Erro ao deletar imagem:", error);
      const errorMessage = error instanceof Error ? error.message : String(error);
      res.status(500).json({ error: "Erro interno do servidor", details: errorMessage });
    }
  }
);

// ══════════════════════════════════════════════════════════════
// BUSCAR BAIRROS
// ══════════════════════════════════════════════════════════════

export const searchNeighborhoods = onRequest(
  { region: "southamerica-east1", cors: false },
  async (req: Request, res: Response) => {
    const axios = require("axios") as any;

    applyCors(res);
    if (req.method === "OPTIONS") { res.status(204).send(""); return; }
    if (req.method !== "POST")    { res.status(405).json({ error: "Método não permitido" }); return; }

    const body = (req.body as any)?.data ?? req.body;
    const { query, city, state, lat, lng } = body ?? {};

    if (!query || !city || !state) {
      res.status(400).json({ error: "Query, city e state são obrigatórios" });
      return;
    }

    const apiKey = googlePlacesApiKey.value();
    if (!apiKey) { res.status(500).json({ error: "API Key não configurada" }); return; }

    try {
      const params: Record<string, string | number> = {
        input:      `${query}, ${city}, ${state}, Brasil`,
        types:      "sublocality|neighborhood|political",
        components: "country:br",
        language:   "pt-BR",
        key:        apiKey,
      };

      if (lat && lng) {
        params.location = `${lat},${lng}`;
        params.radius   = 20000;
      }

      const response = await axios.get(
        "https://maps.googleapis.com/maps/api/place/autocomplete/json",
        { params }
      );

      if (response.data.status === "OK") {
        const predictions = response.data.predictions
          .filter((pred: any) => pred.description.toLowerCase().includes(city.toLowerCase()))
          .map((pred: any) => ({
            place_id:     pred.place_id,
            description:  pred.description,
            neighborhood: extractNeighborhood(pred.description),
          }));

        res.status(200).json({ status: "OK", predictions });
        return;
      }

      res.status(200).json(response.data);
    } catch (error: unknown) {
      const errorMessage = error instanceof Error ? error.message : "Erro ao buscar bairros";
      res.status(500).json({ error: errorMessage });
    }
  }
);

// ══════════════════════════════════════════════════════════════
// BUSCAR COORDENADAS DA CIDADE
// ══════════════════════════════════════════════════════════════

export const getCityCoordinates = onRequest(
  { region: "southamerica-east1", cors: false },
  async (req: Request, res: Response) => {
    const axios = require("axios") as any;

    applyCors(res);
    if (req.method === "OPTIONS") { res.status(204).send(""); return; }
    if (req.method !== "POST")    { res.status(405).json({ error: "Método não permitido" }); return; }

    const body = (req.body as any)?.data ?? req.body;
    const { city, state } = body ?? {};

    if (!city || !state) {
      res.status(400).json({ error: "City e state são obrigatórios" });
      return;
    }

    const apiKey = googlePlacesApiKey.value();
    if (!apiKey) { res.status(500).json({ error: "API Key não configurada" }); return; }

    try {
      const response = await axios.get(
        "https://maps.googleapis.com/maps/api/geocode/json",
        { params: { address: `${city}, ${state}, Brasil`, key: apiKey } }
      );

      if (response.data.status === "OK" && response.data.results.length > 0) {
        const location = response.data.results[0].geometry.location;
        res.status(200).json({ lat: location.lat, lng: location.lng });
        return;
      }

      res.status(200).json(null);
    } catch (error: unknown) {
      const errorMessage = error instanceof Error ? error.message : "Erro ao buscar coordenadas";
      res.status(500).json({ error: errorMessage });
    }
  }
);

// ══════════════════════════════════════════════════════════════
// ENVIAR EMAIL DE REDEFINIÇÃO DE SENHA
// ══════════════════════════════════════════════════════════════

export const sendPasswordResetEmail = onRequest(
  { region: "southamerica-east1", cors: false, secrets: ["GMAIL_USER", "GMAIL_PASS"] },
  async (req: Request, res: Response) => {
    getAdminApp(); // lazy init
    const { getAuth } = require("firebase-admin/auth");
    const nodemailer  = require("nodemailer");

    applyCors(res);
    if (req.method === "OPTIONS") { res.status(204).send(""); return; }
    if (req.method !== "POST")    { res.status(405).json({ error: "Método não permitido" }); return; }

    const { email } = req.body ?? {};
    if (!email || typeof email !== "string") {
      res.status(400).json({ error: "Email não fornecido." });
      return;
    }

    try {
      const resetLink = await getAuth().generatePasswordResetLink(email);

      const gmailUser   = process.env.GMAIL_USER!;
      const gmailPass   = process.env.GMAIL_PASS!;
      const transporter = nodemailer.createTransport({
        host: "smtp.gmail.com", port: 465, secure: true,
        auth: { user: gmailUser, pass: gmailPass },
      });

      await transporter.sendMail({
        from:    `"Empatia 💖" <${gmailUser}>`,
        to:      email,
        subject: "🔑 Redefinir sua senha · Empatia",
        html:    buildResetEmailHtml(resetLink),
      });

      logger.info("✅ Email de redefinição enviado", { email });
      res.status(200).json({ success: true });

    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : String(err);
      if (message.includes("USER_NOT_FOUND") || message.includes("user-not-found")) {
        logger.warn("⚠️ Email não cadastrado (retornando 200 por segurança)", { email });
        res.status(200).json({ success: true });
        return;
      }
      logger.error("❌ Erro ao enviar email de redefinição", { err });
      res.status(500).json({ error: "Erro ao enviar email.", details: message });
    }
  }
);

// ══════════════════════════════════════════════════════════════
// ENVIAR EMAIL DE VERIFICAÇÃO DE CONTA
// ══════════════════════════════════════════════════════════════

export const sendEmailVerification = onRequest(
  { region: "southamerica-east1", cors: false, secrets: ["GMAIL_USER", "GMAIL_PASS"] },
  async (req: Request, res: Response) => {
    getAdminApp(); // lazy init
    const { getAuth } = require("firebase-admin/auth");
    const nodemailer  = require("nodemailer");

    applyCors(res);
    if (req.method === "OPTIONS") { res.status(204).send(""); return; }
    if (req.method !== "POST")    { res.status(405).json({ error: "Método não permitido" }); return; }

    const authHeader = req.headers.authorization ?? "";
    if (!authHeader.startsWith("Bearer ")) {
      res.status(401).json({ error: "Token não fornecido." });
      return;
    }

    const idToken = authHeader.split("Bearer ")[1];

    try {
      const decoded    = await getAuth().verifyIdToken(idToken);
      const uid        = decoded.uid;
      const email      = decoded.email;

      if (!email) {
        res.status(400).json({ error: "Usuário não possui e-mail cadastrado." });
        return;
      }

      const userRecord = await getAuth().getUser(uid);
      if (userRecord.emailVerified) {
        res.status(200).json({ success: true, alreadyVerified: true });
        return;
      }

      const verificationLink = await getAuth().generateEmailVerificationLink(email);

      const gmailUser   = process.env.GMAIL_USER!;
      const gmailPass   = process.env.GMAIL_PASS!;
      const transporter = nodemailer.createTransport({
        host: "smtp.gmail.com", port: 465, secure: true,
        auth: { user: gmailUser, pass: gmailPass },
      });

      await transporter.sendMail({
        from:    `"Empatia 💖" <${gmailUser}>`,
        to:      email,
        subject: "✉️ Confirme seu e-mail · Empatia",
        html:    buildEmailVerificationHtml(verificationLink, email),
      });

      logger.info("✅ E-mail de verificação enviado", { uid, email });
      res.status(200).json({ success: true, alreadyVerified: false });

    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : String(err);
      logger.error("❌ Erro em sendEmailVerification", { err });
      res.status(500).json({ error: "Erro ao enviar e-mail de verificação.", details: message });
    }
  }
);