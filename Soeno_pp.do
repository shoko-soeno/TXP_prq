//Import vital sign data
	clear
	import delimited "/Users/shokosoeno/Downloads/tables_201804_201909/EHR_VITAL_NUMERIC.csv", encoding(utf8) clear
	sort encounter_id vs_date vs_time
		bysort encounter_id: gen n_by_id=_n
		keep if n_by_id==1
		
	save "/Users/shokosoeno/Downloads/TXP_pp/vital.dta", replace

//Import DPC data
	import delimited /Users/shokosoeno/Desktop/20200331_ERresearch_adpc.csv, encoding(utf8) clear 
	//import excel "/Users/shokosoeno/Downloads/20200331_ERresearch_adpc_original.csv", sheet("Sheet1") firstrow clear
		rename encounterid encounter_id

	save "/Users/shokosoeno/Desktop/TXP/prq/dpc.dta", replace

//Import complaint
	import delimited "/Users/shokosoeno/Downloads/tables_201804_201909/EHR_COMPLAINT.csv",  encoding(utf8) varnames(1) clear
		
		///Use only the primary CC
		sort encounter_id item_id
		drop if encounter_id == ""
		reshape wide standardcc, i(encounter_id) j(item_id) 		 
		
	save "/Users/shokosoeno/Downloads/TXP_pp/complaint.dta", replace	

//Import diagnosis
	import delimited "/Users/shokosoeno/Downloads/tables_201804_201909/EHR_DIAGNOSIS.csv", encoding(utf8) varnames(1) clear
		
		///Use only the primary CC
		sort encounter_id item_id
		keep if item_id==1
		
	save "/Users/shokosoeno/Downloads/TXP_pp/diagnosis.dta", replace

//Import encounter data
	import delimited "/Users/shokosoeno/Downloads/tables_201804_201909/EHR_ENCOUNTER.csv", encoding(utf8) varnames(1) clear
	save "/Users/shokosoeno/Downloads/TXP_pp/enc.dta", replace
	
//Import history data
	import delimited "/Users/shokosoeno/Downloads/tables_201804_201909/EHR_MEDICAL_HISTORY_CCI.csv", encoding(utf8) varnames(1) clear
	//caliculate cci
	//bysort encounter_id : gen cci_each = cci1_mi + cci2_chd + cci3_pvd + cci4_cvd + cci5_dementia + cci6_pulmo + /*
	// */cci7_rheu + cci8_ulcer + cci9_mild_liver + cci10_dm_no_comp + cci11_dm_comp*2 + cci12_plegia*2 + cci13_rd*2 + cci14_malig*2 + /*
	// */cci15_mod_sev_liver*3 + cci16_meta*6 + cci17_aids*6
	//keep encounter_id cci_each
	//tab cci_each
	////bysort encounter_id : egen cci = sum(cci_each)
// 	gsort + encounter_id - cci_each
// 	duplicates drop encounter_id, force
// 	tab cci_each
	//collapse (sum) cci = cci_each, by(encounter_id)
	
	///橋本先生からシェアしていただいたcci計算のコード
	//同一患者が別の日に受診している場合、cciの各項目が受診の回数分増えてしまうので、その重複を考慮する必要がある。
	collapse (sum) cci1_mi - cci17_aids, by(encounter_id)
	replace cci1_mi=1 if cci1_mi>=1 & cci1_mi!=.
	replace cci2_chd=1 if cci2_chd>=1 & cci2_chd!=.
	replace cci3_pvd=1 if cci3_pvd>=1 & cci3_pvd!=.
	replace cci4_cvd=1 if cci4_cvd>=1 & cci4_cvd!=.
	replace cci5_dementia=1 if cci5_dementia>=1 & cci5_dementia!=.
	replace cci6_pulmo=1 if cci6_pulmo>=1 & cci6_pulmo!=.
	replace cci7_rheu=1 if cci7_rheu>=1 & cci7_rheu!=.
	replace cci8_ulcer=1 if cci8_ulcer>=1 & cci8_ulcer!=.
	replace cci9_mild_liver=1 if cci9_mild_liver>=1 & cci9_mild_liver!=.
	replace cci10_dm_no_comp=1 if cci10_dm_no_comp>=1 & cci10_dm_no_comp!=.
	replace cci11_dm_comp=1 if cci11_dm_comp>=1 & cci11_dm_comp!=.
	replace cci12_plegia=1 if cci12_plegia>=1 & cci12_plegia!=.
	replace cci13_rd=1 if cci13_rd>=1 & cci13_rd!=.
	replace cci14_malig=1 if cci14_malig>=1 & cci14_malig!=.
	replace cci15_mod_sev_liver=1 if cci15_mod_sev_liver>=1 & cci15_mod_sev_liver!=.
	replace cci16_meta=1 if cci16_meta>=1 & cci16_meta!=.
	replace cci17_aids=1 if cci17_aids>=1 & cci17_aids!=.
	gen cci= cci1_mi + cci2_chd + cci3_pvd + cci4_cvd + cci5_dementia + /*
	*/ cci6_pulmo + cci7_rheu + cci8_ulcer + cci9_mild_liver + cci10_dm_no_comp + /*
	*/ cci11_dm_comp*2 + cci12_plegia*2 + cci13_rd*2 + cci14_malig*2 + cci15_mod_sev_liver*3 + cci16_meta*6 + cci17_aids*6
		
	save "/Users/shokosoeno/Desktop/TXP/prq/cci.dta", replace

