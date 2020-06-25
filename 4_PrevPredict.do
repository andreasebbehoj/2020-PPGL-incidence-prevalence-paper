***** 4_PrevPredict.do *****
* Test 
clear
gen sex = .
gen year = .
gen age = .
local obs = 0

foreach sex in 1 2 {
	forvalues year=1977(1)$lastyear {
		forvalues age = 0(1)99 {
			local obs = `obs'+1
			qui: set obs `obs'
			qui: replace sex = `sex' if _n==`obs'
			qui: replace year = `year' if _n==`obs'
			qui: replace age = `age' if _n==`obs'
		}
	}
}

gen relmort = 2
gen ppgldeath = "ppgldeath"
gen area = "dk"
order ppgldeath sex year age relmort area
export delimited using PIAMOD_relsurv.txt, replace novarnames delim(" ")