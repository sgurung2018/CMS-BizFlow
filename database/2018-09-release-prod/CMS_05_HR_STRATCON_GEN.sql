-- CMS_HR_DB_UPD_20_alter_model_tables.sql 

ALTER TABLE STRATCON_GEN
MODIFY SG_XO_ID NVARCHAR2(32);

ALTER TABLE STRATCON_GEN
MODIFY SG_XO_TITLE NVARCHAR2(200);

ALTER TABLE STRATCON_GEN
MODIFY SG_XO_ORG NVARCHAR2(200);
