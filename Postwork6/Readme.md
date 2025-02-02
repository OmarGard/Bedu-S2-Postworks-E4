﻿
# Postwork Sesión 6. 

#### Objetivo

- Aprender a crear una serie de tiempo en `R`

#### Requisitos

- Tener instalado R y RStudio
- Haber trabajado con el prework y el work

#### Desarrollo

Importa el conjunto de datos match.data.csv a `R` y realiza lo siguiente:

1. Agrega una nueva columna `sumagoles` que contenga la suma de goles por partido.

2. Obtén el promedio por mes de la suma de goles.

3. Crea la serie de tiempo del promedio por mes de la suma de goles hasta diciembre de 2019.

4. Grafica la serie de tiempo.

__Notas para los datos de soccer:__ https://www.football-data.co.uk/notes.txt


### Solución
1. Importamos los datos y agregamos la columna de la suma total de goles por partido
```r
data <- read.csv("https://raw.githubusercontent.com/beduExpert/Programacion-R-Santander-2021/main/Sesion-06/Postwork/match.data.csv")
data <- data %>% mutate(sumagoles = home.score + away.score)
head(data)
```
```r
        date home.team home.score   away.team away.score sumagoles
1 2010-08-28  Hercules          0  Ath Bilbao          1         1
2 2010-08-28   Levante          1     Sevilla          4         5
3 2010-08-28    Malaga          1    Valencia          3         4
4 2010-08-29   Espanol          3      Getafe          1         4
5 2010-08-29 La Coruna          0    Zaragoza          0         0
6 2010-08-29  Mallorca          0 Real Madrid          0         0
```

