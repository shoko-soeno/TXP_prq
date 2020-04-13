	//multiple imputation後の解析///////////////////////////////////////////////////////////////////////////////
	clear
	//import excel "/Users/shokosoeno/Downloads/Soeno_rrindex_20200317/vital_postmi.xlsx", sheet("Sheet 1") firstrow
	import excel "/Users/shokosoeno/Downloads/vital_postmi.xlsx", sheet("Sheet 1") firstrow


	///cleaning
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
// 		destring pr, replace force
// 		destring rr, replace force
// 		destring spo2, replace force
// 		destring sbp, replace force
// 		destring dbp, replace force
// 		destring bt, replace force
// 		destring staylength, replace force
		
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
		
    //RRのグラフは8未満は全て8、32以上は全て32にしてFigureの範囲を変更
	gen rr2 = round(rr) //imputed dataは小数点が含まれるため。
	replace rr2=8 if rr<8
	replace rr2=32 if rr>32 & rr<.
	//replace rr2=round(rr2)

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
	preserve 
	//keep if CC_1_fever == 1
	//keep if CC_2_shortbr==1
	//keep if CC_3_mental == 1
	//keep if CC_4_chestp ==1
	keep if CC_5_abdp ==1
	mkspline sp_hosp_rr = rr2, cubic displayknots
	logistic hosp sp_hosp_rr*
	xblc sp_hosp_rr*, covname(rr2) at(12 16 20 24 28 32) reference(16) eform
	restore


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



