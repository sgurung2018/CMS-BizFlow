--------------------------------------------------------
--  DDL for VW_ERLR_LABOR_NEGO
--------------------------------------------------------
CREATE OR REPLACE VIEW VW_ERLR_LABOR_NEGO
AS
SELECT
    LN.ERLR_CASE_NUMBER
    , EC.ERLR_JOB_REQ_NUMBER
    , EC.PROCID    
    , EC.ERLR_CASE_CREATE_DT
    , LN_NEGOTIATION_TYPE	
    , LN_INITIATOR
	, LN_DEMAND2BARGAIN_DT
	, LN_BRIEFING_REQUEST
	, LN_PROPOSAL_SUBMISSION_DT
	, LN_PROPOSAL_SUBMISSION
	, LN_PROPOSAL_NEGOTIABLE
	, LN_NON_NEGOTIABLE_LETTER
	, LN_FILE_ULP
	, LN_PROPOSAL_INFO_GROUND_RULES
	, LN_PRPSAL_INFO_NEG_COMMENCE_DT
	, LN_LETTER_PROVIDED
	, LN_LETTER_PROVIDED_DT
	, LN_NEGOTIABLE_PROPOSAL
	, LN_BARGAINING_BEGAN_DT
	, LN_IMPASSE_DT
	, LN_FSIP_DECISION_DT
	, LN_BARGAINING_END_DT
	, LN_AGREEMENT_DT
	, LN_SUMMARY_OF_ISSUE
	, LN_SECON_LETTER_REQUEST
	, LN_2ND_LETTER_PROVIDED
	, LN_NEGOTIABL_ISSUE_SUMMARY
	, LN_MNGMNT_ARTICLE4_NTC_DT
	, LN_MNGMNT_NOTICE_RESPONSE
	, LN_MNGMNT_BRIEFING_REQUEST
	, LN_MNGMNT_BARGAIN_SBMSSION_DT
	, LN_MNGMNT_PROPOSAL_SBMSSION
    , LN_BRIEFING_DT
    , LN_2ND_PROVIDED_DT
    , LN_BRIEFING_REQUESTED2_DT
FROM
	ERLR_LABOR_NEGO LN
    LEFT OUTER JOIN ERLR_CASE EC ON LN.ERLR_CASE_NUMBER = EC.ERLR_CASE_NUMBER
;
/
