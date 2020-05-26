	//multiple imputation後の解析///////////////////////////////////////////////////////////////////////////////
	clear
	//import excel "/Users/shokosoeno/Downloads/Soeno_rrindex_20200317/vital_postmi.xlsx", sheet("Sheet 1") firstrow
	import excel "/Users/shokosoeno/Downloads/vital_postmi.xlsx", sheet("Sheet 1") firstrow

		//Drop children and missing age
		drop if age==.
		drop if age<18

		//drop if the primary diagoniss is I46 or S00-U99 (non-medical reasons)
		gen diag_1 = substr(icd10,1,1)
		gen diag_3 = substr(icd10,1,3)
		drop if diag_1 == "S" |  diag_1 == "T"| diag_1 == "V"| diag_1 == "W"| diag_1 == "X"| diag_1 == "Y"
		drop if diag_3 == "I46"  //cardiac arrest 
		drop if diag_1 == "Z"| diag_1 == "U"	
		
		///Drop cardiac arrest (来院時心肺停止)
		drop if cpa_flag==1
		drop if pr==0 | rr==0 | spo2==0
		
		//replace outliers to missings
		replace rr=. if rr<3 | rr>60

	//Disposition
		gen hosp=0 
		replace hosp=1 if disposition=="入院" | disposition=="ICU" | disposition=="直接入院" 
	//人工呼吸器
	gen mv_nippv =0
	replace mv_nippv =1 if mv==1 | nippv==1
	
	gen CC_1_syncope=0
	replace CC_1_syncope=1 if standardcc1=="失神" | standardcc1=="失神・前失神" //失神（cc49）, 失神・前失神（cc50）
	gen CC_2_sob=0
	replace CC_2_sob=1 if standardcc1=="呼吸困難" //呼吸困難
	gen CC_3_palpi =0
	replace CC_3_palpi =1 if standardcc1=="動悸" //動悸（cc33）
	gen CC_4_chestp=0
	replace CC_4_chestp=1 if standardcc1=="胸痛" //胸痛(cc89)
	gen CC_5_disconfort =0
	replace CC_5_disconfort =1 if standardcc1=="胸部不快感" //胸部不快感(cc90)
	gen CC_6_backpain =0
	replace CC_6_backpain =1 if standardcc1=="背部痛" //胸部不快感(cc88)
	gen CC_7_nausea =0
	replace CC_7_nausea =1 if standardcc1=="嘔吐・嘔気" //胸部不快感(cc44)

    // 補完後RRの小数点以下を四捨五入
	gen rr3=round(rr_mi)	

	//Change outliers to missing
	replace sbp=. if sbp<20 | sbp>300
	replace dbp=. if dbp<20 | dbp>300 | sbp < dbp
	replace bt=. if bt<20 | bt>45

	//Generalte PP index = PP/(1/2 * SBP)
	gen pp = sbp_mi - dbp_mi
	gen pp_index = pp/(0.5 * sbp)

	///cvd
	gen cvd = 0
	replace cvd = 1 if diag_3 == "I20" | diag_3 == "I21" | diag_3 == "I24" | diag_3 == "I26" | diag_3 == "I44" | /*
			*/ diag_3 == "I45" |diag_3 == "I48" |diag_3 == "I50" |diag_3 == "I71" 


	//Characteristics of ED visits
	//Output table1
	table1, vars(age contn \ sex cat \ sbp contn \ dbp contn \ pr contn \ /*
	*/ rr contn \ spo2 contn \ bt contn \ jtas cat \ route cat \ /*
	*/ hosp cat \ mv cat \ nippv cat \ death cat \ pp_index contn) format(%9.0f) sav (/Users/shokosoeno/Downloads/TXP_pp/table1) 
	//staylength conts \ cci cat \

	

	//LOWESS curve
	///referenceを0.8に設定、0.3以下は全て0.3、1.3以上は全て1.3としてfigureを作成
	replace pp_index =0.3 if pp_index<0.3
	replace pp_index =1.3 if pp_index>1.3

	lowess hosp pp_index
	lowess mv_nippv pp_index
	lowess cvd pp_index
	
	//主訴別のlowess
	twoway (lowess hosp pp_index if CC_1_syncope==1) /*
	*/ (lowess hosp pp_index if CC_2_sob==1) (lowess hosp pp_index if CC_3_palpi ==1) /*
	*/ (lowess hosp pp_index if CC_4_chestp==1) (lowess hosp pp_index if CC_5_disconfort ==1) /*
	*/ (lowess hosp pp_index if CC_6_backpain==1) (lowess hosp pp_index if CC_7_nausea==1), /*
	*/ legend(order(1 "syncope" 2 "shortness of breath" 3 "palpitation" 4 "chest pain" 5 "chest disconfort" 6 "backpain" 7 "nausea") col(4)) /*
    */                          ylabel(0(.5)1, angle(horiz) format(%2.1fc) ) ///
                                xlabel(0.3(.5)1.3) ///
                                ytitle("Risk of hospitalization") ///
                                xtitle("pp_index")

	twoway (lowess cvd pp_index if CC_1_syncope==1) /*
	*/ (lowess cvd pp_index if CC_2_sob==1) (lowess cvd pp_index if CC_3_palpi ==1) /*
	*/ (lowess cvd pp_index if CC_4_chestp==1) (lowess cvd pp_index if CC_5_disconfort ==1) /*
	*/ (lowess cvd pp_index if CC_6_backpain==1) (lowess cvd pp_index if CC_7_nausea==1), /*
	*/ legend(order(1 "syncope" 2 "shortness of breath" 3 "palpitation" 4 "chest pain" 5 "chest disconfort" 6 "backpain" 7 "nausea") col(4)) /*
    */                          ylabel(0(.5)1, angle(horiz) format(%2.1fc) ) ///
                                xlabel(0.3(.5)1.3) ///
                                ytitle("Risk of cvd") ///
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
