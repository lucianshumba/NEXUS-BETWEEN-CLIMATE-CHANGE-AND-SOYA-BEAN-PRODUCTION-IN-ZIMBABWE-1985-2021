clear
import excel "C:\Users\user\Desktop\Agric Stats Masters Stuff\Trimester 2\Second Phase\Dissertation\Data forecasting.xlsx", sheet("Sheet1") firstrow

//Declaring timeseries dataset
tsset Year

//testing for stationarity
tsline Prod
varsoc Prod
dfuller Prod, lags(1)
varsoc d.Prod
dfuller d.Prod, lags(4)

//Model identification
ac d.Prod, /*for q*/ //1
pac d.Prod, /*for p*/ //4

arima Prod, arima(0,1,0)
estat ic //858.5529

arima Prod, arima(1,1,0)
estat ic //856.2643 

arima Prod, arima(2,1,0)
estat ic // 856.7352


arima Prod, arima(3,1,0)
estat ic // 858.5177 

arima Prod, arima(4,1,0)
estat ic // 855.95


arima Prod, arima(0,1,1)
estat ic //850.0846 

arima Prod, arima(1,1,1)
estat ic //849.2322 

arima Prod, arima(2,1,1)
estat ic // 851.145


arima Prod, arima(3,1,1)
estat ic // 852.7117 

arima Prod, arima(4,1,1)
estat ic // 851.769

 

//Diagnostic testing//
//the stable model with the lower AIC is arima(1,1,1)//
arima Prod, arima(1,1,1) 
predict error, resid
sum error
tsline error, yline(3633.934 )
wntestq error //H0: the residuals are whitenoise          P= 0.2137 we fail to reject Ho/
asdoc estat aroots/*Checking condition for stable univariate ts ie checking if arima process is stable*/
asdoc corrgram error //H0: there is no seral correlation. Since the p values all above 0.005 so, we fail to reject Ho, so there is no serial correlation//
br Year

//Forecast//
tsappend, add(9) 
predict fProd, y dynamic(y(2022))
label var fProd "Forecasted_Production"
tsline Prod fProd

//2 1 1
//the stable model with the lower AIC is arima(1,1,1)//
arima Prod, arima(2,1,1) 

//Forecast//
predict f2Prod, y dynamic(y(2022))


//3 1 1 
//Diagnostic testing//
//the stable model with the lower AIC is arima(1,1,1)//
arima Prod, arima(3,1,1) 
//Forecast//
predict f3Prod, y dynamic(y(2022))

//4 1 1 
//Diagnostic testing//
//the stable model with the lower AIC is arima(1,1,1)//
arima Prod, arima(1,1,1) 
//Forecast//
predict f4Prod, y dynamic(y(2022))

asdoc fcstats Productionintonnes fProd f2Prod

//Trend analysis
ktau Year Prod
ktau Year Temp
ktau Year Rain

//Trend of production
reg Prod Year
predict prodhat, xb
sort Year
twoway (line Prod Year) (line prodhat Year)

//Trend of Temperature
reg Temp Year
predict temphat, xb
sort Year
twoway (line Temp Year) (line temphat Year)

//Trend of Rainfall
reg Rain Year
predict rainhat, xb
sort Year
twoway (line Rain Year) (line rainhat Year)

//ARDL

clear
import excel "C:\Users\user\Desktop\Agric Stats Masters Stuff\Trimester 2\Second Phase\Dissertation\Data 1.xlsx", sheet("Sheet1") firstrow

rename Productionintonnes Prod
rename Annualmeantemperature Temp
rename Annualmeanprecipitationrainf Rain
rename AreainHa Area
des

gen lnprod=ln(Prod)
gen lntemp=ln(Temp)
gen lnrain=ln(Rain)
gen lnarea=ln(Area)

//Normality test
foreach var in lnprod lnarea lnrain lntemp{
    jb   `var'
}

//Median
foreach var in lnprod lnarea lnrain lntemp{
    centile   `var', centile(50)
}

//summary statistics
sum lnprod lnarea lnrain lntemp, d

tsset Year /*setting time series in stata*/


/*Optimal lags determination*/
varsoc lnprod lntemp lnrain lnarea, maxlag(2)
ardl lnprod lntemp lnrain lnarea, maxlag(2) aic

/*ARDL COINTERGRATION TEST*/

//ARDL Bounds Test
ardl lnprod lntemp lnrain lnarea, lags(2 0 0 1) ec 
ardl lnprod lntemp lnrain lnarea, lags(4 5 5 5) ec btest/*variables, lags(specify) ec..........ardl moderl with error correction*/

//ARDL short run ecm MODEL
ardl lnprod lntemp lnrain lnarea, lags(2 0 0 1) aic

//estat btest /*Pesaran/Shin/Smith (2001)  
//ardl bound test for cointergration*/
//estat ectest /*suppresed estat btest as the prime procedure to test for a levels relationship


//diagnostic tests

//STABILITY TEST

quietly ardl lnprod lntemp lnrain lnarea, lags(2 0 0 1)
estat sbcusum



//Normality test
quietly ardl lnprod lntemp lnrain lnarea, lags(2 0 0 1) 
predict resid, r 

histogram resid, normal // skewed to the right 

jb resid // not normally distributed

//Ramsey Test for Model specification:
//Quietly ardl lnprod lntemp lnrain lnarea, lags(2 0 0 1) 
//predict resid, r 
estat ovtest

//Jarque-Bera test is used to assess whether the data follows a normal distribution 

//ssc install jb

//transformed
//foreach var in lnProd lnareaharv lnrainfall lntemp {
 //   jb `var'
//}

//nontransformed
//foreach var1 in Prod areaharv rainfall temp {
//    jb `var1'
//}




//Model Residuals Test -Skewness and kurtosis tests for normality

sktest resid



//Shapiro-Wilk W test for normal data
swilk resid


qnorm resid

//qnorm resid, gen(qq_resid)


//twoway (qnorm qq_resid z, xline(0) yline(0)) (lfit qq_resid z)

histogram resid, normal

kdensity resid, normal

twoway tsline resid


//Heteroskedasticity Test

//Run first the model
quietly ardl lnprod lntemp lnrain lnarea, lags(2 0 0 1) 
predict resid, r
//Pagan Test
//estat hettest //no heteroscedasticity
estat archlm
estat imtest, white


// Serial Correration - Robust Standard Error
varsoc resid // opt lag 0
quietly ardl lnprod lntemp lnrain lnarea resid, lags(2 0 0 1 0)
estat bgodfrey //noserial correlation


  
//Checking Long run and short run Relationship 

ardl lnProd lnareaharv lnrainfall lntemp, lags(2 4 1 1) ec btest 
estat ectest 

//Long run Relationship

asdoc ardl lnProd lnareaharv lnrainfall lntemp, lags(2 4 1 1) ec

//short term relationship
//ardl Prod areaharv rainfall temp, lags(2 4 1 1) aic

asdoc ardl lnProd lnareaharv lnrainfall lntemp, lags(2 4 1 1) aic

