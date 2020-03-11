//Import vital sign data
	clear
	import delimited "/Users/shokosoeno/Downloads/tables_201804_201909/EHR_VITAL_NUMERIC.csv", encoding(utf8) clear
	sort encounter_id vs_date vs_time
		bysort encounter_id: gen n_by_id=_n
		keep if n_by_id==1
		
	save "/Users/shokosoeno/Desktop/TXP/prq/vital.dta", replace

//Import DPC data
	import excel "/Users/shokosoeno/Desktop/TXP_vital_20200106/20191231_ERresearch_adpc_original.xlsx", sheet("Sheet1") firstrow clear
		rename EncounterID encounter_id

	save "/Users/shokosoeno/Desktop/TXP/prq/dpc.dta", replace

//Import complaint
	import delimited "/Users/shokosoeno/Downloads/tables_201804_201909/EHR_COMPLAINT.csv",  encoding(utf8) varnames(1) clear
		
		///Use only the primary CC
		sort encounter_id item_id
		drop if encounter_id == ""
		reshape wide standardcc, i(encounter_id) j(item_id) 		 
		
	save "/Users/shokosoeno/Desktop/TXP/prq/complaint.dta", replace

//Import diagnosis
	import delimited "/Users/shokosoeno/Downloads/tables_201804_201909/EHR_DIAGNOSIS.csv", encoding(utf8) varnames(1) clear
		
		///Use only the primary CC
		sort encounter_id item_id
		keep if item_id==1

		rename icd10 diagnosis
		
	save "/Users/shokosoeno/Desktop/TXP/prq/diagnosis.dta", replace

//Import encounter data
	import delimited "/Users/shokosoeno/Downloads/tables_201804_201909/EHR_ENCOUNTER.csv", encoding(utf8) varnames(1) clear
	save "/Users/shokosoeno/Desktop/TXP/prq/enc.dta", replace
	
//Import history data
	import delimited "/Users/shokosoeno/Downloads/tables_201804_201909/EHR_MEDICAL_HISTORY_CCI.csv", encoding(utf8) varnames(1) clear
	//caliculate cci
	bysort encounter_id : gen cci_each = cci1_mi + cci2_chd + cci3_pvd + cci4_cvd + cci5_dementia + cci6_pulmo + cci7_rheu + cci8_ulcer + cci9_mild_liver + cci10_dm_no_comp + cci11_dm_comp*2 + cci12_plegia*2 + cci13_rd*2 + cci14_malig*2 + cci15_mod_sev_liver*3 + cci16_meta*6 + cci17_aids*6
	keep encounter_id cci_each
	tab cci_each
	//bysort encounter_id : egen cci = sum(cci_each)
	gsort + encounter_id - cci_each
	duplicates drop encounter_id, force
	tab cci_each
	//collapse (sum) cci = cci_each, by(encounter_id)
	save "/Users/shokosoeno/Desktop/TXP/prq/cci.dta", replace
	
//import procedure
	import delimited "/Users/shokosoeno/Downloads/tables_201804_201909/CLAIM_PROCEDURE.csv", encoding(UTF-8)clear
	gen mv_ref=0
		replace mv_ref=1 if procedure_code=="J044" | procedure_code=="J045" 
		
		bysort encounter_id: egen mv=sum(mv_ref)
		bysort encounter_id: gen n_by_id=_n
		keep if n_by_id==1
		replace mv=1 if mv>=1 & mv<.
		keep encounter_id mv
	save "/Users/shokosoeno/Desktop/TXP/prq/mv.dta", replace

//merge vital data and dpc data
	use "/Users/shokosoeno/Desktop/TXP/prq/vital.dta", clear
		merge 1:1 encounter_id using "/Users/shokosoeno/Desktop/TXP/prq/enc.dta"
			drop _merge
		merge 1:1 encounter_id using "/Users/shokosoeno/Desktop/TXP/prq/dpc.dta"
			drop _merge
		merge 1:1 encounter_id using "/Users/shokosoeno/Desktop/TXP/prq/complaint.dta"
			drop _merge
		merge 1:1 encounter_id using "/Users/shokosoeno/Desktop/TXP/prq/diagnosis.dta"
			drop _merge
		merge 1:1 encounter_id using "/Users/shokosoeno/Desktop/TXP/prq/cci.dta"
			drop _merge
		merge 1:1 encounter_id using "/Users/shokosoeno/Desktop/TXP/prq/mv.dta"

	save "/Users/shokosoeno/Desktop/TXP/prq/merged.dta", replace
	
