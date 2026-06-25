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

    // Verificar firma del webhook
    if (eventsSecret && signature) {
      const encoder = new TextEncoder();
      const key = await crypto.subtle.importKey(
        "raw",
        encoder.encode(eventsSecret),
        { name: "HMAC", hash: "SHA-256" },
        false,
        ["sign"]
      );
      const sigBuffer = await crypto.subtle.sign("HMAC", key, encoder.encode(body));
      const computed = Array.from(new Uint8Array(sigBuffer))
        .map((b) => b.toString(16).padStart(2, "0"))
        .join("");

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

      const wompiStatus = tx.status; // APPROVED, DECLINED, VOIDED, ERROR
      const linkId = tx.payment_link_id;

      const statusMap: Record<string, string> = {
        APPROVED: "approved",
        DECLINED: "declined",
        VOIDED: "cancelled",
        ERROR: "failed",
      };

      const newStatus = statusMap[wompiStatus] ?? "pending";
      const supabase = createClient(supabaseUrl, supabaseKey);
      const now = new Date().toISOString();

      // Actualizar transacción
      const { data: txRow } = await supabase
        .from("transactions")
        .update({
          status: newStatus,
          wompi_transaction_id: tx.id,
          payment_method: tx.payment_method_type?.toLowerCase() ?? "wompi",
          updated_at: now,
          ...(newStatus === "approved" ? { completed_at: now } : {}),
        })
        .eq("wompi_link_id", linkId)
        .select("booking_id, walker_id, amount")
        .single();

      // Si aprobado: actualizar booking y balance del paseador
      if (newStatus === "approved" && txRow) {
        await supabase
          .from("bookings")
          .update({ status: "completed", updated_at: now })
          .eq("id", txRow.booking_id);

        // El paseador recibe el monto sin comisión de plataforma (10%)
        const walkerAmount = txRow.amount * 0.9;

        const { data: existing } = await supabase
          .from("walker_balance")
          .select()
          .eq("walker_id", txRow.walker_id)
          .maybeSingle();

        if (existing) {
          await supabase
            .from("walker_balance")
            .update({
              total_earned: (existing.total_earned ?? 0) + walkerAmount,
              available_balance: (existing.available_balance ?? 0) + walkerAmount,
              updated_at: now,
            })
            .eq("walker_id", txRow.walker_id);
        } else {
          await supabase.from("walker_balance").insert({
            walker_id: txRow.walker_id,
            total_earned: walkerAmount,
            available_balance: walkerAmount,
            pending_balance: 0,
            updated_at: now,
          });
        }
      }
    }

    return new Response("ok", { status: 200 });
  } catch (err) {
    console.error("Webhook error:", err);
    return new Response("Error", { status: 500 });
  }
});
