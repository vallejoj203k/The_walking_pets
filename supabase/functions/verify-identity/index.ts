import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const FACEPP_COMPARE_URL = "https://api-us.faceplusplus.com/facepp/v3/compare";
const MATCH_THRESHOLD = 70; // Face++ similarity score threshold (0-100)

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const faceppKey = Deno.env.get("FACEPP_API_KEY");
    const faceppSecret = Deno.env.get("FACEPP_API_SECRET");
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    if (!faceppKey || !faceppSecret) {
      return new Response(
        JSON.stringify({ error: "Face++ credentials not configured" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const { userId, cedulaFrontUrl, selfieUrl } = await req.json();
    const supabase = createClient(supabaseUrl, supabaseKey);

    // Download both images from Supabase Storage
    const [cedulaRes, selfieRes] = await Promise.all([
      fetch(cedulaFrontUrl),
      fetch(selfieUrl),
    ]);

    if (!cedulaRes.ok || !selfieRes.ok) {
      return new Response(
        JSON.stringify({ error: "No se pudieron descargar las imágenes" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const [cedulaBuffer, selfieBuffer] = await Promise.all([
      cedulaRes.arrayBuffer(),
      selfieRes.arrayBuffer(),
    ]);

    // Convert to base64
    const toBase64 = (buffer: ArrayBuffer) =>
      btoa(String.fromCharCode(...new Uint8Array(buffer)));

    const cedulaBase64 = toBase64(cedulaBuffer);
    const selfieBase64 = toBase64(selfieBuffer);

    // Call Face++ compare API
    const formData = new FormData();
    formData.append("api_key", faceppKey);
    formData.append("api_secret", faceppSecret);
    formData.append("image_base64_1", cedulaBase64);
    formData.append("image_base64_2", selfieBase64);

    const faceppRes = await fetch(FACEPP_COMPARE_URL, {
      method: "POST",
      body: formData,
    });

    const faceppData = await faceppRes.json();
    console.log("Face++ response:", JSON.stringify(faceppData));

    const now = new Date().toISOString();

    if (faceppData.error_message) {
      // Face++ returned an error (e.g., no face detected)
      await supabase
        .from("identity_verifications")
        .update({ status: "rejected", match_score: 0, updated_at: now })
        .eq("user_id", userId);

      await supabase
        .from("walkers")
        .update({ verification_status: "rejected", updated_at: now })
        .eq("user_id", userId);

      return new Response(
        JSON.stringify({
          status: "rejected",
          reason: faceppData.error_message.includes("INVALID_IMAGE")
            ? "No se detectó un rostro en las imágenes. Asegúrate de que tu cédula y selfie muestren tu cara claramente."
            : faceppData.error_message,
        }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const confidence = faceppData.confidence ?? 0;
    const approved = confidence >= MATCH_THRESHOLD;
    const status = approved ? "approved" : "rejected";

    // Update identity_verifications table
    await supabase
      .from("identity_verifications")
      .update({ status, match_score: confidence, updated_at: now })
      .eq("user_id", userId);

    // Update walker verification status
    await supabase
      .from("walkers")
      .update({
        verification_status: status,
        verified: approved,
        updated_at: now,
      })
      .eq("user_id", userId);

    console.log(`User ${userId}: confidence=${confidence}, status=${status}`);

    return new Response(
      JSON.stringify({ status, confidence }),
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
