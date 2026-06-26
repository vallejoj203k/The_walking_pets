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

    const { bookingId } = await req.json();
    const supabase = createClient(supabaseUrl, supabaseKey);

    // Buscar la transacción pendiente para este booking
    const { data: txRow, error: txError } = await supabase
      .from("transactions")
      .select("*")
      .eq("booking_id", bookingId)
      .order("created_at", { ascending: false })
      .limit(1)
      .maybeSingle();

    console.log("txRow:", JSON.stringify(txRow), "error:", JSON.stringify(txError));

    if (!txRow) {
      return new Response(
        JSON.stringify({ status: "not_found" }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Si ya está aprobada en nuestra DB, retornar directo
    if (txRow.status === "approved") {
      return new Response(
        JSON.stringify({ status: "approved" }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Buscar transacciones de los últimos 7 días con referencia que empiece con el link ID
    const until = new Date();
    const from = new Date(until.getTime() - 7 * 24 * 60 * 60 * 1000);
    const fromStr = from.toISOString().split("T")[0];
    const untilStr = until.toISOString().split("T")[0];

    const txListRes = await fetch(
      `${WOMPI_BASE}/transactions?page=1&page_size=20&from_date=${fromStr}&until_date=${untilStr}`,
      { headers: { Authorization: `Bearer ${privateKey}` } }
    );
    const txListData = await txListRes.json();
    console.log("Wompi transactions count:", txListData.data?.length);

    // Encontrar la transacción cuya referencia empiece con el wompi_link_id
    const wTx = txListData.data?.find((t: any) =>
      t.reference?.startsWith(txRow.wompi_link_id)
    );

    console.log("Matched transaction:", JSON.stringify(wTx));

    if (!wTx) {
      return new Response(
        JSON.stringify({ status: txRow.status ?? "pending" }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }
    const statusMap: Record<string, string> = {
      APPROVED: "approved",
      DECLINED: "declined",
      VOIDED: "cancelled",
      ERROR: "failed",
    };
    const newStatus = statusMap[wTx.status] ?? "pending";

    const now = new Date().toISOString();

    // Actualizar la transacción en nuestra DB
    await supabase
      .from("transactions")
      .update({
        status: newStatus,
        wompi_transaction_id: wTx.id,
        payment_method: wTx.payment_method_type?.toLowerCase() ?? "wompi",
        updated_at: now,
        ...(newStatus === "approved" ? { completed_at: now } : {}),
      })
      .eq("id", txRow.id);

    if (newStatus === "approved") {
      // Actualizar booking a completado
      await supabase
        .from("bookings")
        .update({ status: "completed", updated_at: now })
        .eq("id", bookingId);

      // Obtener user_id del paseador
      const { data: walkerRow } = await supabase
        .from("walkers")
        .select("user_id")
        .eq("id", txRow.walker_id)
        .maybeSingle();

      const walkerUserId = walkerRow?.user_id;
      console.log("Walker user_id:", walkerUserId);

      if (walkerUserId) {
        const walkerAmount = txRow.amount * 0.9;

        const { data: existing } = await supabase
          .from("walker_balance")
          .select()
          .eq("walker_id", walkerUserId)
          .maybeSingle();

        if (existing) {
          await supabase.from("walker_balance").update({
            total_earned: (existing.total_earned ?? 0) + walkerAmount,
            available_balance: (existing.available_balance ?? 0) + walkerAmount,
            updated_at: now,
          }).eq("walker_id", walkerUserId);
        } else {
          await supabase.from("walker_balance").insert({
            walker_id: walkerUserId,
            total_earned: walkerAmount,
            available_balance: walkerAmount,
            pending_balance: 0,
            updated_at: now,
          });
        }
        console.log("Balance actualizado para walker:", walkerUserId, "monto:", walkerAmount);
      }
    }

    return new Response(
      JSON.stringify({ status: newStatus }),
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
