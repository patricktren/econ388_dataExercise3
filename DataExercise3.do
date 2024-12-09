log using C:/Users/patri/Documents/Econ_388/DataExercise3/DataExercise3.log, replace

cd C:/Users/patri/Documents/Econ_388/DataExercise3

* install mdesc to see where data is missing
ssc install mdesc

* get data on whether there was a recession in the US that year or not
import delimited JHDUSRGDPBR.csv, clear
gen date2 = date(date, "YMD")
format date2 %td
gen year = year(date2)
collapse (mean) avg_rec = jhdusrgdpbr , by(year)
gen recession = 0
replace recession = 1 if avg_rec > 0

save recession_data.dta, replace


* Basic Tasks
* 1.
use chat.dta, clear

rename country_name country

merge 1:1 country year using pwt1001.dta

drop if _merge == 3

levelsof country, local(countries)
foreach c of local countries {
	display "`c'"
}

* rename countries that are named differently between the two files
use chat.dta, clear
rename country_name country

replace country = "Bolivia" if country == "Bolivia (Plurinational State of)"
replace country = "Bosnia and Herzegovina" if country == "Bosnia-Herzegovina"
replace country = "Democratic Republic of the Congo" if country == "D.R. of the Congo"
replace country = "Ivory Coast" if country == "Côte d'Ivoire"
replace country = "Iran" if country == "Iran (Islamic Republic of)"
replace country = "North Macedonia" if country == "Macedonia"
replace country = "Moldova" if country == "Republic of Moldova"
replace country = "Congo" if country == "Republic of the Congo"
replace country = "Russia" if country == "Russian Federation"
replace country = "South Korea" if country == "Republic of Korea"
replace country = "Syria" if country == "Syrian Arab Republic"
replace country = "Venezuela" if country == "Venezuela (Bolivarian Republic of)"
replace country = "Vietnam" if country == "Viet Nam"
save chat_country, replace

use pwt1001.dta, clear
replace country = "Bolivia" if country == "Bolivia (Plurinational State of)"
replace country = "Bosnia and Herzegovina" if country == "Bosnia-Herzegovina"
replace country = "Democratic Republic of the Congo" if country == "D.R. of the Congo"
replace country = "Ivory Coast" if country == "Côte d'Ivoire"
replace country = "Iran" if country == "Iran (Islamic Republic of)"
replace country = "North Macedonia" if country == "Macedonia"
replace country = "Moldova" if country == "Republic of Moldova"
replace country = "Congo" if country == "Republic of the Congo"
replace country = "Russia" if country == "Russian Federation"
replace country = "South Korea" if country == "Republic of Korea"
replace country = "Syria" if country == "Syrian Arab Republic"
replace country = "Venezuela" if country == "Venezuela (Bolivarian Republic of)"
replace country = "Vietnam" if country == "Viet Nam"

save pwt_country, replace


use chat_country, clear
merge 1:1 country year using pwt_country.dta
drop if _merge != 3
drop _merge

drop if year < 1970 | year > 1999

gen emp_rate = emp / pop

gen rgdp_capita = rgdpna / pop
* drop outliers
summarize rgdp_capita
gen is_outlier = (rgdp_capita < r(mean) - 3.5 * r(sd)) | (rgdp_capita > r(mean) + 3.5 * r(sd))
drop if is_outlier

destring ship_all, replace
destring railline, replace
destring ship_steammotor, replace
destring shipton_all, replace
destring shipton_steammotor, replace

* aggregate crude steel (the data is currently split into different methods of steel production that were used over time)
gen steel_crude = 0
replace steel_crude = steel_crude + steel_acidbess if !missing(steel_acidbess)
replace steel_crude = steel_crude + steel_basicbess if !missing(steel_basicbess)
replace steel_crude = steel_crude + steel_bof if !missing(steel_bof)
replace steel_crude = steel_crude + steel_eaf if !missing(steel_eaf)
replace steel_crude = steel_crude + steel_ohf if !missing(steel_ohf)
replace steel_crude = steel_crude + steel_other if !missing(steel_other)
replace steel_crude = . if steel_crude == 0

* aggregate beds for patients
gen bed = 0
replace bed = bed + bed_acute if !missing(bed_acute)
replace bed = bed + bed_hosp if !missing(bed_hosp)
replace bed = bed + bed_longterm if !missing(bed_longterm)
replace bed = . if bed == 0


* see what variables are missing the most/least data
mdesc

* narrow down variables to what we want to look at
keep country year pop emp_rate delta xr rgdp_capita steel_crude cellphone ship_all elecprod ag_tractor bed visitorrooms


