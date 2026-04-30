// Supabase Edge Function: maakt een Mollie iDEAL betaling aan voor een booking
// Deploy: supabase functions deploy create-payment --no-verify-jwt
// Secrets: supabase secrets set MOLLIE_API_KEY=test_xxx

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  try {
    const body = await req.json();
    const bookingId: string | undefined = body.booking_id;
    const returnUrl: string | undefined = body.return_url;
    if (!bookingId) return json({ error: "booking_id is required" }, 400);
    if (!returnUrl) return json({ error: "return_url is required" }, 400);

    const SUPA_URL = Deno.env.get("SUPABASE_URL");
    const SUPA_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const MOLLIE_KEY = Deno.env.get("MOLLIE_API_KEY");
    const WEBHOOK_URL = Deno.env.get("MOLLIE_WEBHOOK_URL"); // optional
    if (!SUPA_URL || !SUPA_KEY) return json({ error: "supabase env missing" }, 500);
    if (!MOLLIE_KEY) return json({ error: "MOLLIE_API_KEY secret not set" }, 500);

    // Haal booking op via service-role (omzeilt RLS)
    const bResp = await fetch(`${SUPA_URL}/rest/v1/bookings?id=eq.${bookingId}&select=*`, {
      headers: { apikey: SUPA_KEY, Authorization: `Bearer ${SUPA_KEY}` },
    });
    if (!bResp.ok) return json({ error: "booking lookup failed" }, 500);
    const rows = await bResp.json();
    const booking = rows[0];
    if (!booking) return json({ error: "booking not found" }, 404);

    const amount = Number(booking.deposit || 0);
    if (!(amount > 0)) return json({ error: "booking has no deposit amount" }, 400);

    const payload: Record<string, unknown> = {
      amount: { currency: "EUR", value: amount.toFixed(2) },
      description: `Voorschot ${booking.ref}`,
      method: "ideal",
      redirectUrl: returnUrl,
      metadata: { booking_id: bookingId, ref: booking.ref },
    };
    if (WEBHOOK_URL) payload.webhookUrl = WEBHOOK_URL;

    const mResp = await fetch("https://api.mollie.com/v2/payments", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${MOLLIE_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(payload),
    });
    const mData = await mResp.json();
    if (!mResp.ok) {
      return json({ error: mData.detail || mData.title || "mollie error", mollie: mData }, 500);
    }

    // Sla payment id op zodat de webhook / check-payment de booking kan terugvinden
    await fetch(`${SUPA_URL}/rest/v1/bookings?id=eq.${bookingId}`, {
      method: "PATCH",
      headers: {
        apikey: SUPA_KEY,
        Authorization: `Bearer ${SUPA_KEY}`,
        "Content-Type": "application/json",
        Prefer: "return=minimal",
      },
      body: JSON.stringify({ mollie_payment_id: mData.id, payment_status: mData.status }),
    });

    return json({
      checkoutUrl: mData._links?.checkout?.href,
      paymentId: mData.id,
      status: mData.status,
    });
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
