-- Add ACL for Horizon Snowflake endpoint (new hostname)
IMPORTANT:
DBMS_CATALOG requires ‘http’ and ‘http_proxy’ privileges — not just ‘connect’ and ‘resolve’. 
Missing http_proxy causes silent failures.

BEGIN
  DBMS_NETWORK_ACL_ADMIN.APPEND_HOST_ACE(
    host       => 'mdlfbgh-ahb18784.snowflakecomputing.com',
    lower_port => 443,
    upper_port => 443,
    ace        => XS$ACE_TYPE(
      privilege_list => XS$NAME_LIST('http', 'http_proxy'),
      principal_name => 'ADMIN',
      principal_type => XS_ACL.PTYPE_DB));
END;
/

  
  
-- verify

select * from DBA_HOST_ACES WHERE PRINCIPAL = 'ADMIN' ORDER BY HOST;

-— Create S3 Credential in Oracle ADB

if not exist, create it
BEGIN
    DBMS_CLOUD.DROP_CREDENTIAL('AWS_S3_WEST_CONN');
END;
  
BEGIN
DBMS_CLOUD.CREATE_CREDENTIAL(
credential_name => 'AWS_S3_WEST_CONN',
username        => '<aws_access_key_id>',
password        => '<aws_secret_access_key>'
);
END;

-— Create Snowflake OAuth Credential in Oracle ADB

  export SNOW_OAUTH_TOKEN=$(curl -s -X POST \
  "https://mdlfbgh-ahb18784.snowflakecomputing.com/polaris/api/catalog/v1/oauth/tokens" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "grant_type=client_credentials" \
  --data-urlencode "scope=session:role:ADB_HZ_ROLE" \
  --data-urlencode  "client_secret= <PAT_TOKEN> \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['access_token'])")
  
BEGIN
    DBMS_CLOUD.DROP_CREDENTIAL('SNOW_HZN_OAUTH');
  EXCEPTION
    WHEN OTHERS THEN NULL;
  END;

BEGIN
  DBMS_CLOUD.CREATE_CREDENTIAL(
    credential_name => 'SNOW_HZN_OAUTH',
    username        => 'bearer',
    password        => 'SNOW_OAUTH_TOKEN'
  );
END;
/

SELECT CREDENTIAL_NAME, USERNAME FROM ALL_CREDENTIALS WHERE CREDENTIAL_NAME = 'SNOW_HZN_OAUTH';

-— Create External Table and Query in Oracle ADB

  -- Create External Table for CRSK_CUSTOMERS
BEGIN
  DBMS_CLOUD.CREATE_EXTERNAL_TABLE(
    table_name      => 'CRSK_CUSTOMERS_HZ_EXT',
    credential_name => 'AWS_S3_WEST_CONN',
    format          => q'[
{
  "access_protocol": {
    "protocol_type": "iceberg",
    "protocol_config": {
      "iceberg_catalog_type": "polaris",
      "rest_catalog_endpoint": "https://mdlfbgh-ahb18784.snowflakecomputing.com/polaris/api/catalog",
      "rest_catalog_prefix": "CRSKDB",
      "rest_authentication": {
        "rest_auth_cred": "SNOW_HZN_OAUTH"
      },
      "table_path": ["CRSK_NS", "CRSK_CUSTOMERS"]
    }
  }
}
]'
  );
END;
/

  -- Create External Table for CRSK_SALES
BEGIN
  DBMS_CLOUD.CREATE_EXTERNAL_TABLE(
    table_name      => 'CRSK_SALES_HZ_EXT',
    credential_name => 'AWS_S3_WEST_CONN',
    format          => q'[
{
  "access_protocol": {
    "protocol_type": "iceberg",
    "protocol_config": {
      "iceberg_catalog_type": "polaris",
      "rest_catalog_endpoint": "https://mdlfbgh-ahb18784.snowflakecomputing.com/polaris/api/catalog",
      "rest_catalog_prefix": "CRSKDB",
      "rest_authentication": {
        "rest_auth_cred": "SNOW_HZN_OAUTH"
      },
      "table_path": ["CRSK_NS", "CRSK_SALES"]
    }
  }
}
]'
  );
END;
/

-- Create External Table for CRSK_ORDERS
BEGIN
  DBMS_CLOUD.CREATE_EXTERNAL_TABLE(
    table_name      => 'CRSK_ORDERS_HZ_EXT',
    credential_name => 'AWS_S3_WEST_CONN',
    format          => q'[
{
  "access_protocol": {
    "protocol_type": "iceberg",
    "protocol_config": {
      "iceberg_catalog_type": "polaris",
      "rest_catalog_endpoint": "https://mdlfbgh-ahb18784.snowflakecomputing.com/polaris/api/catalog",
      "rest_catalog_prefix": "CRSKDB",
      "rest_authentication": {
        "rest_auth_cred": "SNOW_HZN_OAUTH"
      },
      "table_path": ["CRSK_NS", "CRSK_ORDERS"]
    }
  }
}
]'
  );
END;
/

select * from CRSK_CUSTOMERS_HZ_EXT;
SELECT * FROM CRSK_SALES_HZ_EXT;
select * from CRSK_ORDERS_HZ_EXT;



