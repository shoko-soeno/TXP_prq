//Import vital sign data
	clear
	import delimited "/Users/shokosoeno/Downloads/tables_201804_201909/EHR_VITAL_NUMERIC.csv", encoding(utf8) clear
	
		/*We need to check outlier in vital signs*/

	save "/Users/shokosoeno/Downloads/TXP_pp/vital.dta", replace

//Import DPC data
	import excel "/Users/shokosoeno/Desktop/TXP_vital_20200106/20191231_ERresearch_adpc_original.xlsx", sheet("Sheet1") firstrow clear
		rename EncounterID encounter_id

	save "/Users/shokosoeno/Downloads/TXP_pp/dpc.dta", replace

//Import complaint
	import delimited "/Users/shokosoeno/Downloads/tables_201804_201909/EHR_COMPLAINT.csv",  encoding(utf8) varnames(1) clear
		
		///Use only the primary CC
		bysort encounter_id: gen n_by_id=_n
		keep if n_by_id==1
		///Sort by the frequency of CC
		bysort standardcc: gen n_by_cc=_N
		sort n_by_cc
		
		rename standardcc cc

	save "/Users/shokosoeno/Downloads/TXP_pp/complaint.dta", replace

//Import diagnosis
	import delimited "/Users/shokosoeno/Downloads/tables_201804_201909/EHR_DIAGNOSIS.csv", encoding(utf8) varnames(1) clear
		
		///Use only the primary CC
		bysort encounter_id: gen n_by_id=_n
		keep if n_by_id==1
		///Sort by the frequency of CC
		bysort icd10_1: gen n_by_cc=_N
		sort n_by_cc
		
		rename icd10_1 diagnosis

	save "/Users/shokosoeno/Downloads/TXP_pp/diagnosis.dta", replace

//Import encounter data
	import delimited "/Users/shokosoeno/Downloads/tables_201804_201909/EHR_ENCOUNTER.csv", encoding(utf8) varnames(1) clear
	save "/Users/shokosoeno/Downloads/TXP_pp/enc.dta", replace
	
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
	save "/Users/shokosoeno/Downloads/TXP_pp/cci.dta", replace
	
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

	save "/Users/shokosoeno/Downloads/TXP_pp/merged.dta", replace
	
///Data cleaning
	use "/Users/shokosoeno/Downloads/TXP_pp/merged.dta", clear
	
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
		drop if sbp < 0 | sbp > 300
		//drop if dbp < 0 | dbp > 300
		drop if sbp < dbp

		//drop if the dprimary diagoniss is I46 or S00-U99 ...0 observations deleted
		//drop if diagnosis = "I46"
		//gen dia_new = substr(diagnosis,1,1)
		//drop if dia_new == "S" |  dia_new == "T" | dia_new == "U"
		
		//Generalte PP index = PP/(1/2 * SBP)
		gen pp = sbp-dbp
		tab pp
		gen pp_index = pp/(1/2 * sbp)
		tab pp_index
		
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
	
	save "/Users/shokosoeno/Downloads/TXP_pp/analysis.dta", replace
	
