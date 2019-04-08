SET DEFINE OFF;

CREATE TABLE INCENTIVES_LE_CRED
(
	PROC_ID				NUMBER(10) NOT NULL,
	SEQ_NUM				NUMBER(10) NOT NULL,
	START_DATE			VARCHAR2(10),
	END_DATE			VARCHAR2(10),
	WORK_SCHEDULE		VARCHAR2(15),
	POS_TITLE			VARCHAR2(140),
	CALCULATED_YEARS	NUMBER(10) DEFAULT 0 NULL,
	CALCULATED_MONTHS	NUMBER(10) DEFAULT 0 NULL,
	CREDITABLE_YEARS	NUMBER(10) DEFAULT 0 NULL,
	CREDITABLE_MONTHS	NUMBER(10) DEFAULT 0 NULL
);

CREATE UNIQUE INDEX INCENTIVES_LE_CRED_UK1 ON INCENTIVES_LE_CRED (PROC_ID, SEQ_NUM);
/

ALTER TABLE INCENTIVES_LE ADD (
  TOTAL_CREDITABLE_YEARS NUMBER(10) DEFAULT 0 NULL,
  TOTAL_CREDITABLE_MONTHS NUMBER(10) DEFAULT 0 NULL
);
/

GRANT SELECT, INSERT, UPDATE, DELETE ON HHS_CMS_HR.INCENTIVES_LE_CRED TO HHS_CMS_HR_RW_ROLE;
GRANT SELECT, INSERT, UPDATE, DELETE ON HHS_CMS_HR.INCENTIVES_LE_CRED TO HHS_CMS_HR_DEV_ROLE;
GRANT SELECT, INSERT, UPDATE, DELETE ON HHS_CMS_HR.INCENTIVES_LE_CRED TO BIZFLOW;
/

ALTER TABLE  "HHS_CMS_HR"."ERLR_GEN" ADD GEN_EMPLOYEE_ID VARCHAR2(64);

UPDATE HHS_CMS_HR.ERLR_GEN
   SET GEN_EMPLOYEE_ID
     = (SELECT 
        XMLQUERY('/formData/items/item[id="GEN_EMPLOYEE_ID"]/value/text()' PASSING FIELD_DATA RETURNING CONTENT).GETSTRINGVAL()
        FROM HHS_CMS_HR.TBL_FORM_DTL F JOIN HHS_CMS_HR.ERLR_CASE C ON F.PROCID = C.PROCID 
	WHERE C.ERLR_CASE_NUMBER = ERLR_GEN.ERLR_CASE_NUMBER);

COMMIT;
/

RENAME  "ERLR_EMPLOYEE_CASE" TO "ERLR_EMPLOYEE_CASE_V1"; 
DROP PROCEDURE SP_ERLR_EMPLOYEE_CASE_ADD;
DROP PROCEDURE SP_ERLR_EMPLOYEE_CASE_DEL;

CREATE TABLE "HHS_CMS_HR"."ERLR_RELATED_CASE" 
(	
	"CASE_NUMBER" NUMBER(10,0) NOT NULL, 
	"RELATED_CASE_NUMBER" NUMBER(10,0) NOT NULL,
	"TRIGGER_F" CHAR(1) DEFAULT 'F' NOT NULL,
	"M_DT" DATE, 
	"M_MEMBER_ID" VARCHAR2(10 BYTE), 
	"M_MEMBER_NAME" NVARCHAR2(100)
);
/   

CREATE UNIQUE INDEX "HHS_CMS_HR"."ERLR_RELATED_CASE_PK" ON "HHS_CMS_HR"."ERLR_RELATED_CASE" 
(
     "CASE_NUMBER", "RELATED_CASE_NUMBER"
);

CREATE TABLE "HHS_CMS_HR"."ERLR_EMPLOYEE_CASE" 
(	
	"HHSID" VARCHAR2(64) NOT NULL, 
	"CASE_NUMBER" NUMBER(10,0) NOT NULL
);
/   

