-- =====================================================
-- THE WALKING PETS - Supabase Schema (Fase 2)
-- Ejecutar en: Supabase Dashboard > SQL Editor
-- =====================================================

-- Services table
CREATE TABLE IF NOT EXISTS services (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  walker_id uuid NOT NULL REFERENCES walkers(id) ON DELETE CASCADE,
  type text NOT NULL CHECK (type IN ('paseo', 'cuidado', 'baño')),
  price decimal(10, 2) NOT NULL CHECK (price > 0),
  description text,
  image_url text,
  is_active boolean DEFAULT true,
  created_at timestamp WITH TIME ZONE DEFAULT now(),
  updated_at timestamp WITH TIME ZONE DEFAULT now()
);

-- Bookings table
CREATE TABLE IF NOT EXISTS bookings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  walker_id uuid NOT NULL REFERENCES walkers(id) ON DELETE CASCADE,
  owner_id uuid NOT NULL REFERENCES owners(id) ON DELETE CASCADE,
  service_id uuid REFERENCES services(id) ON DELETE SET NULL,
  pet_id uuid NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'accepted', 'in_progress', 'completed', 'cancelled')),
  scheduled_date timestamp WITH TIME ZONE NOT NULL,
  notes text,
  created_at timestamp WITH TIME ZONE DEFAULT now(),
  updated_at timestamp WITH TIME ZONE DEFAULT now()
);

-- Walker locations (para tiempo real)
CREATE TABLE IF NOT EXISTS walker_locations (
  walker_id uuid PRIMARY KEY REFERENCES walkers(id) ON DELETE CASCADE,
  latitude decimal(10, 8) NOT NULL,
  longitude decimal(11, 8) NOT NULL,
  is_sharing boolean DEFAULT false,
  last_updated timestamp WITH TIME ZONE DEFAULT now()
);

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_services_walker ON services(walker_id);
CREATE INDEX IF NOT EXISTS idx_services_active ON services(is_active);
CREATE INDEX IF NOT EXISTS idx_bookings_walker ON bookings(walker_id);
CREATE INDEX IF NOT EXISTS idx_bookings_owner ON bookings(owner_id);
CREATE INDEX IF NOT EXISTS idx_bookings_status ON bookings(status);

-- Habilitar Realtime para walker_locations
ALTER PUBLICATION supabase_realtime ADD TABLE walker_locations;

-- =====================================================
-- RLS DESHABILITADO (para desarrollo - Fase 1 ya lo hizo)
-- =====================================================
ALTER TABLE services DISABLE ROW LEVEL SECURITY;
ALTER TABLE bookings DISABLE ROW LEVEL SECURITY;
ALTER TABLE walker_locations DISABLE ROW LEVEL SECURITY;
