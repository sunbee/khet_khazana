BEGIN;

DO $$
DECLARE
    v_farm_id       int;
    v_plot_id       int;
    v_variety_id    int;
    v_sowing_id     int;
    v_enum_test     text;
BEGIN

    -- ============================================================
    -- SEED PREREQUISITE DATA
    -- ============================================================

    INSERT INTO farms (farm_name, farming_type, total_acreage, created_at, updated_at)
    VALUES ('Sowing Test Farm', 'permaculture'::farming_type_enum, 11, NOW(), NOW())
    RETURNING farm_id INTO v_farm_id;
    RAISE NOTICE 'SEED: farm_id=%', v_farm_id;

    INSERT INTO plots (farm_id, plot_number, irrigation_type, acreage, created_at, updated_at)
    VALUES (v_farm_id, 'P-SOWING-TEST', 'drip'::irrigation_type_enum, 1.0, NOW(), NOW())
    RETURNING plot_id INTO v_plot_id;
    RAISE NOTICE 'SEED: plot_id=%', v_plot_id;

    INSERT INTO crop_varieties (crop_name, variety_name, crop_category, created_at)
    VALUES ('Tomato', 'Roma', 'vegetable'::crop_category_enum, NOW())
    RETURNING variety_id INTO v_variety_id;
    RAISE NOTICE 'SEED: variety_id=%', v_variety_id;

    -- ============================================================
    -- EXPRESSION UNIT TESTS
    -- ============================================================

    -- T01: empty string → NULL for date
    ASSERT NULLIF(NULLIF(''::text, ''), 'null')::date IS NULL,
        'T01 FAIL: empty string should become NULL for date';
    RAISE NOTICE 'T01 PASS: empty string becomes NULL for date';

    -- T02: string "null" → NULL for date
    ASSERT NULLIF(NULLIF('null'::text, ''), 'null')::date IS NULL,
        'T02 FAIL: string null should become NULL for date';
    RAISE NOTICE 'T02 PASS: string null becomes NULL for date';

    -- T03: real date passes through
    ASSERT NULLIF(NULLIF('2024-03-15'::text, ''), 'null')::date = '2024-03-15'::date,
        'T03 FAIL: real date should pass through';
    RAISE NOTICE 'T03 PASS: real date passes through';

    -- T04: quantity_unit enum guard on empty string
    v_enum_test := '';
    ASSERT (CASE
        WHEN NULLIF(NULLIF(v_enum_test, ''), 'null') IS NULL THEN NULL
        ELSE v_enum_test::quantity_unit_enum
    END) IS NULL,
        'T04 FAIL: empty string quantity_unit guard should return NULL';
    RAISE NOTICE 'T04 PASS: empty string quantity_unit guard returns NULL';

    -- T05: quantity_unit enum guard on string "null"
    v_enum_test := 'null';
    ASSERT (CASE
        WHEN NULLIF(NULLIF(v_enum_test, ''), 'null') IS NULL THEN NULL
        ELSE v_enum_test::quantity_unit_enum
    END) IS NULL,
        'T05 FAIL: null string quantity_unit guard should return NULL';
    RAISE NOTICE 'T05 PASS: null string quantity_unit guard returns NULL';

    -- T06: valid quantity_unit passes through — replace 'kg' with actual enum value
    v_enum_test := 'kg';
    ASSERT (CASE
        WHEN NULLIF(NULLIF(v_enum_test, ''), 'null') IS NULL THEN NULL
        ELSE v_enum_test::quantity_unit_enum
    END) = 'kg'::quantity_unit_enum,
        'T06 FAIL: valid quantity_unit should pass through';
    RAISE NOTICE 'T06 PASS: valid quantity_unit passes through';

    -- T07: status enum guard on empty string
    v_enum_test := '';
    ASSERT (CASE
        WHEN NULLIF(NULLIF(v_enum_test, ''), 'null') IS NULL THEN NULL
        ELSE v_enum_test::planting_status_enum
    END) IS NULL,
        'T07 FAIL: empty string status guard should return NULL';
    RAISE NOTICE 'T07 PASS: empty string status guard returns NULL';

    -- T08: status enum guard on string "null"
    v_enum_test := 'null';
    ASSERT (CASE
        WHEN NULLIF(NULLIF(v_enum_test, ''), 'null') IS NULL THEN NULL
        ELSE v_enum_test::planting_status_enum
    END) IS NULL,
        'T08 FAIL: null string status guard should return NULL';
    RAISE NOTICE 'T08 PASS: null string status guard returns NULL';

    -- T09: valid status passes through — replace 'active' with actual enum value
    v_enum_test := 'active';
    ASSERT (CASE
        WHEN NULLIF(NULLIF(v_enum_test, ''), 'null') IS NULL THEN NULL
        ELSE v_enum_test::planting_status_enum
    END) = 'active'::planting_status_enum,
        'T09 FAIL: valid status should pass through';
    RAISE NOTICE 'T09 PASS: valid status passes through';

    -- T10: is_continuous_harvest null string → false via COALESCE
    ASSERT COALESCE(NULLIF(NULLIF('null'::text, ''), 'null')::boolean, false) = false,
        'T10 FAIL: null string bool should default to false';
    RAISE NOTICE 'T10 PASS: null string is_continuous_harvest defaults to false';

    -- T11: is_replanting explicit true passes through
    ASSERT COALESCE(NULLIF(NULLIF('true'::text, ''), 'null')::boolean, false) = true,
        'T11 FAIL: explicit true should pass through';
    RAISE NOTICE 'T11 PASS: explicit true is_replanting passes through';

    -- T12: area_utilized_percent real value passes through
    ASSERT NULLIF(NULLIF('75.5'::text, ''), 'null')::numeric = 75.5,
        'T12 FAIL: real numeric should pass through';
    RAISE NOTICE 'T12 PASS: area_utilized_percent real value passes through';

    -- T13: estimated_harvest_interval_days string "null" → NULL
    ASSERT NULLIF(NULLIF('null'::text, ''), 'null')::int IS NULL,
        'T13 FAIL: string null should become NULL for int';
    RAISE NOTICE 'T13 PASS: estimated_harvest_interval_days null string becomes NULL';

    -- ============================================================
    -- INSERT TESTS
    -- ============================================================

    -- T14: happy path full insert
    BEGIN
        INSERT INTO sowing_records (
            plot_id, variety_id, planting_date,
            quantity_planted, quantity_unit, seed_source,
            expected_first_harvest, expected_final_harvest,
            status, is_continuous_harvest,
            estimated_harvest_interval_days, is_replanting,
            original_sowing_id, area_utilized_percent,
            notes, created_at, updated_at
        )
        VALUES (
            v_plot_id, v_variety_id, '2024-03-15'::date,
            10.0, 'kg'::quantity_unit_enum, 'local supplier',
            '2024-06-15'::date, '2024-09-15'::date,
            'active'::planting_status_enum, false,
            7, false,
            NULL, 75.0,
            'test sowing', NOW(), NOW()
        )
        RETURNING sowing_id INTO v_sowing_id;
        RAISE NOTICE 'T14 PASS: happy path insert, sowing_id=%', v_sowing_id;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'T14 FAIL: happy path insert — %', SQLERRM;
    END;

	-- T15: happy path full insert
    BEGIN
        INSERT INTO sowing_records (
            plot_id, variety_id, planting_date,
            quantity_planted, quantity_unit, 
            status, area_utilized_percent,
            created_at, updated_at
        )
        VALUES (
            v_plot_id, v_variety_id, '2024-03-15'::date,
            10.0, 'kg'::quantity_unit_enum, 
            'active'::planting_status_enum, 75.0,
            NOW(), NOW()
        )
        RETURNING sowing_id INTO v_sowing_id;
        RAISE NOTICE 'T15 PASS: happy path insert, sowing_id=%', v_sowing_id;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'T15 FAIL: happy path insert — %', SQLERRM;
    END;

    -- T16: happy path full insert
    BEGIN
        INSERT INTO sowing_records (
            plot_id, variety_id, planting_date,
            quantity_planted, quantity_unit, 
            status, 
            created_at, updated_at
        )
        VALUES (
            v_plot_id, v_variety_id, '2024-03-15'::date,
            10.0, 'kg'::quantity_unit_enum, 
            'active'::planting_status_enum, 
            NOW(), NOW()
        )
        RETURNING sowing_id INTO v_sowing_id;
        RAISE NOTICE 'T16 PASS: happy path insert, sowing_id=%', v_sowing_id;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'T16 FAIL: happy path insert — %', SQLERRM;
    END;

	-- T17: happy path full insert
    BEGIN
        INSERT INTO sowing_records (
            plot_id, variety_id, planting_date,
            quantity_planted, quantity_unit, 
            created_at, updated_at
        )
        VALUES (
            v_plot_id, v_variety_id, '2024-03-15'::date,
            10.0, 'kg'::quantity_unit_enum, 
            NOW(), NOW()
        )
        RETURNING sowing_id INTO v_sowing_id;
        RAISE NOTICE 'T17 PASS: happy path insert, sowing_id=%', v_sowing_id;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'T17 FAIL: happy path insert — %', SQLERRM;
    END;

	-- T18: NULL plot_id should throw
    BEGIN
        INSERT INTO sowing_records (plot_id, variety_id, planting_date, created_at, updated_at)
        VALUES (NULL, v_variety_id, '2024-03-15'::date, NOW(), NOW());
        RAISE NOTICE 'T18 FAIL: NULL plot_id should have thrown';
    EXCEPTION WHEN not_null_violation THEN
        RAISE NOTICE 'T18 PASS: NULL plot_id correctly rejected - %', SQLERRM;
    END;

    -- T19: NULL variety_id should throw
    BEGIN
        INSERT INTO sowing_records (plot_id, variety_id, planting_date, created_at, updated_at)
        VALUES (v_plot_id, NULL, '2024-03-15'::date, NOW(), NOW());
        RAISE NOTICE 'T19 FAIL: NULL variety_id should have thrown';
    EXCEPTION WHEN not_null_violation THEN
        RAISE NOTICE 'T19 PASS: NULL variety_id correctly rejected - %', SQLERRM;
    END;

    -- T20: NULL planting_date should throw
    BEGIN
        INSERT INTO sowing_records (plot_id, variety_id, planting_date, created_at, updated_at)
        VALUES (v_plot_id, v_variety_id, NULL, NOW(), NOW());
        RAISE NOTICE 'T20 FAIL: NULL planting_date should have thrown';
    EXCEPTION WHEN not_null_violation THEN
        RAISE NOTICE 'T20 PASS: NULL planting_date correctly rejected - %', SQLERRM;
    END;

    -- T21: invalid plot FK should throw
    BEGIN
        INSERT INTO sowing_records (
			plot_id, variety_id, planting_date, 
			quantity_planted, quantity_unit, 
			created_at, updated_at)
        VALUES (
			999999, v_variety_id, '2024-03-15'::date, 
			10.0, 'kg'::quantity_unit_enum, 
			NOW(), NOW());
        RAISE NOTICE 'T21 FAIL: invalid plot FK should have thrown';
    EXCEPTION WHEN foreign_key_violation THEN
        RAISE NOTICE 'T21 PASS: invalid plot FK correctly rejected - %s', SQLERRM;
    END;

    -- T22: invalid variety FK should throw
    BEGIN
        INSERT INTO sowing_records (
			plot_id, variety_id, planting_date, 
			quantity_planted, quantity_unit, 
			created_at, updated_at)
        VALUES (
			v_plot_id, 999999, '2024-03-15'::date, 
			10.0, 'kg'::quantity_unit_enum, 
			NOW(), NOW());
        RAISE NOTICE 'T22 FAIL: invalid variety FK should have thrown';
    EXCEPTION WHEN foreign_key_violation THEN
        RAISE NOTICE 'T22 PASS: invalid variety FK correctly rejected - %', SQLERRM;
    END;

	-- T23: NULL quantity should throw
	BEGIN
		INSERT INTO sowing_records (
			plot_id, variety_id, planting_date,
			quantity_planted, quantity_unit,
			created_at, updated_at
		)
		VALUES (
			v_plot_id, v_variety_id, '2024-03-15'::date,
			NULL, 'kg'::quantity_unit_enum, 
			NOW(), NOW()
		);
		RAISE NOTICE 'T23 FAIL: NULL sowing quantity should have thrown';
	EXCEPTION WHEN not_null_violation THEN
		RAISE NOTICE 'T23 PASS: NULL quantity correctly rejected - %', SQLERRM;
	END;

	-- T24: invalid enum should throw
	BEGIN
		INSERT INTO sowing_records (
			plot_id, variety_id, planting_date,
			quantity_planted, quantity_unit,
			created_at, updated_at
		)
		VALUES (
			v_plot_id, v_variety_id, '2024-03-15'::date,
			10.0, 'invalid_type'::quantity_unit_enum,
			NOW(), NOW()
		);
		RAISE NOTICE 'T24 FAIL: invalid enum should have thrown';
    EXCEPTION WHEN invalid_text_representation THEN
        RAISE NOTICE 'T24 PASS: invalid enum correctly rejected - %', SQLERRM;
	END;

 	-- T25: optional fields NULL insert cleanly
    BEGIN
        INSERT INTO sowing_records (
			plot_id, variety_id, planting_date, 
			quantity_planted, quantity_unit, 
			seed_source, expected_first_harvest, expected_final_harvest,
			created_at, updated_at)
        VALUES (
			v_plot_id, v_variety_id, '2024-03-15'::date,
			10.0, 'kg'::quantity_unit_enum, 
			NULL, NULL, NULL,
			NOW(), NOW());
        RAISE NOTICE 'T25 PASS: optional fields NULL insert cleanly';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'T25 FAIL: optional fields NULL — %', SQLERRM;
    END;


    -- T26: NULL replanting flag correctly rejected 
    BEGIN
        INSERT INTO sowing_records (
			plot_id, variety_id, planting_date, 
			quantity_planted, quantity_unit, 
			seed_source, expected_first_harvest, expected_final_harvest,
			is_replanting,
			created_at, updated_at)
        VALUES (
			v_plot_id, v_variety_id, '2024-03-15'::date,
			10.0, 'kg'::quantity_unit_enum, 
			NULL, NULL, NULL,
			NULL,
			NOW(), NOW());
        RAISE NOTICE 'T26 FAIL: NULL replanting flag should have thrown';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'T26 PASS: NULL replanting flag correctly rejected - %', SQLERRM;
    END;

    -- T27: self-referencing original_sowing_id (replanting)
    BEGIN
        INSERT INTO sowing_records (
            plot_id, variety_id, planting_date,
			quantity_planted, quantity_unit, 
            is_replanting, original_sowing_id,
            created_at, updated_at
        )
        VALUES (
            v_plot_id, v_variety_id, '2024-04-15'::date,
			10.0, 'kg'::quantity_unit_enum, 
            true, v_sowing_id,
            NOW(), NOW()
        );
        RAISE NOTICE 'T27 PASS: replanting with valid original_sowing_id';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'T27 FAIL: replanting insert — %', SQLERRM;
    END;

    -- T28: invalid original_sowing_id FK should throw
    BEGIN
        INSERT INTO sowing_records (
            plot_id, variety_id, planting_date,
			quantity_planted, quantity_unit, 
            is_replanting, original_sowing_id,
            created_at, updated_at
        )
        VALUES (
            v_plot_id, v_variety_id, '2024-04-15'::date,
			10.0, 'kg'::quantity_unit_enum, 
            true, 999999,
            NOW(), NOW()
        );
        RAISE NOTICE 'T28 FAIL: invalid original_sowing_id FK should have thrown';
    EXCEPTION WHEN foreign_key_violation THEN
        RAISE NOTICE 'T28 PASS: invalid original_sowing_id FK correctly rejected - %', SQLERRM;
    END;

    -- T29: UPDATE happy path
    BEGIN
        UPDATE sowing_records SET
            quantity_planted = 15.0,
            area_utilized_percent = 80.0,
            notes = 'updated notes',
            updated_at = NOW()
        WHERE sowing_id = v_sowing_id;
        RAISE NOTICE 'T29 PASS: update succeeded';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'T29 FAIL: update — %', SQLERRM;
    END;

    -- T30: UPDATE status enum
    BEGIN
        UPDATE sowing_records SET
            status = 'active'::planting_status_enum,  -- replace with actual enum value
            updated_at = NOW()
        WHERE sowing_id = v_sowing_id;
        RAISE NOTICE 'T30 PASS: status update succeeded';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'T30 FAIL: status update — %', SQLERRM;
    END;

    RAISE NOTICE '-- rolling back all test data --';

EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'UNEXPECTED ERROR in outer block: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

ROLLBACK;