//Import procedure data	
	import delimited "/Users/shokosoeno/Downloads/tables_201804_201909/CLAIM_PROCEDURE.csv", encoding(UTF-8)clear

	gen mv_ref=0
		replace mv_ref=1 if procedure_code=="J044" | procedure_code=="J045" 
	gen nippv_ref=0
		replace nippv_ref=1 if procedure_code=="J026"
		
		bysort encounter_id: egen mv=sum(mv_ref)
		bysort encounter_id: gen n_by_id=_n
		keep if n_by_id==1
		replace mv=1 if mv>=1 & mv<.

		bysort encounter_id: egen nippv=sum(nippv_ref)
		bysort encounter_id: gen n_by_id_nippv=_n
		keep if n_by_id_nippv==1
		replace nippv=1 if nippv>=1 & nippv<.

		keep encounter_id mv nippv
	save "/Users/shokosoeno/Downloads/TXP_pp/mv.dta", replace

//merge vital data and dpc data
	use "/Users/shokosoeno/Downloads/TXP_pp/vital.dta", clear
		merge 1:1 encounter_id using "/Users/shokosoeno/Downloads/TXP_pp/enc.dta"
			drop _merge
		merge 1:1 encounter_id using "/Users/shokosoeno/Downloads/TXP_pp/complaint.dta"
			drop _merge
		merge 1:1 encounter_id using "/Users/shokosoeno/Downloads/TXP_pp/diagnosis.dta"
			drop _merge
		merge 1:1 encounter_id using "/Users/shokosoeno/Downloads/TXP_pp/mv.dta"

		save "/Users/shokosoeno/Downloads/TXP_pp/merged.dta", replace
	
///Data cleaning
	use "/Users/shokosoeno/Downloads/TXP_pp/merged.dta", clear
	
		//Age category
		gen agecat=1 if age>=18 & age<40
		replace agecat=2 if age>=40 & age<65
		replace agecat=3 if age>=65 & age<85
		replace agecat=4 if age>=85 & age<.

		//Top 10 CC category 
		//tab CC, sort
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

		replace mv=0 if mv==.
		replace nippv=0 if nippv==.
		
		//disposition
		gen hosp=0 
		replace hosp=1 if disposition=="入院" | disposition=="ICU" | disposition=="直接入院" 
		gen death=0
		replace death=1 if disposition=="死亡"
	
	save "/Users/shokosoeno/Downloads/TXP_pp/analysis.dta", replace
	
