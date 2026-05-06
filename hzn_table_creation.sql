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

-- Check what database/schema context you want to create the Horizon table in
SELECT CURRENT_DATABASE(), CURRENT_SCHEMA();  -- CRSKDB	CRSK_NS

-- Step 1 - Create External Volume
CREATE OR REPLACE EXTERNAL VOLUME crsk_s3ext_vol
  STORAGE_LOCATIONS = (
    (
      NAME                   = 'crsk_s3_west'
      STORAGE_PROVIDER       = 'S3'
      STORAGE_BASE_URL       = 's3://crsk-s3-bucket-west/'
      STORAGE_AWS_ROLE_ARN   = 'arn:aws:iam::<account>:role/<your_snowflake_role>'
      STORAGE_AWS_EXTERNAL_ID = 'iceberg_table_external_id'
    )
  );

  SHOW EXTERNAL VOLUMES;  -- list all volumes
  DESC EXTERNAL VOLUME crsk_s3ext_vol;

-- Step 2 Create Iceberg Table
CREATE OR REPLACE ICEBERG TABLE CRSK_CUSTOMERS (
  CUSTOMER_ID   INT,
  FULL_NAME     STRING,
  EMAIL         STRING,
  PHONE         STRING,
  CARD_NUMBER   STRING,
  CARD_EXPIRY   STRING,
  CARD_TYPE     STRING,
  CITY          STRING,
  COUNTRY       STRING
)
CATALOG        = 'SNOWFLAKE'
EXTERNAL_VOLUME = 'crsk_s3ext_vol'
BASE_LOCATION  = 'crsk_ns/customers';

CREATE OR REPLACE ICEBERG TABLE CRSK_SALES (
  SALE_ID      INT,
  CUSTOMER_ID  INT,
  PRODUCT      STRING,
  QUANTITY     INT,
  AMOUNT       NUMBER(10,2),
  SALE_DATE    DATE,
  REGION       STRING,
  STATUS       STRING
)
CATALOG        = 'SNOWFLAKE'
EXTERNAL_VOLUME = 'crsk_s3ext_vol'
BASE_LOCATION  = 'crsk_ns/sales';


  CREATE OR REPLACE ICEBERG TABLE CRSK_ORDERS (
  ORDER_ID     INT,
  SALE_ID      INT,
  CUSTOMER_ID  INT,
  ORDER_DATE   DATE,
  SHIP_DATE    DATE,
  STATUS       STRING,
  TOTAL        NUMBER(10,2),
  SHIP_REGION  STRING
)
CATALOG        = 'SNOWFLAKE'
EXTERNAL_VOLUME = 'crsk_s3ext_vol'
BASE_LOCATION  = 'crsk_ns/orders';


-- verify

SHOW ICEBERG TABLES IN SCHEMA CRSKDB.CRSK_NS;

SELECT table_catalog,table_schema,table_name,table_type, FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = 'CRSK_NS' AND IS_ICEBERG = 'YES';

SELECT * FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));


-- Step 3 Insert Sample Data

