-- =============================================================
-- migrations/001_baseline_schema.sql
-- Baseline schema for khetkekhiladi
-- Cleaned: no OWNER TO, no tiger/topology, no session noise
-- PostGIS kept (used for geometry columns on farms and plots)
-- =============================================================

-- Extensions
CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;

-- =============================================================
-- ENUM TYPES
-- =============================================================

CREATE TYPE public.crop_category_enum AS ENUM (
    'vegetable',
    'fruit',
    'grain',
    'legume',
    'herb',
    'perennial',
    'other'
);

CREATE TYPE public.farming_type_enum AS ENUM (
    'permaculture',
    'conventional'
);

CREATE TYPE public.irrigation_type_enum AS ENUM (
    'drip',
    'flood',
    'rain-fed',
    'sprinkler',
    'other'
);

CREATE TYPE public.planting_status_enum AS ENUM (
    'planned',
    'active',
    'completed',
    'failed',
    'abandoned'
);

CREATE TYPE public.quantity_unit_enum AS ENUM (
    'kg',
    'nos'
);

CREATE TYPE public.resource_type_enum AS ENUM (
    'equipment',
    'labor',
    'material',
    'water',
    'biological',
    'energy',
    'other'
);

CREATE TYPE public.user_role AS ENUM (
    'Viewer',
    'Editor',
    'Admin',
    'Custom'
);

-- =============================================================
-- FUNCTIONS
-- =============================================================

CREATE FUNCTION public.upsert_sowing_record(
    p_sowing_id text,
    p_plot_id text,
    p_variety_id text,
    p_planting_date text,
    p_quantity_planted text,
    p_quantity_unit text,
    p_seed_source text,
    p_expected_first_harvest text,
    p_expected_final_harvest text,
    p_status text,
    p_is_continuous_harvest boolean,
    p_estimated_harvest_interval_days text,
    p_is_replanting boolean,
    p_original_sowing_id text,
    p_area_utilized_percent text,
    p_notes text
) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_id INT;
BEGIN

INSERT INTO sowing_records (
    plot_id,
    variety_id,
    planting_date,
    quantity_planted,
    quantity_unit,
    seed_source,
    expected_first_harvest,
    expected_final_harvest,
    status,
    is_continuous_harvest,
    estimated_harvest_interval_days,
    is_replanting,
    original_sowing_id,
    area_utilized_percent,
    notes,
    created_at,
    updated_at
)
VALUES (
    NULLIF(NULLIF(p_plot_id, ''), 'null')::int,
    NULLIF(NULLIF(p_variety_id, ''), 'null')::int,
    NULLIF(NULLIF(p_planting_date, ''), 'null')::date,
    CASE
        WHEN NULLIF(NULLIF(p_quantity_planted, ''), 'null') IS NULL THEN NULL
        ELSE p_quantity_planted::numeric
    END,
    CASE
        WHEN NULLIF(NULLIF(p_quantity_unit, ''), 'null') IS NULL THEN NULL
        ELSE p_quantity_unit::quantity_unit_enum
    END,
    NULLIF(NULLIF(p_seed_source, ''), 'null'),
    NULLIF(NULLIF(p_expected_first_harvest, ''), 'null')::date,
    NULLIF(NULLIF(p_expected_final_harvest, ''), 'null')::date,
    NULLIF(NULLIF(p_status, ''), 'null')::planting_status_enum,
    COALESCE(p_is_continuous_harvest, false),
    NULLIF(NULLIF(p_estimated_harvest_interval_days, ''), 'null')::int,
    COALESCE(p_is_replanting, false),
    NULLIF(NULLIF(p_original_sowing_id, ''), 'null')::int,
    NULLIF(NULLIF(p_area_utilized_percent, ''), 'null')::numeric,
    NULLIF(NULLIF(p_notes, ''), 'null'),
    NOW(),
    NOW()
)
ON CONFLICT (sowing_id)
DO UPDATE SET
    planting_date = EXCLUDED.planting_date,
    quantity_planted = EXCLUDED.quantity_planted,
    quantity_unit = EXCLUDED.quantity_unit,
    seed_source = EXCLUDED.seed_source,
    expected_first_harvest = EXCLUDED.expected_first_harvest,
    expected_final_harvest = EXCLUDED.expected_final_harvest,
    status = EXCLUDED.status,
    is_continuous_harvest = EXCLUDED.is_continuous_harvest,
    estimated_harvest_interval_days = EXCLUDED.estimated_harvest_interval_days,
    is_replanting = EXCLUDED.is_replanting,
    original_sowing_id = EXCLUDED.original_sowing_id,
    area_utilized_percent = EXCLUDED.area_utilized_percent,
    notes = EXCLUDED.notes,
    updated_at = NOW()
