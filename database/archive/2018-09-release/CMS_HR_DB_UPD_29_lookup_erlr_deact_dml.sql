
SET DEFINE OFF;



-- deactivate 'Alternative Discipline'
UPDATE TBL_LOOKUP 
SET TBL_ACTIVE = '0'
WHERE TBL_ID IN (731)
;


INSERT INTO TBL_LOOKUP (TBL_ID, TBL_PARENT_ID, TBL_LTYPE, TBL_NAME, TBL_LABEL, TBL_ACTIVE, TBL_MANDATORY, TBL_EFFECTIVE_DT, TBL_EXPIRATION_DT)
VALUES (809, 0, 'ERLRInitialResponseCaseTpe', 'Within Grade Increase Denial', 'Within Grade Increase Denial/Reconsideration', 1, 'N', TO_DATE('2017-01-01 00:00:00', 'YYYY-MM-DD HH24:MI:SS'),TO_DATE('2050-01-01 00:00:00', 'YYYY-MM-DD HH24:MI:SS'))
; 
