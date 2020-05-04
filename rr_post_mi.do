	//multiple imputation後の解析///////////////////////////////////////////////////////////////////////////////
	clear
	//import excel "/Users/shokosoeno/Downloads/Soeno_rrindex_20200317/vital_postmi.xlsx", sheet("Sheet 1") firstrow
	import excel "/Users/shokosoeno/Downloads/vital_postmi.xlsx", sheet("Sheet 1") firstrow

		//Drop children and missing age
// 		drop if age==.
// 		drop if age<18

		//drop if the primary diagoniss is I46 or S00-U99 (non-medical reasons)
// 		gen diag_1 = substr(icd10,1,1)
		gen diag_3 = substr(icd10,1,3)
// 		drop if diag_1 == "S" |  diag_1 == "T"| diag_1 == "V"| diag_1 == "W"| diag_1 == "X"| diag_1 == "Y"
		drop if diag_3 == "I46"  //cardiac arrest 
// 		drop if diag_1 == "Z"| diag_1 == "U"	
		
		///Drop cardiac arrest (来院時心肺停止)
		drop if cpa_flag==1
		drop if pr==0 | rr==0 | spo2==0
		
		//replace outliers to missings
		replace rr=. if rr_mi<3 | rr_mi>60

	//Disposition
		gen hosp=0 
		replace hosp=1 if disposition=="入院" | disposition=="ICU" | disposition=="直接入院" 
	
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
				
	// outliers to missing
        replace rr=. if rr_mi<3 | rr_mi>60

    // 補完後RRの小数点以下を四捨五入
	gen rr3=round(rr_mi)	

	//full dataで、RRを16未満と、24以上で分け、主訴別のdiagnosisのtop5を出す
	//診断名ですが、case-completeではなくfull dataで見たときにRR<16での各主訴での入院top3ぐらいまで出せますか？
	gen rr_cat=.
	replace rr_cat=0 if rr<16
	replace rr_cat=1 if rr>=16 & rr<24
	replace rr_cat=2 if rr>=24
	preserve
	keep if hosp == 1
	keep if rr_cat==2
	tabulate icd10 if CC_1_fever==1, sort
	//tabulate icd10 if CC_2_shortbr==1, sort
	//tabulate icd10 if CC_3_mental==1, sort
	//tabulate icd10 if CC_4_chestp==1, sort
	//tabulate icd10 if CC_5_abdp==1, sort
	restore
	
	//Cubic spline regression
	//install xbrcspline 
	//findit xblc
	
	//hospとRR
	preserve
	mkspline sp_hosp_rr = rr3, cubic displayknots
	logistic hosp sp_hosp_rr*
	xblc sp_hosp_rr*, covname(rr) at(8 12 16 20 24 28 32) reference(16) eform
	restore

	//mv＋NIPPVとRR
	gen mn = 0
	replace mn = 1 if mv ==1 | nippv ==1
	
	preserve
	mkspline sp_mn_rr = rr3, cubic displayknots
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
	mkspline sp_hosp_rr = rr3, cubic displayknots
	logistic hosp sp_hosp_rr*
	xblc sp_hosp_rr*, covname(rr) at(12 16 20 24 28 32) reference(16) eform
	restore

  
//RRのグラフは8未満は全て8、32以上は全て32にしてFigureの範囲を変更
	//gen rr2 = round(rr) //imputed dataは小数点が含まれるため。
	replace rr3=8 if rr<8
	replace rr3=32 if rr>32 & rr<.
	
	//LOWESS curve for hospitalization or mv
	twoway (lowess hosp rr3) (lowess mv rr3), /*
	*/ legend(order(1 "Hospitalization" 2 "Mechanical ventilation") col(3)) /*
    */                          ylabel(0(.5)1, angle(horiz) format(%2.1fc) )
                                xlabel(8(4)32)
                                ytitle("Risk of the clinical outcomes")
                                xtitle("Respiratory Rate")

	//Lowess curve by CC
	//RR
	twoway (lowess hosp rr3 if CC_1_fever==1) /*
	*/ (lowess hosp rr3 if CC_2_shortbr==1) (lowess hosp rr3 if CC_3_mental==1) /*
	*/ (lowess hosp rr3 if CC_4_chestp==1) (lowess hosp rr3 if CC_5_abdp==1),  /*
	*/ legend(order(1 "Fever" 2 "Shortness of breath" 3 "Altered mental status" 4 "Chest pain" 5 "Abdominal pain") col(2)) /*
    */                          ylabel(0(.5)1, angle(horiz) format(%2.1fc) ) ///
                                xlabel(8(4)32) ///
                                ytitle("Risk of hospitalization") ///
                                xtitle("Respiratory rate")

	//ロジスティック回帰に関してはnの問題もありますがRR16をreferenceとして
	//RRcat=RR<12, 12-15, 16-20 (ref), 21-24, 25-28, 29-31, ≥31もしくはRRcat2=<12, 13-20, 21-28, ≥28でカテゴリわけして
	//ロジスティック回してください（logistic hosp i.RRcat, or）
	//RRはcut関数などを使用してカテゴリ分けし、referenceを16にする場合、logistic hosp i.RRcat, base(16) or 
	gen rrcat=0 if rr>=16 & rr<=20
	replace rrcat=1 if rr<=12
	replace rrcat=2 if rr>=12 & rr<16
	replace rrcat=3 if rr>=20 & rr<24
	replace rrcat=4 if rr>=24 & rr<28
	replace rrcat=5 if rr>=28 & rr<32
	replace rrcat=6 if rr==.
	logistic hosp i.rrcat, or

