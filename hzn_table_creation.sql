USE ROLE ACCOUNTADMIN;
USE DATABASE crskdb;
CREATE SCHEMA crsk_ns;
USE DATABASE crskdb;
USE SCHEMA crsk_ns;


-- Check what database/schema context you want to create the Horizon table in
SELECT CURRENT_DATABASE(), CURRENT_SCHEMA();
SHOW EXTERNAL VOLUMES;  -- list all volumes
desc external volume  crsk_ext_vol;

-- Also check your current account identifier (needed for Horizon REST URL)
SELECT CURRENT_ORGANIZATION_NAME() || '-' || CURRENT_ACCOUNT_NAME() AS ACCOUNT_IDENTIFIER;

-- ==============================
-- Start for Horizon catalog with ADB
-- ==================================
USE DATABASE crskdb;
USE SCHEMA crsk_ns;

-- 3. Check what database/schema context you want to create the Horizon table in
SELECT CURRENT_DATABASE(), CURRENT_SCHEMA();  -- CRSKDB	CRSK_NS

CREATE OR REPLACE EXTERNAL VOLUME crsk_s3ext_vol
  STORAGE_LOCATIONS = (
    (
      NAME                   = 'crsk_s3_west'
      STORAGE_PROVIDER       = 'S3'
      STORAGE_BASE_URL       = 's3://crsk-s3-bucket-west/'
      STORAGE_AWS_ROLE_ARN   = 'arn:aws:iam::069959537626:role/crsk_snowflake_role'
      STORAGE_AWS_EXTERNAL_ID = 'iceberg_table_external_id'
    )
  );

  SHOW EXTERNAL VOLUMES;  -- list all volumes
  DESC EXTERNAL VOLUME crsk_s3ext_vol;
