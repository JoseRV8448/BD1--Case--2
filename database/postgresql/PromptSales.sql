-- =========================================================
-- PromptSales (En PostgreSQL, usando pgAdmin4)
-- =========================================================


-- Creamos los esquemas para que funcione el ETL, control, registros (snap), el histórico y las tablas sumarizadas
CREATE SCHEMA IF NOT EXISTS meta;
CREATE SCHEMA IF NOT EXISTS snap; 
CREATE SCHEMA IF NOT EXISTS hist;  
CREATE SCHEMA IF NOT EXISTS dw;   

-- Acá hacemos la tabla de control de corridas y marcas (fechas) con info, estado, etc
CREATE TABLE IF NOT EXISTS meta.etl_run (
  run_id      bigserial PRIMARY KEY,
  started_at  timestamptz NOT NULL DEFAULT now(),
  ended_at    timestamptz,
  status      text CHECK (status IN ('OK','ERROR')) DEFAULT 'OK',
  details     text
);

-- Y esto sería la marca de tiempo, con el nombre y una fecha (defecto incluido)
CREATE TABLE IF NOT EXISTS meta.watermark (
  source_name text PRIMARY KEY,                          
  last_ts     timestamptz NOT NULL DEFAULT '2025-01-01 00:00:00+00' 
);

-- A partir de aquí creamos tablas para registrar la información de cada BD


-- PromptAds. Resumen inmediato por campaña (con la vista en SQL Server):
DROP TABLE IF EXISTS snap.ads_campaign_summary CASCADE;
CREATE TABLE snap.ads_campaign_summary (
-- guardamos básicamente todo lo que vendría en la info de campaña, mucho texto
  campaign_id     int PRIMARY KEY,
  business_id     int,
  name            text,
  starts_at       timestamptz,
  ends_at         timestamptz,
  channels_cnt    int,
  placements_cnt  int,
  impressions     bigint,
  reach           bigint,
  clicks          bigint,
  conversions     bigint,
  likes           bigint,
  comments        bigint,
  shares          bigint,
  saves           bigint,
  revenue_usd     numeric(18,2),
  cost_usd        numeric(18,2),
  roi_ads_only    numeric(18,4),
  
  -- clicks/impresiones y conversions que tuvo la campaña
  ctr             numeric(18,4),
  cvr             numeric(18,4),
  updated_at      timestamptz NOT NULL -- clave delta de ads
);


-- PromptCRM. Apartado de ventas por campaña: 
DROP TABLE IF EXISTS snap.crm_campaign_sales CASCADE;
CREATE TABLE snap.crm_campaign_sales (
-- Guardamos la info de crm
  campaign_id       int PRIMARY KEY,
  customers_reached bigint,
  orders            bigint,
  net_revenue_usd   numeric(18,2),
  updated_at        timestamptz NOT NULL  -- delta de CRM
);


-- PromptContent. Mensajes por campaña (Mongo):
DROP TABLE IF EXISTS snap.content_campaign_msgs CASCADE;
CREATE TABLE snap.content_campaign_msgs (
-- Guardamos la campaña, un conteo de sus mensajes y multimedia (además del delta, claro)
  campaign_id   text PRIMARY KEY,
  approved_msgs int,
  assets_used   int,
  last_change   timestamptz NOT NULL
);




-- Aquí índices a modo de estructuras de datos para ahorrarnos molestias con cada una de las bases
CREATE INDEX IF NOT EXISTS ix_ads_summary_updated ON snap.ads_campaign_summary(updated_at);
CREATE INDEX IF NOT EXISTS ix_crm_sales_updated   ON snap.crm_campaign_sales(updated_at);
CREATE INDEX IF NOT EXISTS ix_content_msgs_last   ON snap.content_campaign_msgs(last_change);


-- Esto es la tabla del histórico de ADS, guarda la información (una fila por campaña y corrida)
CREATE TABLE IF NOT EXISTS hist.ads_campaign_summary (
-- Guarda toda la info de la vista de cada campaña
-- Se diferencia de el snap en que este posee todos los estados de la campaña
-- Osease, todos los registro existentes desde que empezó la campaña, mientras snap es el más reciente
  run_id         bigint REFERENCES meta.etl_run(run_id),
  snapshot_at    timestamptz NOT NULL,   
  campaign_id    int,
  business_id    int,
  name           text,
  starts_at      timestamptz,
  ends_at        timestamptz,
  channels_cnt   int,
  placements_cnt int,
  impressions    bigint,
  reach          bigint,
  clicks         bigint,
  conversions    bigint,
  likes          bigint,
  comments       bigint,
  shares         bigint,
  saves          bigint,
  revenue_usd    numeric(18,2),
  cost_usd       numeric(18,2),
  roi_ads_only   numeric(18,4),
  ctr            numeric(18,4),
  cvr            numeric(18,4),
  updated_at     timestamptz,
  PRIMARY KEY (run_id, campaign_id)
);


