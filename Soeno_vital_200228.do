//Import vital sign data
	clear
	import delimited "/Users/shokosoeno/Downloads/tidy_tables/ERresearch_EHR_VITAL_NUMERIC.csv", encoding(utf8) clear
	
		/*We need to check outlier in vital signs*/

	save "/Users/shokosoeno/Downloads/TXP_prq/vital.dta", replace

//Import DPC data
	import excel "/Users/shokosoeno/Desktop/TXP_vital_20200106/20191231_ERresearch_adpc_original.xlsx", sheet("Sheet1") firstrow clear
		rename EncounterID encounter_id

	save "/Users/shokosoeno/Downloads/TXP_prq/dpc.dta", replace

//Import complaint
	import delimited "/Users/shokosoeno/Downloads/tidy_tables/ERresearch_EHR_COMPLAINT.csv",  encoding(utf8) varnames(1) clear
		
		///Use only the primary CC
		bysort encounter_id: gen n_by_id=_n
		keep if n_by_id==1
		///Sort by the frequency of CC
		bysort standardcc: gen n_by_cc=_N
		sort n_by_cc
		
		rename standardcc cc

	save "/Users/shokosoeno/Downloads/TXP_prq/complaint.dta", replace

//Import diagnosis
	import delimited "/Users/shokosoeno/Downloads/tidy_tables/ERresearch_EHR_DIAGNOSIS.csv", encoding(utf8) varnames(1) clear
		
		///Use only the primary CC
		bysort encounter_id: gen n_by_id=_n
		keep if n_by_id==1
		///Sort by the frequency of CC
		bysort icd10_1: gen n_by_cc=_N
		sort n_by_cc
		
		rename icd10_1 diagnosis

	save "/Users/shokosoeno/Downloads/TXP_prq/diagnosis.dta", replace

//Import encounter data
	import delimited "/Users/shokosoeno/Downloads/tidy_tables/ERresearch_EHR_ENCOUNTER.csv", encoding(utf8) varnames(1) clear
	save "/Users/shokosoeno/Downloads/TXP_prq/enc.dta", replace
	
//Import history data
	import delimited "/Users/shokosoeno/Downloads/tables_201804_201909/EHR_MEDICAL_HISTORY_CCI.csv", encoding(utf8) varnames(1) clear
	//caliculate cci
	tab cci1_mi
	tab cci2_chd
	tab cci3_pvd
	tab cci4_cvd
	tab cci5_dementia
	tab cci6_pulmo
	tab cci7_rheu
	tab cci8_ulcer
	tab cci9_mild_liver
	tab cci10_dm_no_comp
	tab cci11_dm_comp*2
	tab cci12_plegia*2
	tab cci13_rd*2
	tab cci14_malig*2
    tab cci15_mod_sev_liver*3
	tab cci16_meta*6
	tab cci17_aids*6
	bysort encounter_id : gen cci_each = cci1_mi + cci2_chd + cci3_pvd + cci4_cvd + cci5_dementia + cci6_pulmo + cci7_rheu + cci8_ulcer + cci9_mild_liver + cci10_dm_no_comp + cci11_dm_comp*2 + cci12_plegia*2 + cci13_rd*2 + cci14_malig*2 + cci15_mod_sev_liver*3 + cci16_meta*6 + cci17_aids*6
	keep encounter_id cci_each
	tab cci_each
	//bysort encounter_id : egen cci = sum(cci_each)
	gsort + encounter_id - cci_each
	duplicates drop encounter_id, force
	tab cci_each
	//collapse (sum) cci = cci_each, by(encounter_id)
	save "/Users/shokosoeno/Downloads/TXP_prq/cci.dta", replace

//////////////////////////////////////////
	
//merge vital data and dpc data
	use "/Users/shokosoeno/Downloads/TXP_prq/vital.dta", clear
		merge 1:1 encounter_id using "/Users/shokosoeno/Downloads/TXP_prq/enc.dta"
			drop _merge
		merge 1:1 encounter_id using "/Users/shokosoeno/Downloads/TXP_prq/dpc.dta"
			drop _merge
		merge 1:1 encounter_id using "/Users/shokosoeno/Downloads/TXP_prq/complaint.dta"
			drop _merge
		merge 1:1 encounter_id using "/Users/shokosoeno/Downloads/TXP_prq/diagnosis.dta"
			drop _merge
		merge 1:1 encounter_id using "/Users/shokosoeno/Downloads/TXP_prq/cci.dta"

	save "/Users/shokosoeno/Downloads/TXP_prq/merged.dta", replace
	
