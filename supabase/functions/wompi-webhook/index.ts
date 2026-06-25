import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { crypto } from "https://deno.land/std@0.168.0/crypto/mod.ts";

serve(async (req) => {
  try {
    const eventsSecret = Deno.env.get("WOMPI_EVENTS_SECRET");
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    const body = await req.text();
    const signature = req.headers.get("x-event-checksum");

    if (eventsSecret && signature) {
      const encoder = new TextEncoder();
      const key = await crypto.subtle.importKey(
        "raw", encoder.encode(eventsSecret),
        { name: "HMAC", hash: "SHA-256" }, false, ["sign"]
      );
      const sigBuffer = await crypto.subtle.sign("HMAC", key, encoder.encode(body));
      const computed = Array.from(new Uint8Array(sigBuffer))
        .map((b) => b.toString(16).padStart(2, "0")).join("");
      if (computed !== signature) {
        console.error("Firma inválida");
        return new Response("Unauthorized", { status: 401 });
      }
    }

    const event = JSON.parse(body);
    console.log("Wompi event:", event.event);

    if (event.event === "transaction.updated") {
      const tx = event.data?.transaction;
      if (!tx) return new Response("ok");

      const statusMap: Record<string, string> = {
        APPROVED: "approved", DECLINED: "declined",
        VOIDED: "cancelled", ERROR: "failed",
      };
      const newStatus = statusMap[tx.status] ?? "pending";
      const supabase = createClient(supabaseUrl, supabaseKey);
      const now = new Date().toISOString();

      console.log("Actualizando transacción con wompi_link_id:", tx.payment_link_id);

      const { data: txRow, error: txError } = await supabase
        .from("transactions")
        .update({
          status: newStatus,
          wompi_transaction_id: tx.id,
          payment_method: tx.payment_method_type?.toLowerCase() ?? "wompi",
          updated_at: now,
          ...(newStatus === "approved" ? { completed_at: now } : {}),
        })
        .eq("wompi_link_id", tx.payment_link_id)
        .select("booking_id, walker_id, owner_id, amount")
        .maybeSingle();

      console.log("txRow:", JSON.stringify(txRow), "error:", JSON.stringify(txError));

      if (newStatus === "approved" && txRow) {
        // Actualizar booking a completado
        const { error: bookingError } = await supabase
          .from("bookings")
          .update({ status: "completed", updated_at: now })
          .eq("id", txRow.booking_id);

        console.log("Booking update error:", JSON.stringify(bookingError));

        // Obtener user_id del paseador desde la tabla walkers
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
    }

    return new Response("ok", { status: 200 });
  } catch (err) {
    console.error("Webhook error:", err);
    return new Response("Error", { status: 500 });
  }
});