-- Tabla sumarizada y su histórico:
DROP TABLE IF EXISTS dw.campaign_overview CASCADE;
CREATE TABLE dw.campaign_overview (
-- Acá se mezcla lo de Ads con CRM y dejamos 1 sola fila por campaña con el estado más reciente existente
  campaign_id        int PRIMARY KEY,
  name               text,
  business_id        int,
  starts_at          timestamptz,
  ends_at            timestamptz,
  impressions        bigint,
  reach              bigint,
  clicks             bigint,
  conversions        bigint,
  likes              bigint,
  comments           bigint,
  shares             bigint,
  saves              bigint,
  ads_revenue_usd    numeric(18,2),
  ads_cost_usd       numeric(18,2),
  crm_orders         bigint,
  crm_net_revenue    numeric(18,2),
  roi_ads_only       numeric(18,4),
  ctr                numeric(18,4),
  cvr                numeric(18,4),
  updated_at         timestamptz NOT NULL DEFAULT now()
);
-- Un índice con la función de facilitar consultas
CREATE INDEX IF NOT EXISTS ix_dw_overview_updated ON dw.campaign_overview(updated_at);


-- Este es lo mismo que lo de arriba pero con la funcionalidad del histórico:
-- Guardar todas las actualizaciones, no solo lam ás reciente
CREATE TABLE IF NOT EXISTS hist.campaign_overview (
  run_id             bigint REFERENCES meta.etl_run(run_id),
  snapshot_at        timestamptz NOT NULL,
  campaign_id        int,
  name               text,
  business_id        int,
  starts_at          timestamptz,
  ends_at            timestamptz,
  impressions        bigint,
  reach              bigint,
  clicks             bigint,
  conversions        bigint,
  likes              bigint,
  comments           bigint,
  shares             bigint,
  saves              bigint,
  ads_revenue_usd    numeric(18,2),
  ads_cost_usd       numeric(18,2),
  crm_orders         bigint,
  crm_net_revenue    numeric(18,2),
  roi_ads_only       numeric(18,4),
  ctr                numeric(18,4),
  cvr                numeric(18,4),
  PRIMARY KEY (run_id, campaign_id)
);
  



-- Y apartir de acá son funciones del ETL. Se llaman desde el pipeline:

-- 1. Iniciar corrida (devuelve run_id)
CREATE OR REPLACE FUNCTION meta.start_run() RETURNS bigint AS $$
DECLARE v_run_id bigint;
BEGIN
  INSERT INTO meta.etl_run DEFAULT VALUES RETURNING run_id INTO v_run_id;
  RETURN v_run_id;
END$$ LANGUAGE plpgsql;

-- 2. Poner el estado en OK
CREATE OR REPLACE FUNCTION meta.end_run_ok(p_run_id bigint) RETURNS void AS $$
BEGIN
  UPDATE meta.etl_run SET ended_at = now(), status='OK'
  WHERE run_id = p_run_id;
END$$ LANGUAGE plpgsql;

-- 3. Poner el estado en error (y detalles del error porque sino no hacemos nada)
CREATE OR REPLACE FUNCTION meta.end_run_error(p_run_id bigint, p_details text) RETURNS void AS $$
BEGIN
  UPDATE meta.etl_run SET ended_at = now(), status='ERROR', details=p_details
  WHERE run_id = p_run_id;
END$$ LANGUAGE plpgsql;

-- 4. Pone las marcas de agua en los registros
CREATE OR REPLACE FUNCTION meta.seed_watermarks() RETURNS void AS $$
BEGIN
  INSERT INTO meta.watermark(source_name) VALUES
    ('promptads.campaign_summary'),
    ('promptcrm.campaign_sales'),
    ('promptcontent.campaign_msgs')
  ON CONFLICT DO NOTHING;
END$$ LANGUAGE plpgsql;

-- 5. Esto para obtener las marcas de agua en un solo JSON
CREATE OR REPLACE FUNCTION meta.get_watermarks() RETURNS jsonb AS $$
DECLARE v jsonb;
BEGIN
  SELECT jsonb_object_agg(source_name, last_ts) INTO v FROM meta.watermark;
  RETURN COALESCE(v, '{}'::jsonb);
