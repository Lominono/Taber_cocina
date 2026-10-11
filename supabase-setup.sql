-- ============================================================
--  TABERNÁCULO SANTO — Cocina · Configuración Supabase
--  Ejecuta este archivo en Supabase > SQL Editor > New query
-- ============================================================

-- 1. Artículos del menú
create table if not exists menu_items (
  id          uuid primary key default gen_random_uuid(),
  nombre      text not null,
  categoria   text not null default '',
  precio      numeric(10,2) not null default 0,
  promo_qty   integer default 0,
  promo_precio numeric(10,2) default 0,
  promo_desc  text not null default '',
  descripcion text not null default '',
  activo      boolean not null default true,
  created_at  timestamptz not null default now()
);

-- 2. Promociones
create table if not exists promos (
  id          uuid primary key default gen_random_uuid(),
  nombre      text not null,
  descripcion text not null default '',
  precio      numeric(10,2) not null default 0,
  hasta       date,
  activa      boolean not null default true,
  created_at  timestamptz not null default now()
);

-- 3. Personas (miembros / clientes)
create table if not exists personas (
  id         uuid primary key default gen_random_uuid(),
  nombre     text not null,
  telefono   text not null default '',
  email      text not null default '',
  notas      text not null default '',
  created_at timestamptz not null default now()
);

-- 4. Ventas (cabecera)
create table if not exists ventas (
  id              uuid primary key default gen_random_uuid(),
  persona_id      uuid references personas(id) on delete set null,
  persona_nombre  text not null default 'Sin asignar',
  camarero        text not null default '',
  num_platos      integer not null default 0,
  notas           text default '',
  total           numeric(10,2) not null,
  pago            text not null default 'pendiente'
                  check (pago in ('efectivo','bizum','pendiente')),
  created_at      timestamptz not null default now()
);

-- Migraciones seguras para bases de datos existentes:
alter table menu_items add column if not exists promo_qty integer default 0;
alter table menu_items add column if not exists promo_precio numeric(10,2) default 0;
alter table menu_items add column if not exists promo_desc text default '';

alter table ventas add column if not exists camarero text default '';
alter table ventas add column if not exists num_platos integer default 0;
alter table ventas add column if not exists notas text default '';

-- 5. Líneas de cada venta
create table if not exists venta_lineas (
  id          uuid primary key default gen_random_uuid(),
  venta_id    uuid not null references ventas(id) on delete cascade,
  item_nombre text not null,
  precio      numeric(10,2) not null,
  qty         integer not null default 1,
  created_at  timestamptz not null default now()
);

-- 6. Reportes diarios (Cierres de caja guardados con Nombre y Apellidos)
create table if not exists reportes_diarios (
  id              uuid primary key default gen_random_uuid(),
  responsable     text not null, -- Nombre y Apellidos de la persona que cierra
  fecha           date not null default current_date,
  total_recaudado numeric(10,2) not null default 0,
  total_efectivo  numeric(10,2) not null default 0,
  total_bizum     numeric(10,2) not null default 0,
  total_pendiente numeric(10,2) not null default 0,
  num_ventas      integer not null default 0,
  desglose_items  jsonb default '[]'::jsonb,
  notas           text default '',
  created_at      timestamptz not null default now()
);

-- ============================================================
--  SEGURIDAD: RLS Y PERMISOS
-- ============================================================
alter table menu_items       disable row level security;
alter table promos           disable row level security;
alter table personas         disable row level security;
alter table ventas           disable row level security;
alter table venta_lineas     disable row level security;
alter table reportes_diarios disable row level security;

grant all on menu_items, promos, personas, ventas, venta_lineas, reportes_diarios to anon, authenticated;

-- ============================================================
--  BASE LIMPIA (Sin datos inventados)
-- ============================================================
-- Las tablas quedan creadas vacías y listas para que introduzcas
-- tus propios platos, precios y comandas reales desde la web.

-- NOTA: Si anteriormente ejecutaste los datos de prueba, puedes
-- eliminarlos ejecutando estas dos líneas:
-- delete from menu_items where nombre in ('Café solo', 'Café con leche', 'Zumo naranja', 'Agua', 'Bocadillo jamón', 'Bocadillo queso', 'Tostada con aceite', 'Napolitana', 'Croissant');
-- delete from promos where nombre in ('Menú del día', 'Desayuno');