RETURNING sowing_id INTO v_id;

RETURN v_id;

END;
$$;

-- =============================================================
-- SEQUENCES
-- =============================================================

CREATE SEQUENCE public.app_users_id_seq AS integer START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;
CREATE SEQUENCE public.crop_varieties_variety_id_seq AS integer START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;
CREATE SEQUENCE public.farms_farm_id_seq AS integer START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;
CREATE SEQUENCE public.harvest_records_harvest_id_seq AS integer START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;
CREATE SEQUENCE public.input_records_input_id_seq AS integer START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;
CREATE SEQUENCE public.plots_plot_id_seq AS integer START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;
CREATE SEQUENCE public.resources_resource_id_seq AS integer START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;
CREATE SEQUENCE public.soil_health_records_soil_id_seq AS integer START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;

-- =============================================================
-- TABLES
-- =============================================================

CREATE TABLE public.app_users (
    id integer NOT NULL DEFAULT nextval('public.app_users_id_seq'::regclass),
    email character varying(255) NOT NULL,
    full_name character varying(100),
    role public.user_role DEFAULT 'Viewer'::public.user_role NOT NULL,
    user_group character varying(50),
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);

ALTER SEQUENCE public.app_users_id_seq OWNED BY public.app_users.id;

CREATE TABLE public.farms (
    farm_id integer NOT NULL DEFAULT nextval('public.farms_farm_id_seq'::regclass),
    farm_name character varying(255) NOT NULL,
    farming_type public.farming_type_enum NOT NULL,
    total_acreage numeric(10,4) NOT NULL,
    location public.geometry(Point,4326),
    state character varying(100),
    district character varying(100),
    owner_name character varying(255),
    contact_email character varying(255),
    contact_phone character varying(20),
    established_year integer,
    notes text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    is_active boolean DEFAULT true
);

COMMENT ON TABLE public.farms IS 'Master table for farms; enables comparison between permaculture and conventional systems';

ALTER SEQUENCE public.farms_farm_id_seq OWNED BY public.farms.farm_id;

CREATE TABLE public.plots (
    plot_id integer NOT NULL DEFAULT nextval('public.plots_plot_id_seq'::regclass),
    farm_id integer NOT NULL,
    plot_number character varying(50) NOT NULL,
    acreage numeric(10,4) NOT NULL,
    soil_type character varying(100),
    irrigation_type public.irrigation_type_enum,
    location public.geometry(Polygon,4326),
    elevation integer,
    slope_percent numeric(5,2),
    aspect character varying(20),
    notes text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    is_active boolean DEFAULT true
);

COMMENT ON TABLE public.plots IS 'Individual cultivation plots within a farm, including spatial boundaries and terrain data';

ALTER SEQUENCE public.plots_plot_id_seq OWNED BY public.plots.plot_id;

CREATE TABLE public.crop_varieties (
    variety_id integer NOT NULL DEFAULT nextval('public.crop_varieties_variety_id_seq'::regclass),
    crop_name character varying(100) NOT NULL,
    variety_name character varying(100) NOT NULL,
    crop_category public.crop_category_enum NOT NULL,
    yield_unit character varying(50) DEFAULT 'kg'::character varying NOT NULL,
    description text,
    typical_yield_per_acre numeric(12,4),
    growing_days integer,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    is_active boolean DEFAULT true
);