END$$ LANGUAGE plpgsql;

-- 6. Actualiza la marca de agua a la fecha y hora actuales
CREATE OR REPLACE FUNCTION meta.bump_watermark(p_source text) RETURNS void AS $$
BEGIN
  UPDATE meta.watermark SET last_ts = now() WHERE source_name = p_source;
END$$ LANGUAGE plpgsql;

-- 7. Snapshot histórico de ADS (guarda el estado actual de snap en el histórico)
CREATE OR REPLACE FUNCTION hist.take_ads_snapshot(p_run_id bigint) RETURNS void AS $$
BEGIN
  INSERT INTO hist.ads_campaign_summary (
    run_id, snapshot_at, campaign_id, business_id, name, starts_at, ends_at,
    channels_cnt, placements_cnt, impressions, reach, clicks, conversions,
    likes, comments, shares, saves, revenue_usd, cost_usd, roi_ads_only, ctr, cvr, updated_at
  )
  SELECT p_run_id, now(),
         campaign_id, business_id, name, starts_at, ends_at,
         channels_cnt, placements_cnt, impressions, reach, clicks, conversions,
         likes, comments, shares, saves, revenue_usd, cost_usd, roi_ads_only, ctr, cvr, updated_at
  FROM snap.ads_campaign_summary;
END$$ LANGUAGE plpgsql;

-- 8. Actualiza el sumarizado
CREATE OR REPLACE FUNCTION dw.rebuild_campaign_overview() RETURNS void AS $$
BEGIN
  INSERT INTO dw.campaign_overview AS t (
    campaign_id, name, business_id, starts_at, ends_at,
    impressions, reach, clicks, conversions,
    likes, comments, shares, saves,
    ads_revenue_usd, ads_cost_usd,
    crm_orders, crm_net_revenue,
    roi_ads_only, ctr, cvr, updated_at
  )
  SELECT
    a.campaign_id, a.name, a.business_id, a.starts_at, a.ends_at,
    a.impressions, a.reach, a.clicks, a.conversions,
    a.likes, a.comments, a.shares, a.saves,
    a.revenue_usd, a.cost_usd,
    COALESCE(c.orders,0)       AS crm_orders,
    COALESCE(c.net_revenue_usd,0) AS crm_net_revenue,
    a.roi_ads_only, a.ctr, a.cvr, now()
  FROM snap.ads_campaign_summary a
  LEFT JOIN snap.crm_campaign_sales c USING (campaign_id)
  ON CONFLICT (campaign_id) DO UPDATE SET
    name = EXCLUDED.name,
    business_id = EXCLUDED.business_id,
    starts_at   = EXCLUDED.starts_at,
    ends_at     = EXCLUDED.ends_at,
    impressions = EXCLUDED.impressions,
    reach       = EXCLUDED.reach,
    clicks      = EXCLUDED.clicks,
    conversions = EXCLUDED.conversions,
    likes       = EXCLUDED.likes,
    comments    = EXCLUDED.comments,
    shares      = EXCLUDED.shares,
    saves       = EXCLUDED.saves,
    ads_revenue_usd = EXCLUDED.ads_revenue_usd,
    ads_cost_usd    = EXCLUDED.ads_cost_usd,
    crm_orders      = EXCLUDED.crm_orders,
    crm_net_revenue = EXCLUDED.crm_net_revenue,
    roi_ads_only    = EXCLUDED.roi_ads_only,
    ctr             = EXCLUDED.ctr,
    cvr             = EXCLUDED.cvr,
    updated_at      = now();
END$$ LANGUAGE plpgsql;

-- 9. Snapshot histórico del sumarizado (lo mismo que la 7 pero para ads y crm juntos)
CREATE OR REPLACE FUNCTION hist.take_overview_snapshot(p_run_id bigint) RETURNS void AS $$
BEGIN
  INSERT INTO hist.campaign_overview (
    run_id, snapshot_at, campaign_id, name, business_id, starts_at, ends_at,
    impressions, reach, clicks, conversions, likes, comments, shares, saves,
    ads_revenue_usd, ads_cost_usd, crm_orders, crm_net_revenue,
    roi_ads_only, ctr, cvr
  )
  SELECT p_run_id, now(), campaign_id, name, business_id, starts_at, ends_at,
         impressions, reach, clicks, conversions, likes, comments, shares, saves,
         ads_revenue_usd, ads_cost_usd, crm_orders, crm_net_revenue,
         roi_ads_only, ctr, cvr
  FROM dw.campaign_overview;
END$$ LANGUAGE plpgsql;


-- Hasta allí con el ETL