reshape wide pop emp_rate delta xr rgdp_capita steel_crude cellphone ship_all elecprod ag_tractor bed visitorrooms, i(country) j(year)

forvalues i=1970/1998 {
	local j=`i'+1
	generate rgdp_capita_growth`i'=((rgdp_capita`j'/rgdp_capita`i')-1)*100
	generate steel_crude_growth`i'=((steel_crude`j'/steel_crude`i')-1)*100
	generate cellphone_growth`i'=((cellphone`j'/cellphone`i')-1)*100
	generate ship_all_growth`i'=((ship_all`j'/ship_all`i')-1)*100
	generate elecprod_growth`i'=((elecprod`j'/elecprod`i')-1)*100
	generate ag_tractor_growth`i'=((ag_tractor`j'/ag_tractor`i')-1)*100
	generate bed_growth`i'=((bed`j'/bed`i')-1)*100
	generate visitorrooms_growth`i'=((visitorrooms`j'/visitorrooms`i')-1)*100

}



reshape long pop emp_rate delta xr rgdp_capita_growth steel_crude_growth cellphone_growth ship_all_growth elecprod_growth ag_tractor_growth bed_growth visitorrooms_growth rgdp_capita steel_crude cellphone ship_all elecprod ag_tractor bed visitorrooms, i(country) j(year)

* merge the recession data
merge m:1 year using recession_data
gen recession_xr_inter = recession * xr
drop if _merge != 3
drop _merge
drop avg_rec



* 2.
* how tech affects rgdp_capita_growth
encode country, gen(country_id)
xtset country_id year
prais rgdp_capita_growth emp_rate delta xr recession_xr_inter steel_crude_growth cellphone_growth ship_all_growth elecprod_growth ag_tractor_growth bed_growth visitorrooms_growth, robust

test steel_crude_growth cellphone_growth ship_all_growth elecprod_growth ag_tractor_growth bed_growth visitorrooms_growth

scatter rgdp_capita year, xtitle("year") ytitle("rGDP per capita")
	
scatter rgdp_capita_growth year

gen isDeveloped = 0
replace isDeveloped = 1 if country == "France" | country == "Germany" | country == "Italy" | country == "Japan" | country == "United Kingdom" | country == "United States"

save pwt_chat_BasicTasks, replace



* 3.
collapse (mean) rgdp_capita_growth steel_crude_growth cellphone_growth ship_all_growth elecprod_growth ag_tractor_growth bed_growth visitorrooms_growth [aweight=pop], by(year isDeveloped)
* Create the line graph with different colors for each variable
twoway (line steel_crude_growth year if isDeveloped == 0, lcolor(blue)) ///
       (line cellphone_growth year if isDeveloped == 0, lcolor(red)) ///
       (line ship_all_growth year if isDeveloped == 0, lcolor(green)) ///
	   (line elecprod_growth year if isDeveloped == 0, lcolor(orange)) ///
	   (line ag_tractor_growth year if isDeveloped == 0, lcolor(black)) ///
	   (line bed_growth year if isDeveloped == 0, lcolor(yellow)) ///
	   (line visitorrooms_growth year if isDeveloped == 0, lcolor(purple)), ///
       title("Average tech growth (undevloped)") ///
	   xtitle("year") ///
	   ytitle("% change") ///

twoway (line steel_crude_growth year if isDeveloped == 1, lcolor(blue)) ///
       (line cellphone_growth year if isDeveloped == 1, lcolor(red)) ///
       (line ship_all_growth year if isDeveloped == 1, lcolor(green)) ///
	   (line elecprod_growth year if isDeveloped == 1, lcolor(orange)) ///
	   (line ag_tractor_growth year if isDeveloped == 1, lcolor(black)) ///
	   (line bed_growth year if isDeveloped == 1, lcolor(yellow)) ///
	   (line visitorrooms_growth year if isDeveloped == 1, lcolor(purple)), ///
       title("Average tech growth (devloped)") ///
	   xtitle("year") ///
	   ytitle("% change") ///

use pwt_chat_BasicTasks, clear
* show summary data by isDeveloped
collapse (mean) rgdp_capita_growth steel_crude_growth cellphone_growth ship_all_growth elecprod_growth ag_tractor_growth bed_growth visitorrooms_growth [aweight=pop], by(year isDeveloped)
by isDeveloped, sort: summ



// collapse (mean) rgdp_capita_growth steel_crude_growth cellphone_growth ship_all_growth elecprod_growth ag_tractor_growth bed_growth visitorrooms_growth [aweight=pop], by(country)



log close