COMMENT ON TABLE public.crop_varieties IS 'Master list of crop varieties cultivated on the farm';

ALTER SEQUENCE public.crop_varieties_variety_id_seq OWNED BY public.crop_varieties.variety_id;

CREATE TABLE public.resources (
    resource_id integer NOT NULL DEFAULT nextval('public.resources_resource_id_seq'::regclass),
    resource_type public.resource_type_enum NOT NULL,
    resource_name character varying(150) NOT NULL,
    unit character varying(50) NOT NULL,
    description text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    is_active boolean DEFAULT true
);

ALTER SEQUENCE public.resources_resource_id_seq OWNED BY public.resources.resource_id;

CREATE TABLE public.sowing_records (
    sowing_id integer NOT NULL,
    plot_id integer NOT NULL,
    variety_id integer NOT NULL,
    planting_date date NOT NULL,
    quantity_planted numeric(12,4) NOT NULL,
    seed_source character varying(255),
    expected_first_harvest date,
    expected_final_harvest date,
    status public.planting_status_enum DEFAULT 'active'::public.planting_status_enum NOT NULL,
    is_continuous_harvest boolean DEFAULT false NOT NULL,
    estimated_harvest_interval_days integer,
    is_replanting boolean DEFAULT false NOT NULL,
    original_sowing_id integer,
    area_utilized_percent numeric(5,2) DEFAULT 100 NOT NULL,
    notes text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    quantity_unit public.quantity_unit_enum NOT NULL,
    CONSTRAINT sowing_records_area_utilized_percent_check CHECK (((area_utilized_percent > (0)::numeric) AND (area_utilized_percent <= (100)::numeric))),
    CONSTRAINT sowing_records_check CHECK (((NOT is_continuous_harvest) OR (estimated_harvest_interval_days IS NOT NULL))),
    CONSTRAINT sowing_records_check1 CHECK (((expected_first_harvest IS NULL) OR (expected_first_harvest >= planting_date))),
    CONSTRAINT sowing_records_check2 CHECK (((expected_final_harvest IS NULL) OR (expected_final_harvest >= planting_date)))
);

ALTER TABLE public.sowing_records ALTER COLUMN sowing_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.sowing_records_sowing_id_seq
    START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1
);

COMMENT ON TABLE public.sowing_records IS 'Records of crop sowings including planting dates, lifecycle status, and expected harvest windows';

