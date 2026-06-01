-- =============================================================
-- migrations/002_seed_data.sql
-- Minimal dev/test seed data
-- 1 farm, 1 plot, 5 crop varieties, 3 sowings, 3 harvest records
-- All 26 resources included (reference/lookup data)
-- =============================================================

-- -------------------------------------------------------------
-- USER
-- -------------------------------------------------------------
INSERT INTO public.app_users (id, email, full_name, role, user_group, is_active) VALUES
(1, 'admin@khet.dev', 'Dev Admin', 'Admin', 'Software Developer', true);

SELECT setval('public.app_users_id_seq', 1);

-- -------------------------------------------------------------
-- FARM
-- -------------------------------------------------------------
INSERT INTO public.farms (farm_id, farm_name, farming_type, total_acreage, state, district, owner_name, notes) VALUES
(1, 'AoL Permaculture', 'permaculture', 5.5, 'Karnataka', 'Kanakapura', 'AoL Permaculture', 'Seed data farm for dev/test');

SELECT setval('public.farms_farm_id_seq', 1);

-- -------------------------------------------------------------
-- PLOT
-- -------------------------------------------------------------
INSERT INTO public.plots (plot_id, farm_id, plot_number, acreage, irrigation_type, notes) VALUES
(1, 1, 'Plot 1', 0.0820, 'drip', 'Seed data plot for dev/test');

SELECT setval('public.plots_plot_id_seq', 1);

-- -------------------------------------------------------------
-- CROP VARIETIES (5 representative varieties)
-- -------------------------------------------------------------
INSERT INTO public.crop_varieties (variety_id, crop_name, variety_name, crop_category, yield_unit, description, typical_yield_per_acre, growing_days) VALUES
(1, 'Banana',      'Yellaki',          'fruit',     'kg', 'Popular South Indian banana',            0.0000,  330),
(2, 'Amaranthus',  'Local Green',      'vegetable', 'kg', 'Heat-tolerant leafy vegetable',          0.1100,   30),
(3, 'Amaranthus',  'Local Red',        'vegetable', 'kg', 'Local red/purple leafy variety',         0.1000,   25),
(4, 'Bean',        'Long Bean',        'legume',    'kg', 'Fast-growing climbing legume',           2.0000,   50),
(5, 'Basil',       'Sweet Basil',      'herb',      'kg', 'Continuous harvest aromatic herb',       4000.0000, 90);

SELECT setval('public.crop_varieties_variety_id_seq', 5);

-- -------------------------------------------------------------
-- RESOURCES (all 26 — reference/lookup data, keep complete)
-- -------------------------------------------------------------
INSERT INTO public.resources (resource_id, resource_type, resource_name, unit, description) VALUES
( 1, 'water',      'Borewell Water',        'liters',  'Groundwater used for irrigation'),
( 2, 'water',      'Rainwater Harvested',   'liters',  'Collected rainwater from tanks and ponds'),
( 3, 'water',      'Greywater',             'liters',  'Filtered household greywater for trees'),
( 4, 'labor',      'Manual Labor',          'hours',   'General farm labor activities'),
( 5, 'labor',      'Skilled Farm Labor',    'hours',   'Experienced permaculture practitioners'),
( 6, 'labor',      'Volunteer Labor',       'hours',   'Seva / volunteer contribution'),
( 7, 'equipment',  'Tractor',               'hours',   'Tractor usage for hauling and land prep'),
( 8, 'equipment',  'Power Tiller',          'hours',   'Small plot tillage and bed prep'),
( 9, 'equipment',  'Wood Chipper',          'hours',   'Chipping pruned biomass for mulch'),
(10, 'equipment',  'Water Pump',            'hours',   'Pump operation for irrigation'),
(11, 'equipment',  'Brush Cutter',          'hours',   'Grass and weed cutting'),
(12, 'material',   'Cow Dung (Fresh)',      'kg',      'Fresh cow dung for compost and preparations'),
(13, 'material',   'Cow Urine',             'liters',  'Used in natural formulations'),
(14, 'material',   'Farmyard Manure (FYM)', 'kg',      'Well-decomposed cow manure'),
(15, 'material',   'Vermicompost',          'kg',      'Worm-processed organic compost'),
(16, 'material',   'Leaf Litter / Biomass', 'kg',      'Collected dry leaves and biomass'),
(17, 'material',   'Mulch Straw',           'kg',      'Dry straw mulch for moisture retention'),
(18, 'biological', 'Jeevamrut',             'liters',  'Microbial culture for soil life'),
(19, 'biological', 'Beejamrut',             'liters',  'Seed treatment microbial solution'),
(20, 'biological', 'Panchagavya',           'liters',  'Natural growth stimulant'),
(21, 'biological', 'Vermiwash',             'liters',  'Liquid extract from vermicompost'),
(22, 'material',   'Seeds',                 'grams',   'Open-pollinated and native seeds'),
(23, 'material',   'Saplings',              'count',   'Nursery-raised plants'),
(24, 'material',   'Rhizomes / Tubers',     'kg',      'Ginger, turmeric, sweet potato planting material'),
(25, 'energy',     'Electricity',           'kWh',     'Electric power for pumps and tools'),
(26, 'energy',     'Diesel',                'liters',  'Fuel for tractor and machinery');

SELECT setval('public.resources_resource_id_seq', 26);

-- -------------------------------------------------------------
-- SOWING RECORDS (3 sowings on Plot 1)
-- -------------------------------------------------------------
INSERT INTO public.sowing_records
    (sowing_id, plot_id, variety_id, planting_date, quantity_planted, quantity_unit,
     seed_source, expected_first_harvest, expected_final_harvest,
     status, is_continuous_harvest, estimated_harvest_interval_days,
     is_replanting, area_utilized_percent, notes)
VALUES
(1, 1, 2, '2026-04-01', 0.50, 'kg', 'Local',
 '2026-05-01', '2026-05-15',
 'active', false, null, false, 50, 'Amaranthus green — seed data'),

(2, 1, 4, '2026-04-08', 0.20, 'kg', null,
 '2026-05-28', null,
 'active', false, null, false, 100, 'Long bean — seed data'),

(3, 1, 5, '2026-03-15', 0.10, 'kg', 'Self-saved',
 '2026-04-20', '2026-09-30',
 'active', true, 10, false, 30, 'Basil continuous harvest — seed data');

SELECT setval('public.sowing_records_sowing_id_seq', 3);

-- -------------------------------------------------------------
-- HARVEST RECORDS (3 harvests from the basil sowing above)
-- -------------------------------------------------------------
INSERT INTO public.harvest_records
    (harvest_id, plot_id, variety_id, harvest_date,
     harvest_time_start, harvest_time_end,
     quantity_harvested, quality_grade, harvest_sequence_number,
     estimated_remaining_yield, notes)
VALUES
(1, 1, 5, '2026-04-22', '07:00:00', '07:30:00', 1.20, 'A', 1, 8.00, 'First basil cut — seed data'),
(2, 1, 5, '2026-05-02', '07:05:00', '07:35:00', 1.40, 'A', 2, 7.00, 'Second cut — good regrowth'),
(3, 1, 5, '2026-05-12', '07:00:00', '07:40:00', 1.60, 'A', 3, 6.00, 'Third cut — peak aroma');

SELECT setval('public.harvest_records_harvest_id_seq', 3);
