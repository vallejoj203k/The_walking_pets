import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const WOMPI_BASE = "https://production.wompi.co/v1";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const privateKey = Deno.env.get("WOMPI_PRIVATE_KEY");
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    if (!privateKey) {
      return new Response(
        JSON.stringify({ error: "WOMPI_PRIVATE_KEY no configurada" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const { bookingId, amountInCents, description, ownerEmail, ownerName } = await req.json();

    const supabase = createClient(supabaseUrl, supabaseKey);

    // Obtener walker_id y owner_id del booking
    const { data: booking } = await supabase
      .from("bookings")
      .select("walker_id, owner_id")
      .eq("id", bookingId)
      .single();

    const wompiRes = await fetch(`${WOMPI_BASE}/payment_links`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${privateKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        name: "The Walking Pets",
        description: description ?? "Pago de servicio de mascotas",
        single_use: true,
        collect_shipping: false,
        currency: "COP",
        amount_in_cents: Math.round(amountInCents),
        redirect_url: "https://thewalkingpets.app/payment-result",
        customer_data: {
          customer_email: ownerEmail,
          customer_full_name: ownerName,
        },
      }),
    });

    const wompiData = await wompiRes.json();
    console.log("Wompi response:", JSON.stringify(wompiData));

    if (!wompiRes.ok) {
      return new Response(
        JSON.stringify({ error: "Error Wompi", detail: wompiData }),
        { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const paymentLink = wompiData.data;
    const paymentUrl = paymentLink.payment_link_url ??
                       `https://checkout.wompi.co/l/${paymentLink.id}`;

    console.log("Payment URL:", paymentUrl);

    const now = new Date().toISOString();
    await supabase.from("transactions").insert({
      booking_id: bookingId,
      walker_id: booking?.walker_id ?? null,
      owner_id: booking?.owner_id ?? null,
      wompi_link_id: paymentLink.id,
      amount: amountInCents / 100,
      status: "pending",
      payment_method: "wompi",
      created_at: now,
      updated_at: now,
    });

    return new Response(
      JSON.stringify({ paymentUrl, linkId: paymentLink.id }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    console.error("Error:", err);
    return new Response(
      JSON.stringify({ error: String(err) }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
