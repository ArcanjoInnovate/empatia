// functions/src/shared.ts
//
// Helpers e utilitários compartilhados entre todos os módulos.
// Nenhuma Cloud Function é exportada aqui.
// ─────────────────────────────────────────────────────────────

import { Response } from 'express';
import { getApps, initializeApp } from 'firebase-admin/app';

// ══════════════════════════════════════════════════════════════
// INIT — Firebase Admin
//
// Histórico do bug "The default Firebase app does not exist":
//   1ª tentativa: initializeApp() lazy dentro de cada handler → falhava
//      de forma intermitente em cold start.
//   2ª tentativa: hook onInit() do firebase-functions/v2 → TESTADO
//      DUAS VEZES em produção, falhou as duas — o push simplesmente
//      parava de chegar (mesmo erro "app does not exist" nos logs).
//      Na teoria devia funcionar, mas nesse projeto não funcionou.
//   3ª tentativa: initializeApp() direto no topo do módulo → foi a
//      ÚNICA que realmente funcionou (confirmado com notificação
//      chegando de verdade). Um timeout de deploy apareceu depois
//      disso, mas em teste separado — não está confirmado que foi
//      causado por essa mudança (pode ter sido um problema pontual/
//      transitório do próprio `firebase deploy`, que é conhecido por
//      ter timeouts de "discovery" instáveis às vezes). Como essa é
//      a única abordagem com push funcionando de verdade nesse
//      projeto, voltamos pra ela — se o timeout de deploy voltar a
//      acontecer, investigamos como um problema separado, sem mexer
//      de novo nisso aqui.
// ══════════════════════════════════════════════════════════════

if (!getApps().length) initializeApp();

/** Mantido por compatibilidade com o restante do código — agora é só
 *  um no-op seguro, já que a inicialização real acontece acima, no
 *  carregamento do módulo. */
export function getAdminApp(): void {
  if (!getApps().length) initializeApp();
}

// ══════════════════════════════════════════════════════════════
// CORS
// ══════════════════════════════════════════════════════════════

export function applyCors(res: Response): void {
  res.set('Access-Control-Allow-Origin',  '*');
  res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
}

// ══════════════════════════════════════════════════════════════
// HELPERS GEOGRÁFICOS
// ══════════════════════════════════════════════════════════════

export function extractNeighborhood(fullDescription: string): string {
  const parts = fullDescription.split(',');
  return parts.length > 0 ? parts[0].trim() : fullDescription;
}

// ══════════════════════════════════════════════════════════════
// EMAIL HTML BUILDERS
// ══════════════════════════════════════════════════════════════

export function buildResetEmailHtml(resetLink: string): string {
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

export function buildEmailVerificationHtml(verificationLink: string, email: string): string {
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

export function buildEmailChangeHtml(verificationLink: string, newEmail: string): string {
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