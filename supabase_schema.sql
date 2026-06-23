-- =====================================================
-- THE WALKING PETS - Supabase Schema (Fase 1)
-- Ejecutar en: Supabase Dashboard > SQL Editor
-- =====================================================

-- Users table (extiende auth.users de Supabase)
CREATE TABLE IF NOT EXISTS users (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email text UNIQUE NOT NULL,
  role text NOT NULL CHECK (role IN ('walker', 'owner')),
  created_at timestamp WITH TIME ZONE DEFAULT now(),
  updated_at timestamp WITH TIME ZONE DEFAULT now()
);

-- Walkers table
CREATE TABLE IF NOT EXISTS walkers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name text NOT NULL,
  photo_url text,
  experience_years integer CHECK (experience_years >= 0 AND experience_years <= 50),
  services text[] DEFAULT '{}',
  hourly_rate decimal(10, 2) CHECK (hourly_rate >= 0),
  coverage_zone text,
  verified boolean DEFAULT false,
  created_at timestamp WITH TIME ZONE DEFAULT now(),
  updated_at timestamp WITH TIME ZONE DEFAULT now()
);

-- Owners table
CREATE TABLE IF NOT EXISTS owners (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name text NOT NULL,
  photo_url text,
  address text,
  created_at timestamp WITH TIME ZONE DEFAULT now(),
  updated_at timestamp WITH TIME ZONE DEFAULT now()
);

-- Pets table
CREATE TABLE IF NOT EXISTS pets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id uuid NOT NULL REFERENCES owners(id) ON DELETE CASCADE,
  name text NOT NULL,
  type text NOT NULL CHECK (type IN ('perro', 'gato', 'otro')),
  size text NOT NULL CHECK (size IN ('pequeño', 'mediano', 'grande')),
  created_at timestamp WITH TIME ZONE DEFAULT now()
);

-- =====================================================
-- ROW LEVEL SECURITY (RLS)
-- =====================================================

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE walkers ENABLE ROW LEVEL SECURITY;
ALTER TABLE owners ENABLE ROW LEVEL SECURITY;
ALTER TABLE pets ENABLE ROW LEVEL SECURITY;

-- Users: solo el dueño puede ver/modificar su propio registro
CREATE POLICY "Users: ver propio" ON users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users: insertar propio" ON users
  FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users: actualizar propio" ON users
  FOR UPDATE USING (auth.uid() = id);

-- Walkers: cualquier autenticado puede ver; solo el paseador puede modificar
CREATE POLICY "Walkers: ver todos" ON walkers
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Walkers: insertar propio" ON walkers
  FOR INSERT WITH CHECK (
    auth.uid() = user_id
  );

CREATE POLICY "Walkers: actualizar propio" ON walkers
  FOR UPDATE USING (
    auth.uid() = user_id
  );

CREATE POLICY "Walkers: eliminar propio" ON walkers
  FOR DELETE USING (auth.uid() = user_id);

-- Owners: solo el dueño puede ver/modificar su propio perfil
CREATE POLICY "Owners: ver propio" ON owners
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Owners: insertar propio" ON owners
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Owners: actualizar propio" ON owners
  FOR UPDATE USING (auth.uid() = user_id);

-- Pets: solo el dueño del owner puede ver/modificar sus mascotas
CREATE POLICY "Pets: ver propias" ON pets
  FOR SELECT USING (
    owner_id IN (SELECT id FROM owners WHERE user_id = auth.uid())
  );

CREATE POLICY "Pets: insertar propias" ON pets
  FOR INSERT WITH CHECK (
    owner_id IN (SELECT id FROM owners WHERE user_id = auth.uid())
  );

CREATE POLICY "Pets: eliminar propias" ON pets
  FOR DELETE USING (
    owner_id IN (SELECT id FROM owners WHERE user_id = auth.uid())
  );

-- =====================================================
-- STORAGE: Bucket 'avatars'
-- Ejecutar en: Supabase Dashboard > Storage
-- O usar el SQL a continuación:
-- =====================================================

-- Crear bucket avatars (público)
INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

-- Política de storage: cualquiera puede ver (público)
CREATE POLICY "Avatars: lectura pública" ON storage.objects
  FOR SELECT USING (bucket_id = 'avatars');

-- Política de storage: solo autenticados pueden subir a su carpeta
CREATE POLICY "Avatars: subir propio" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'avatars'
    AND auth.role() = 'authenticated'
    AND (
      name LIKE 'walkers/' || auth.uid() || '/%'
      OR name LIKE 'owners/' || auth.uid() || '/%'
    )
  );

CREATE POLICY "Avatars: actualizar propio" ON storage.objects
  FOR UPDATE USING (
    bucket_id = 'avatars'
    AND auth.role() = 'authenticated'
    AND (
      name LIKE 'walkers/' || auth.uid() || '/%'
      OR name LIKE 'owners/' || auth.uid() || '/%'
    )
  );
