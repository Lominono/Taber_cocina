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

-- 7. Anotadores registrados (Sincronización de usuarios de Supabase con nombre real)
create table if not exists anotadores (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid,
  email           text not null unique,
  nombre_completo text not null,
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
alter table anotadores       disable row level security;

grant all on menu_items, promos, personas, ventas, venta_lineas, reportes_diarios, anotadores to anon, authenticated;

-- ============================================================
--  8. AUTO-CONFIRMAR USUARIOS (Sin confirmación de email)
-- ============================================================
-- Este trigger confirma automáticamente el email de cualquier
-- nuevo usuario que se registre en Supabase, permitiendo que
-- inicie sesión de inmediato sin esperar enlace por correo.

create or replace function public.auto_confirm_new_user()
returns trigger
language plpgsql
security definer
as $$
begin
  new.email_confirmed_at = coalesce(new.email_confirmed_at, now());
  new.confirmed_at = coalesce(new.confirmed_at, now());
  return new;
end;
$$;

drop trigger if exists on_auth_user_created_auto_confirm on auth.users;
create trigger on_auth_user_created_auto_confirm
  before insert on auth.users
  for each row execute function public.auto_confirm_new_user();

-- Trigger para guardar/sincronizar automáticamente en la tabla anotadores:
create or replace function public.sync_anotador_profile()
returns trigger
language plpgsql
security definer
as $$
begin
  insert into public.anotadores (user_id, email, nombre_completo)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1))
  )
  on conflict (email) do update
  set user_id = excluded.user_id,
      nombre_completo = coalesce(nullif(excluded.nombre_completo, ''), anotadores.nombre_completo);
  return new;
end;
$$;

drop trigger if exists on_auth_user_created_sync_anotador on auth.users;
create trigger on_auth_user_created_sync_anotador
  after insert on auth.users
  for each row execute function public.sync_anotador_profile();

-- ============================================================
--  BASE LIMPIA (Sin datos inventados)
-- ============================================================
-- Las tablas quedan creadas vacías y listas para que introduzcas
-- tus propios platos, precios y comandas reales desde la web.

-- NOTA: Si anteriormente ejecutaste los datos de prueba, puedes
-- eliminarlos ejecutando estas dos líneas:
-- delete from menu_items where nombre in ('Café solo', 'Café con leche', 'Zumo naranja', 'Agua', 'Bocadillo jamón', 'Bocadillo queso', 'Tostada con aceite', 'Napolitana', 'Croissant');
-- delete from promos where nombre in ('Menú del día', 'Desayuno');
