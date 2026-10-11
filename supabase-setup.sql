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
  total           numeric(10,2) not null,
  pago            text not null default 'pendiente'
                  check (pago in ('efectivo','bizum','pendiente')),
  created_at      timestamptz not null default now()
);

-- 5. Líneas de cada venta
create table if not exists venta_lineas (
  id          uuid primary key default gen_random_uuid(),
  venta_id    uuid not null references ventas(id) on delete cascade,
  item_nombre text not null,
  precio      numeric(10,2) not null,
  qty         integer not null default 1,
  created_at  timestamptz not null default now()
);

-- ============================================================
--  SEGURIDAD: RLS
--  Para uso interno (solo vosotros) es más sencillo
--  desactivar RLS. Si en el futuro quieres añadir autenticación
--  elimina las líneas "disable row level security" y configura
--  políticas adecuadas.
-- ============================================================

alter table menu_items   disable row level security;
alter table promos       disable row level security;
alter table personas     disable row level security;
alter table ventas       disable row level security;
alter table venta_lineas disable row level security;

-- ============================================================
--  DATOS DE EJEMPLO (opcional — borra si no los quieres)
-- ============================================================
insert into menu_items (nombre, categoria, precio, descripcion) values
  ('Café solo',         'Bebidas',     1.00, ''),
  ('Café con leche',    'Bebidas',     1.20, ''),
  ('Zumo naranja',      'Bebidas',     1.50, 'Natural'),
  ('Agua',              'Bebidas',     0.50, ''),
  ('Bocadillo jamón',   'Bocadillos',  2.50, ''),
  ('Bocadillo queso',   'Bocadillos',  2.00, ''),
  ('Tostada con aceite','Desayunos',   1.00, ''),
  ('Napolitana',        'Repostería',  1.20, ''),
  ('Croissant',         'Repostería',  1.00, '')
on conflict do nothing;

insert into promos (nombre, descripcion, precio) values
  ('Menú del día',    'Bocadillo + bebida + postre',  4.50),
  ('Desayuno',        'Café + tostada',               1.80)
on conflict do nothing;
