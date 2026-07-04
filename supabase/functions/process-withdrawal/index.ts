import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const WOMPI_PAYOUTS_BASE = "https://api.payouts.wompi.co/v1";
const WOMPI_ACCOUNT_ID = "WOMPI_ACCOUNT";

const BANK_ID_MAP: Record<string, string> = {
  "Bancolombia": "fe0dc841-b057-4349-a6dc-a88d29d2605a",
  "Banco de Bogotá": "ab8a9954-0f01-41fa-bc0f-d12862806df2",
  "Davivienda": "b38b9c92-e44d-4831-b74f-e3a517c75b4e",
  "BBVA": "9183a03b-cd82-451a-a6c7-6a9ab406a477",
  "Nequi": "6e422ee9-6863-4882-a265-42258b410caa",
  "Daviplata": "4b636ca6-3808-4428-89a4-48ab2da42bd0",
  "Banco Popular": "35ad5684-f9b1-4f12-be25-0a42e7e86fd6",
  "AV Villas": "33618602-f875-4a8c-ba3c-e7f76055b417",
  "Banco de Occidente": "eac87f23-3aa1-4d62-97ce-b27186160619",
  "Banco Caja Social": "09929648-ce86-4689-9ac8-dc60cd07a657",
  "Scotiabank Colpatria": "b8b11d82-8ae4-4d4a-bc51-8db066c9aa9f",
  "Nu Bank": "942a4163-505a-40c4-bb21-cdb10c80029a",
  "Lulo Bank": "cc61df83-0098-41cc-825e-076f20b45a43",
  "Movii": "75e0b723-f52a-4470-ac2c-2a744028f0e1",
  "Rappipay": "9330c6a9-cde9-4969-b890-08d02752ba8a",
  "Ualá": "85fb8d01-d93b-4eec-a007-2c641bccba47",
  "Bold": "62ead327-ac39-4612-a8c1-afae74cd50a9",
  "Bancoomeva": "54f52c3e-e09d-4993-af73-a529520843bd",
  "Otro": "",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const wompiApiKey = Deno.env.get("WOMPI_PAYOUTS_API_KEY")!;
    const wompiUserId = Deno.env.get("WOMPI_PAYOUTS_USER_ID")!;

    if (!wompiApiKey || !wompiUserId) {
      return new Response(
        JSON.stringify({ error: "Wompi Payouts secrets not configured" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const { withdrawalRequestId } = await req.json();
    if (!withdrawalRequestId) {
      return new Response(
        JSON.stringify({ error: "withdrawalRequestId is required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const supabase = createClient(supabaseUrl, supabaseKey);

    // Get withdrawal request details
    const { data: wr, error: wrError } = await supabase
      .from("withdrawal_requests")
      .select("*")
      .eq("id", withdrawalRequestId)
      .eq("status", "pending")
      .single();

    if (wrError || !wr) {
      return new Response(
        JSON.stringify({ error: "Withdrawal request not found or not pending" }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const bankId = BANK_ID_MAP[wr.bank_name];
    if (!bankId) {
      return new Response(
        JSON.stringify({ error: `Bank not found in map: ${wr.bank_name}` }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const amountInCents = Math.round(wr.amount * 100);
    const idempotencyKey = `wr-${withdrawalRequestId}`;
    const now = new Date().toISOString();

    // Create payout in Wompi
    const payoutRes = await fetch(`${WOMPI_PAYOUTS_BASE}/payouts`, {
      method: "POST",
      headers: {
        "x-api-key": wompiApiKey,
        "user-principal-id": wompiUserId,
        "idempotency-key": idempotencyKey,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        reference: idempotencyKey,
        accountId: WOMPI_ACCOUNT_ID,
        paymentType: "PAYROLL",
        transactions: [{
          legalIdType: wr.legal_id_type ?? "CC",
          legalId: wr.legal_id,
          bankId,
          accountType: wr.account_type === "Ahorros" ? "AHORROS" : "CORRIENTE",
          accountNumber: wr.account_number,
          name: wr.walker_name,
          email: wr.walker_email,
          amount: amountInCents,
          reference: `twp-${withdrawalRequestId}`,
        }],
      }),
    });

    const payoutData = await payoutRes.json();
    console.log("[Payouts] Wompi response:", JSON.stringify(payoutData));

    if (payoutRes.status !== 200 && payoutRes.status !== 201) {
      await supabase.from("withdrawal_requests").update({
        status: "failed",
        notes: JSON.stringify(payoutData),
        updated_at: now,
      }).eq("id", withdrawalRequestId);

      return new Response(
        JSON.stringify({ error: "Wompi payout failed", details: payoutData }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Update withdrawal request as processed
    await supabase.from("withdrawal_requests").update({
      status: "processed",
      wompi_batch_id: payoutData.data?.id ?? null,
      updated_at: now,
    }).eq("id", withdrawalRequestId);

    return new Response(
      JSON.stringify({ success: true, batchId: payoutData.data?.id }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    console.error("[Payouts] Error:", err);
    return new Response(
      JSON.stringify({ error: String(err) }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