CREATE UNIQUE INDEX "HHS_CMS_HR"."ERLR_EMPLOYEE_CASE_PK" ON "HHS_CMS_HR"."ERLR_EMPLOYEE_CASE" 
(
     "HHSID", "CASE_NUMBER"
);

GRANT SELECT, INSERT, UPDATE, DELETE ON HHS_CMS_HR.ERLR_RELATED_CASE TO HHS_CMS_HR_RW_ROLE;
GRANT SELECT, INSERT, UPDATE, DELETE ON HHS_CMS_HR.ERLR_RELATED_CASE TO HHS_CMS_HR_DEV_ROLE;
GRANT SELECT, INSERT, UPDATE, DELETE ON HHS_CMS_HR.ERLR_RELATED_CASE TO BIZFLOW;


-- triggered cases
INSERT INTO ERLR_RELATED_CASE (CASE_NUMBER, RELATED_CASE_NUMBER, TRIGGER_F) 
select b.caseid, a.erlr_case_number, 'T'
from erlr_case a, (   
SELECT procid, max(casenumber) as caseid, max(fromprocid) as fromprocid
FROM(
SELECT R.procid, r.rlvntdataname, r.value 
  FROM BIZFLOW.PROCS P JOIN BIZFLOW.RLVNTDATA R ON P.PROCID = R.PROCID 
 WHERE P.NAME = 'ER/LR Case Initiation'
   and rlvntdataname in ('caseNumber', 'fromProcID')
   and value is not null
) T
PIVOT (
    MAX(VALUE) FOR RLVNTDATANAME IN ('caseNumber' casenumber, 'fromProcID' fromprocid)
)
where fromprocid is not null
group by procid 
) b
where a.procid = b.fromprocid;

-- Employee cases
INSERT INTO ERLR_EMPLOYEE_CASE(HHSID, CASE_NUMBER) 
SELECT DISTINCT F.HHSID, TO_NUMBER(R.VALUE)
    FROM (
    SELECT PROCID,
    XMLQUERY('/formData/items/item[id="GEN_EMPLOYEE_ID"]/value/text()' PASSING FIELD_DATA RETURNING CONTENT).GETSTRINGVAL() AS HHSID 
      FROM TBL_FORM_DTL 
     WHERE FORM_TYPE='CMSERLR') F JOIN BIZFLOW.RLVNTDATA R ON F.PROCID = R.PROCID AND R.RLVNTDATANAME = 'caseNumber'
 WHERE HHSID IS NOT NULL;
/

COMMIT;
/

ALTER TABLE ERLR_GEN
ADD CC_FINAL_ACTION_OTHER NVARCHAR2(100);

COMMIT;

-- Update Closed Cases
UPDATE HHS_CMS_HR.TBL_FORM_DTL
   SET FIELD_DATA = UPDATEXML(FIELD_DATA,'/formData/items/item[id="GEN_CASE_STATUS"]/value/text()', 'Closed')
 WHERE FORM_TYPE = 'CMSERLR'
   AND PROCID IN (SELECT PROCID FROM BIZFLOW.RLVNTDATA WHERE RLVNTDATANAME ='caseStatus' AND VALUE = 'closeNow');
/   

UPDATE HHS_CMS_HR.ERLR_GEN
   SET GEN_CASE_STATUS = 'Closed'
 WHERE GEN_CASE_STATUS = 'closeNow';
/

UPDATE HHS_CMS_HR.ERLR_CASE
   SET ERLR_CASE_STATUS_ID = 'Closed'
 WHERE ERLR_CASE_STATUS_ID = 'closeNow';
/

UPDATE BIZFLOW.RLVNTDATA
   SET VALUE = 'Closed'
 WHERE RLVNTDATANAME ='caseStatus'
   AND VALUE = 'closeNow';
/

UPDATE BIZFLOW.RLVNTDATA
   SET VALUE = 'Completed'
 WHERE RLVNTDATANAME ='caseStatus'
   AND PROCID IN (SELECT C.PROCID FROM ERLR_CASE C JOIN BIZFLOW.PROCS P ON C.PROCID = P.PROCID
                   WHERE P.STATE = 'C'
                     AND (C.ERLR_CASE_STATUS_ID IS NULL OR C.ERLR_CASE_STATUS_ID <> 'Closed'));

