// //Import vital sign data
// 	clear
// 	//2017/4〜2020/3/31までのデータ↓
// 	import delimited "/Users/shokosoeno/Downloads/tables_201804_201909/EHR_VITAL_NUMERIC.csv", encoding(utf8) 
	
// 	//study period: April, 2018 through September, 2019
// // 	gen subdate = substr(vs_time,1,10)
// // 	gen bdate = date(subdate, "YMD")
// // 	format bdate %td
// // 	gen before = (bdate<date("2018Mar31","YMD"))
// // 	gen after = (bdate>date("2019Oct01","YMD"))
// // 	drop if before == 1 | after == 1
	
// 	//keep if vs_timing == "病着時"
	
// // 	gen jtas_n =.
// // 	replace jtas_n = 1 if jtas == "Ⅰ"
// // 	replace jtas_n = 2 if jtas == "Ⅱ"
// // 	replace jtas_n = 3 if jtas == "Ⅲ"
// // 	replace jtas_n = 4 if jtas == "Ⅳ"
// // 	replace jtas_n = 5 if jtas == "Ⅴ"
	
// 	sort encounter_id vs_time
// 		bysort encounter_id: gen n_by_id=_n
// 		keep if n_by_id==1
	
// 	save "/Users/shokosoeno/Desktop/TXP/prq/vital.dta", replace

// //Import DPC data
// 	import delimited /Users/shokosoeno/Desktop/TXP_20200331/20200331_ERresearch_adpc_original.csv, encoding(utf8) clear 
// 	//import excel "/Users/shokosoeno/Downloads/20200331_ERresearch_adpc_original.csv", sheet("Sheet1") firstrow clear
// 		rename encounterid encounter_id

// 	save "/Users/shokosoeno/Desktop/TXP/prq/dpc.dta", replace

// //Import complaint
// 	import delimited "/Users/shokosoeno/Downloads/tables_201804_201909/EHR_COMPLAINT.csv",  encoding(utf8) varnames(1) clear
		
// 		///Use only the primary CC
// 		sort encounter_id item_id
// 		drop if encounter_id == ""
// 		reshape wide standardcc, i(encounter_id) j(item_id) 		 
		
// 	save "/Users/shokosoeno/Desktop/TXP/prq/complaint.dta", replace

// //Import diagnosis
// 	import delimited "/Users/shokosoeno/Downloads/tables_201804_201909/EHR_DIAGNOSIS.csv", encoding(utf8) varnames(1) clear
		
// 		///Use only the primary CC
// 		sort encounter_id item_id
// 		keep if item_id==1
		
// 	save "/Users/shokosoeno/Desktop/TXP/prq/diagnosis.dta", replace

// //Import encounter data
// 	import delimited "/Users/shokosoeno/Downloads/tables_201804_201909/EHR_ENCOUNTER.csv", encoding(utf8) varnames(1) clear
// 	save "/Users/shokosoeno/Desktop/TXP/prq/enc.dta", replace
	
// //Import history data
// 	import delimited "/Users/shokosoeno/Downloads/tables_201804_201909/EHR_MEDICAL_HISTORY_CCI.csv", encoding(utf8) varnames(1) clear
	
// 	///橋本先生からシェアしていただいたcci計算のコード
// 	//同一患者が別の日に受診している場合、cciの各項目が受診の回数分増えてしまうので、その重複を考慮する必要がある。
// 	collapse (sum) cci1_mi - cci17_aids, by(encounter_id)
// 	replace cci1_mi=1 if cci1_mi>=1 & cci1_mi!=.
// 	replace cci2_chd=1 if cci2_chd>=1 & cci2_chd!=.
// 	replace cci3_pvd=1 if cci3_pvd>=1 & cci3_pvd!=.
// 	replace cci4_cvd=1 if cci4_cvd>=1 & cci4_cvd!=.
// 	replace cci5_dementia=1 if cci5_dementia>=1 & cci5_dementia!=.
// 	replace cci6_pulmo=1 if cci6_pulmo>=1 & cci6_pulmo!=.
// 	replace cci7_rheu=1 if cci7_rheu>=1 & cci7_rheu!=.
// 	replace cci8_ulcer=1 if cci8_ulcer>=1 & cci8_ulcer!=.
// 	replace cci9_mild_liver=1 if cci9_mild_liver>=1 & cci9_mild_liver!=.
// 	replace cci10_dm_no_comp=1 if cci10_dm_no_comp>=1 & cci10_dm_no_comp!=.
// 	replace cci11_dm_comp=1 if cci11_dm_comp>=1 & cci11_dm_comp!=.
// 	replace cci12_plegia=1 if cci12_plegia>=1 & cci12_plegia!=.
// 	replace cci13_rd=1 if cci13_rd>=1 & cci13_rd!=.
// 	replace cci14_malig=1 if cci14_malig>=1 & cci14_malig!=.
// 	replace cci15_mod_sev_liver=1 if cci15_mod_sev_liver>=1 & cci15_mod_sev_liver!=.
// 	replace cci16_meta=1 if cci16_meta>=1 & cci16_meta!=.
// 	replace cci17_aids=1 if cci17_aids>=1 & cci17_aids!=.
// 	gen cci= cci1_mi + cci2_chd + cci3_pvd + cci4_cvd + cci5_dementia + /*
// 	*/ cci6_pulmo + cci7_rheu + cci8_ulcer + cci9_mild_liver + cci10_dm_no_comp + /*
// 	*/ cci11_dm_comp*2 + cci12_plegia*2 + cci13_rd*2 + cci14_malig*2 + cci15_mod_sev_liver*3 + cci16_meta*6 + cci17_aids*6
		