///Data cleaning
	use "/Users/shokosoeno/Downloads/TXP_prq/merged.dta", clear
	
		//Drop children and missing age
		drop if age==.
		drop if age<18
		
		///Drop missing data on respiratory rate
		drop if pr==. | rr==. | spo2==.

		///Drop CPA
		drop if cpa_flag==1 | pr==0 | rr==0 | spo2==0
		
		//Drop outliers
		drop if pr<10 | pr>300
		drop if rr<3 | rr>60
		drop if spo2<10 | spo2>100

		//drop if the dprimary diagoniss is I46 or S00-U99 ...0 observations deleted
		//もう少し賢いやり方がありそうなので後藤先生に聞いてみる
		//drop if diagnosis = "I46"
		//gen dia_new = substr(diagnosis,1,1)
		//drop if dia_new == "S" |  dia_new == "T" | dia_new == "U"
		
		//Generalte pulse-respiration quotient (PRQ) and REFI
		gen prq=pr/rr
		gen refi=(rr*100)/spo2
		replace prq = 2 if prq <2
		replace prq = 8 if prq >8
		replace refi = 10 if refi < 10
		replace refi = 40 if refi > 40
		
		//Age category
		gen agecat=1 if age>=18 & age<40
		replace agecat=2 if age>=40 & age<65
		replace agecat=3 if age>=65 & age<85
		replace agecat=4 if age>=85 & age<.
		
		//Top 10 CC category 
		//tab CC, sort
		gen CC_1_fever=0
		replace CC_1_fever=1 if cc_code=="cc80" //発熱
		gen CC_2_shortbr=0
		replace CC_2_shortbr=1 if cc_code=="cc38" //呼吸困難
		gen CC_3_mental=0
		replace CC_3_mental=1 if cc_code=="cc58" //意識障害
		gen CC_4_chestp=0
		replace CC_4_chestp=1 if cc_code=="cc89" //胸痛 
		gen CC_5_abdp=0
		replace CC_5_abdp=1 if cc_code=="cc94" | cc_code=="cc96" | cc_code=="cc54" | cc_code=="cc35" | cc_code=="cc36" 
			//腹痛: 臍下部痛はcc96, 心窩部痛はcc54, 右上腹部痛はcc35, 右下腹部痛はcc36
		
		//Route 分類について後藤先生に再確認
		//replace route = 1
		//replace route=2 if Route=="ems" | Route=="ems_dr" | Route=="ems_heli" | Route=="DRカー" 
		//replace route=3 if Route=="walkin_direct" | Route=="walkin_follow" | Route=="others" | Route=="rrs"
		
		//Disposition
		gen hosp=0 
		replace hosp=1 if disposition=="入院" | disposition=="ICU" | disposition=="直接入院" 

		gen icu=0
		replace icu=1 if disposition=="ICU" 
		
		gen death=0
		replace death=1 if tenki=="死亡" | disposition=="死亡"
	
	save "/Users/shokosoeno/Downloads/TXP_prq/analysis.dta", replace