/

COMMIT;
/
----

-- Update Completed Cases
UPDATE ERLR_GEN
   SET PROCID = (SELECT PROCID FROM ERLR_CASE WHERE ERLR_GEN.ERLR_CASE_NUMBER = ERLR_CASE.ERLR_CASE_NUMBER);
/

UPDATE HHS_CMS_HR.TBL_FORM_DTL
   SET FIELD_DATA = UPDATEXML(FIELD_DATA,'/formData/items/item[id="GEN_CASE_STATUS"]/value/text()', 'Completed')
 WHERE FORM_TYPE = 'CMSERLR'
   AND PROCID IN (SELECT C.PROCID FROM ERLR_CASE C JOIN BIZFLOW.PROCS P ON C.PROCID = P.PROCID
                   WHERE P.STATE = 'C'
                     AND (C.ERLR_CASE_STATUS_ID IS NULL OR C.ERLR_CASE_STATUS_ID <> 'Closed'));
/

UPDATE HHS_CMS_HR.ERLR_GEN
   SET GEN_CASE_STATUS = 'Completed'
 WHERE PROCID IN (SELECT C.PROCID FROM ERLR_CASE C JOIN BIZFLOW.PROCS P ON C.PROCID = P.PROCID
                   WHERE P.STATE = 'C'
                     AND (C.ERLR_CASE_STATUS_ID IS NULL OR C.ERLR_CASE_STATUS_ID <> 'Closed'));
/

UPDATE HHS_CMS_HR.ERLR_CASE
   SET ERLR_CASE_STATUS_ID = 'Completed'
 WHERE PROCID IN (SELECT C.PROCID FROM ERLR_CASE C JOIN BIZFLOW.PROCS P ON C.PROCID = P.PROCID
                   WHERE P.STATE = 'C'
                     AND (C.ERLR_CASE_STATUS_ID IS NULL OR C.ERLR_CASE_STATUS_ID <> 'Closed'));
/

COMMIT;

ALTER TABLE ERLR_GEN ADD PROCID NUMBER;

/

SET DEFINE OFF;

--------------------------------------------------------
--  DDL for altering the tables INCENTIVES_COM
--------------------------------------------------------
ALTER TABLE INCENTIVES_COM ADD (
	SS_NAME        VARCHAR2(100),
	SS_EMAIL       VARCHAR2(100),
	SS_ID          VARCHAR2(10),
	VACANCY_NUMBER	 NUMBER(10)

);
/