// 	save "/Users/shokosoeno/Desktop/TXP/prq/cci.dta", replace
	
// //import procedure
// 	import delimited "/Users/shokosoeno/Downloads/tables_201804_201909/CLAIM_PROCEDURE.csv", encoding(UTF-8)clear
// 	gen mv_ref=0
// 		replace mv_ref=1 if procedure_code=="J044" | procedure_code=="J045" 
// 	gen nippv=0
// 		replace nippv=1 if procedure_code=="J026"
// 		// NIPPV：J026
		
// 		bysort encounter_id: egen mv=sum(mv_ref)
// 		bysort encounter_id: gen n_by_id=_n
// 		keep if n_by_id==1
// 		replace mv=1 if mv>=1 & mv<.
// 		keep encounter_id mv nippv
// 	save "/Users/shokosoeno/Desktop/TXP/prq/mv.dta", replace

// //merge vital data and dpc data
// 	use "/Users/shokosoeno/Desktop/TXP/prq/vital.dta", clear
// 		merge 1:1 encounter_id using "/Users/shokosoeno/Desktop/TXP/prq/enc.dta"
// 			drop _merge
// 		merge 1:1 encounter_id using "/Users/shokosoeno/Desktop/TXP/prq/dpc.dta"
// 			drop _merge
// 		merge 1:1 encounter_id using "/Users/shokosoeno/Desktop/TXP/prq/complaint.dta"
// 			drop _merge
// 		merge 1:1 encounter_id using "/Users/shokosoeno/Desktop/TXP/prq/diagnosis.dta"
// 			drop _merge
// 		merge 1:1 encounter_id using "/Users/shokosoeno/Desktop/TXP/prq/cci.dta"
// 			drop _merge
// 		merge 1:1 encounter_id using "/Users/shokosoeno/Desktop/TXP/prq/mv.dta"

// 	save "/Users/shokosoeno/Desktop/TXP/prq/merged.dta", replace
	
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
		
		//stringからnumericに
		destring staylength, replace force
		
		///Drop cardiac arrest (来院時心肺停止)
		drop if cpa_flag==1
		drop if pr==0 | rr==0 | spo2==0
		
		//replace outliers to missings
		replace pr=. if pr<10 | pr>300
		replace rr=. if rr<3 | rr>60
		replace spo2=. if spo2<10 | spo2>100
		replace sbp=. if sbp<20 | sbp>300
		replace dbp=. if dbp<20 | dbp>300
		replace bt=. if bt<20 | bt>45

		//欠測値の割合
		//findit tabmiss
		tabmiss sbp dbp pr rr spo2 bt
		
		//Age category
// 		gen agecat=1 if age>=18 & age<40
// 		replace agecat=2 if age>=40 & age<65
// 		replace agecat=3 if age>=65 & age<85
// 		replace agecat=4 if age>=85 & age<.

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
		//gen CC_6_ha=0
		//replace CC_6_ha=1 if standardcc1=="頭痛" 
		//gen CC_7_nausea=0
		//replace CC_7_nausea=1 if standardcc1=="嘔吐・嘔気"
		
		//Disposition
		gen hosp=0 
		replace hosp=1 if disposition=="入院" | disposition=="ICU" | disposition=="直接入院" 

		//gen icu=0
		//replace icu=1 if disposition=="ICU" 
		
		gen death=0
		replace death=1 if tenki=="死亡" | disposition=="死亡"