///Data cleaning
	use "/Users/shokosoeno/Desktop/TXP/prq/merged.dta", clear
	
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

		gen CC_1_fever=0
		replace CC_1_fever=1 if standardcc1=="発熱" //発熱
		gen CC_2_shortbr=0
		replace CC_2_shortbr=1 if standardcc1=="呼吸困難" //呼吸困難
		gen CC_3_mental=0
		replace CC_3_mental=1 if standardcc1=="意識障害" //意識障害
		gen CC_4_chestp=0
		replace CC_4_chestp=1 if standardcc1=="胸痛" //胸痛 
		gen CC_5_abdp=0
		replace CC_5_abdp=1 if standardcc1=="腹痛" | standardcc1=="臍下部痛" | standardcc1=="心窩部痛" | standardcc1=="右上腹部痛" | standardcc1=="右下腹部痛" 
		gen CC_6_ha=0
		replace CC_6_ha=1 if standardcc1=="頭痛" 
		gen CC_7_nausea=0
		replace CC_7_nausea=1 if standardcc1=="嘔吐・嘔気"
		
		//Disposition
		gen hosp=0 
		replace hosp=1 if disposition=="入院" | disposition=="ICU" | disposition=="直接入院" 

		//gen icu=0
		//replace icu=1 if disposition=="ICU" 
		
		gen death=0
		replace death=1 if tenki=="死亡" | disposition=="死亡"
	
	save "/Users/shokosoeno/Desktop/TXP/prq/analysis.dta", replace
	