2. Extraemos los meses y los años
```r
data <- data %>% mutate(date = as.Date(date))
data <- data %>% mutate(mes = as.numeric(format(date, '%m')),
                        anio = as.numeric(format(date, '%Y')))
```
3. Sacamos el promedio mensual
```r
promedio <- data %>% 
    select(sumagoles, mes, anio) %>%
    group_by(anio, mes) %>%
    summarise(promedio = mean(sumagoles))
```
4.  Convertimos los datos en una serie de tiempo
```r
serie <- ts(promedio$promedio, start = c(2010,8), end = c(2019,12), frequency = 12)
```
Graficamos nuestra serie de tiempo
```r
library(ggplot2)
library(ggfortify)
serie %>%
    autoplot(ts.colour = "#0D3B66") +
    ggtitle("Promedio de la suma mensual total de goles") +
    xlab("Año") + ylab("Promedio de goles") +
    theme_test() +
    geom_hline(aes(yintercept = mean(serie), color="media")) +
    scale_color_manual(name = "Estadísticos", values = c(media = "#EE964B"))
```
![grafica_ts](https://raw.githubusercontent.com/OmarGard/Bedu-F2-Postworks-E4/main/img/serie1.png)
 Notamos que nuestra serie tiene una media que parece constante, pero una varianza que no lo es,
 así que esto no la hace una gran candidata a ser una serie estacionaria

 Podemos analizar el correlograma de la serie y el parcial de la serie, y podemos notar
 que no es tan sencillo determinar los efectos de valores anteriores en los valores futuros
 de la serie de tiempo
 ```r
 acf(serie, lag.max = 50)
 ```
 ![acfSerie1](https://raw.githubusercontent.com/OmarGard/Bedu-F2-Postworks-E4/main/img/acfSerie1.png)

```r
pacf(serie, lag.max = 50)
```
![pacfSerie1](https://raw.githubusercontent.com/OmarGard/Bedu-F2-Postworks-E4/main/img/pacfSerie1.png)
Vamos a realizar una prueba de hipótesis para determinar si nuestra prueba es estacionaria
 para poder ver si podemos aplicar algún modelo de autoregresión sobre ella, 
 para ello tomaremos como hipótesis nula que nuestra serie contiene alguna raíz unitaria:
 
 ![\Large \Eta_0:\varphi = 1](https://latex.codecogs.com/svg.latex?\Large&space;H_0:\varphi=1)
 
 ![\Large  \Eta_1: \varphi < 1](https://latex.codecogs.com/svg.latex?\Large&space;H_0:\varphi<1)
 
 
 >Nota: La hipótesis nula significa que nuestra serie presenta una tendencia estocástica y no es una serie estacionaria y la alternativa es que no presenta tendencia estocástica y es estacionaria ya que la raíz unitaria es menor a 1 

Y probaremos dicha hipótesis con una prueba de Dicky-Fuller Aumentada con el comando __ur.df__ que viene de Unit Root Dickey - Fuller por su nombre en inglés
```r
library(urca)
y2 <- ur.df(serie,type="none", selectlags="AIC")
summary(y2)  
```
Y obtenemos lo siguiente:
```r
# ############################################### 
# # Augmented Dickey-Fuller Test Unit Root Test # 
# ############################################### 
# 
# Test regression none 
# 
# 
# Call:
#     lm(formula = z.diff ~ z.lag.1 - 1 + z.diff.lag)
# 
# Residuals:
#     Min       1Q   Median       3Q      Max 
# -1.15512 -0.21988  0.03193  0.20536  0.93389 
# 
# Coefficients:
#     Estimate Std. Error t value Pr(>|t|)    
# z.lag.1    -0.004696   0.013194  -0.356    0.723    
# z.diff.lag -0.515050   0.082727  -6.226 9.14e-09 ***
#     ---
#     Signif. codes:  0 ‘***’ 0.001 ‘**’ 0.01 ‘*’ 0.05 ‘.’ 0.1 ‘ ’ 1
# 
# Residual standard error: 0.3799 on 109 degrees of freedom
# Multiple R-squared:  0.2668,	Adjusted R-squared:  0.2534 
# F-statistic: 19.84 on 2 and 109 DF,  p-value: 4.501e-08
# 
# 
# Value of test-statistic is: -0.3559 
# 
# Critical values for test statistics: 
#     1pct  5pct 10pct
# tau1 -2.58 -1.95 -1.62
```
Notamos que para un valor del 99%, 95% y 90% de significancia, el estadístico de prueba supera a todas las pruebas, así que por lo tanto nuestra serie es __no estacionaria__.

Partiendo de la hipótesis de que la serie tiene raíces unitarias, podemos idealizar una forma en la que podemos hacer nuestra serie estacionaria. Supongamos que nuestra serie se puede modelar de la siguiente forma:

![\Large Y_t=\beta_0 +\beta_1t+\epsilon_t](https://latex.codecogs.com/svg.latex?\Large&space;Y_t=\beta_0+\beta_1t+\epsilon_t) 

Donde:

![\Large Y_t\text{&space;es&space;el&space;valor&space;actual de&space;la &space;serie}](https://latex.codecogs.com/svg.latex?\Large&space;Y_t\text{&space;es&space;el&space;valor&space;actual&space;de&space;la&space;serie})
![\Large B_0\text{&space;es&space;un&space;coeficiente&space;de&space;intercepto}](https://latex.codecogs.com/svg.latex?\Large&space;B_0\text{&space;es&space;un&space;coeficiente&space;de&space;intercepto})
![\Large B_1\text{&space;es&space;un&space;coeficiente&space;de&space;la&space;variable&space;de&space;tiempo}](https://latex.codecogs.com/svg.latex?\Large&space;B_1\text{&space;es&space;un&space;coeficiente&space;de&space;la&space;variable&space;de&space;tiempo})
![\Large e_t\text{&space;es&space;un&space;error&space;proveniente&space;de&space;una&space;distribución&space;normal&space;que&space;puede&space;ser&space;ruido&space;blanco}](https://latex.codecogs.com/svg.latex?\Large&space;e_t\text{&space;es&space;un&space;error&space;proveniente&space;de&space;una&space;distribucion&space;normal&space;que&space;puede&space;ser&space;ruido&space;blanco})

Definimos:

![\Large z_t = y_t - y_{t-1}](https://latex.codecogs.com/svg.latex?\Large&space;z_t=y_t-y_{t-1})

![\Large \text{ Calculamos la diferencia entre un valor y su consecutivo para } y_t ](https://latex.codecogs.com/svg.latex?\Large&space;\text{&space;Calculamos&space;la&space;diferencia&space;entre&space;un&space;valor&space;y&space;su&space;consecutivo&space;para&space;}y_t)


Entonces sustituyendo

![\Large z_t = (\beta_0 + \beta_1  t + \epsilon_t ) - (\beta_0 + \beta_1  t_{t-1} + \epsilon_{t-1} )](https://latex.codecogs.com/svg.latex?\Large&space;z_t&space;=&space;[\beta_0+\beta_1t+\epsilon_t\]-[\beta_0+\beta_1t_{t-1}+\epsilon_{t-1}])

![\Large z_t =\beta_1 + (\epsilon_t - \epsilon_{t-1})](https://latex.codecogs.com/svg.latex?\Large&space;z_t=\beta_1+[\epsilon_t-\epsilon_{t-1}])

Ahora si observamos la esperanza de la nueva serie, podemos notar que:

![\Large E(Z_t) = B_1](https://latex.codecogs.com/svg.latex?\Large&space;E[Z_t]=B_1)

Ya que B₁ es una constante así que no se ve afectada, y (eₜ - e₍ₜ₋₁₎) son errores que se asumen vienen de una distribución de ruido blanco o normal N(0,..).

 Y si observamos la varianza, podemos notar que:
 
 ![\Large Var(Z_t) = 2K^2](https://latex.codecogs.com/svg.latex?\Large&space;Var[Z_t]=2K^2)
 
Ya que B₁ es una constante, así que no afecta la varianza, y (eₜ - e₍ₜ₋₁₎) son errores independientes uno del otro, ya que vienen de una distribución normal, así que podemos tomar la suma  de sus varianzas, y supongamos que la varianza de eₜ es algún número K².

Entonces la varianza de  e₍ₜ₋₁₎ es igual k². 

Ya que provienen de la misma distribución, entonces nos queda:

![\Large K^2 + K^2 = 2K^2](https://latex.codecogs.com/svg.latex?\Large&space;K^2+K^2=2K^2)

Entonces tenemos que la nueva serie de diferencias tiene una media y una varianza constante, por lo tanto, debe de ser estacionaria, este proceso lo podemos repetir varias veces hasta obtener una serie estacionaria proveniente de nuestra serie original. Para calcular el número de veces, realizaremos una prueba de __Dickey - Fuller__ para cada iteración de diferencias, obteniendo lo siguiente:
```r
library(forecast)
ndiffs(serie)
# [1] 1
```
Entonces debemos realizar solo una serie de diferencias, para obtener una serie que sea estacionaria
```r
serie.diff <- diff(serie)
```
Graficamos la nueva serie para ver los resultados
```r
serie.diff %>%
    autoplot(ts.colour = "#0D3B66") +
    ggtitle("Promedio de la suma mensual total de goless") +
    xlab("Año") + ylab("Promedio de goles") +
    theme_test() +
    geom_hline(aes(yintercept = mean(serie.diff), color="media")) +
    scale_color_manual(name = "Estadísticos", values = c(media = "#EE964B")
```
![serieDiff](https://raw.githubusercontent.com/OmarGard/Bedu-F2-Postworks-E4/main/img/serieDiff.png)

Tenemos un mejor correlograma total y parcial para nuestra serie de tiempo
```r
acf(serie.diff, lag.max = 50)
```
![acfSerieDiff](https://raw.githubusercontent.com/OmarGard/Bedu-F2-Postworks-E4/main/img/acfSerieDiff.png)
```r
pacf(serie.diff, lag.max = 50)
```
![pacfSerieDiff](https://raw.githubusercontent.com/OmarGard/Bedu-F2-Postworks-E4/main/img/pacfSerieDiff.png)
Realizamos una prueba de Dickey - Fuller para corroborar los resultados:
```r
y3 <- ur.df(serie.diff,type="none", selectlags="AIC")
summary(y3) 

# Value of test-statistic is: -13.8505 
# 
# Critical values for test statistics: 
#     1pct  5pct 10pct
# tau1 -2.58 -1.95 -1.62
```
Ahora podemos notar que el valor del estadístico de prueba es -13.8505, y es muchísimo menor que cualquier valor de significancia del 99%,95% y 90%. Por lo tanto tenemos una serie estacionaria a la cual le podemos aplicar algún modelo de autoregresión.




#### FORECAST (MODELO ARIMA)

Trabajar con series de tiempo nos permite ampliar el análisis de los datos para realizar predicciones futuras utilizando la infomación disponible del pasado. \
Una vez que nuetra serie es estacionaria y dado que se le aplicó una diferencia, se encuentra apta para emplear un **modelo ARIMA(5,1,2)** \
Los parametros son acorde a los resultados arrojados por los correlogramas acf y pacf de la serie con una diferencia.

Aplicamos el modelo con 5 auto regresivos, una diferencia y dos medias móvil
```r
modelo_1 <- arima(serie, order = c(5,1,2))
```

Observamos el diagnóstico del modelo utilizando tsdiag() \
En donde se observa que los errores estandarizados tienen un comportamiento de ruido blanco, mientras que los valores p del estadístico Ljung-Box se encuentran por encima de 0.05
```r
tsdiag(modelo_1)
```
![diagnostico_arima](https://raw.githubusercontent.com/OmarGard/Bedu-F2-Postworks-E4/main/img/diagnostico_arima.png)

Aplicamos el test de Ljung-Box para comprobar si hay ruido blanco, donde: \
Hₒ = Hay presencia de ruido blanco \
Hₐ = No hay presencia de ruido blanco
```r
Box.test(residuals(modelo_1), type ="Ljung-Box")

# Box-Ljung test
# data:  residuals(modelo_1)
# X-squared = 0.037264, df = 1, p-value = 0.8469
```

Observamos el comportamiento de los residuos
```r
plot(residuals(modelo_1), main = "Gráfico de los residuales", xlab = "Año", ylab ="")
```
![residuales_arima](https://raw.githubusercontent.com/OmarGard/Bedu-F2-Postworks-E4/main/img/residuales_arima.png)

Hacemos el pronóstico para los próximos 12 meses
```r
pronostico <- forecast(modelo_1, 12)
# Observemos que ademas de tener el forecast, tambien podemos observar el límite superior e inferior a un 
# 80 y 95% de confianza
# Notemos que el promedio de la suma de goles totales oscila entre 2 y 3 goles para los próximos meses
```
```
Point Forecast    Lo 80    Hi 80    Lo 95    Hi 95
Jan 2020       2.691815 2.307153 3.076477 2.103525 3.280105
Feb 2020       2.678214 2.293522 3.062907 2.089878 3.266551
Mar 2020       2.811488 2.426351 3.196624 2.222472 3.400503
Apr 2020       2.809167 2.419317 3.199018 2.212943 3.405392
May 2020       2.833140 2.426608 3.239671 2.211403 3.454876
Jun 2020       2.695623 2.286357 3.104889 2.069705 3.321542
Jul 2020       2.705084 2.271171 3.138996 2.041472 3.368696
Aug 2020       2.737632 2.293179 3.182085 2.057900 3.417364
Sep 2020       2.785638 2.337584 3.233691 2.100399 3.470876
Oct 2020       2.772907 2.321089 3.224724 2.081912 3.463902
Nov 2020       2.771533 2.308155 3.234910 2.062858 3.480207
Dec 2020       2.739906 2.268697 3.211116 2.019253 3.460559
```

Graficamos el forecast

```r
# Con ggplot
pronostico %>%
    autoplot(ts.colour = "#0D3B66") +
    ggtitle("Promedio de la suma mensual total de goles (pronóstico)") +
    xlab("Año") + ylab("Promedio de goles") +
    theme_test() +
    geom_hline(aes(yintercept = mean(serie), color="media")) +
    scale_color_manual(name = "Estadísticos", values = c(media = "#EE964B"))
```

![pronostico_arima](https://raw.githubusercontent.com/OmarGard/Bedu-F2-Postworks-E4/main/img/pronostico_arima.png)