// 		table1, vars(age contn \ sex cat \ sbp contn \ dbp contn \ pr contn \ /*
// 	*/ rr contn \ spo2 contn \ bt contn \ jtas cat \ route cat \ cci cat \/*
// 	*/ hosp cat \ mv cat \ nippv cat \ death cat \ staylength conts \ /*
// 	*/ CC_1_fever cat\ CC_2_shortbr cat\CC_3_mental cat\ CC_4_chestp cat\ CC_5_abdp cat) format(%9.0f) 
	//save (/Users/shokosoeno/Desktop/TXP/prq/table1) 
	
	tabstat age sbp dbp pr rr spo2 bt, stat(p25 p50 p75)
	tab jtas
	tab route
	tab cci
    tab mv 
    tab nippv 
	tab death 
	tabstat staylength, stat(p25 p50 p75)
	tab CC_1_fever
	tab CC_2_shortbr
	tab CC_3_mental
	tab CC_4_chestp
	tab CC_5_abdp
	
	save "/Users/shokosoeno/Desktop/TXP/prq/analysis.dta", replace
	
///Data analysis(case complete)
	use "/Users/shokosoeno/Desktop/TXP/prq/analysis.dta", clear

	gen missed =0
	replace missed =1 if rr ==.
	
	tabstat age sbp dbp pr rr spo2 bt, stat(p25 p50 p75) by (missed)
	tab jtas missed
	tab route
	tab cci
    tab mv
    tab nippv
	tab death
