import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// Send FCM v1 API notification
async function sendFcmNotification(
  fcmToken: string,
  title: string,
  body: string,
  data: Record<string, string>,
  projectId: string,
  serviceAccountJson: string
) {
  // Get OAuth2 access token using service account
  const serviceAccount = JSON.parse(serviceAccountJson);
  const now = Math.floor(Date.now() / 1000);
  const header = btoa(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const payload = btoa(JSON.stringify({
    iss: serviceAccount.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  }));

  const signingInput = `${header}.${payload}`;

  // Import private key
  const privateKey = serviceAccount.private_key;
  const keyData = privateKey
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\n/g, "");
  const binaryKey = Uint8Array.from(atob(keyData), c => c.charCodeAt(0));

  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    binaryKey,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"]
  );

  const encoder = new TextEncoder();
  const signatureBuffer = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    cryptoKey,
    encoder.encode(signingInput)
  );

  const signature = btoa(String.fromCharCode(...new Uint8Array(signatureBuffer)));
  const jwt = `${signingInput}.${signature}`;

  const tokenRes = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });
  const tokenData = await tokenRes.json();
  const accessToken = tokenData.access_token;

  if (!accessToken) {
    throw new Error(`Failed to get FCM access token: ${JSON.stringify(tokenData)}`);
  }

  // Send notification
  const fcmRes = await fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${accessToken}`,
      },
      body: JSON.stringify({
        message: {
          token: fcmToken,
          notification: { title, body },
          data,
          android: {
            priority: "high",
            notification: { channel_id: "twp_high_importance" },
          },
          apns: {
            payload: { aps: { sound: "default", badge: 1 } },
          },
        },
      }),
    }
  );

  const fcmData = await fcmRes.json();
  console.log("[FCM] Response:", JSON.stringify(fcmData));
  return fcmData;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const fcmProjectId = Deno.env.get("FCM_PROJECT_ID");
    const fcmServiceAccount = Deno.env.get("FCM_SERVICE_ACCOUNT_JSON");

    if (!fcmProjectId || !fcmServiceAccount) {
      return new Response(
        JSON.stringify({ error: "FCM secrets not configured" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const { userId, title, body, data = {} } = await req.json();

    if (!userId || !title || !body) {
      return new Response(
        JSON.stringify({ error: "userId, title, and body are required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const supabase = createClient(supabaseUrl, supabaseKey);

    // Get FCM token for user
    const { data: tokenRow, error: tokenError } = await supabase
      .from("user_fcm_tokens")
      .select("token")
      .eq("user_id", userId)
      .maybeSingle();

    if (tokenError || !tokenRow?.token) {
      console.log("[FCM] No token found for user:", userId);
      return new Response(
        JSON.stringify({ sent: false, reason: "no_token" }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    await sendFcmNotification(
      tokenRow.token,
      title,
      body,
      data,
      fcmProjectId,
      fcmServiceAccount
    );

    return new Response(
      JSON.stringify({ sent: true }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    console.error("[FCM] Error:", err);
    return new Response(
      JSON.stringify({ error: String(err) }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
