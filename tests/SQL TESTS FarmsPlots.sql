
BEGIN;

DO $$
DECLARE
    v_result text;
    v_farm_id int;
	v_enum_test text;
BEGIN

    -- ============================================================
    -- EXPRESSION UNIT TESTS (SELECT based, cannot throw)
    -- ============================================================

    -- T01: empty string → NULL
    ASSERT NULLIF(NULLIF(''::text, ''), 'null')::int IS NULL,
        'T01 FAIL: empty string should become NULL';
    RAISE NOTICE 'T01 PASS: empty string becomes NULL';

    -- T02: string "null" → NULL
    ASSERT NULLIF(NULLIF('null'::text, ''), 'null')::int IS NULL,
        'T02 FAIL: string null should become NULL';
    RAISE NOTICE 'T02 PASS: string null becomes NULL';

    -- T03: real value passes through
    ASSERT NULLIF(NULLIF('42'::text, ''), 'null')::int = 42,
        'T03 FAIL: real value should pass through';
    RAISE NOTICE 'T03 PASS: real value passes through';

    -- T04: zero passes through (falsy trap)
    ASSERT NULLIF(NULLIF('0'::text, ''), 'null')::int = 0,
        'T04 FAIL: zero should pass through';
    RAISE NOTICE 'T04 PASS: zero passes through';

        -- T05: enum guard on empty string
    v_enum_test := '';
    ASSERT (CASE
        WHEN NULLIF(NULLIF(v_enum_test, ''), 'null') IS NULL THEN NULL
        ELSE v_enum_test::farming_type_enum
    END) IS NULL,
        'T05 FAIL: empty string enum guard should return NULL';
    RAISE NOTICE 'T05 PASS: empty string enum guard returns NULL';

    -- T06: enum guard on string "null"
    v_enum_test := 'null';
    ASSERT (CASE
        WHEN NULLIF(NULLIF(v_enum_test, ''), 'null') IS NULL THEN NULL
        ELSE v_enum_test::farming_type_enum
    END) IS NULL,
        'T06 FAIL: null string enum guard should return NULL';
    RAISE NOTICE 'T06 PASS: null string enum guard returns NULL';

    -- T07: valid enum passes through
    v_enum_test := 'permaculture';
    ASSERT (CASE
        WHEN NULLIF(NULLIF(v_enum_test, ''), 'null') IS NULL THEN NULL
        ELSE v_enum_test::farming_type_enum
    END) = 'permaculture'::farming_type_enum,
        'T07 FAIL: valid enum should pass through';
    RAISE NOTICE 'T07 PASS: valid enum passes through';

    -- T08: bool null string → false via COALESCE
    ASSERT COALESCE(NULLIF(NULLIF('null'::text, ''), 'null')::boolean, false) = false,
        'T08 FAIL: null string bool should default to false';
    RAISE NOTICE 'T08 PASS: null string bool defaults to false';

    -- T09: explicit true passes through
    ASSERT COALESCE(NULLIF(NULLIF('true'::text, ''), 'null')::boolean, false) = true,
        'T09 FAIL: explicit true should pass through';
    RAISE NOTICE 'T09 PASS: explicit true passes through';

    -- T10: geometry guard on empty coords
    ASSERT (CASE
        WHEN NULLIF(NULLIF(''::text, ''), 'null') IS NULL
          OR NULLIF(NULLIF(''::text, ''), 'null') IS NULL
        THEN NULL
        ELSE ST_SetSRID(ST_MakePoint(0,0), 4326)
    END) IS NULL,
        'T10 FAIL: empty coords should produce NULL geometry';
    RAISE NOTICE 'T10 PASS: empty coords produce NULL geometry';

    -- ============================================================
    -- INSERT/UPDATE TESTS (each in its own sub-block)
    -- ============================================================

    -- T11: happy path farm insert
    BEGIN
        INSERT INTO farms (farm_name, farming_type, total_acreage, created_at, updated_at)
        VALUES ('Test Farm', 'permaculture'::farming_type_enum, 11, NOW(), NOW())
        RETURNING farm_id INTO v_farm_id;
        RAISE NOTICE 'T11 PASS: happy path farm insert, farm_id=%', v_farm_id;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'T11 FAIL: happy path farm insert - %', SQLERRM;
    END;

    -- T12: NULL farm_name should throw NOT NULL violation
    BEGIN
        INSERT INTO farms (farm_name, farming_type, created_at, updated_at)
        VALUES (NULL, 'permaculture'::farming_type_enum, NOW(), NOW());
        RAISE NOTICE 'T12 FAIL: NULL farm_name should have thrown';
    EXCEPTION WHEN not_null_violation THEN
        RAISE NOTICE 'T12 PASS: NULL farm_name correctly rejected - %', SQLERRM;
    END;

    -- T13: invalid enum should throw
    BEGIN
        INSERT INTO farms (farm_name, farming_type, created_at, updated_at)
        VALUES ('Bad Enum Farm', 'invalid_type'::farming_type_enum, NOW(), NOW());
        RAISE NOTICE 'T13 FAIL: invalid enum should have thrown';
    EXCEPTION WHEN invalid_text_representation THEN
        RAISE NOTICE 'T13 PASS: invalid enum correctly rejected - %', SQLERRM;
    END;

    -- T14: NULL enum on NOT NULL column should throw
    BEGIN
        INSERT INTO farms (farm_name, farming_type, created_at, updated_at)
        VALUES ('Null Enum Farm', NULL, NOW(), NOW());
        RAISE NOTICE 'T14 FAIL: NULL farming_type should have thrown';
    EXCEPTION WHEN not_null_violation THEN
        RAISE NOTICE 'T14 PASS: NULL farming_type correctly rejected - %', SQLERRM;
    END;

    -- T15: happy path plot insert (requires v_farm_id from T11)
    BEGIN
        INSERT INTO plots (farm_id, plot_number, irrigation_type, acreage, created_at, updated_at)
        VALUES (
            v_farm_id,
            'P-001',
            'drip'::irrigation_type_enum,
			0.25,
            NOW(), NOW()
        );
        RAISE NOTICE 'T15 PASS: happy path plot insert';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'T15 FAIL: happy path plot insert — %', SQLERRM;
    END;

	-- T16: happy path plot insert (requires v_farm_id from T11)
    BEGIN
        INSERT INTO plots (farm_id, plot_number, acreage, created_at, updated_at)
        VALUES (
            v_farm_id,
            'P-002',
			0.25,
            NOW(), NOW()
        );
        RAISE NOTICE 'T16 PASS: happy path plot insert';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'T16 FAIL: happy path plot insert — %', SQLERRM;
    END;

	-- T17: duplicate plot number should throw
    BEGIN
        INSERT INTO plots (farm_id, plot_number, acreage, created_at, updated_at)
        VALUES (
            v_farm_id,
            'P-001',
			0.25,
            NOW(), NOW()
        );
        RAISE NOTICE 'T17 FAIL: duplicate plot number should have thrown';
    EXCEPTION WHEN unique_violation THEN
        RAISE NOTICE 'T17 PASS: duplicate plot number correctly rejected — %', SQLERRM;
    END;

	-- T18: invalid irrigation enum should fail
	BEGIN
    	INSERT INTO plots (farm_id, plot_number, acreage, irrigation_type, 
			created_at, updated_at
		)
    	VALUES (
        	v_farm_id,
        	'Invalid Enum Plot',
        	0.50,
        	'invalid_type'::irrigation_type_enum, -- invalid enum
        	NOW(), NOW()
    	);
    	RAISE NOTICE 'T18 FAIL: invalid enum should have thrown';
	EXCEPTION WHEN invalid_text_representation THEN
        RAISE NOTICE 'T18 PASS: invalid irrigation enum rejected - %', SQLERRM;
	END;

	-- T19: NULL acreage should violate NOT NULL
	BEGIN INSERT INTO plots (farm_id, plot_number, acreage, created_at, updated_at)
	    VALUES (
	        v_farm_id,
	        'Null Acreage Plot',
	        NULL,
	        NOW(), NOW()
	    );
	    RAISE NOTICE 'T19 FAIL: NULL acreage should have thrown';
	EXCEPTION WHEN not_null_violation THEN
        RAISE NOTICE 'T19 PASS: NULL acreage correctly rejected - %', SQLERRM;
	END;

    -- T20: invalid FK on plot should throw
    BEGIN
        INSERT INTO plots (farm_id, plot_number, acreage, created_at, updated_at)
        VALUES (999999, 'P-BAD-FK', 0.6, NOW(), NOW());
        RAISE NOTICE 'T20 FAIL: invalid FK should have thrown';
    EXCEPTION WHEN foreign_key_violation THEN
        RAISE NOTICE 'T20 PASS: invalid FK correctly rejected - %', SQLERRM;
    END;

    -- T21: farm update
    BEGIN
        UPDATE farms SET
            farm_name = 'Updated Farm',
            updated_at = NOW()
        WHERE farm_id = v_farm_id;
        RAISE NOTICE 'T21 PASS: farm update succeeded';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'T21 FAIL: farm update — %', SQLERRM;
    END;

    -- T22: toggle is_active
    BEGIN
        UPDATE farms SET is_active = NOT is_active
        WHERE farm_id = v_farm_id;
        RAISE NOTICE 'T22 PASS: is_active toggled';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'T22 FAIL: toggle is_active — %', SQLERRM;
    END;

    -- clean up all test data
    RAISE NOTICE '-- rolling back all test data --';

EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'UNEXPECTED ERROR in outer block: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

ROLLBACK;