destring staylength, replace force
	tabstat staylength, stat(p25 p50 p75)
	tab CC_1_fever missed, col
	tab CC_2_shortbr missed, col
	tab CC_3_mental missed, col
	tab CC_4_chestp missed, col
	tab CC_5_abdp missed, col
	
	//case completeにするため欠測をdrop
	drop if rr==.
	
	//logistic
	gen rrcat=0 if rr>=16 & rr<20
	replace rrcat=1 if rr<12
	replace rrcat=2 if rr>=12 & rr<16
	replace rrcat=3 if rr>=20 & rr<24
	replace rrcat=4 if rr>=24 & rr<28
	replace rrcat=5 if rr>=28
	replace rrcat=6 if rr==.
	logistic hosp i.rrcat, or

	//Characteristics of ED visits
	//Use Table 1 command (findit table1)
	hist rr, frequency bin(60)

	//Cubic spline regression
	//install xbrcspline 
	
	//Cubic spline for rr and hosp 
	//hospとRR
	preserve
	mkspline sp_hosp_rr = rr, cubic displayknots
	logistic hosp sp_hosp_rr*
	xblc sp_hosp_rr*, covname(rr) at(8 12 16 20 24 28 32) reference(16) eform
	restore
	
	//deathとRR
	preserve
	mkspline sp_death_rr = rr, cubic displayknots
	logistic death sp_death_rr*
	xblc sp_death_rr*, covname(rr) at(8 12 16 20 24 28 32) reference(16) eform
	restore

	lowess death rr
	//mv＋NIPPVとRR（nippvは0なので実質mvのみ）
	preserve
	mkspline sp_mv_rr = mv, cubic displayknots
	logistic mv sp_mv_rr*
	xblc sp_mv_rr*, covname(rr) at(16 20 24 28 32) reference(16) eform
	restore

	//Cubic spline for rr and hosp by CC
	preserve 
	//keep if CC_1_fever == 1
	//keep if CC_2_shortbr==1
	//keep if CC_3_mental == 1
	//keep if CC_4_chestp ==1
	keep if CC_5_abdp ==1
	mkspline sp_hosp_rr = rr, cubic displayknots
	logistic hosp sp_hosp_rr*
	xblc sp_hosp_rr*, covname(rr) at(12 16 20 24 28 32) reference(16) eform
	restore
	
		//RRのグラフは8未満は全て8、30（もしくは35）以上は全て30、REFIは15以下を全て15にしてFigureの範囲を変更
		replace rr = 8 if rr < 8
		replace rr = 35 if rr > 35
		
		lowess death rr

	//LOWESS curve for hospitalization or mv
	twoway (lowess hosp rr, lpattern(solid)) (lowess mv rr), /*
	*/ legend(order(1 "hospitalization" 2 "mechanical ventilation") col(2)) /*
    */                          ylabel(0(.5)1, angle(horiz) format(%2.1fc) ) ///
                                xlabel(8(4)32) ///
                                ytitle("Risk of the clinical outcomes") ///
                                xtitle("Respiratory Rate")

	//Lowess curve by CC
	//RR and hosp
	twoway (lowess hosp rr if CC_1_fever==1) /*
	*/ (lowess hosp rr if CC_2_shortbr==1) (lowess hosp rr if CC_3_mental==1) /*
	*/ (lowess hosp rr if CC_4_chestp==1) (lowess hosp rr if CC_5_abdp==1), /*
	*/ legend(order(1 "Fever" 2 "Shortness of breath" 3 "Altered mental status" 4 "Chest pain" 5 "Abdominal pain") col(2)) /*
    */                          ylabel(0(.5)1, angle(horiz) format(%2.1fc) ) ///
                                xlabel(8(4)32) ///
                                ytitle("Risk of hospitalization") ///
                                xtitle("Respiratory Rate")
 
	//RR and mv
	twoway (lowess mv rr if CC_1_fever==1) /*
	*/ (lowess mv rr if CC_2_shortbr==1) (lowess mv rr if CC_3_mental==1) /*
	*/ (lowess mv rr if CC_4_chestp==1) (lowess mv rr if CC_5_abdp==1), /*
	*/ legend(order(1 "Fever" 2 "Shortness of breath" 3 "Altered mental status" 4 "Chest pain" 5 "Abdominal pain") col(2)) /*
    */                          ylabel(0(.5)1, angle(horiz) format(%2.1fc) ) ///
                                xlabel(8(4)32) ///
                                ytitle("Risk of mechanical ventilation") ///
                                xtitle("Respiratory Rate")


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
	tabulate icd10 if CC_5_abdp==1, sort
	restore
	


	//multiple imputation後の解析///////////////////////////////////////////////////////////////////////////////
	clear
	//import excel "/Users/shokosoeno/Downloads/Soeno_rrindex_20200317/vital_postmi.xlsx", sheet("Sheet 1") firstrow
	import excel "/Users/shokosoeno/Downloads/vital_postmi.xlsx", sheet("Sheet 1") firstrow

	//Disposition
		gen hosp=0 
		replace hosp=1 if disposition=="入院" | disposition=="ICU" | disposition=="直接入院" 

		gen death=0
		replace death=1 if tenki=="死亡" | disposition=="死亡"

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
		
    //RRのグラフは8未満は全て8、30（もしくは35）以上は全て30、REFIは15以下を全て15にしてFigureの範囲を変更
	gen rr2 = round(rr) //imputed dataは小数点が含まれるため。
	replace rr2=8 if rr<8
	replace rr2=32 if rr>32 & rr<.
	replace rr2=round(rr2)

	table1, vars(age contn \ sex cat \ sbp contn \ dbp contn \ pr contn \ /*
	*/ rr contn \ spo2 contn \ bt contn \ jtas cat \ route cat \ cci cat \/*
	*/ hosp cat \ mv cat \ nippv cat \ /*
	*/ CC_1_fever cat\ CC_2_shortbr cat\CC_3_mental cat\ CC_4_chestp cat\ CC_5_abdp cat) format(%9.0f)
	

	//LOWESS curve for hospitalization or mv
	twoway (lowess hosp rr2) (lowess mv rr2), /*
	*/ legend(order(1 "Hospitalization" 2 "Mechanical ventilation") col(3)) /*
    */                          ylabel(0(.5)1, angle(horiz) format(%2.1fc) )
                                xlabel(8(4)32)
                                ytitle("Risk of the clinical outcomes")
                                xtitle("Respiratory Rate")

	//Lowess curve by CC
	//RR
	twoway (lowess hosp rr2 if CC_1_fever==1) /*
	*/ (lowess hosp rr2 if CC_2_shortbr==1) (lowess hosp rr2 if CC_3_mental==1) /*
	*/ (lowess hosp rr2 if CC_4_chestp==1) (lowess hosp rr2 if CC_5_abdp==1),  /*
	*/ legend(order(1 "Fever" 2 "Shortness of breath" 3 "Altered mental status" 4 "Chest pain" 5 "Abdominal pain") col(2)) /*
    */                          ylabel(0(.5)1, angle(horiz) format(%2.1fc) ) ///
                                xlabel(8(4)32) ///
                                ytitle("Risk of hospitalization") ///
                                xtitle("Respiratory rate")

	//Cubic spline regression
	//install xbrcspline 
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
	keep if CC_5_abdp ==1
	mkspline sp_hosp_rr = rr2, cubic displayknots
	logistic hosp sp_hosp_rr*
	xblc sp_hosp_rr*, covname(rr2) at(12 16 20 24 32) reference(16) eform
	restore

	//ROI = spo2/fio2/rr
	gen fio2 =.
	replace fio2 = 21 if
	replace fio2 = 21 if
	replace fio2 = 21 if
	
	gen roi = spo2/fio2/rr
