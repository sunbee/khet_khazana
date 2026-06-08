BEGIN;

DO $$
DECLARE
    v_variety_id int;
    v_enum_test text;
BEGIN

    -- ============================================================
    -- EXPRESSION UNIT TESTS
    -- ============================================================

    -- T01: empty string → NULL for numeric
    ASSERT NULLIF(NULLIF(''::text, ''), 'null')::numeric IS NULL,
        'T01 FAIL: empty string should become NULL';
    RAISE NOTICE 'T01 PASS: empty string becomes NULL for numeric';

    -- T02: string "null" → NULL for int
    ASSERT NULLIF(NULLIF('null'::text, ''), 'null')::int IS NULL,
        'T02 FAIL: string null should become NULL';
    RAISE NOTICE 'T02 PASS: string null becomes NULL for int';

    -- T03: real numeric passes through
    ASSERT NULLIF(NULLIF('12.5'::text, ''), 'null')::numeric = 12.5,
        'T03 FAIL: real numeric should pass through';
    RAISE NOTICE 'T03 PASS: real numeric passes through';

    -- T04: real int passes through
    ASSERT NULLIF(NULLIF('90'::text, ''), 'null')::int = 90,
        'T04 FAIL: real int should pass through';
    RAISE NOTICE 'T04 PASS: real int passes through';

    -- T05: crop_category enum guard on empty string
    v_enum_test := '';
    ASSERT (CASE
        WHEN NULLIF(NULLIF(v_enum_test, ''), 'null') IS NULL THEN NULL
        ELSE v_enum_test::crop_category_enum
    END) IS NULL,
        'T05 FAIL: empty string enum guard should return NULL';
    RAISE NOTICE 'T05 PASS: empty string enum guard returns NULL';

    -- T06: crop_category enum guard on string "null"
    v_enum_test := 'null';
    ASSERT (CASE
        WHEN NULLIF(NULLIF(v_enum_test, ''), 'null') IS NULL THEN NULL
        ELSE v_enum_test::crop_category_enum
    END) IS NULL,
        'T06 FAIL: null string enum guard should return NULL';
    RAISE NOTICE 'T06 PASS: null string enum guard returns NULL';

    -- T07: valid crop_category passes through
    v_enum_test := 'vegetable'; -- replace with actual enum value
    ASSERT (CASE
        WHEN NULLIF(NULLIF(v_enum_test, ''), 'null') IS NULL THEN NULL
        ELSE v_enum_test::crop_category_enum
    END) = 'vegetable'::crop_category_enum,
        'T07 FAIL: valid crop_category should pass through';
    RAISE NOTICE 'T07 PASS: valid crop_category passes through';

    -- ============================================================
    -- INSERT TESTS
    -- ============================================================

    -- T08: happy path insert
    BEGIN
        INSERT INTO crop_varieties (
            crop_name, variety_name, crop_category,
            description, typical_yield_per_acre, growing_days, created_at
        )
        VALUES (
            'Tomato', 'Roma',
            'vegetable'::crop_category_enum, -- replace with actual enum value
            'Test description', 12.5, 90,
            NOW()
        )
        RETURNING variety_id INTO v_variety_id;
        RAISE NOTICE 'T08 PASS: happy path insert, variety_id=%', v_variety_id;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'T08 FAIL: happy path insert — %', SQLERRM;
    END;

	-- T08: happy path insert
    BEGIN
        INSERT INTO crop_varieties (
            crop_name, variety_name, crop_category, 
			created_at
        )
        VALUES (
            'Tomato', 'Test', 'vegetable'::crop_category_enum, 
			NOW()
        )
        RETURNING variety_id INTO v_variety_id;
        RAISE NOTICE 'T08 PASS: happy path insert, variety_id=%', v_variety_id;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'T08 FAIL: happy path insert — %', SQLERRM;
    END;

 	-- T09: duplicate crop variety should fail
	BEGIN
    	INSERT INTO crop_varieties (crop_name, variety_name, crop_category,
        created_at
    	)
    	VALUES (
        	'Tomato', 'Test', 'vegetable'::crop_category_enum,
        	NOW()
    	);
    	RAISE NOTICE 'T09 FAIL: duplicate should have thrown';
	EXCEPTION WHEN unique_violation THEN
        RAISE NOTICE 'T09 PASS: duplicate correctly rejected - %', SQLERRM;
    WHEN OTHERS THEN RAISE NOTICE
          'T08 FAIL: unexpected error. Error: %, SQLSTATE: %',
          SQLERRM, SQLSTATE;
	END;

    -- T10: NULL crop_name should throw
    BEGIN
        INSERT INTO crop_varieties (crop_name, variety_name, crop_category, created_at)
        VALUES (NULL, 'Roma', 'vegetable'::crop_category_enum, NOW());
        RAISE NOTICE 'T10 FAIL: NULL crop_name should have thrown';
    EXCEPTION WHEN not_null_violation THEN
        RAISE NOTICE 'T10 PASS: NULL crop_name correctly rejected - %', SQLERRM;
    END;

    -- T11: NULL variety_name should throw
    BEGIN
        INSERT INTO crop_varieties (crop_name, variety_name, crop_category, created_at)
        VALUES ('Tomato', NULL, 'vegetable'::crop_category_enum, NOW());
        RAISE NOTICE 'T11 FAIL: NULL variety_name should have thrown';
    EXCEPTION WHEN not_null_violation THEN
        RAISE NOTICE 'T11 PASS: NULL variety_name correctly rejected - %', SQLERRM;
    END;

    -- T12: NULL crop_category should throw (NOT NULL column)
    BEGIN
        INSERT INTO crop_varieties (crop_name, variety_name, crop_category, created_at)
        VALUES ('Tomato', 'Roma', NULL, NOW());
        RAISE NOTICE 'T12 FAIL: NULL crop_category should have thrown';
    EXCEPTION WHEN not_null_violation THEN
        RAISE NOTICE 'T12 PASS: NULL crop_category correctly rejected - %', SQLERRM;
    END;

    -- T13: invalid enum should throw
    BEGIN
        v_enum_test := 'invalid_category';
        INSERT INTO crop_varieties (crop_name, variety_name, crop_category, created_at)
        VALUES ('Tomato', 'Roma', v_enum_test::crop_category_enum, NOW());
        RAISE NOTICE 'T13 FAIL: invalid enum should have thrown';
    EXCEPTION WHEN invalid_text_representation THEN
        RAISE NOTICE 'T13 PASS: invalid enum correctly rejected - %', SQLERRM;
    END;

    -- T14: NULL optional fields insert cleanly
    BEGIN
        INSERT INTO crop_varieties (
            crop_name, variety_name, crop_category,
            description, typical_yield_per_acre, growing_days, created_at
        )
        VALUES (
            'Tomato', 'Cherry',
            'vegetable'::crop_category_enum,
            NULL, NULL, NULL,
            NOW()
        );
        RAISE NOTICE 'T14 PASS: NULL optional fields insert cleanly';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'T14 FAIL: NULL optional fields — %', SQLERRM;
    END;

    -- T15: UPDATE happy path
    BEGIN
        UPDATE crop_varieties SET
            crop_name = 'Updated Tomato',
            growing_days = 100,
            typical_yield_per_acre = 15.0
        WHERE variety_id = v_variety_id;
        RAISE NOTICE 'T15 PASS: update succeeded';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'T15 FAIL: update — %', SQLERRM;
    END;

    -- T16: toggle is_active
    BEGIN
        UPDATE crop_varieties
        SET is_active = NOT is_active
        WHERE variety_id = v_variety_id;
        RAISE NOTICE 'T16 PASS: is_active toggled';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'T16 FAIL: toggle is_active — %', SQLERRM;
    END;

    RAISE NOTICE '-- rolling back all test data --';

EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'UNEXPECTED ERROR in outer block: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

ROLLBACK;