///Data analysis
	use "/Users/shokosoeno/Downloads/TXP_prq/analysis.dta", clear
	
	//Characteristics of ED visits
	//Use Table 1 command (findit table1)
	
	//Change outliers to missing
	replace sbp=. if sbp<20 | sbp>300
	replace dbp=. if dbp<20 | dbp>300
	replace bt=. if bt<20 | bt>45
	
	//Output table1
	table1, vars(age contn \ sex cat \ sbp contn \ dbp contn \ pr contn \ /*
	*/ rr contn \ spo2 contn \ bt contn \ jtas cat \ route cat \ cci cat \/*
	*/ hosp cat \ icu cat \ death cat \ staylength conts \ prq contn \ refi contn) format(%9.0f) sav (/Users/shokosoeno/Downloads/TXP_prq/table1) 
	

	//LOWESS curve
	lowess hosp prq
	lowess death prq
	lowess hosp refi
	lowess death refi
	
	//Cubic spline regression
	//install xbrcspline 
	
	//Cubic spline for pqr and hosp 
	preserve
	mkspline prqs = prq , nknots(7) cubic displayknots
	mat knots = r(knots)
	logit hosp prqs*
	
	xbrcspline prqs , matknots(knots) ///
	values(2 3 4 5 6 7 8 9 10) ///
	ref(6) eform gen(prq_f or lb ub)
	
	twoway (line lb ub or prq_f, lp(- - l) lc(black black black) ) ///
                if inrange(prq_f, 0,11)  , ///
                                scheme(s1mono) legend(off) ///
                                ylabel(0(.5)3, angle(horiz) format(%2.1fc) ) ///
                                xlabel(1(1)11) ///
                                ytitle("Odds ratio of hospitalization") ///
                                xtitle("Pulse-respiration quotient")
	restore

	//Cubic spline for refi and hosp 
	//drop refis1 refis2 refis3 refis4 refis5 refis6
	preserve
	mkspline refis = refi , nknots(7) cubic displayknots
	mat knots = r(knots)
	logit hosp refis*
	
	xbrcspline refis , matknots(knots) ///
	values(5 10 15 20 25 30 35 40 45 50) ///
	ref(15) eform gen(refi_f or lb ub)
	
		twoway (line lb ub or refi_f, lp(- - l) lc(black black black) ) ///
                if inrange(refi_f, 0, 55)  , ///
                                scheme(s1mono) legend(off) ///
                                ylabel(0(.5)8, angle(horiz) format(%2.1fc) ) ///
                                xlabel(0(5)55) ///
                                ytitle("Odds ratio of hospitalization") ///
                                xtitle("Respiratory Efficacy Index")
	restore

	//Cubic spline for pqr and death 
	//drop prqs1 prqs2 prqs3 prqs4 prqs5 prqs6
	mkspline prqs = prq , nknots(7) cubic displayknots
	mat knots = r(knots)
	logit death prqs*
	
	xbrcspline prqs , matknots(knots) ///
	values(2 3 4 5 6 7 8 9 10) ///
	ref(6) eform

	//Cubic spline for refi and death
	//drop refis1 refis2 refis3 refis4 refis5 refis6
	mkspline refis = refi , nknots(7) cubic displayknots
	mat knots = r(knots)
	logit death refis*
	
	xbrcspline refis , matknots(knots) ///
	values(5 10 15 20 25 30 35 40 45 50) ///
	ref(15) eform
	
	//LOWESS for each CC
	lowess hosp prq if CC_1_fever==1
	lowess death prq if CC_1_fever==1
	lowess hosp refi if CC_1_fever==1
	lowess death refi if CC_1_fever==1
		
	lowess hosp prq if CC_2_shortbr==1
	lowess death prq if CC_2_shortbr==1
	lowess hosp refi if CC_2_shortbr==1
	lowess death refi if CC_2_shortbr==1	
	
	lowess hosp prq if CC_3_mental==1
	lowess death prq if CC_3_mental==1
	lowess hosp refi if CC_3_mental==1
	lowess death refi if CC_3_mental==1	
	
	lowess hosp prq if CC_4_chestp==1
	lowess death prq if CC_4_chestp==1
	lowess hosp refi if CC_4_chestp==1
	lowess death refi if CC_4_chestp==1	
	
	lowess hosp prq if CC_5_abdp==1
	lowess death prq if CC_5_abdp==1
	lowess hosp refi if CC_5_abdp==1
	lowess death refi if CC_5_abdp==1	

	
	//主訴別のdiagnosisのtop3 図を
	tabulate diagnosis if CC_1_fever==1, sort
	tabulate diagnosis if CC_2_shortbr==1, sort
	tabulate diagnosis if CC_3_mental==1, sort
	tabulate diagnosis if CC_4_chestp==1, sort
	tabulate diagnosis if CC_5_abdp==1, sort
	
	//Respiratory rate単体
	lowess hosp rr if CC_1_fever==1
	lowess death rr if CC_1_fever==1
	
	lowess hosp rr if CC_2_shortbr==1
	lowess death rr if CC_2_shortbr==1
	
	lowess hosp rr if CC_3_mental==1
	lowess death rr if CC_3_mental==1
	
	lowess hosp rr if CC_4_chestp==1
	lowess death rr if CC_4_chestp==1
	
	lowess hosp rr if CC_5_abdp==1
	lowess death rr if CC_5_abdp==1
