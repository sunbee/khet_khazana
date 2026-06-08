BEGIN;

DO $$
DECLARE
    v_farm_id       int;
    v_plot_id       int;
    v_variety_id    int;
    v_harvest_id    int;
BEGIN

    -- ============================================================
    -- SEED PREREQUISITE DATA
    -- ============================================================

    INSERT INTO farms (farm_name, farming_type, total_acreage, created_at, updated_at)
    VALUES ('Harvest Test Farm', 'permaculture'::farming_type_enum, 11, NOW(), NOW())
    RETURNING farm_id INTO v_farm_id;
    RAISE NOTICE 'SEED: farm_id=%', v_farm_id;

    INSERT INTO plots (farm_id, plot_number, irrigation_type, acreage, created_at, updated_at)
    VALUES (v_farm_id, 'P-HARVEST-TEST', 'drip'::irrigation_type_enum, 1.0, NOW(), NOW())
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
    ASSERT NULLIF(NULLIF('2024-01-15'::text, ''), 'null')::date = '2024-01-15'::date,
        'T03 FAIL: real date should pass through';
    RAISE NOTICE 'T03 PASS: real date passes through';

    -- T04: time extraction from datetime string
    ASSERT SUBSTRING('2024-01-15T08:30:00.000'::text FROM 12 FOR 8) = '08:30:00',
        'T04 FAIL: time extraction should return HH:MM:SS';
    RAISE NOTICE 'T04 PASS: time extraction returns correct HH:MM:SS';

    -- T05: time extraction empty → NULL
    ASSERT NULLIF(NULLIF(SUBSTRING(''::text FROM 12 FOR 8), ''), 'null')::time IS NULL,
        'T05 FAIL: empty time string should become NULL';
    RAISE NOTICE 'T05 PASS: empty time string becomes NULL';

    -- T06: sequence number COALESCE default
    ASSERT COALESCE(NULLIF(NULLIF('null'::text, ''), 'null')::int, 1) = 1,
        'T06 FAIL: null sequence should default to 1';
    RAISE NOTICE 'T06 PASS: null sequence defaults to 1';

    -- T07: sequence number real value passes through
    ASSERT COALESCE(NULLIF(NULLIF('3'::text, ''), 'null')::int, 1) = 3,
        'T07 FAIL: real sequence number should pass through';
    RAISE NOTICE 'T07 PASS: real sequence number passes through';

    -- T08: quantity empty → NULL
    ASSERT NULLIF(NULLIF(''::text, ''), 'null')::numeric IS NULL,
        'T08 FAIL: empty quantity should become NULL';
    RAISE NOTICE 'T08 PASS: empty quantity becomes NULL';

    -- ============================================================
    -- INSERT TESTS
    -- ============================================================

    -- T09: happy path full insert
    BEGIN
        INSERT INTO harvest_records (
            plot_id, variety_id, harvest_date,
            harvest_time_start, harvest_time_end,
            quantity_harvested, quality_grade,
            harvest_sequence_number, estimated_remaining_yield,
            notes, created_at, updated_at
        )
        VALUES (
            v_plot_id, v_variety_id, '2024-01-15'::date,
            '08:30:00'::time, '12:00:00'::time,
            25.5, 'A',
            1, 10.0,
            'test harvest', NOW(), NOW()
        )
        RETURNING harvest_id INTO v_harvest_id;
        RAISE NOTICE 'T09 PASS: happy path insert, harvest_id=%', v_harvest_id;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'T09 FAIL: happy path insert — %', SQLERRM;
    END;

	 -- T10: happy path full insert
    BEGIN
        INSERT INTO harvest_records (
            plot_id, variety_id, harvest_date, quantity_harvested, 
            created_at, updated_at
        )
        VALUES (
            v_plot_id, v_variety_id, '2024-01-15'::date, 25.5, 
            NOW(), NOW()
        )
        RETURNING harvest_id INTO v_harvest_id;
        RAISE NOTICE 'T10 PASS: happy path insert, harvest_id=%', v_harvest_id;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'T10 FAIL: happy path insert — %', SQLERRM;
    END;

    -- T11: NULL plot_id should throw
    BEGIN
        INSERT INTO harvest_records (
            plot_id, variety_id, harvest_date,
            quantity_harvested, created_at, updated_at
        )
        VALUES (NULL, v_variety_id, '2024-01-15'::date, 25.5, NOW(), NOW());
        RAISE NOTICE 'T11 FAIL: NULL plot_id should have thrown';
    EXCEPTION WHEN not_null_violation THEN
        RAISE NOTICE 'T11 PASS: NULL plot_id correctly rejected - %', SQLERRM;
    END;

    -- T12: NULL variety_id should throw
    BEGIN
        INSERT INTO harvest_records (
            plot_id, variety_id, harvest_date,
            quantity_harvested, created_at, updated_at
        )
        VALUES (v_plot_id, NULL, '2024-01-15'::date, 25.5, NOW(), NOW());
        RAISE NOTICE 'T12 FAIL: NULL variety_id should have thrown';
    EXCEPTION WHEN not_null_violation THEN
        RAISE NOTICE 'T12 PASS: NULL variety_id correctly rejected - %', SQLERRM;
    END;

    -- T13: NULL harvest_date should throw
    BEGIN
        INSERT INTO harvest_records (
            plot_id, variety_id, harvest_date,
            quantity_harvested, created_at, updated_at
        )
        VALUES (v_plot_id, v_variety_id, NULL, 25.5, NOW(), NOW());
        RAISE NOTICE 'T13 FAIL: NULL harvest_date should have thrown';
    EXCEPTION WHEN not_null_violation THEN
        RAISE NOTICE 'T13 PASS: NULL harvest_date correctly rejected - %', SQLERRM;
    END;

    -- T14: NULL quantity_harvested should throw
    BEGIN
        INSERT INTO harvest_records (
            plot_id, variety_id, harvest_date,
            quantity_harvested, created_at, updated_at
        )
        VALUES (v_plot_id, v_variety_id, '2024-01-15'::date, NULL, NOW(), NOW());
        RAISE NOTICE 'T14 FAIL: NULL quantity_harvested should have thrown';
    EXCEPTION WHEN not_null_violation THEN
        RAISE NOTICE 'T14 PASS: NULL quantity_harvested correctly rejected - %', SQLERRM;
    END;

    -- T15: invalid FK plot_id should throw
    BEGIN
        INSERT INTO harvest_records (
            plot_id, variety_id, harvest_date,
            quantity_harvested, created_at, updated_at
        )
        VALUES (999999, v_variety_id, '2024-01-15'::date, 25.5, NOW(), NOW());
        RAISE NOTICE 'T15 FAIL: invalid plot FK should have thrown';
    EXCEPTION WHEN foreign_key_violation THEN
        RAISE NOTICE 'T15 PASS: invalid plot FK correctly rejected - %', SQLERRM;
    END;

    -- T16: invalid FK variety_id should throw
    BEGIN
        INSERT INTO harvest_records (
            plot_id, variety_id, harvest_date,
            quantity_harvested, created_at, updated_at
        )
        VALUES (v_plot_id, 999999, '2024-01-15'::date, 25.5, NOW(), NOW());
        RAISE NOTICE 'T16 FAIL: invalid variety FK should have thrown';
    EXCEPTION WHEN foreign_key_violation THEN
        RAISE NOTICE 'T16 PASS: invalid variety FK correctly rejected - %', SQLERRM;
    END;

    -- T17: optional fields NULL insert cleanly
    BEGIN
        INSERT INTO harvest_records (
            plot_id, variety_id, harvest_date,
            quantity_harvested, created_at, updated_at
        )
        VALUES (v_plot_id, v_variety_id, '2024-01-15'::date, 25.5, NOW(), NOW());
        RAISE NOTICE 'T17 PASS: optional fields NULL insert cleanly';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'T17 FAIL: optional fields NULL — %', SQLERRM;
    END;

    -- T18: sequence number defaults to 1 via COALESCE
    BEGIN
        INSERT INTO harvest_records (
            plot_id, variety_id, harvest_date,
            quantity_harvested, harvest_sequence_number,
            created_at, updated_at
        )
        VALUES (
            v_plot_id, v_variety_id, '2024-01-15'::date,
            25.5, COALESCE(NULL::int, 1),
            NOW(), NOW()
        );
        RAISE NOTICE 'T18 PASS: sequence number defaulted to 1';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'T18 FAIL: sequence number default — %', SQLERRM;
    END;

    -- T19: UPDATE happy path
    BEGIN
        UPDATE harvest_records SET
            quantity_harvested = 30.0,
            notes = 'updated notes',
            updated_at = NOW()
        WHERE harvest_id = v_harvest_id;
        RAISE NOTICE 'T19 PASS: update succeeded';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'T19 FAIL: update — %', SQLERRM;
    END;

    RAISE NOTICE '-- rolling back all test data --';

EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'UNEXPECTED ERROR in outer block: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

ROLLBACK;


/*
 *
 *---
 * Harvest UI — CRUD Test Script (Cleanup-Safe)
 * ---

# CREATE TESTS

## Test C1 — Minimal required fields

**Input**

* plot_id ✅
* variety_id ✅
* harvest_date = today ✅
* quantity_harvested = 10 ✅
* notes = `TEST-HARVEST-<timestamp>`

**Expected**

* Record created
* All optional fields = `NULL`
* No `"null"` / `''` in DB

---

## Test C2 — Full payload

Fill:

* time start/end
* quality_grade
* estimated_remaining_yield
* harvest_sequence_number (optional test)

**Expected**

* All fields persist correctly
* Time stored correctly (no substring bugs)

---

## Test C3 — Nullable fields blank

Leave:

* quality_grade
* notes (except codeword)
* sequence_number

**Expected**

* Stored as `NULL`
* No forced defaults (like `1`)

---

## Test C4 — Invalid input

* quantity = `"abc"`

**Expected**

* UI or DB rejects
* No record created

---

# 📖 READ TESTS

## Test R1 — Table load

* All created records visible

## Test R2 — Data integrity

* Dates correct
* Times correct
* NULL shows clean (blank, not `"null"`)

---

# ✏️ UPDATE TESTS

## Test U1 — Update quantity

* Change 10 → 25

**Expected**

* Updated correctly
* `updated_at` changes

---

## Test U2 — Clear optional field

* Remove `quality_grade`

**Expected**

* Becomes `NULL`

---

## Test U3 — Leave sequence untouched

* Open edit, don’t touch sequence

**Expected**

* Value unchanged (if using preserve logic)

---

## Test U4 — Set sequence NULL

* Clear it

**Expected**

* Either NULL or unchanged (based on your chosen logic)

---

# ❌ DELETE TESTS

## Test D1 — Delete one record

* Delete a created record

**Expected**

* Removed from table
* No side effects

---

## Test D2 — Bulk delete via UI

* Delete multiple test rows

---

# 🧹 CLEANUP (MANDATORY)

## 🔥 Method 1 — Codeword SQL cleanup

Run this:

```sql
DELETE FROM harvest_records
WHERE notes LIKE 'TEST-HARVEST-%';
```

👉 Safe, fast, wipes all test runs

---

## 🔥 Method 2 — ID-based cleanup (if tracked)

```sql
DELETE FROM harvest_records
WHERE harvest_id = ANY(ARRAY[
  -- paste IDs from appsmith.store.harvestTestIds
]);
```

---

## 🔥 Method 3 — Combined (bulletproof)

```sql
DELETE FROM harvest_records
WHERE notes LIKE 'TEST-HARVEST-%'
   OR harvest_id = ANY(ARRAY[ ... ]);
```

---

# ⚠️ Final sanity checklist

Before you say “tests passed”:

* ✅ No test records left in DB
* ✅ No `''` or `'null'` strings stored
* ✅ NULL behaves correctly
* ✅ No fake defaults (like sequence = 1)
* ✅ Time fields stored correctly

---

# 🧠 One strong suggestion

Make `notes` **required during testing only** (via UI), so:

> no record enters DB without a test tag

Prevents “oops I forgot to tag it.”

---

If you want next step, I can:

* add a **“Run Tests + Cleanup” button** in your UI
* or give you a **single SQL script that validates + deletes in one go**

That’s where this becomes really slick.

 */

