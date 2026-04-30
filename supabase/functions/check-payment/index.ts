// Supabase Edge Function: controleert de status van een Mollie-betaling en
// werkt de bijbehorende booking bij. Wordt aangeroepen door de frontend
// nadat Mollie de gebruiker heeft teruggestuurd naar de site.
// Deploy: supabase functions deploy check-payment --no-verify-jwt

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  try {
    const { booking_id, payment_id } = await req.json();
    if (!booking_id && !payment_id) return json({ error: "booking_id or payment_id required" }, 400);

    const SUPA_URL = Deno.env.get("SUPABASE_URL");
    const SUPA_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const MOLLIE_KEY = Deno.env.get("MOLLIE_API_KEY");
    if (!SUPA_URL || !SUPA_KEY || !MOLLIE_KEY) return json({ error: "env missing" }, 500);

    let mid = payment_id;
    if (!mid) {
      const r = await fetch(
        `${SUPA_URL}/rest/v1/bookings?id=eq.${booking_id}&select=mollie_payment_id`,
        { headers: { apikey: SUPA_KEY, Authorization: `Bearer ${SUPA_KEY}` } },
      );
      const rows = await r.json();
      mid = rows[0]?.mollie_payment_id;
      if (!mid) return json({ error: "no mollie_payment_id on booking" }, 404);
    }

    const mResp = await fetch(`https://api.mollie.com/v2/payments/${mid}`, {
      headers: { Authorization: `Bearer ${MOLLIE_KEY}` },
    });
    const m = await mResp.json();
    if (!mResp.ok) return json({ error: m.detail || "mollie error", mollie: m }, 500);

    const update = mapMollieStatus(m.status);
    await fetch(`${SUPA_URL}/rest/v1/bookings?mollie_payment_id=eq.${mid}`, {
      method: "PATCH",
      headers: {
        apikey: SUPA_KEY,
        Authorization: `Bearer ${SUPA_KEY}`,
        "Content-Type": "application/json",
        Prefer: "return=minimal",
      },
      body: JSON.stringify(update),
    });

    return json({ status: m.status, booking: update, ref: m.metadata?.ref });
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});

function mapMollieStatus(status: string) {
  // 'open' | 'pending' | 'authorized' | 'paid' | 'canceled' | 'expired' | 'failed'
  const u: Record<string, unknown> = { payment_status: status };
  if (status === "paid") u.paid = "partial"; // voorschot voldaan
  else if (status === "canceled" || status === "expired" || status === "failed") u.paid = "unpaid";
  return u;
}

function json(o: unknown, status = 200) {
  return new Response(JSON.stringify(o), {
    status,
    headers: { ...cors, "content-type": "application/json" },
  });
}
