-- Tabla para almacenar los datos de verificación de identidad
CREATE TABLE IF NOT EXISTS identity_verifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
  cedula_front_url text,
  cedula_back_url text,
  selfie_url text,
  status text DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  match_score float,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Agregar columna verification_status a walkers si no existe
ALTER TABLE walkers ADD COLUMN IF NOT EXISTS verification_status text DEFAULT 'pending'
  CHECK (verification_status IN ('pending', 'approved', 'rejected'));

-- Deshabilitar RLS para simplificar (el Edge Function usa service role key)
ALTER TABLE identity_verifications DISABLE ROW LEVEL SECURITY;

-- Bucket de Storage para documentos de identidad
-- Ejecutar en el dashboard de Supabase > Storage > New bucket:
-- Nombre: identity-docs
-- Public: true (para que el Edge Function pueda descargar las imágenes)
