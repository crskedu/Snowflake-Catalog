-- ============================
-- Poc For Masking
-- ===========================

-- Check current user, role, database, schema and warehouse in one shot
SELECT 
    CURRENT_USER()      AS LOGGED_IN_USER,
    CURRENT_ROLE()      AS ACTIVE_ROLE,
    CURRENT_DATABASE()  AS CURRENT_DB,
    CURRENT_SCHEMA()    AS CURRENT_SCHEMA,
    CURRENT_WAREHOUSE() AS CURRENT_WH;

-- 1a — Masking Policy for CARD_NUMBER 
-- Show last 4 digits only — e.g. ****-****-****-1111

CREATE OR REPLACE MASKING POLICY mask_card_number
  AS (val STRING) RETURNS STRING ->
  CASE
    WHEN CURRENT_ROLE() IN ('ACCOUNTADMIN', 'SYSADMIN')
      THEN val
    ELSE '****-****-****-' || RIGHT(val, 4)
  END;
    OP : Masking policy MASK_CARD_NUMBER successfully created.


  1b — Masking Policy for EMAIL
  Mask domain — e.g. jam***@***.com

  CREATE OR REPLACE MASKING POLICY mask_email
  AS (val STRING) RETURNS STRING ->
  CASE
    WHEN CURRENT_ROLE() IN ('ACCOUNTADMIN', 'SYSADMIN')
      THEN val
    ELSE LEFT(val, 3) || '***@***.com'
  END;

  1c — Masking Policy for PHONE
Show last 4 digits only — e.g. ***-***-0101

CREATE OR REPLACE MASKING POLICY mask_phone
  AS (val STRING) RETURNS STRING ->
  CASE
    WHEN CURRENT_ROLE() IN ('ACCOUNTADMIN', 'SYSADMIN')
      THEN val
    ELSE '***-***-' || RIGHT(val, 4)
  END;

  1d — Masking Policy for CARD_EXPIRY
Mask completely — e.g. **/**

CREATE OR REPLACE MASKING POLICY mask_card_expiry
  AS (val STRING) RETURNS STRING ->
  CASE
    WHEN CURRENT_ROLE() IN ('ACCOUNTADMIN', 'SYSADMIN')
      THEN val
    ELSE '**/**'
  END;

-- Verify all 4 policies created:
  SHOW MASKING POLICIES IN SCHEMA CRSKDB.CRSK_NS;


Apply all 4 masking policies to CRSK_CUSTOMERS columns:
-- Mask CARD_NUMBER
ALTER ICEBERG TABLE CRSK_CUSTOMERS MODIFY COLUMN CARD_NUMBER SET MASKING POLICY mask_card_number;
-- Mask EMAIL
ALTER ICEBERG TABLE CRSK_CUSTOMERS MODIFY COLUMN EMAIL SET MASKING POLICY mask_email;
-- Mask PHONE
ALTER ICEBERG TABLE CRSK_CUSTOMERS MODIFY COLUMN PHONE SET MASKING POLICY mask_phone;
-- Mask CARD_EXPIRY 
ALTER ICEBERG TABLE CRSK_CUSTOMERS MODIFY COLUMN CARD_EXPIRY SET MASKING POLICY mask_card_expiry;


-- Verify policies are applied:
SELECT
    REF_ENTITY_NAME AS TABLE_NAME,
    REF_COLUMN_NAME AS COLUMN_NAME,
    POLICY_NAME,
    POLICY_KIND
FROM
    TABLE(INFORMATION_SCHEMA.POLICY_REFERENCES(
        POLICY_NAME => 'CRSKDB.CRSK_NS.MASK_CARD_NUMBER'
    ));




-- Verify masking works INSIDE Snowflake As ACCOUNTADMIN (should see unmasked):
USE ROLE ACCOUNTADMIN;
SELECT CUSTOMER_ID, FULL_NAME, EMAIL, PHONE, CARD_NUMBER, CARD_EXPIRY FROM CRSKDB.CRSK_NS.CRSK_CUSTOMERS;

