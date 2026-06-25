import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const WOMPI_BASE = "https://sandbox.wompi.co/v1"; // cambiar a https://production.wompi.co/v1 en producción

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

    const { bookingId, amountInCents, description, ownerEmail, ownerName, redirectUrl } =
      await req.json();

    if (!bookingId || !amountInCents) {
      return new Response(
        JSON.stringify({ error: "bookingId y amountInCents son requeridos" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Crear payment link en Wompi
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
        redirect_url: redirectUrl ?? "thewalkingpets://payment-result",
        customer_data: {
          customer_email: ownerEmail,
          customer_full_name: ownerName,
        },
      }),
    });

    const wompiData = await wompiRes.json();

    if (!wompiRes.ok) {
      console.error("Wompi error:", JSON.stringify(wompiData));
      return new Response(
        JSON.stringify({ error: "Error al crear el link de pago", detail: wompiData }),
        { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const paymentLink = wompiData.data;
    const paymentUrl = `${WOMPI_BASE.replace("/v1", "")}/p/${paymentLink.id}`;

    // Guardar transacción en Supabase con status 'pending'
    const supabase = createClient(supabaseUrl, supabaseKey);
    const now = new Date().toISOString();

    await supabase.from("transactions").insert({
      booking_id: bookingId,
      wompi_link_id: paymentLink.id,
      amount: amountInCents / 100,
      status: "pending",
      payment_method: "wompi",
      created_at: now,
      updated_at: now,
    });

    return new Response(
      JSON.stringify({
        paymentUrl,
        linkId: paymentLink.id,
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    console.error("Error:", err);
    return new Response(
      JSON.stringify({ error: "Error interno del servidor" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