///Data analysis
	use "/Users/shokosoeno/Desktop/TXP/prq/analysis.dta", clear
	
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
	
	
	//LOWESS curve for hospitalization or death
	twoway (lowess hosp rr) (lowess mv rr) (lowess death rr), /*
	*/ legend(order(1 "hospitalization" 2 "mechanical ventilation" 3 "death") col(3)) /*
    */                          ylabel(0(.5)1, angle(horiz) format(%2.1fc) ) ///
                                xlabel(0(5)40) ///
                                ytitle("Risk of clinical outcome") ///
                                xtitle("Respiratory Rate")

	twoway (lowess hosp refi)(lowess mv refi) (lowess death refi), /*
	*/ legend(order(1 "hospitalization" 2 "mechanical ventilation" 3 "death") col(3)) /*
    */                          ylabel(0(.5)1, angle(horiz) format(%2.1fc) ) ///
                                xlabel(0(10)50) ///
                                ytitle("Risk of clinical outcome") ///
                                xtitle("REFI")

	twoway (lowess hosp prq)(lowess mv prq)(lowess death prq), /*
	*/ legend(order(1 "hospitalization" 2 "mechanical ventilation" 3 "death") col(3)) /*
    */                          ylabel(0(.5)1, angle(horiz) format(%2.1fc) ) ///
                                xlabel(0(1)10) ///
                                ytitle("Risk of clinical outcome") ///
                                xtitle("PRQ")

	//Lowess curve by CC
	//RR
	twoway (lowess hosp rr if CC_1_fever==1) /*
	*/ (lowess hosp rr if CC_2_shortbr==1) (lowess hosp rr if CC_3_mental==1) /*
	*/ (lowess hosp rr if CC_4_chestp==1) (lowess hosp rr if CC_5_abdp==1), /*
	*/ legend(order(1 "Fever" 2 "Shortness of breath" 3 "Altered mental status" 4 "Chest pain" 5 "Abdominal pain") col(4)) /*
    */                          ylabel(0(.5)1, angle(horiz) format(%2.1fc) ) ///
                                xlabel(0(5)40) ///
                                ytitle("Risk of hospitalization") ///
                                xtitle("Respiratory Rate")
	//REFI
	twoway (lowess hosp refi if CC_1_fever==1) /*
	*/ (lowess hosp refi if CC_2_shortbr==1) (lowess hosp refi if CC_3_mental==1) /*
	*/ (lowess hosp refi if CC_4_chestp==1) (lowess hosp refi if CC_5_abdp==1), /*
	*/ legend(order(1 "Fever" 2 "Shortness of breath" 3 "Altered mental status" 4 "Chest pain" 5 "Abdominal pain") col(4)) /*
    */                          ylabel(0(.5)1, angle(horiz) format(%2.1fc) ) ///
                                xlabel(10(10)50) ///
                                ytitle("Risk of hospitalization") ///
                                xtitle("REFI")

	//PRQ
	twoway (lowess hosp prq if CC_1_fever==1) /*
	*/ (lowess hosp prq if CC_2_shortbr==1) (lowess hosp prq if CC_3_mental==1) /*
	*/ (lowess hosp prq if CC_4_chestp==1) (lowess hosp prq if CC_5_abdp==1), /*
	*/ legend(order(1 "Fever" 2 "Shortness of breath" 3 "Altered mental status" 4 "Chest pain" 5 "Abdominal pain") col(4)) /*
    */                          ylabel(0(.5)1, angle(horiz) format(%2.1fc) ) ///
                                xlabel(0(1)10) ///
                                ytitle("Risk of hospitalization") ///
                                xtitle("PRQ")
	
	//Cubic spline regression
	//install xbrcspline 
	
	//Cubic spline for rr and hosp 
	preserve
	mkspline rrs = rr , nknots(7) cubic displayknots
	mat knots = r(knots)
	logit hosp rrs*
	
	xbrcspline rrs , matknots(knots) ///
	values(8 12 16 20 24 28 32) ///
	ref(16) eform gen(rr_f or lb ub)
	
	twoway (line lb ub or rr_f, lp(- - l) lc(black black black) ) ///
                if inrange(rr_f, 0,32)  , ///
                                scheme(s1mono) legend(off) ///
                                ylabel(0(1)3, angle(horiz) format(%2.1fc) ) ///
                                xlabel(8(1)32) ///
                                ytitle("Odds ratio of hospitalization") ///
                                xtitle("Respiratory Rate")
	restore
	//Cubic spline for rr and hosp by CC
	preserve 
	keep if CC_1_fever == 1
	mkspline rrs = rr , nknots(7) cubic displayknots
	mat knots = r(knots)
	logit hosp rrs*
	xbrcspline rrs , matknots(knots) ///
	values(8 12 16 20 24 28 32) ///
	ref(16) eform gen(rr_f or lb ub)
	restore

	preserve 
	keep if CC_2_shortbr==1
	mkspline rrs = rr , nknots(7) cubic displayknots
	mat knots = r(knots)
	logit hosp rrs*
	xbrcspline rrs , matknots(knots) ///
	values(8 12 16 20 24 28 32) ///
	ref(16) eform gen(rr_f or lb ub)
	restore

	preserve 
	keep if CC_3_mental == 1
	mkspline rrs = rr , nknots(7) cubic displayknots
	mat knots = r(knots)
	logit hosp rrs*
	xbrcspline rrs , matknots(knots) ///
	values(8 12 16 20 24 28 32) ///
	ref(16) eform gen(rr_f or lb ub)
	restore

	preserve 
	keep if CC_4_chestp ==1
	mkspline rrs = rr , nknots(7) cubic displayknots
	mat knots = r(knots)
	logit hosp rrs*
	xbrcspline rrs , matknots(knots) ///
	values(8 12 16 20 24 28 32) ///
	ref(16) eform gen(rr_f or lb ub)
	restore

	preserve 
	keep if CC_5_abdp ==1
	mkspline rrs = rr , nknots(7) cubic displayknots
	mat knots = r(knots)
	logit hosp rrs*
	xbrcspline rrs , matknots(knots) ///
	values(8 12 16 20 24 28 32) ///
	ref(16) eform gen(rr_f or lb ub)
	restore

	//Cubic spline for refi and hosp by cc
	preserve
	mkspline refis = refi , nknots(7) cubic displayknots
	mat knots = r(knots)
	logit hosp refis*
	xbrcspline refis , matknots(knots) ///
	values(10 15 20 25 30 35 40) ///
	ref(20) eform gen(refi_f or lb ub)
	restore

	preserve
	keep if CC_1_fever == 1
	mkspline refis = refi , nknots(7) cubic displayknots
	mat knots = r(knots)
	logit hosp refis*
	xbrcspline refis , matknots(knots) ///
	values(10 15 20 25 30 35 40) ///
	ref(20) eform gen(refi_f or lb ub)
	restore

	preserve 
	keep if CC_2_shortbr==1
	mkspline refis = refi , nknots(7) cubic displayknots
	mat knots = r(knots)
	logit hosp refis*
	xbrcspline refis , matknots(knots) ///
	values(10 15 20 25 30 35 40) ///
	ref(20) eform gen(refi_f or lb ub)
	restore

	preserve 
	keep if CC_3_mental == 1
	mkspline refis = refi , nknots(7) cubic displayknots
	mat knots = r(knots)
	logit hosp refis*
	xbrcspline refis , matknots(knots) ///
	values(10 15 20 25 30 35 40) ///
	ref(20) eform gen(refi_f or lb ub)
	restore

	preserve 
	keep if CC_4_chestp ==1
	mkspline refis = refi , nknots(7) cubic displayknots
	mat knots = r(knots)
	logit hosp refis*
	xbrcspline refis , matknots(knots) ///
	values(10 15 20 25 30 35 40) ///
	ref(20) eform gen(refi_f or lb ub)
	restore

	preserve 
	keep if CC_5_abdp ==1
	mkspline refis = refi , nknots(7) cubic displayknots
	mat knots = r(knots)
	logit hosp refis*
	xbrcspline refis , matknots(knots) ///
	values(10 15 20 25 30 35 40) ///
	ref(20) eform gen(refi_f or lb ub)
	restore
	
	//Cubic spline for pqr and hosp by cc
	preserve
	mkspline prqs = prq , nknots(7) cubic displayknots
	mat knots = r(knots)
	logit hosp prqs*
	xbrcspline prqs , matknots(knots) ///
	values(2 3 4 5 6 7 8) ///
	ref(4) eform gen(prq_f or lb ub)
	restore

	preserve
	keep if CC_1_fever == 1
	mkspline prqs = prq , nknots(7) cubic displayknots
	mat knots = r(knots)
	logit hosp prqs*
	xbrcspline prqs , matknots(knots) ///
	values(2 3 4 5 6 7 8) ///
	ref(4) eform gen(prq_f or lb ub)
	restore

	preserve 
	keep if CC_2_shortbr==1
	mkspline prqs = prq , nknots(7) cubic displayknots
	mat knots = r(knots)
	logit hosp prqs*
	xbrcspline prqs , matknots(knots) ///
	values(2 3 4 5 6 7 8) ///
	ref(4) eform gen(prq_f or lb ub)
	restore

	preserve 
	keep if CC_3_mental == 1
	mkspline prqs = prq , nknots(7) cubic displayknots
	mat knots = r(knots)
	logit hosp prqs*
	xbrcspline prqs , matknots(knots) ///
	values(2 3 4 5 6 7 8) ///
	ref(4) eform gen(prq_f or lb ub)
	restore

	preserve 
	keep if CC_4_chestp ==1
	mkspline prqs = prq , nknots(7) cubic displayknots
	mat knots = r(knots)
	logit hosp prqs*
	xbrcspline prqs , matknots(knots) ///
	values(2 3 4 5 6 7 8) ///
	ref(4) eform gen(prq_f or lb ub)
	restore

	preserve 
	keep if CC_5_abdp ==1
	mkspline prqs = prq , nknots(7) cubic displayknots
	mat knots = r(knots)
	logit hosp prqs*
	xbrcspline prqs , matknots(knots) ///
	values(2 3 4 5 6 7 8) ///
	ref(4) eform gen(prq_f or lb ub)
	restore

	//主訴別のdiagnosisのtop3
	tabulate diagnosis if CC_1_fever==1, sort
	tabulate diagnosis if CC_2_shortbr==1, sort
	tabulate diagnosis if CC_3_mental==1, sort
	tabulate diagnosis if CC_4_chestp==1, sort
	tabulate diagnosis if CC_5_abdp==1, sort
	

	