///Data analysis
	use "/Users/shokosoeno/Downloads/TXP_pp/analysis.dta", clear

	///Drop CPA
	drop if cpa_flag==1 | pr==0 | rr==0 | spo2==0 | dbp==0 | sbp==0

	//Drop children and missing age
	drop if age<18
	drop if age==.

	//drop if the primary diagoniss is I46 or S00-U99
	gen diag_1 = substr(icd10,1,1)
	gen diag_3 = substr(icd10,1,3)
	drop if diag_1 == "S" |  diag_1 == "T"| diag_1 == "V"| diag_1 == "W"| diag_1 == "X"| diag_1 == "Y"
	drop if diag_3 == "I46" //cardiac arrest
	drop if diag_1 == "Z"| diag_1 == "U"

	//Change outliers to missing
	replace sbp=. if sbp<20 | sbp>300
	replace dbp=. if dbp<20 | dbp>300 | sbp < dbp
	replace bt=. if bt<20 | bt>45

	//Generalte PP index = PP/(1/2 * SBP)
	gen pp = sbp-dbp
	tab pp
	gen pp_index = pp/(0.5 * sbp)
	tab pp_index

	//Characteristics of ED visits
	//Output table1
	table1, vars(age contn \ sex cat \ sbp contn \ dbp contn \ pr contn \ /*
	*/ rr contn \ spo2 contn \ bt contn \ jtas cat \ route cat \ /*
	*/ hosp cat \ mv cat \ nippv cat \ death cat \ pp_index contn) format(%9.0f) sav (/Users/shokosoeno/Downloads/TXP_pp/table1) 
	//staylength conts \ cci cat \
	
	//pp_indexの分布
	hist pp_index
	centile (pp_index), centile (5 25 50 75 95)
	centile (pp_index), centile (10 20 30 40 50 60 70 80 90 100)
	tabulate icd10 if pp_index < 0.58, sort
	tabulate disposition if pp_index < 0.58,
	tabulate icd10 if pp_index < 0.67 & pp_index >= 0.58, sort
	tabulate disposition if pp_index < 0.67 & pp_index >= 0.58
	tabulate icd10 if pp_index < 0.73 & pp_index >= 0.67, sort
	tabulate disposition if pp_index < 0.73 & pp_index >= 0.67
	tabulate icd10 if pp_index < 0.78 & pp_index >= 0.73, sort
	tabulate disposition if pp_index < 0.78 & pp_index >= 0.73
	tabulate icd10 if pp_index < 0.82 & pp_index >= 0.78, sort
	tabulate disposition if pp_index < 0.82 & pp_index >= 0.78
	tabulate icd10 if pp_index < 0.87 & pp_index >= 0.82, sort
	tabulate disposition if pp_index < 0.87 & pp_index >= 0.82
	tabulate icd10 if pp_index < 0.92 & pp_index >= 0.87, sort
	tabulate disposition if pp_index < 0.92 & pp_index >= 0.87
	tabulate icd10 if pp_index < 0.98 & pp_index >= 0.92, sort
	tabulate disposition if pp_index < 0.98 & pp_index >= 0.92
	tabulate icd10 if pp_index < 1.07 & pp_index >= 0.98, sort
	tabulate disposition if pp_index < 1.07 & pp_index >= 0.98
	tabulate icd10 if pp_index < 1.91 & pp_index >= 1.07, sort
	tabulate disposition if pp_index < 1.91 & pp_index >= 1.07

	////cvd
	gen cvd = 0
	replace cvd = 1 if diag_3 == "I20" | diag_3 == "I21" | diag_3 == "I24" | diag_3 == "I26" | diag_3 == "I50" | /*
			*/ diag_3 == "I71" | diag_3 == "I60" | diag_3 == "I61" | diag_3 == "I62" | diag_3 == "I63" | diag_3 == "I64"

	//sepsis
	gen sepsis=0
	replace sepsis = 1 if icd10 == "A390" | diag_3 == "A40" | diag_3 == "A41" | icd10 == "B956" | | diag_3 == "B96" | icd10 == "B962" |  /*
			*/ icd10 == "D695" |diag_3 == "G03" | icd10 == "G934" | icd10 == "G720" | diag_3 == "J18" | diag_3 == "J44" | diag_3 == "96" |/*
			*/ diag_3 == "K83" | diag_3 == "N39" | diag_3 == "N10"
	/////////////ICD-10 codes：D65のDIC、G93,1のAnoxic brain damage、K72.9のhelatic failure、N17のrenal failureは削除済
	

	//人工呼吸器
	gen mv_nippv =0
	replace mv_nippv =1 if mv==1 | nippv==1

	//LOWESS curve
	///referenceを0.8に設定、0.3以下は全て0.3、1.3以上は全て1.3としてfigureを作成
	replace pp_index =0.3 if pp_index<0.3
	replace pp_index =1.3 if pp_index>1.3

	lowess hosp pp_index
	lowess mv_nippv pp_index
	//胸痛で受診した患者群でのcvdとpp_indexの関連、発熱で受診した患者群でのinfectionとpp_indexの関連
	lowess cvd pp_index if CC_4_chestp==1
	lowess sepsis pp_index if CC_1_fever==1
	//主訴別のlowess
	twoway (lowess hosp pp_index if CC_1_fever==1) /*
	*/ (lowess hosp pp_index if CC_2_shortbr==1) (lowess hosp pp_index if CC_3_mental==1) /*
	*/ (lowess hosp pp_index if CC_4_chestp==1) (lowess hosp pp_index if CC_5_abdp==1) /*
	*/ (lowess hosp pp_index if CC_6_ha==1) (lowess hosp pp_index if CC_7_nausea==1), /*
	*/ legend(order(1 "発熱" 2 "呼吸困難" 3 "意識障害" 4 "胸痛" 5 "腹痛" 6 "頭痛" 7 "嘔気") col(4)) /*
    */                          ylabel(0(.5)1, angle(horiz) format(%2.1fc) ) ///
                                xlabel(0.3(.5)1.3) ///
                                ytitle("Risk of hospitalization") ///
                                xtitle("pp_index")
	
	//Cubic spline for pp_index and hosp
	preserve
	mkspline pp_indexs = pp_index , nknots(5) cubic displayknots
	mat knots = r(knots)
	logit hosp pp_indexs*
	
	xbrcspline pp_indexs , matknots(knots) ///
	values(0.3, 0.5, 0.8, 1.1, 1.3) ///
	ref(0.8) eform gen(pp_index_f or lb ub)
	
	twoway (line lb ub or pp_index_f, lp(- - l) lc(black black black) ) ///
                if inrange(pp_index_f, 0,2)  , ///
                                scheme(s1mono) legend(off) ///
                                ylabel(0(1)2, angle(horiz) format(%2.1fc) ) ///
                                xlabel(0(.5)2) ///
                                ytitle("Odds ratio of hospitalization") ///
                                xtitle("pp_index")
	restore

	//Cubic spline for pp_index and mechanical ventilaion/NIPPV in all patients
	preserve
	mkspline pp_indexs = pp_index , nknots(5) cubic displayknots
	mat knots = r(knots)
	logit mv_nippv pp_indexs*
	
	xbrcspline pp_indexs , matknots(knots) ///
	values(0.3, 0.5, 0.8, 1.1, 1.3) ///
	ref(0.8) eform gen(pp_index_f or lb ub)
	
	twoway (line lb ub or pp_index_f, lp(- - l) lc(black bshusolack black) ) ///
                if inrange(pp_index_f, 0,2)  , ///
                                scheme(s1mono) legend(off) ///
                                ylabel(0(1)2, angle(horiz) format(%2.1fc) ) ///
                                xlabel(0(.5)2) ///
                                ytitle("mv_nippv") ///
                                xtitle("pp_index")
	restore

	//Cubic spline for pp_index and cvd
	preserve
	keep if CC_4_chestp==1
	mkspline pp_indexs = pp_index , nknots(6) cubic displayknots
	mat knots = r(knots)
	logit cvd pp_indexs*
	
	xbrcspline pp_indexs , matknots(knots) ///
	values(0.3, 0.5, 0.8, 1.1, 1.3) ///
	ref(0.8) eform gen(pp_index_f or lb ub)
	
	twoway (line lb ub or pp_index_f, lp(- - l) lc(black bshusolack black) ) ///
                if inrange(pp_index_f, 0,2)  , ///
                                scheme(s1mono) legend(off) ///
                                ylabel(0(1)2, angle(horiz) format(%2.1fc) ) ///
                                xlabel(0(.5)2) ///
                                ytitle("cvd") ///
                                xtitle("pp_index")
	restore

	//Cubic spline for pp_index and sepsis
	preserve
	keep if CC_1_fever==1
	mkspline pp_indexs = pp_index , nknots(6) cubic displayknots
	mat knots = r(knots)
	logit sepsis pp_indexs*
	
	xbrcspline pp_indexs , matknots(knots) ///
	values(0.3, 0.5, 0.8, 1.1, 1.3) ///
	ref(0.8) eform gen(pp_index_f or lb ub)
	
	twoway (line lb ub or pp_index_f, lp(- - l) lc(black bshusolack black) ) ///
                if inrange(pp_index_f, 0,2)  , ///
                                scheme(s1mono) legend(off) ///
                                ylabel(0(1)2, angle(horiz) format(%2.1fc) ) ///
                                xlabel(0(.5)2) ///
                                ytitle("sepsis") ///
                                xtitle("pp_index")
	restore

	//多重補完後のデータ使用////////////////////////////////////////////////////////////////////////////////
	clear
	import excel "/Users/shokosoeno/Downloads/Soeno_rrindex_20200317/vital_postmi.xlsx", sheet("Sheet 1") firstrow
	save "/Users/shokosoeno/Downloads/TXP_pp/vital_postmi.dta", replace

	//merge vital data and dpc data
	use "/Users/shokosoeno/Downloads/TXP_pp/vital_postmi.dta", clear
		merge 1:1 encounter_id using "/Users/shokosoeno/Downloads/TXP_pp/enc.dta"
			drop _merge
		merge 1:1 encounter_id using "/Users/shokosoeno/Downloads/TXP_pp/complaint.dta"
			drop _merge
		merge 1:1 encounter_id using "/Users/shokosoeno/Downloads/TXP_pp/diagnosis.dta"
			drop _merge
		merge 1:1 encounter_id using "/Users/shokosoeno/Downloads/TXP_pp/mv.dta"

		save "/Users/shokosoeno/Downloads/TXP_pp/merged_postmi.dta", replace

	///Drop CPA
	drop if cpa_flag==1 | pr==0 | rr==0 | spo2==0 | dbp==0 | sbp==0

	//Drop children and missing age
	drop if age<18
	drop if age==.

	//drop if the primary diagoniss is I46 or S00-U99
	gen diag_1 = substr(icd10,1,1)
	gen diag_3 = substr(icd10,1,3)
	drop if diag_1 == "S" |  diag_1 == "T"| diag_1 == "V"| diag_1 == "W"| diag_1 == "X"| diag_1 == "Y"
	drop if diag_3 == "I46" //cardiac arrest
	drop if diag_1 == "Z"| diag_1 == "U"

	//Change outliers to missing
	replace sbp=. if sbp<20 | sbp>300
	replace dbp=. if dbp<20 | dbp>300 | sbp < dbp
	replace bt=. if bt<20 | bt>45

	//Generalte PP index = PP/(1/2 * SBP)
	//imputed dataは小数点が含まれるので、必ずroundしてから使う（例：gen rr2 = round(rr)）
	gen pp = sbp-dbp
	gen pp_index = round(pp/(0.5 * sbp))

	////cvd
	gen cvd = 0
	replace cvd = 1 if diag_3 == "I20" | diag_3 == "I21" | diag_3 == "I24" | diag_3 == "I26" | diag_3 == "I50" | /*
			*/ diag_3 == "I71" | diag_3 == "I60" | diag_3 == "I61" | diag_3 == "I62" | diag_3 == "I63" | diag_3 == "I64"

	//sepsis
	gen sepsis=0
	replace sepsis = 1 if diag_3 == "A39" | diag_3 == "A40" | diag_3 == "A41" | diag_3 == "B95" | diag_3 == "B96" | diag_3 == "D69" | /*
			*/ diag_3 == "D65" | diag_3 == "G03" | diag_3 == "G93" | diag_3 == "J18" | diag_3 == "J44" | diag_3 == "96" |/*
			*/ diag_3 == "K72" | diag_3 == "K83" | diag_3 == "N39" | diag_3 == "N10" | diag_3 == "N17"
	
	//主訴別のlowess
	twoway (lowess hosp pp_index if CC_1_fever==1) /*
	*/ (lowess hosp pp_index if CC_2_shortbr==1) (lowess hosp pp_index if CC_3_mental==1) /*
	*/ (lowess hosp pp_index if CC_4_chestp==1) (lowess hosp pp_index if CC_5_abdp==1) /*
	*/ (lowess hosp pp_index if CC_6_ha==1) (lowess hosp pp_index if CC_7_nausea==1), /*
	*/ legend(order(1 "発熱" 2 "呼吸困難" 3 "意識障害" 4 "胸痛" 5 "腹痛" 6 "頭痛" 7 "嘔気") col(4)) /*
    */                          ylabel(0(.5)1, angle(horiz) format(%2.1fc) ) ///
                                xlabel(0(.5)2) ///
                                ytitle("Risk of hospitalization") ///
                                xtitle("pp_index")
	
	//Cubic spline for pp_index and hosp
	preserve
	mkspline pp_indexs = pp_index , nknots(6) cubic displayknots
	mat knots = r(knots)
	logit hosp pp_indexs*
	
	xbrcspline pp_indexs , matknots(knots) ///
	values(0 0.4 0.8 1.2 1.6 2) ///
	ref() eform gen(pp_index_f or lb ub)
	
	twoway (line lb ub or pp_index_f, lp(- - l) lc(black black black) ) ///
                if inrange(pp_index_f, 0,2)  , ///
                                scheme(s1mono) legend(off) ///
                                ylabel(0(1)2, angle(horiz) format(%2.1fc) ) ///
                                xlabel(0(.5)2) ///
                                ytitle("Odds ratio of hospitalization") ///
                                xtitle("pp_index")
	restore

	//Cubic spline for pp_index and mechanical ventilaion/NIPPV in all patients
	preserve
	gen mv_nippv =0
	replace mv_nippv =1 if mv==1 | nippv==1

	mkspline pp_indexs = pp_index , nknots(6) cubic displayknots
	mat knots = r(knots)
	logit mv_nippv pp_indexs*
	
	xbrcspline pp_indexs , matknots(knots) ///
	values(0 0.4 0.8 1.2 1.6 2) ///
	ref() eform gen(pp_index_f or lb ub)
	
	twoway (line lb ub or pp_index_f, lp(- - l) lc(black bshusolack black) ) ///
                if inrange(pp_index_f, 0,2)  , ///
                                scheme(s1mono) legend(off) ///
                                ylabel(0(1)2, angle(horiz) format(%2.1fc) ) ///
                                xlabel(0(.5)2) ///
                                ytitle("mv_nippv") ///
                                xtitle("pp_index")
	restore

	//LOWESS curve
	lowess hosp pp_index
	lowess death pp_index
	//胸痛で受診した患者群でのcvdとpp_indexの関連、発熱で受診した患者群でのinfectionとpp_indexの関連
	lowess cvd pp_index if CC_4_chestp==1
	lowess infection pp_index if CC_1_fever==1

	//Cubic spline for pp_index and cvd
	preserve
	//keep if CC_4_chestp==1
	mkspline pp_indexs = pp_index , nknots(6) cubic displayknots
	mat knots = r(knots)
	logit cvd pp_indexs*
	
	xbrcspline pp_indexs , matknots(knots) ///
	values(0 0.4 0.8 1.2 1.6 2) ///
	ref() eform gen(pp_index_f or lb ub)
	
	twoway (line lb ub or pp_index_f, lp(- - l) lc(black bshusolack black) ) ///
                if inrange(pp_index_f, 0,2)  , ///
                                scheme(s1mono) legend(off) ///
                                ylabel(0(1)2, angle(horiz) format(%2.1fc) ) ///
                                xlabel(0(.5)2) ///
                                ytitle("cvd") ///
                                xtitle("pp_index")
	restore

	//Cubic spline for pp_index and sepsis
	preserve
	//keep if CC_1_fever==1
	mkspline pp_indexs = pp_index , nknots(6) cubic displayknots
	mat knots = r(knots)
	logit sepsis pp_indexs*
	
	xbrcspline pp_indexs , matknots(knots) ///
	values(0 0.4 0.8 1.2 1.6 2) ///
	ref() eform gen(pp_index_f or lb ub)
	
	twoway (line lb ub or pp_index_f, lp(- - l) lc(black bshusolack black) ) ///
                if inrange(pp_index_f, 0,2)  , ///
                                scheme(s1mono) legend(off) ///
                                ylabel(0(1)2, angle(horiz) format(%2.1fc) ) ///
                                xlabel(0(.5)2) ///
                                ytitle("sepsis") ///
                                xtitle("pp_index")
	restore


