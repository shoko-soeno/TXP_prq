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
	gen nippv=0
		replace nippv=1 if procedure_code=="J026"
		// NIPPV：J026
		
		bysort encounter_id: egen mv=sum(mv_ref)
		bysort encounter_id: gen n_by_id=_n
		keep if n_by_id==1
		replace mv=1 if mv>=1 & mv<.
		keep encounter_id mv nippv
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
		
		describe
		//Drop children and missing age
		drop if age==.
		drop if age<18

		//drop if the primary diagoniss is I46 or S00-U99 (non-medical reasons)
		gen diag_1 = substr(icd10,1,1)
		gen diag_3 = substr(icd10,1,3)
		drop if diag_1 == "S" |  diag_1 == "T"| diag_1 == "V"| diag_1 == "W"| diag_1 == "X"| diag_1 == "Y"
		drop if diag_3 == "I46"  //cardiac arrest 
		drop if diag_1 == "Z"| diag_1 == "U"
		
		///Drop cardiac arrest (おそらくEDで死亡)
		drop if cpa_flag==1 | pr==0 | rr==0 | spo2==0
		
		//replace outliers to missings
		replace pr=. if pr<10 | pr>300
		replace rr=. if rr<3 | rr>60
		replace spo2=. if spo2<10 | spo2>100
		replace sbp=. if sbp<20 | sbp>300
		replace dbp=. if dbp<20 | dbp>300
		replace bt=. if bt<20 | bt>45

		//欠測値の割合
		//findit tabmiss
		tabmiss rr
		
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
		//gen CC_7_nausea=0
		//replace CC_7_nausea=1 if standardcc1=="嘔吐・嘔気"
		
		//Disposition
		gen hosp=0 
		replace hosp=1 if disposition=="入院" | disposition=="ICU" | disposition=="直接入院" 

		//gen icu=0
		//replace icu=1 if disposition=="ICU" 
		
		gen death=0
		replace death=1 if tenki=="死亡" | disposition=="死亡"

		table1, vars(age contn \ sex cat \ sbp contn \ dbp contn \ pr contn \ /*
	*/ rr contn \ spo2 contn \ bt contn \ jtas cat \ route cat \ cci cat \/*
	*/ hosp cat \ mv cat \ nippv cat \ death cat \ staylength conts \ /*
	*/ CC_1_fever cat\ CC_2_shortbr cat\CC_3_mental cat\ CC_4_chestp cat\ CC_5_abdp cat\ CC_6_ha cat) format(%9.0f) sav (/Users/shokosoeno/Desktop/TXP/prq/table1) 
	

	
	save "/Users/shokosoeno/Desktop/TXP/prq/analysis.dta", replace
	
