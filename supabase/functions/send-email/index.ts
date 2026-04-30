// Supabase Edge Function: stuurt een e-mail via Resend API.
// Deploy: supabase functions deploy send-email --no-verify-jwt
// Secrets:
//   RESEND_API_KEY   = re_xxx           (van Resend dashboard)
//   RESEND_FROM      = "Mor Ephrem <onboarding@resend.dev>"  (test) of eigen domein
//
// Body (JSON): { to, subject, body, html?, reply_to?, parish_id? }
// Antwoord:    { id } bij succes, { error } bij fout.

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  try {
    const { to, subject, body, html, reply_to, bcc } = await req.json();
    if (!to || !subject || (!body && !html)) {
      return json({ error: "to, subject and body/html zijn verplicht" }, 400);
    }

    const KEY = Deno.env.get("RESEND_API_KEY");
    const FROM = Deno.env.get("RESEND_FROM") || "onboarding@resend.dev";
    if (!KEY) return json({ error: "RESEND_API_KEY secret niet ingesteld" }, 500);

    const payload: Record<string, unknown> = {
      from: FROM,
      to: Array.isArray(to) ? to : [to],
      subject,
    };
    if (html) payload.html = html;
    if (body) payload.text = body;
    if (reply_to) payload.reply_to = reply_to;
    if (bcc) payload.bcc = Array.isArray(bcc) ? bcc : [bcc];

    const r = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(payload),
    });
    const data = await r.json();
    if (!r.ok) {
      return json({ error: data.message || data.error || "resend error", resend: data }, r.status);
    }
    return json({ id: data.id, ok: true });
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});

function json(o: unknown, status = 200) {
  return new Response(JSON.stringify(o), {
    status,
    headers: { ...cors, "content-type": "application/json" },
  });
}