///Data analysis
	use "/Users/shokosoeno/Downloads/TXP_pp/analysis.dta", clear
	
	//Characteristics of ED visits
	//Use Table 1 command (findit table1)
	
	//Change outliers to missing
	replace sbp=. if sbp<20 | sbp>300
	replace dbp=. if dbp<20 | dbp>300
	replace bt=. if bt<20 | bt>45
	
	//Output table1
	table1, vars(age contn \ sex cat \ sbp contn \ dbp contn \ pr contn \ /*
	*/ rr contn \ spo2 contn \ bt contn \ jtas cat \ route cat \ cci cat \/*
	*/ hosp cat \ icu cat \ death cat \ staylength conts \ pp_index contn) format(%9.0f) sav (/Users/shokosoeno/Downloads/TXP_pp/table1) 
	
	//pp_indexの分布
	hist pp_index
	centile (pp_index), centile (5 25 50 75 95)
	centile (pp_index), centile (10 20 30 40 50 60 70 80 90 100)
	tabulate diagnosis if pp_index < 0.58, sort
	tabulate disposition if pp_index < 0.58,
	tabulate diagnosis if pp_index < 0.67 & pp_index >= 0.58, sort
	tabulate disposition if pp_index < 0.67 & pp_index >= 0.58
	tabulate diagnosis if pp_index < 0.73 & pp_index >= 0.67, sort
	tabulate disposition if pp_index < 0.73 & pp_index >= 0.67
	tabulate diagnosis if pp_index < 0.78 & pp_index >= 0.73, sort
	tabulate disposition if pp_index < 0.78 & pp_index >= 0.73
	tabulate diagnosis if pp_index < 0.82 & pp_index >= 0.78, sort
	tabulate disposition if pp_index < 0.82 & pp_index >= 0.78
	tabulate diagnosis if pp_index < 0.87 & pp_index >= 0.82, sort
	tabulate disposition if pp_index < 0.87 & pp_index >= 0.82
	tabulate diagnosis if pp_index < 0.92 & pp_index >= 0.87, sort
	tabulate disposition if pp_index < 0.92 & pp_index >= 0.87
	tabulate diagnosis if pp_index < 0.98 & pp_index >= 0.92, sort
	tabulate disposition if pp_index < 0.98 & pp_index >= 0.92
	tabulate diagnosis if pp_index < 1.07 & pp_index >= 0.98, sort
	tabulate disposition if pp_index < 1.07 & pp_index >= 0.98
	tabulate diagnosis if pp_index < 1.91 & pp_index >= 1.07, sort
	tabulate disposition if pp_index < 1.91 & pp_index >= 1.07
	
	//Cubic spline for pp_index and hosp 
	preserve
	mkspline pp_indexs = pp_index , nknots(5) cubic displayknots
	mat knots = r(knots)
	logit hosp pp_indexs*
	
	xbrcspline pp_indexs , matknots(knots) ///
	values(0.5 0.7 0.8 0.9 1.1) ///
	ref() eform gen(pp_index_f or lb ub)
	
	twoway (line lb ub or pp_index_f, lp(- - l) lc(black black black) ) ///
                if inrange(pp_index_f, 0,2)  , ///
                                scheme(s1mono) legend(off) ///
                                ylabel(0(.5)1, angle(horiz) format(%2.1fc) ) ///
                                xlabel(0.6(.1)1.1) ///
                                ytitle("Odds ratio of hospitalization") ///
                                xtitle("pp_index")
	restore
	//////////////////////////////////////////////

	//Cubic spline for pp_index and death 
	preserve
	mkspline pp_indexs = pp_index , nknots(5) cubic displayknots
	mat knots = r(knots)
	logit death pp_indexs*
	
	xbrcspline pp_indexs , matknots(knots) ///
	values(0.5 0.7 0.8 0.9 1.1) ///
	ref() eform gen(pp_index_f or lb ub)
	
	twoway (line lb ub or pp_index_f, lp(- - l) lc(black black black) ) ///
                if inrange(pp_index_f, 0,2)  , ///
                                scheme(s1mono) legend(off) ///
                                ylabel(0(.5)1, angle(horiz) format(%2.1fc) ) ///
                                xlabel(0.6(.1)1.1) ///
                                ytitle("Odds ratio of hospitalization") ///
                                xtitle("pp_index")
	restore

	//LOWESS curve
	lowess hosp pp_index
	lowess death pp_index

	//twoway (lowess hosp bt2 if CC_1_fever==1) /*
	//*/ (lowess hosp bt2 if CC_2_shortbr==1) (lowess hosp bt2 if CC_3_mental==1) /*
	//*/ (lowess hosp bt2 if CC_4_chestp==1) (lowess hosp bt2 if CC_5_abdp==1) /*
	//*/ (lowess hosp bt2 if CC_6_ha==1) (lowess hosp bt2 if CC_7_nausea==1), /*
	//*/ legend(order(1 "発熱" 2 "呼吸困難" 3 "意識障害" 4 "胸痛" 5 "腹痛" 6 "頭痛" 7 "嘔気") col(4)) /*
    //*/                          ylabel(0(.5)1, angle(horiz) format(%2.1fc) ) ///
                                //xlabel(35(.5)40) ///
                                //ytitle("Risk of hospitalization") ///
                                //xtitle("Body temperature")
	
	//Cubic spline for each CC ///////////////////////////
	
	//Cubic spline for pp_index and hosp in patients with fever
	preserve 
	keep if CC_1_fever == 1
	mkspline pp_indexs = pp_index , nknots(7) cubic displayknots
	mat knots = r(knots)
	logit hosp pp_indexs*
	
	xbrcspline pp_indexs , matknots(knots) ///
	values(2 3 4 5 6 7 8 9 10) ///
	ref(4) eform gen(pp_index_f or lb ub)
	
	twoway (line lb ub or pp_index_f, lp(- - l) lc(black black black) ) ///
                if inrange(pp_index_f, 0,11)  , ///
                                scheme(s1mono) legend(off) ///
                                ylabel(0(.5)3, angle(horiz) format(%2.1fc) ) ///
                                xlabel(1(1)11) ///
                                ytitle("Odds ratio of hospitalization") ///
                                xtitle("pp_index")
	restore
	
	//LOWESS for each CC
	lowess hosp pp_index if CC_1_fever==1
	lowess death pp_index if CC_1_fever==1
		
	lowess hosp pp_index if CC_2_shortbr==1
	lowess death pp_index if CC_2_shortbr==1	
	
	lowess hosp pp_index if CC_3_mental==1
	lowess death pp_index if CC_3_mental==1
	
	lowess hosp pp_index if CC_4_chestp==1
	lowess death pp_index if CC_4_chestp==1
	
	lowess hosp pp_index if CC_5_abdp==1
	lowess death pp_index if CC_5_abdp==1
	

	
