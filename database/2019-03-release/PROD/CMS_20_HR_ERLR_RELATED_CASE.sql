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
   

CREATE UNIQUE INDEX "HHS_CMS_HR"."ERLR_RELATED_CASE_PK" 
    ON "HHS_CMS_HR"."ERLR_RELATED_CASE" 
    (
     "CASE_NUMBER", "RELATED_CASE_NUMBER"
    );

   

CREATE OR REPLACE VIEW VW_ERLR_RELATED_CASE
AS SELECT E.RELATED_CASE_NUMBER AS CASE_NUMBER, 
    G.GEN_EMPLOYEE_ID AS HHSID, 
    CASE WHEN E.TRIGGER_F = 'F' AND E.M_DT IS NULL THEN 'T' ELSE 'F' END AS DELETABLE, 
    E.CASE_NUMBER ||'-'|| D.TBL_LABEL||'-'|| NVL(L.LAST_NAME,'N/A') AS DISPLAY
FROM ERLR_RELATED_CASE E 
     JOIN ERLR_GEN G ON G.ERLR_CASE_NUMBER = E.RELATED_CASE_NUMBER 
     JOIN TBL_LOOKUP D ON D.TBL_ID = G.GEN_CASE_TYPE 
     LEFT JOIN HHS_HR.EMPLOYEE_LOOKUP L ON L.HHSID = G.GEN_EMPLOYEE_ID;

-- MIGRATION

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



COMMIT;


