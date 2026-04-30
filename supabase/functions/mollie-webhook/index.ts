// Supabase Edge Function: ontvangt webhook-pings van Mollie wanneer een
// betaling van status verandert. Mollie POST't naar deze URL met body
// "id=tr_xxx" (form-urlencoded). Wij halen vervolgens de actuele status
// op en updaten de booking. Ook bij dubbel-pings is dit idempotent.
// Deploy: supabase functions deploy mollie-webhook --no-verify-jwt
// Daarna in Mollie Dashboard NIET nodig om iets in te stellen — we geven
// de webhookUrl mee bij elke create-payment call (zie MOLLIE_WEBHOOK_URL
// in create-payment).

Deno.serve(async (req) => {
  if (req.method !== "POST") return new Response("method", { status: 405 });
  try {
    const fd = await req.formData();
    const id = fd.get("id");
    if (typeof id !== "string" || !id) return new Response("ok");

    const SUPA_URL = Deno.env.get("SUPABASE_URL");
    const SUPA_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const MOLLIE_KEY = Deno.env.get("MOLLIE_API_KEY");
    if (!SUPA_URL || !SUPA_KEY || !MOLLIE_KEY) {
      console.error("env missing");
      return new Response("ok"); // 200, zodat Mollie niet eindeloos retried
    }

    const mResp = await fetch(`https://api.mollie.com/v2/payments/${id}`, {
      headers: { Authorization: `Bearer ${MOLLIE_KEY}` },
    });
    if (!mResp.ok) {
      console.error("mollie fetch failed", mResp.status);
      return new Response("ok");
    }
    const m = await mResp.json();

    const u: Record<string, unknown> = { payment_status: m.status };
    if (m.status === "paid") u.paid = "partial";
    else if (["canceled", "expired", "failed"].includes(m.status)) u.paid = "unpaid";

    await fetch(`${SUPA_URL}/rest/v1/bookings?mollie_payment_id=eq.${id}`, {
      method: "PATCH",
      headers: {
        apikey: SUPA_KEY,
        Authorization: `Bearer ${SUPA_KEY}`,
        "Content-Type": "application/json",
        Prefer: "return=minimal",
      },
      body: JSON.stringify(u),
    });

    return new Response("ok");
  } catch (e) {
    console.error("webhook error", e);
    return new Response("ok");
  }
});