///Data analysis
	use "/Users/shokosoeno/Desktop/TXP/prq/analysis.dta", clear
	
	//case completeにするため欠測をdrop
	drop if rr==.

	//Characteristics of ED visits
	//Use Table 1 command (findit table1)
	hist rr
	
		//RRのグラフは8未満は全て8、30（もしくは35）以上は全て30、REFIは15以下を全て15にしてFigureの範囲を変更
		replace rr = 8 if rr < 8
		replace rr = 35 if rr > 35

	//LOWESS curve for hospitalization or death
	twoway (lowess hosp rr, lpattern(solid)) (lowess mv rr, lpattern(dash)) (lowess death rr,lpattern(shortdash)), /*
	*/ legend(order(1 "hospitalization" 2 "mechanical ventilation" 3 "death") col(3)) /*
    */                          ylabel(0(.5)1, angle(horiz) format(%2.1fc) ) ///
                                xlabel(8(4)32) ///
                                ytitle("Risk of clinical outcome") ///
                                xtitle("Respiratory Rate")

	//Lowess curve by CC
	//RR
	twoway (lowess hosp rr if CC_1_fever==1) /*
	*/ (lowess hosp rr if CC_2_shortbr==1) (lowess hosp rr if CC_3_mental==1, lpattern(longdash)) /*
	*/ (lowess hosp rr if CC_4_chestp==1, lpattern(dash_dot)) (lowess hosp rr if CC_5_abdp==1,lpattern(shortdash))(lowess hosp rr if CC_6_ha==1), /*
	*/ legend(order(1 "Fever" 2 "Shortness of breath" 3 "Altered mental status" 4 "Chest pain" 5 "Abdominal pain" 6 "Headache") col(2)) /*
    */                          ylabel(0(.5)1, angle(horiz) format(%2.1fc) ) ///
                                xlabel(8(4)32) ///
                                ytitle("Risk of hospitalization") ///
                                xtitle("Respiratory Rate")

	//Cubic spline regression
	//install xbrcspline 
	
	//Cubic spline for rr and hosp 
	//hospとRR
	preserve
	mkspline sp_hosp_rr = rr, cubic displayknots
	logistic hosp sp_hosp_rr*
	xblc sp_hosp_rr*, covname(rr) at(8 12 16 20 24 28 32) reference(16) eform
	restore

	//mv＋NIPPVとRR（nippvは0なので実質mvのみ）
	preserve
	mkspline sp_mn_rr = mv, cubic displayknots
	logistic mv sp_mn_rr*
	xblc sp_mv_rr*, covname(rr) at(12 16 20 24 28 32) reference(16) eform
	restore

	//Cubic spline for rr and hosp by CC
	preserve 
	//keep if CC_1_fever == 1
	//keep if CC_2_shortbr==1
	//keep if CC_3_mental == 1
	//keep if CC_4_chestp ==1
	//keep if CC_5_abdp ==1
	keep if CC_6_ha ==1
	mkspline sp_hosp_rr = rr, cubic displayknots
	logistic hosp sp_hosp_rr*
	xblc sp_hosp_rr*, covname(rr) at(16 20 24 32) reference(16) eform
	restore

	//RRを16未満と、24以上で分け、主訴別のdiagnosisのtop5を出す
	gen rr_cat=.
	replace rr_cat=0 if rr<16
	replace rr_cat=1 if rr>=16 & rr<24
	replace rr_cat=2 if rr>=24
	
	preserve
	//keep if rr_cat==0
	//tabulate icd10 if CC_1_fever==1, sort
	//tabulate icd10 if CC_2_shortbr==1, sort
	//tabulate icd10 if CC_3_mental==1, sort
	//tabulate icd10 if CC_4_chestp==1, sort
	//tabulate icd10 if CC_5_abdp==1, sort
	tabulate icd10 if CC_6_ha==1, sort
	restore
	
	//multiple imputation後の解析
	clear
	import excel "/Users/shokosoeno/Downloads/Soeno_rrindex_20200317/vital_postmi.xlsx", sheet("Sheet 1") firstrow
		
    //RRのグラフは8未満は全て8、30（もしくは35）以上は全て30、REFIは15以下を全て15にしてFigureの範囲を変更
	replace rr = 8 if rr < 8
	replace rr = 35 if rr > 35

	//LOWESS curve for hospitalization or death
	twoway (lowess hosp rr, lpattern(solid)) (lowess mv rr, lpattern(dash)) (lowess death rr,lpattern(shortdash)), /*
	*/ legend(order(1 "hospitalization" 2 "mechanical ventilation" 3 "death") col(3)) /*
    */                          ylabel(0(.5)1, angle(horiz) format(%2.1fc) )
                                xlabel(8(4)32)
                                ytitle("Risk of clinical outcome")
                                xtitle("Respiratory Rate")

	//Lowess curve by CC
	//RR
	twoway (lowess hosp rr if CC_1_fever==1) /*
	*/ (lowess hosp rr if CC_2_shortbr==1) (lowess hosp rr if CC_3_mental==1,lpattern(longdash)) /*
	*/ (lowess hosp rr if CC_4_chestp==1,lpattern(dash_dot)) (lowess hosp rr if CC_5_abdp==1,lpattern(shortdash)) (lowess hosp rr if CC_6_ha==1),  /*
	*/ legend(order(1 "Fever" 2 "Shortness of breath" 3 "Altered mental status" 4 "Chest pain" 5 "Abdominal pain" 6 "Headache") col(2)) /*
    */                          ylabel(0(.5)1, angle(horiz) format(%2.1fc) ) ///
                                xlabel(8(4)32) ///
                                ytitle("Risk of hospitalization") ///
                                xtitle("Respiratory Rate")

	//Cubic spline regression
	//install xbrcspline 
	gen rr2 = round(rr) //imputed dataは小数点が含まれるため。
	
	//findit xblc
	
	//hospとRR
	preserve
	mkspline sp_hosp_rr = rr2, cubic displayknots
	logistic hosp sp_hosp_rr*
	xblc sp_hosp_rr*, covname(rr) at(8 12 16 20 24 28 32) reference(16) eform
	restore

	//mv＋NIPPVとRR
	gen mn = 0
	replace mn = 1 if mv ==1 | nippv ==1
	
	preserve
	mkspline sp_mn_rr = rr2, cubic displayknots
	logistic mn sp_mn_rr*
	xblc sp_mn_rr*, covname(rr) at(8 12 16 20 24 28 32) reference(16) eform
	restore

	//Cubic spline for rr and hosp by CC
	//value 8 of rr not observedというエラーメッセージが出るため8は削除
	preserve 
	//keep if CC_1_fever == 1
	//keep if CC_2_shortbr==1
	//keep if CC_3_mental == 1
	//keep if CC_4_chestp ==1
	//keep if CC_5_abdp ==1
	keep if CC_6_ha ==1
	mkspline sp_hosp_rr = rr2, cubic displayknots
	logistic hosp sp_hosp_rr*
	xblc sp_hosp_rr*, covname(rr2) at(16 20 24 32) reference(16) eform
	restore

	//ROI = spo2/fio2/rr
	gen fio2 =.
	replace fio2 = 21 if
	replace fio2 = 21 if
	replace fio2 = 21 if
	
	gen roi = spo2/fio2/rr