CREATE TABLE INCENTIVES_PDP
(
	PROC_ID              NUMBER(10),
	PDP_TYPE             VARCHAR2(18),
	PDP_TYPE_OTHER	VARCHAR2(150),
	EXISTINGREQUEST	CHAR(1),
	-- Position
	WORK_SCHEDULE        VARCHAR2(15),
	HOURS_PER_WEEK       VARCHAR2(5),
	BD_CERT_REQ          VARCHAR2(5),
	LIC_INFO             VARCHAR2(140),
	MARKET_PAY_RATE VARCHAR2(9), 
	CURRENT_FED_EMPLOYEE  CHAR(1), 
	LEVEL_RESPONSIBILITY VARCHAR2(50),
	EXEC_RESP_AMT_REQUESTED NUMBER(10), 
	EXEC_RESP_JUSTIF_DETERMIN_AMT VARCHAR2(1000), 
	EXPT_QF_Q1_AMT_REQUESTED NUMBER(10), 
	EXPT_QF_Q1_JUSTIF_DETERMIN_AMT VARCHAR2(1000), 
	EXPT_QF_Q2_AMT_REQUESTED NUMBER(10), 
	EXPT_QF_Q2_JUSTIF_DETERMIN_AMT VARCHAR2(1000), 
	EXPT_QF_Q3_AMT_REQUESTED NUMBER(10), 
	EXPT_QF_Q3_JUSTIF_DETERMIN_AMT VARCHAR2(1000), 
	EXPT_QF_Q4_AMT_REQUESTED NUMBER(10), 
	EXPT_QF_Q4_JUSTIF_DETERMIN_AMT VARCHAR2(1000), 
	EXPT_QF_Q5_AMT_REQUESTED NUMBER(10), 
	EXPT_QF_Q5_JUSTIF_DETERMIN_AMT VARCHAR2(1000), 
	TOTAL_AMT_EXPT_QUALIFICATIONS NUMBER(10),
	CURRENT_PAY_GRADE NUMBER(2), 
	CURRENT_PAY_STEP NUMBER(2), 
	CURRENT_PAY_POSITION_TITLE VARCHAR2(70), 
	CURRENT_PAY_TABLE NUMBER(2), 
	CURRENT_PAY_TIER NUMBER(2), 
	CLINICAL_SPECIALTY_BOARD_CERT VARCHAR2(200),
	OTHER_SPECIALTY VARCHAR2(140),
	CURRENT_PAY_RECRUITMENT NUMBER(10), 
	CURRENT_PAY_RELOCATION NUMBER(10), 
	CURRENT_PAY_RETENTION NUMBER(10), 
	CURRENT_PAY_3R_TOTAL NUMBER(10), 
	CURRENT_PAY_BASE NUMBER(10), 
	CURRENT_PAY_LOCALITY_MARKET NUMBER(10), 
	CURRENT_PAY_TOTAL_ANNUAL_PAY NUMBER(10), 
	CURRENT_PAY_TOTAL_COMPENSATION NUMBER(10), 
	CURRENT_PAY_NOTES VARCHAR2(500), 
	PROPOSED_PAY_STEP NUMBER(2), 
	PROPOSED_PAY_TABLE NUMBER(2), 
	PROPOSED_PAY_TIER NUMBER(2), 
	PROPOSED_PAY_RECRUITMENT NUMBER(10), 
	PROPOSED_PAY_RELOCATION NUMBER(10), 
	PROPOSED_PAY_RETENTION NUMBER(10), 
	PROPOSED_PAY_TOTAL_3R NUMBER(10), 
	PROPOSED_GS_BASE_PAY NUMBER(10), 
	PROPOSED_MARKET_PAY NUMBER(10), 
	PROPOSED_TOTAL_ANNUAL_PAY NUMBER(10), 
	PROPOSED_TOTAL_ANNUAL_COMPENS NUMBER(10), 
	INCENTIVES_APPROVED_BY_TABG VARCHAR2(3), 
	PROPOSED_PAY_NOTES VARCHAR2(500), 
	DATE_OF_MEETING DATE, 
	PANEL_MEMBER_NAME VARCHAR2(100), 
	PANEL_MEMBER_COMPONENT VARCHAR2(50), 
	PANEL_ROLE VARCHAR2(9), 
	VOTING_STATUS VARCHAR2(16), 
	PANEL_RECOMMENDED_COMPENSATION NUMBER(10), 
	QUORUM_REACHED CHAR(1),
	PANEL_CURRENT_SALARY NUMBER(10), 
	PANEL_PDP_AMOUNT NUMBER(10), 
	PANEL_RECOMM_ANNUAL_SALARY NUMBER(10), 
	SELECTING_OFFICIAL_REVIEWER VARCHAR2(100), 
	SELECTING_OFFICIAL_REVIEW_DT DATE, 
	TABG_DIVISION_DIR_REVIEW_DT DATE, 
	CMS_CHIEF_PHYSICIAN_REVIEW_DT DATE, 
	OFM_REVIEW_DATE DATE, 
	TABG_REVIEW_DATE DATE, 
	OHC_REVIEW_DATE DATE, 
	ADMINISTRATOR_APPROVAL_DATE DATE
);

CREATE UNIQUE INDEX INCENTIVES_PDP_UK1 ON INCENTIVES_PDP (PROC_ID);

/

SET DEFINE OFF;

GRANT SELECT, INSERT, UPDATE, DELETE ON HHS_CMS_HR.INCENTIVES_PDP TO HHS_CMS_HR_RW_ROLE;
GRANT SELECT, INSERT, UPDATE, DELETE ON HHS_CMS_HR.INCENTIVES_PDP TO HHS_CMS_HR_DEV_ROLE;
GRANT SELECT, INSERT, UPDATE, DELETE ON HHS_CMS_HR.INCENTIVES_PDP TO BIZFLOW;
/

