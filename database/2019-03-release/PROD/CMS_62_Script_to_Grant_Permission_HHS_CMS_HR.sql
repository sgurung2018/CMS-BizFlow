/**
 * Script to regrant all permissions to CMS database roles.
 *      HHS_CMS_HR_RW_ROLE and BF_DEV_ROLE
 * Last Updated by Taeho Lee on Feb 25, 2019
 * Usage: run this query whenever there are any changes made in HHS_CMS_HR database.
 **/

/*
    -- Query to check if invalid object still exists after running this query
    SELECT * 
      FROM ALL_OBJECTS
     WHERE STATUS != 'VALID';
*/

SET SERVEROUTPUT ON;

DECLARE 
    P_SCHEMA_OWNER VARCHAR2(100) := 'HHS_CMS_HR';
    V_NUM_OF_INVALID_OBJECT INTEGER := 0;
BEGIN

    DBMS_OUTPUT.PUT_LINE('-- ReGranting begins ');

    ----------------------------------------------------------------------------------------------------------------------------

	FOR ATAB IN (SELECT TABLE_NAME FROM ALL_TABLES WHERE OWNER = P_SCHEMA_OWNER ORDER BY TABLE_NAME ) LOOP
        DBMS_OUTPUT.PUT_LINE('GRANT SELECT, INSERT, UPDATE, DELETE ON ' || P_SCHEMA_OWNER || '.'||ATAB.TABLE_NAME||' TO HHS_CMS_HR_RW_ROLE;');
		EXECUTE IMMEDIATE 'GRANT SELECT, INSERT, UPDATE, DELETE ON ' || P_SCHEMA_OWNER || '.'||ATAB.TABLE_NAME||' TO HHS_CMS_HR_RW_ROLE';
        DBMS_OUTPUT.PUT_LINE('GRANT SELECT, INSERT, UPDATE, DELETE ON ' || P_SCHEMA_OWNER || '.'||ATAB.TABLE_NAME||' TO BF_DEV_ROLE;');
        EXECUTE IMMEDIATE 'GRANT SELECT, INSERT, UPDATE, DELETE ON ' || P_SCHEMA_OWNER || '.'||ATAB.TABLE_NAME||' TO BF_DEV_ROLE';
	END LOOP;

	FOR ATAB IN (SELECT OBJECT_NAME FROM ALL_OBJECTS WHERE OWNER = P_SCHEMA_OWNER AND OBJECT_TYPE = 'VIEW' ORDER BY OBJECT_NAME ) LOOP
        DBMS_OUTPUT.PUT_LINE('GRANT SELECT ON ' || P_SCHEMA_OWNER || '.'||ATAB.OBJECT_NAME||' TO HHS_CMS_HR_RW_ROLE;');
		EXECUTE IMMEDIATE 'GRANT SELECT ON ' || P_SCHEMA_OWNER || '.'||ATAB.OBJECT_NAME||' TO HHS_CMS_HR_RW_ROLE';
        DBMS_OUTPUT.PUT_LINE('GRANT SELECT ON ' || P_SCHEMA_OWNER || '.'||ATAB.OBJECT_NAME||' TO BF_DEV_ROLE;');
        EXECUTE IMMEDIATE 'GRANT SELECT ON ' || P_SCHEMA_OWNER || '.'||ATAB.OBJECT_NAME||' TO BF_DEV_ROLE';
	END LOOP;

	FOR AFUNC IN (SELECT OBJECT_NAME FROM ALL_OBJECTS WHERE OWNER = P_SCHEMA_OWNER AND OBJECT_TYPE = 'FUNCTION' ORDER BY OBJECT_NAME ) LOOP
        DBMS_OUTPUT.PUT_LINE('GRANT EXECUTE ON ' || P_SCHEMA_OWNER || '.'||AFUNC.OBJECT_NAME||' TO HHS_CMS_HR_RW_ROLE;');
		EXECUTE IMMEDIATE 'GRANT EXECUTE ON ' || P_SCHEMA_OWNER || '.'||AFUNC.OBJECT_NAME||' TO HHS_CMS_HR_RW_ROLE';
        DBMS_OUTPUT.PUT_LINE('GRANT EXECUTE ON ' || P_SCHEMA_OWNER || '.'||AFUNC.OBJECT_NAME||' TO BF_DEV_ROLE;');
        EXECUTE IMMEDIATE 'GRANT EXECUTE ON ' || P_SCHEMA_OWNER || '.'||AFUNC.OBJECT_NAME||' TO BF_DEV_ROLE';
	END LOOP;

	FOR ASP IN (SELECT OBJECT_NAME FROM ALL_OBJECTS WHERE OWNER = P_SCHEMA_OWNER AND OBJECT_TYPE = 'PROCEDURE' ORDER BY OBJECT_NAME ) LOOP
        DBMS_OUTPUT.PUT_LINE('GRANT EXECUTE ON ' || P_SCHEMA_OWNER || '.'||ASP.OBJECT_NAME||' TO HHS_CMS_HR_RW_ROLE;');
		EXECUTE IMMEDIATE 'GRANT EXECUTE ON ' || P_SCHEMA_OWNER || '.'||ASP.OBJECT_NAME||' TO HHS_CMS_HR_RW_ROLE';
        DBMS_OUTPUT.PUT_LINE('GRANT EXECUTE ON ' || P_SCHEMA_OWNER || '.'||ASP.OBJECT_NAME||' TO BF_DEV_ROLE;');
        EXECUTE IMMEDIATE 'GRANT EXECUTE ON ' || P_SCHEMA_OWNER || '.'||ASP.OBJECT_NAME||' TO BF_DEV_ROLE';
	END LOOP;

END;
/
