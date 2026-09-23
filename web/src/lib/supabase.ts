import { createClient, type SupabaseClient } from "@supabase/supabase-js";

/// Client Supabase optionnel.
///
/// Tant que `NEXT_PUBLIC_SUPABASE_URL` / `NEXT_PUBLIC_SUPABASE_ANON_KEY`
/// ne sont pas définis dans `web-nextjs/.env.local`, l'application tourne
/// intégralement sur les données démo (`src/lib/demo-data.ts`) — exactement
/// comme le store local du Flutter. Aucune page ne casse sans identifiants.

const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
const anonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;

export const isSupabaseConfigured = Boolean(url && anonKey);

let client: SupabaseClient | null = null;

export function getSupabase(): SupabaseClient | null {
  if (!isSupabaseConfigured) return null;
  if (!client) {
    client = createClient(url as string, anonKey as string, {
      auth: { persistSession: true },
    });
  }
  return client;
}