--------------------------------------------------------
-- DDL to alter Table CMS_TIME_TO_HIRE_WEEKLY_PILOT
--------------------------------------------------------
ALTER TABLE HHS_CMS_HR.CMS_TIME_TO_HIRE_WEEKLY_PILOT ADD 
(
    ACTION_ACTIVE_PRIOR_STRAT_CON NUMBER(10), -- flag if Request_Status = 'Request Created' then 1 else 0
    ACHIEVED_STRAT_CON      NUMBER(10),
    ACHIEVED_CLASS          NUMBER(10),
    ACHIEVED_QUALS          NUMBER(10),
    ACHIEVED_SELECTION      NUMBER(10),
    OFFER_START             DATE,          
    OFFER_END               DATE, 
    ACHIEVED_OFFER          NUMBER(10),
    MISSED_OFFER            NUMBER(10)
);

GRANT DELETE, INSERT, SELECT, UPDATE ON HHS_CMS_HR.CMS_TIME_TO_HIRE_WEEKLY_PILOT TO HHS_CMS_HR_RW_ROLE;
GRANT DELETE, INSERT, SELECT, UPDATE ON HHS_CMS_HR.CMS_TIME_TO_HIRE_WEEKLY_PILOT TO HHS_CMS_HR_DEV_ROLE;
/

ALTER TABLE ERLR_PERF_ISSUE ADD (
    PI_CLPD_ENTRANCE_DUTY_DT DATE NULL,
    PI_CLPD_NEXT_CLP_DUE_DT DATE NULL,
    PI_CLPD_PRE_WITHHELD NVARCHAR2(3) NULL,
    PI_CLPD_FIRST_WNI_DT DATE NULL,
    PI_CLPD_NEXT_REVIEW_DUE_DT DATE NULL,
    PI_CLPD_DAPI_DT DATE NULL,
    PI_CLPD_FIRST_WITHHELD_DT DATE NULL,
    PI_CLPD_PLANNED_REVIEW_DT DATE NULL,
    PI_CLPD_DETER_FAV NVARCHAR2(3) NULL,
    PI_CLPD_SECOND_WNI_DT DATE NULL,
    PI_CLPD_DECISION_ISSUED_DT DATE NULL,
    PI_CLPD_DECIDING_OFFCL NVARCHAR2(100) NULL,
    PI_CLPD_EMP_GRIEVANCE NVARCHAR2(3) NULL,
    PI_CLPD_EMP_APPEAL_DECISION NVARCHAR2(3) NULL
);
/

ALTER TABLE INCENTIVES_LE ADD (
  APPROVER_NOTES VARCHAR2(500) NULL
);
/

ALTER TABLE HHS_CMS_HR.CMS_TIME_TO_HIRE_WEEKLY_PILOT RENAME COLUMN OFFER_START TO TENT_OFFER_START;
ALTER TABLE HHS_CMS_HR.CMS_TIME_TO_HIRE_WEEKLY_PILOT RENAME COLUMN OFFER_END TO TENT_OFFER_END;
ALTER TABLE HHS_CMS_HR.CMS_TIME_TO_HIRE_WEEKLY_PILOT RENAME COLUMN ACHIEVED_OFFER TO ACHIEVED_TENT_OFFER;
ALTER TABLE HHS_CMS_HR.CMS_TIME_TO_HIRE_WEEKLY_PILOT RENAME COLUMN MISSED_OFFER TO MISSED_TENT_OFFER;

ALTER TABLE HHS_CMS_HR.CMS_TIME_TO_HIRE_WEEKLY_PILOT ADD 
(
    OFCL_OFFER_START             DATE,          
    OFCL_OFFER_END               DATE, 
    ACHIEVED_OFCL_OFFER          NUMBER(10),
    MISSED_OFCL_OFFER            NUMBER(10)
);
/

COMMIT;
/
