clear
	import delimited /Users/shokosoeno/Downloads/EHR_MEDICAL_HISTORY.csv, encoding(utf8) clear
	gen year = substr(date,1,4)
	drop if year == "2016" | year == "2017"
	gen yearMonth = substr(date,1,7)
	drop if yearMonth == "2018-01" | yearMonth == "2018-02" | yearMonth == "2018-03"
	
	//HT, dyslipidemia, heartfailure, copd, stroke, myocardialInfarctionのダミー変数を作成する
	gen mi =.
	replace mi = 1 if text_disease == "心筋梗塞"
	
	collapse (sum) mi_c = mi, by (encounter_id)
	tab mi_c
	gen mi_pmh =. 
	replace mi_pmh =1 if mi_c >= 1
	rename encounter_id encounterid
	
	save "/Users/shokosoeno/Desktop/TXP/pp/pmh_mi.dta", replace
	
	clear
	import delimited /Users/shokosoeno/Downloads/Pulse_Pressure_pre_multiple_imputation.csv, encoding(utf8) bindquote(strict) clear
	save "/Users/shokosoeno/Desktop/TXP/pp/pp_twoYears_premi.dta", replace
	
	use "/Users/shokosoeno/Desktop/TXP/pp/pp_twoYears_premi.dta", clear
		merge 1:1 encounterid using "/Users/shokosoeno/Desktop/TXP/pp/pmh_mi.dta"
			drop _merge
	save "/Users/shokosoeno/Desktop/TXP/pp/pmh_mi_merged.dta", replace
	
	use "/Users/shokosoeno/Desktop/TXP/pp/pmh_mi_merged.dta", clear
	tab mi_pmh //224
	tab cci1_mi //76
	