-- Insert records 
INSERT INTO CRSK_CUSTOMERS VALUES
  (1001, 'James Anderson',  'james.anderson@email.com',  '+1-415-555-0101', '4111111111111111', '12/26', 'VISA',       'San Francisco', 'USA'),
  (1002, 'Priya Sharma',    'priya.sharma@email.com',    '+91-98765-43210', '5500005555555559', '08/25', 'MASTERCARD', 'Mumbai',        'India'),
  (1003, 'Carlos Mendes',   'carlos.mendes@email.com',   '+55-11-91234-567','378282246310005',  '03/27', 'AMEX',       'São Paulo',     'Brazil'),
  (1004, 'Sophie Laurent',  'sophie.laurent@email.com',  '+33-6-1234-5678', '4012888888881881', '11/26', 'VISA',       'Paris',         'France'),
  (1005, 'Ahmed Al-Rashid', 'ahmed.alrashid@email.com',  '+971-50-123-4567','5105105105105100', '06/28', 'MASTERCARD', 'Dubai',         'UAE'),
  (1006, 'Linda Chukwu',    'linda.chukwu@email.com',    '+234-803-123-4567','4222222222222',   '09/25', 'VISA',       'Lagos',         'Nigeria'),
  (1007, 'Raj Patel',       'raj.patel@email.com',       '+44-7911-123456', '6011111111111117', '01/27', 'DISCOVER',   'London',        'UK'),
  (1008, 'Mei Lin',         'mei.lin@email.com',         '+86-138-0000-1234','4111111111111111','07/26', 'VISA',       'Shanghai',      'China');


  INSERT INTO CRSK_SALES VALUES
  (1, 1001, 'Laptop Pro 15',    1,  1299.99, DATE '2025-01-10', 'US-WEST',  'COMPLETED'),
  (2, 1002, 'Wireless Mouse',   2,    49.98, DATE '2025-01-12', 'APAC',     'COMPLETED'),
  (3, 1003, 'Mechanical Keyboard', 1, 129.99, DATE '2025-01-15', 'LATAM',   'COMPLETED'),
  (4, 1004, 'USB-C Hub',        3,    89.97, DATE '2025-01-18', 'EMEA',     'COMPLETED'),
  (5, 1005, '4K Monitor',       1,   549.99, DATE '2025-02-02', 'EMEA',     'COMPLETED'),
  (6, 1006, 'Webcam HD',        1,    99.99, DATE '2025-02-10', 'AFRICA',   'COMPLETED'),
  (7, 1007, 'Noise Cancelling Headset', 1, 249.99, DATE '2025-02-14', 'EMEA', 'COMPLETED'),
  (8, 1008, 'Tablet 10"',       1,   399.99, DATE '2025-02-20', 'APAC',     'COMPLETED'),
  (9, 1001, 'External SSD 1TB', 2,   259.98, DATE '2025-03-05', 'US-WEST',  'COMPLETED'),
  (10,1003, 'Laptop Stand',     1,    49.99, DATE '2025-03-12', 'LATAM',    'SHIPPED');


  INSERT INTO CRSK_ORDERS VALUES
  (2001, 1,  1001, DATE '2025-01-10', DATE '2025-01-13', 'DELIVERED', 1299.99, 'US-WEST'),
  (2002, 2,  1002, DATE '2025-01-12', DATE '2025-01-16', 'DELIVERED',   49.98, 'APAC'),
  (2003, 3,  1003, DATE '2025-01-15', DATE '2025-01-20', 'DELIVERED',  129.99, 'LATAM'),
  (2004, 4,  1004, DATE '2025-01-18', DATE '2025-01-22', 'DELIVERED',   89.97, 'EMEA'),
  (2005, 5,  1005, DATE '2025-02-02', DATE '2025-02-07', 'DELIVERED',  549.99, 'EMEA'),
  (2006, 6,  1006, DATE '2025-02-10', DATE '2025-02-16', 'DELIVERED',   99.99, 'AFRICA'),
  (2007, 7,  1007, DATE '2025-02-14', DATE '2025-02-19', 'DELIVERED',  249.99, 'EMEA'),
  (2008, 8,  1008, DATE '2025-02-20', DATE '2025-02-26', 'DELIVERED',  399.99, 'APAC'),
  (2009, 9,  1001, DATE '2025-03-05', DATE '2025-03-09', 'DELIVERED',  259.98, 'US-WEST'),
  (2010, 10, 1003, DATE '2025-03-12', NULL,              'IN-TRANSIT',  49.99, 'LATAM');

select * fROM CRSK_CUSTOMERS;
select * fROM CRSK_SALES;
select * fROM CRSK_ORDERS;


-- Step 4 — Create Snowflake Role, User and Grant Access for Oracle ADB

4.1 — Create Role and User
CREATE OR REPLACE ROLE ADB_HZN_ROLE;

CREATE OR REPLACE USER ADB_HZN_USER
  PASSWORD        = 'StrongPaxx_20xx'
  DEFAULT_ROLE    = ADB_HZN_ROLE
  MUST_CHANGE_PASSWORD = FALSE;

GRANT ROLE ADB_HZN_ROLE TO USER ADB_HZN_USER;

4.2 — Grant Privileges on Database, Schema and Tables

GRANT USAGE ON DATABASE CRSKDB             TO ROLE ADB_HZN_ROLE;
GRANT USAGE ON SCHEMA CRSKDB.CRSK_NS       TO ROLE ADB_HZN_ROLE;

GRANT SELECT ON ICEBERG TABLE CRSKDB.CRSK_NS.CRSK_SALES      TO ROLE ADB_HZN_ROLE;
GRANT SELECT ON ICEBERG TABLE CRSKDB.CRSK_NS.CRSK_ORDERS     TO ROLE ADB_HZN_ROLE;
GRANT SELECT ON ICEBERG TABLE CRSKDB.CRSK_NS.CRSK_CUSTOMERS  TO ROLE ADB_HZN_ROLE;

4.3 — Verify Role and Grants

-- Verify user exists and has correct role
SHOW USERS LIKE 'ADB_HZN_USER';
-- Verify grants on schema
SHOW GRANTS TO ROLE ADB_HORIZON_ROLE;

--Step 5 — Create Programmatic Access Token (PAT)

ALTER USER ADB_HORIZON_USER
  ADD PROGRAMMATIC ACCESS TOKEN ADB_HORIZON_PAT
  DAYS_TO_EXPIRY = 7;

Verify:
SHOW USER PROGRAMMATIC ACCESS TOKENS FOR USER ADB_HORIZON_USER;

-- Step 6 — Exchange PAT for OAuth Access Token


    # Step 6a — Exchange PAT for OAuth Access Token and store it
export SNOW_OAUTH_TOKEN=$(curl -s -X POST \
  "https://<yourorg_name>-<youraccount_num>.snowflakecomputing.com/polaris/api/catalog/v1/oauth/tokens" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "grant_type=client_credentials" \
  --data-urlencode "scope=session:role:ADB_HZN_ROLE" \
  --data-urlencode  "client_secret=sA" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['access_token'])")

# Step 6b — Verify the token was captured
echo $SNOW_OAUTH_TOKEN