CREATE TABLE public.harvest_records (
    harvest_id integer NOT NULL DEFAULT nextval('public.harvest_records_harvest_id_seq'::regclass),
    plot_id integer NOT NULL,
    variety_id integer NOT NULL,
    harvest_date date NOT NULL,
    harvest_time_start time without time zone,
    harvest_time_end time without time zone,
    quantity_harvested numeric(12,4) NOT NULL,
    quality_grade character varying(20),
    harvest_sequence_number integer DEFAULT 1,
    estimated_remaining_yield numeric(12,4),
    notes text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE public.harvest_records IS 'Records of harvest events capturing yield quantity, quality, and harvest cycles';

ALTER SEQUENCE public.harvest_records_harvest_id_seq OWNED BY public.harvest_records.harvest_id;

CREATE TABLE public.input_records (
    input_id integer NOT NULL DEFAULT nextval('public.input_records_input_id_seq'::regclass),
    plot_id integer NOT NULL,
    resource_id integer NOT NULL,
    quantity numeric(12,4) NOT NULL,
    date_recorded date NOT NULL,
    activity_description character varying(255),
    assigned_to character varying(255),
    batch_id character varying(100),
    notes text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE public.input_records IS 'Tracking of resource usage such as labor, equipment, water, and organic materials';

ALTER SEQUENCE public.input_records_input_id_seq OWNED BY public.input_records.input_id;

CREATE TABLE public.soil_health_records (
    soil_id integer NOT NULL DEFAULT nextval('public.soil_health_records_soil_id_seq'::regclass),
    plot_id integer NOT NULL,
    measurement_date date NOT NULL,
    organic_matter_percent numeric(5,2),
    carbon_percent numeric(5,2),
    ph numeric(4,2),
    nitrogen_ppm numeric(8,2),
    phosphorus_ppm numeric(8,2),
    potassium_ppm numeric(8,2),
    microbial_count character varying(100),
    texture_class character varying(50),
    color character varying(50),
    moisture_level character varying(50),
    notes text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE public.soil_health_records IS 'Periodic soil health observations including organic carbon and biological indicators';

ALTER SEQUENCE public.soil_health_records_soil_id_seq OWNED BY public.soil_health_records.soil_id;

-- =============================================================
-- VIEWS
-- =============================================================

CREATE VIEW public.farm_cumulative_yield_rolling AS
 WITH monthly AS (
         SELECT (date_trunc('month'::text, (h.harvest_date)::timestamp with time zone))::date AS month,
            sum(h.quantity_harvested) AS monthly_kg
           FROM public.harvest_records h
          WHERE (h.harvest_date >= (CURRENT_DATE - '365 days'::interval))
          GROUP BY ((date_trunc('month'::text, (h.harvest_date)::timestamp with time zone))::date)
        )
 SELECT month,
    monthly_kg,
    sum(monthly_kg) OVER (ORDER BY month) AS cumulative_kg
   FROM monthly
  ORDER BY month;

CREATE VIEW public.farm_monthly_yield_rolling AS
 SELECT (date_trunc('month'::text, (harvest_date)::timestamp with time zone))::date AS month,
    sum(quantity_harvested) AS monthly_kg
   FROM public.harvest_records h
  WHERE (harvest_date >= (CURRENT_DATE - '365 days'::interval))
  GROUP BY ((date_trunc('month'::text, (harvest_date)::timestamp with time zone))::date)
  ORDER BY ((date_trunc('month'::text, (harvest_date)::timestamp with time zone))::date);

CREATE VIEW public.farm_yield_rolling_365 AS
 SELECT f.farm_id,
    f.farm_name,
    p.plot_id,
    p.plot_number,
    p.acreage,
    count(h.harvest_id) AS number_of_harvests,
    COALESCE(sum(h.quantity_harvested), (0)::numeric) AS total_yield_kg,
    round((COALESCE(sum(h.quantity_harvested), (0)::numeric) / NULLIF(p.acreage, (0)::numeric)), 2) AS yield_kg_per_acre,
    round((COALESCE(sum(h.quantity_harvested), (0)::numeric) / (p.acreage * (43560)::numeric)), 4) AS yield_kg_per_sqft,
    1.0 AS target_kg_per_sqft,
    round(((COALESCE(sum(h.quantity_harvested), (0)::numeric) / (p.acreage * (43560)::numeric)) - 1.0), 4) AS delta_vs_target
   FROM ((public.farms f
     JOIN public.plots p ON ((f.farm_id = p.farm_id)))
     LEFT JOIN public.harvest_records h ON (((p.plot_id = h.plot_id) AND (h.harvest_date >= (CURRENT_DATE - '365 days'::interval)))))
  GROUP BY f.farm_id, f.farm_name, p.plot_id, p.plot_number, p.acreage;

CREATE VIEW public.farm_yield_summary AS
 SELECT f.farm_id,
    f.farm_name,
    f.farming_type,
    p.plot_id,
    p.plot_number,
    p.acreage,
    (date_trunc('year'::text, (h.harvest_date)::timestamp with time zone))::date AS harvest_year,
    count(h.harvest_id) AS number_of_harvests,
    sum(h.quantity_harvested) AS total_yield_kg,
    round((sum(h.quantity_harvested) / NULLIF(p.acreage, (0)::numeric)), 2) AS yield_kg_per_acre,
    round((sum(h.quantity_harvested) / (p.acreage * (43560)::numeric)), 4) AS yield_kg_per_sqft,
    1.0 AS target_kg_per_sqft,
    round(((sum(h.quantity_harvested) / (p.acreage * (43560)::numeric)) - 1.0), 4) AS delta_vs_target
   FROM ((public.farms f
     JOIN public.plots p ON ((f.farm_id = p.farm_id)))
     JOIN public.harvest_records h ON ((p.plot_id = h.plot_id)))
  GROUP BY f.farm_id, f.farm_name, f.farming_type, p.plot_id, p.plot_number, p.acreage, (date_trunc('year'::text, (h.harvest_date)::timestamp with time zone));

COMMENT ON VIEW public.farm_yield_summary IS 'Aggregated yield metrics per farm, plot, crop, and season';

CREATE VIEW public.planting_pulse AS
 SELECT s.sowing_id,
    s.plot_id,
    cv.crop_name,
    cv.variety_name,
    s.planting_date,
    s.expected_first_harvest,
    s.expected_final_harvest,
    s.status AS sowing_status,
    s.area_utilized_percent,
    s.is_continuous_harvest,
        CASE
            WHEN (s.status = 'completed'::public.planting_status_enum) THEN 'Closed'::text
            WHEN (s.status = 'abandoned'::public.planting_status_enum) THEN 'Biomass / Seed Mode'::text
            WHEN ((s.status = 'active'::public.planting_status_enum) AND (s.expected_first_harvest IS NOT NULL) AND (CURRENT_DATE < s.expected_first_harvest)) THEN 'Growing (Pre-Harvest)'::text
            WHEN ((s.status = 'active'::public.planting_status_enum) AND (s.expected_first_harvest IS NOT NULL) AND (CURRENT_DATE >= s.expected_first_harvest) AND ((s.expected_final_harvest IS NULL) OR (CURRENT_DATE <= s.expected_final_harvest))) THEN 'Currently Producing'::text
            WHEN ((s.status = 'active'::public.planting_status_enum) AND (s.expected_final_harvest IS NOT NULL) AND (CURRENT_DATE > s.expected_final_harvest)) THEN 'Overdue for Closure'::text
            ELSE 'Planned / Unknown'::text
        END AS operational_status,
    count(h.harvest_id) AS harvest_events,
    COALESCE(sum(h.quantity_harvested), (0)::numeric) AS life_to_date_yield,
    max(h.harvest_date) AS last_harvest_date,
        CASE
            WHEN ((s.expected_first_harvest IS NOT NULL) AND (CURRENT_DATE > s.expected_first_harvest) AND (count(h.harvest_id) = 0)) THEN 'Harvest Delayed'::text
            WHEN ((s.expected_final_harvest IS NOT NULL) AND (CURRENT_DATE > s.expected_final_harvest)) THEN 'Past Expected Window'::text
            ELSE 'On Track'::text
        END AS risk_flag
   FROM ((public.sowing_records s
     JOIN public.crop_varieties cv ON ((s.variety_id = cv.variety_id)))
     LEFT JOIN public.harvest_records h ON (((h.plot_id = s.plot_id) AND (h.variety_id = s.variety_id) AND (h.harvest_date >= s.planting_date))))
  WHERE (s.status <> 'completed'::public.planting_status_enum)
  GROUP BY s.sowing_id, s.plot_id, cv.crop_name, cv.variety_name, s.planting_date, s.expected_first_harvest, s.expected_final_harvest, s.status, s.area_utilized_percent, s.is_continuous_harvest;

CREATE VIEW public.plot_input_efficiency AS
 SELECT f.farm_id,
    f.farm_name,
    p.plot_id,
    p.plot_number,
    p.acreage,
    r.resource_type,
    r.resource_name,
    r.unit,
    (date_trunc('year'::text, (i.date_recorded)::timestamp with time zone))::date AS year,
    sum(i.quantity) AS total_input_quantity,
    sum(h.quantity_harvested) AS total_yield_kg,
    round((sum(h.quantity_harvested) / NULLIF(sum(i.quantity), (0)::numeric)), 4) AS kg_per_unit_input,
    round((sum(h.quantity_harvested) / NULLIF(p.acreage, (0)::numeric)), 2) AS yield_kg_per_acre
   FROM ((((public.plots p
     JOIN public.farms f ON ((p.farm_id = f.farm_id)))
     JOIN public.input_records i ON ((p.plot_id = i.plot_id)))
     JOIN public.resources r ON ((i.resource_id = r.resource_id)))
     LEFT JOIN public.harvest_records h ON (((p.plot_id = h.plot_id) AND (date_trunc('year'::text, (h.harvest_date)::timestamp with time zone) = date_trunc('year'::text, (i.date_recorded)::timestamp with time zone)))))
  GROUP BY f.farm_id, f.farm_name, p.plot_id, p.plot_number, p.acreage, r.resource_type, r.resource_name, r.unit, (date_trunc('year'::text, (i.date_recorded)::timestamp with time zone));

COMMENT ON VIEW public.plot_input_efficiency IS 'Analysis of yield produced per unit of inputs such as water, labor, and materials';

-- =============================================================
-- PRIMARY KEYS & UNIQUE CONSTRAINTS
-- =============================================================

ALTER TABLE ONLY public.app_users ADD CONSTRAINT app_users_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.app_users ADD CONSTRAINT app_users_email_key UNIQUE (email);

ALTER TABLE ONLY public.farms ADD CONSTRAINT farms_pkey PRIMARY KEY (farm_id);
ALTER TABLE ONLY public.farms ADD CONSTRAINT farms_farm_name_key UNIQUE (farm_name);

ALTER TABLE ONLY public.plots ADD CONSTRAINT plots_pkey PRIMARY KEY (plot_id);
ALTER TABLE ONLY public.plots ADD CONSTRAINT plots_farm_id_plot_number_key UNIQUE (farm_id, plot_number);

ALTER TABLE ONLY public.crop_varieties ADD CONSTRAINT crop_varieties_pkey PRIMARY KEY (variety_id);
ALTER TABLE ONLY public.crop_varieties ADD CONSTRAINT crop_varieties_crop_name_variety_name_key UNIQUE (crop_name, variety_name);

ALTER TABLE ONLY public.resources ADD CONSTRAINT resources_pkey PRIMARY KEY (resource_id);
ALTER TABLE ONLY public.resources ADD CONSTRAINT resources_resource_name_key UNIQUE (resource_name);

ALTER TABLE ONLY public.sowing_records ADD CONSTRAINT sowing_records_pkey PRIMARY KEY (sowing_id);

ALTER TABLE ONLY public.harvest_records ADD CONSTRAINT harvest_records_pkey PRIMARY KEY (harvest_id);

ALTER TABLE ONLY public.input_records ADD CONSTRAINT input_records_pkey PRIMARY KEY (input_id);

ALTER TABLE ONLY public.soil_health_records ADD CONSTRAINT soil_health_records_pkey PRIMARY KEY (soil_id);

-- =============================================================
-- FOREIGN KEYS
-- =============================================================

ALTER TABLE ONLY public.plots
    ADD CONSTRAINT plots_farm_id_fkey FOREIGN KEY (farm_id) REFERENCES public.farms(farm_id) ON DELETE RESTRICT;

ALTER TABLE ONLY public.sowing_records
    ADD CONSTRAINT sowing_records_plot_id_fkey FOREIGN KEY (plot_id) REFERENCES public.plots(plot_id) ON DELETE RESTRICT;

ALTER TABLE ONLY public.sowing_records
    ADD CONSTRAINT sowing_records_variety_id_fkey FOREIGN KEY (variety_id) REFERENCES public.crop_varieties(variety_id) ON DELETE RESTRICT;

ALTER TABLE ONLY public.sowing_records
    ADD CONSTRAINT sowing_records_original_sowing_id_fkey FOREIGN KEY (original_sowing_id) REFERENCES public.sowing_records(sowing_id);

ALTER TABLE ONLY public.harvest_records
    ADD CONSTRAINT harvest_records_plot_id_fkey FOREIGN KEY (plot_id) REFERENCES public.plots(plot_id) ON DELETE RESTRICT;

ALTER TABLE ONLY public.harvest_records
    ADD CONSTRAINT harvest_records_variety_id_fkey FOREIGN KEY (variety_id) REFERENCES public.crop_varieties(variety_id) ON DELETE RESTRICT;

ALTER TABLE ONLY public.input_records
    ADD CONSTRAINT input_records_plot_id_fkey FOREIGN KEY (plot_id) REFERENCES public.plots(plot_id) ON DELETE RESTRICT;

ALTER TABLE ONLY public.input_records
    ADD CONSTRAINT input_records_resource_id_fkey FOREIGN KEY (resource_id) REFERENCES public.resources(resource_id) ON DELETE RESTRICT;

ALTER TABLE ONLY public.soil_health_records
    ADD CONSTRAINT soil_health_records_plot_id_fkey FOREIGN KEY (plot_id) REFERENCES public.plots(plot_id) ON DELETE RESTRICT;

-- =============================================================
-- INDEXES
-- =============================================================

CREATE INDEX idx_farms_active ON public.farms USING btree (is_active);
CREATE INDEX idx_farms_farming_type ON public.farms USING btree (farming_type);
CREATE INDEX idx_farms_location ON public.farms USING gist (location);

CREATE INDEX idx_plots_active ON public.plots USING btree (is_active);
CREATE INDEX idx_plots_farm_id ON public.plots USING btree (farm_id);
CREATE INDEX idx_plots_location ON public.plots USING gist (location);

CREATE INDEX idx_crop_varieties_active ON public.crop_varieties USING btree (is_active);
CREATE INDEX idx_varieties_category ON public.crop_varieties USING btree (crop_category);
CREATE INDEX idx_varieties_crop_name ON public.crop_varieties USING btree (crop_name);

CREATE INDEX idx_resources_active ON public.resources USING btree (is_active);
CREATE INDEX idx_resources_type ON public.resources USING btree (resource_type);

CREATE INDEX idx_sowing_active ON public.sowing_records USING btree (status) WHERE (status = ANY (ARRAY['active'::public.planting_status_enum, 'planned'::public.planting_status_enum]));
CREATE INDEX idx_sowing_overlapping ON public.sowing_records USING btree (plot_id, planting_date, expected_final_harvest);
CREATE INDEX idx_sowing_planting_date ON public.sowing_records USING btree (planting_date);
CREATE INDEX idx_sowing_plot_id ON public.sowing_records USING btree (plot_id);
CREATE INDEX idx_sowing_status ON public.sowing_records USING btree (status);
CREATE INDEX idx_sowing_variety_id ON public.sowing_records USING btree (variety_id);

CREATE INDEX idx_harvest_date ON public.harvest_records USING btree (harvest_date);
CREATE INDEX idx_harvest_plot_date ON public.harvest_records USING btree (plot_id, harvest_date);
CREATE INDEX idx_harvest_plot_id ON public.harvest_records USING btree (plot_id);
CREATE INDEX idx_harvest_sequence ON public.harvest_records USING btree (plot_id, harvest_sequence_number);

CREATE INDEX idx_input_date ON public.input_records USING btree (date_recorded);
CREATE INDEX idx_input_plot_id ON public.input_records USING btree (plot_id);
CREATE INDEX idx_input_resource_id ON public.input_records USING btree (resource_id);

CREATE INDEX idx_soil_measurement_date ON public.soil_health_records USING btree (measurement_date);
CREATE INDEX idx_soil_plot_id ON public.soil_health_records USING btree (plot_id);
