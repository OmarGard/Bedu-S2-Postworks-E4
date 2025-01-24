  # ##########################################################################
  #                        Sesion_5 POSTWORK
  # ########################################################################### 
  
  # 1. A partir del conjunto de datos de soccer de la liga española de las temporadas 2017/2018,
  # 2018/2019 y 2019/2020, crea el data frame SmallData, que contenga las columnas 
  # date, home.team, home.score, away.team y away.score; 
  # Luego establece un directorio de trabajo y con ayuda de la función write.csv guarda el data frame como un archivo csv con nombre soccer.csv.
  # Puedes colocar como argumento row.names = FALSE en write.csv.
  
  # 2. Con la función create.fbRanks.dataframes del paquete fbRanks importe el archivo soccer.csv a R y 
  # al mismo tiempo asignelo a una variable llamada listasoccer. 
  # Se creará una lista con los elementos scores y teams que son data frames listos para la función rank.teams.
  # Asigna estos data frames a variables llamadas anotaciones y equipos.
  
  # 3. Con ayuda de la función unique crea un vector de fechas (fecha) que no se repitan 
  # y que correspondan a las fechas en las que se jugaron partidos.
  # Crea una variable llamada n que contenga el número de fechas diferentes.
  # Posteriormente, con la función rank.teams y usando como argumentos los data frames anotaciones y equipos, 
  # crea un ranking de equipos usando únicamente datos desde la fecha inicial 
  # y hasta la penúltima fecha en la que se jugaron partidos, 
  # estas fechas las deberá especificar en max.date y min.date. 
  # Guarda los resultados con el nombre ranking.
  
  # 4. Finalmente estima las probabilidades de los eventos, el equipo de casa gana, 
  # el equipo visitante gana o el resultado es un empate para los partidos que se jugaron en la última fecha del vector de fechas fecha. 
  # Esto lo puedes hacer con ayuda de la función predict y usando como argumentos ranking y fecha[n] 
  # que deberá especificar en date.


  library(dplyr)
  library(ggplot2)
  
  #inserte cual es su directorio raiz
  rootdir <- "E:/ecardoz/Bedu-F2-Postworks-E4/"
  
  # Cargamos los datos
  df <- read.csv("https://raw.githubusercontent.com/OmarGard/Bedu-F2-Postworks-E4/main/output_data/postwork_2/D1_17_18_19.csv")
  head(df)
  
  # Seleccionamos variables de interes
  SmallData <- df %>%
    select(Date, HomeTeam, AwayTeam, FTHG, FTAG)
  
  head(SmallData)
  
  
  # Renombramos variables para el uso posterior de "fbRanks"
  SmallData <- SmallData %>%
    rename(
      date = Date,
      home.team = HomeTeam,
      home.score = FTHG,
      away.team = AwayTeam,
      away.score = FTAG
    )
  
  head(SmallData)
  getwd()
  setwd(rootdir)
  
  # Guardamos los datos
  write.csv(SmallData, file = "output_data/postwork_5/soccer.csv", row.names = FALSE)
  
  # 2. Leemos los datos con ayuda de fbRanks
  library(fbRanks)
  listasoccer<- create.fbRanks.dataframes(scores.file = "output_data/postwork_5/soccer.csv", date.format = "%Y-%m-%d")
  
  anotaciones <- listasoccer$scores
  equipos <- listasoccer$teams 
  
  # 3. Creamos vector de fechas
  fecha <- unique(listasoccer$scores$date)
  n <- length(fecha)
  
  ranking <- rank.teams(scores = anotaciones, 
                        teams = equipos,
                        min.date = fecha[1], 
                        max.date = fecha[n-1])
  
  # 4. Estimacion de probabilidades
  predict(ranking, date = fecha[n])
  
  # Predicted Match Results for 1900-05-01 to 2100-06-01
  # Model based on data from 2017-08-18 to 2020-12-22
  # ---------------------------------------------
  # 2020-12-23 Leganes vs Sevilla, HW 22%, AW 50%, T 27%, pred score 0.8-1.4  actual: T (1-1)
  # 2020-12-23 Valencia vs Huesca, HW 57%, AW 20%, T 22%, pred score 1.8-1  actual: HW (2-1)
  # 2020-12-23 Vallecano vs Levante, HW 26%, AW 52%, T 22%, pred score 1.3-1.9  actual: HW (2-1)
  # ----------------------------------------------------------------------------------------------
  # ----------------------------------------------------------------------------------------------
  # ----------------------------------------------------------------------------------------------
  
  # Podemos ver que los equipos que han sido más anotadores en el pasado tienen una mayor probabilidad de anotar 
  # goles en el futuro. Es un buen momento para presentar la distribución de Poisson.Es una distribución de probabilidad
  # discreta que describe la probabilidad del número de eventos en un período de tiempo específico (por ejemplo, 90 minutos) 
  # con una tasa media conocida de ocurrencia. Un supuesto clave es que el número de eventos es independiente del tiempo. 
  # En nuestro contexto, esto significa que los goles no se vuelven más o menos probables por el número de goles ya marcados en el partido. 
  # En cambio, el número de objetivos se expresa puramente como función de una tasa media de objetivos. Podemos utilizarla
  # siguiendo la función a continuación: 
  #                 P(X=x) = EXP(λ) * (λ ^K) / K!,λ > 0
  # representa la tasa media (por ejemplo, número medio de goles, número medio de cartas que recibes, etc. ). Por lo tanto, 
  # podemos tratar el número de goles anotados por el equipo de casa y de fuera como dos distribuciones independientes de Poisson. 
  # Lo siguiente será tratar de encontrar la proporción de goles anotados en comparación con el número de goles estimado por las distribuciones 
  # de Poisson correspondientes
  
  # Predicción de Poisson
  # Primero haremos un análisis para probar la teoría de las distribuciones analizando los goles hechos
  # por los locales y por los visitantes 
  
  # Obtenemos los dataframes de las frecuencias relativas de los goles de locales y visitantes
  home.df <- as.data.frame(prop.table(table(SmallData[,"home.score"])))
  away.df <- as.data.frame(prop.table(table(SmallData[,"away.score"])))
  
  # Calculamos las predicciones de probabilidad de Poisson para cada número de goles
  poisson_pred.home <- dpois(c(0:8),mean(SmallData[,"home.score"]))
  poisson_pred.away <- dpois(c(0:6),mean(SmallData[,"away.score"]))
  
  # Agregamos la columna de las predicciones al dataframe, así como también la clase del dato, es decir,
  # si la tupla fue hecha por un visitante o un local, y una variable auxiliara x_ para el momento de graficar
  # los resultados y renombramos la columna "Var1" por "goals"
  
  home.df
  home.df <- home.df %>%
    mutate(
      poisson_pred = poisson_pred.home,
      x_ = as.numeric(as.character(Var1)) + 0.25,
      clase = "Home"
    ) 
  home.df <- home.df %>%
    rename(goals = Var1)
  # Hacemos lo mismo para el dataframe de los goles de visitantes
  away.df <- away.df %>%
    mutate(
      poisson_pred = poisson_pred.away,
      x_ = as.numeric(as.character(Var1)) - 0.25,
      clase = "Away"
      )
  away.df <- away.df %>%
    rename(goals = Var1)

  # Creamos un único dataframe mexclando los de local y visitante
  home_away.df <- rbind(home.df,away.df)
  
  # Transformamos el tipo de dato de la columna de goals, ya que es 
  # de tipo factor al convertirlo de table a dataframe
  home_away.df <- home_away.df %>%
    transform(goals = as.numeric(as.character(goals)))
  str(home_away.df)
  
  
  # Finalmente ploteamos los resultados de los goles y las predicciones de Poisson, podemos observar 
  # que la distribución tiene una predicción bastante acertada respecto a los resultados verdaderos
  home_away.df %>%
      ggplot() +
      geom_col(aes(x = goals, y = Freq, fill = clase),position = "dodge") +
      guides(fill=guide_legend(title="Valores Verdaderos")) +
      geom_point(aes(x=x_,y=poisson_pred, group=clase, colour=clase)) +
      geom_line(aes(x=x_,y=poisson_pred, group=clase, colour=clase))+
      scale_color_manual(values = c(Away= '#CE5754',
                                 Home = '#048386')) +
      labs(x = "Goles Anotados",y = "Proporción de partidos", color = "Predicción Poisson") +
      scale_x_discrete(limits = c(0:8)) +
      ggtitle("Número de goles por partido (PDE Temporadas 2017-2019)")
  
  # ----------------------------------------------------------------------------------------------
  # ----------------------------------------------------------------------------------------------
  # ----------------------------------------------------------------------------------------------
  # Análisis Leganes - Sevilla
  # Ahora analizaremos uno de los partidos predecidos por nuestro modelo, el cuál es:
  # 2020-12-23 Leganes vs Sevilla, HW 22%, AW 50%, T 27%, pred score 0.8-1.4  actual: T (1-1)
  
  # Obtenemos los dataframes de los goles de local y visitante para ambos equipos
  leganes.home.df <- as.data.frame(prop.table(table(subset(SmallData,(home.team == "Leganes"))["home.score"])))
  leganes.away.df <- as.data.frame(prop.table(table(subset(SmallData,(away.team == "Leganes"))["away.score"])))
  
  sevilla.home.df <- as.data.frame(prop.table(table(subset(SmallData,(home.team == "Sevilla"))["home.score"])))
  sevilla.away.df <- as.data.frame(prop.table(table(subset(SmallData,(away.team == "Sevilla"))["away.score"])))
  
  # Transformamos la columna de Var1 que se genera al convertirse, a tipo numérico
  leganes.home.df <- leganes.home.df %>%
    transform(Var1 = as.numeric(as.character(Var1)))
  sevilla.home.df <- sevilla.home.df %>%
    transform(Var1 = as.numeric(as.character(Var1)))
  leganes.away.df <- leganes.away.df %>%
    transform(Var1 = as.numeric(as.character(Var1)))
  sevilla.away.df <- sevilla.away.df %>%
    transform(Var1 = as.numeric(as.character(Var1)))
  
  # Calculamos las predicciones de Poisson para cada equipo jugando de ambos lados
  poisson.leganes.home <- dpois(c(0:3),sum(leganes.home.df[,"Var1"]*leganes.home.df[,"Freq"]))
  poisson.leganes.away <- dpois(c(0:4),sum(leganes.away.df[,"Var1"]*leganes.away.df[,"Freq"]))
  
  poisson.sevilla.home <- dpois(c(0,1,2,3,5),sum(sevilla.home.df[,"Var1"]*sevilla.home.df[,"Freq"]))
  poisson.sevilla.away <- dpois(c(0,1,2,3,4,6),sum(sevilla.away.df[,"Var1"]*sevilla.away.df[,"Freq"]))
  
  # Agregamos la clase de las tuplas, la vairable auxiliar x_, y la predicción de Poisson y una columna nueva
  # div que nos ayudará a poder hacer un facet_grid en los resultados, ya que ahora estamos considerando 
  # una variable extra en la gráfica para los 4 dataframes
  leganes.home.df <- leganes.home.df %>%
    mutate(
      poisson_pred = poisson.leganes.home,
      x_ = Var1 - 0.25,
      clase = "Leganes",
      div = "Home"
    ) 
  leganes.home.df <- leganes.home.df %>%
    rename(goals = Var1)
  
  leganes.away.df <- leganes.away.df %>%
    mutate(
      poisson_pred = poisson.leganes.away,
      x_ = Var1 - 0.25,
      clase = "Leganes",
      div = "Away"
    ) 
  leganes.away.df <- leganes.away.df %>%
    rename(goals = Var1)
  
  sevilla.home.df <- sevilla.home.df %>%
    mutate(
      poisson_pred = poisson.sevilla.home,
      x_ = Var1 + 0.25,
      clase = "Sevilla",
      div = "Home"
    ) 
  sevilla.home.df <- sevilla.home.df %>%
    rename(goals = Var1)
  
  sevilla.away.df <- sevilla.away.df %>%
    mutate(
      poisson_pred = poisson.sevilla.away,
      x_ = Var1 + 0.25,
      clase = "Sevilla",
      div = "Away"
    ) 
  sevilla.away.df <- sevilla.away.df %>%
    rename(goals = Var1)
  
  # Unimos los 4 dataframes en uno solo para su graficación
  leganes_sevilla <- rbind(leganes.home.df,leganes.away.df,sevilla.home.df,sevilla.away.df)
  
  # Podemos ver que incluso separando los valores por equipos específicos y de diferentes bandos de juego, 
  # la distribución de Poisson sigue dando resultados muy acertados a los valores reales, con esto podemos
  # darnos y convencernos que el número de goles anotados por cada equipo puede ser aproximado usando una distribución de Poisson
  leganes_sevilla %>%
    ggplot() +
    geom_col(aes(x = goals, y = Freq, fill = clase),position = "dodge") +
    guides(fill=guide_legend(title="Valores Verdaderos")) +
    geom_point(aes(x=x_,y=poisson_pred, group=clase, colour=clase)) +
    geom_line(aes(x=x_,y=poisson_pred, group=clase, colour=clase))+
    scale_color_manual(values = c(Leganes= '#CE5754',
                                  Sevilla = '#048386')) +
    labs(x = "Goles Anotados",y = "Proporción de partidos", color = "Predicción Poisson") +
    scale_x_discrete(limits = c(0:6)) +
    ggtitle("Número de goles por partido (PDE Temporadas 2017-2019)") +
    facet_grid(div ~ .)
  
  # Convettimos el ranking de los equipos a un dataframe para poder obtener algunos datos de él
  ranks.df <- print.fbRanks(ranking)
  ranks.df<- as.data.frame(ranks.df)
  
  # Vamos a calcular los goles esperados para este partido por el Leganes al Sevilla, y ay que el Leganes es Local y Sevilla visitante, 
  # los goles esperados siguen la siguiente fórmula:
  # E_equipoA_equipoB = Fuerza de Ataque(Equipo A) * Fuerza de Defensa(Equipo B) * Media de goles de local de la liga
  
  expectedGoals.leganes <- as.numeric(subset(ranks.df,(ranks.team=="Leganes"))["ranks.attack"]) * 
    as.numeric(subset(ranks.df,(ranks.team=="Sevilla"))["ranks.defense"]) * 
    mean(SmallData[,"home.score"])
  expectedGoals.leganes
  # [1] 1.215251
  
  # De igual manera obtenemos los goles esperados del Sevilla al Leganes
  expectedGoals.sevilla <- as.numeric(subset(ranks.df,(ranks.team=="Sevilla"))["ranks.attack"]) * 
    as.numeric(subset(ranks.df,(ranks.team=="Leganes"))["ranks.defense"]) * 
    mean(SmallData[,"away.score"])
  expectedGoals.sevilla
  # [1] 1.461535
  
  # Obtenemos las predicciones de Poisson para los una cantidad de goles X=0,1,2,...,6 para ambos
  # equipos utilizando los goles esperados por cada uno
  probs.leganes <- dpois(c(0:6),expectedGoals.leganes)
  probs.leganes
  # [1] 0.296635534 0.360486645 0.219040887 0.088729890 0.026957273 0.006551971 0.001327048
  probs.sevilla <- dpois(c(0:6),expectedGoals.sevilla)
  probs.sevilla
  # [1] 0.231880127 0.338900860 0.247657689 0.120653439 0.044084798 0.012886293 0.003138961
  # Podemos notar que para abos equipos, anotar 1 gol tiene la mayor probabilidad dentro de todos.
  # Así que calcularemos ahora la probabilidad de que empaten para ver si el 1-1 es un resultado realmente posible
  
  # Crearemos una matriz de las probabilidades conjuntas de que cada equipo anote una cierta cantidad de goles
  probsGoals <- rep(0,49)
  for(i in 0:6){
    for(j in 0:6){
      pos <- (i*7) + (j+1)
      probsGoals[pos] <- probs.leganes[i+1] * probs.sevilla[j+1]
    }
  }
  
  # Por último renombraremos las filas y columnas de la matriz
  m <- matrix(probsGoals, nrow = 7, ncol=7)
  colnames(m) <- c("0","1","2","3","4","5","6")
  rownames(m) <- c("0","1","2","3","4","5","6")
  m
  
  # Para calcular la probabilidad de empate hay que sumar la diagonal principal de la matriz
  sum(diag(m))
  # [1] 0.2571828

  
  # Con esto podemos darnos cuenta de que el resultado de empatar representa un 25% del resultado posible 
  # del encuentro, y cotejando con nuestro modelo de predicción de fbRanks, podemos ver que obtuvimos un 27% de probabilidad también
  # Y checando con el resultado original del encuentro, podemos darnos cuenta que efectivamente el resultado final fue 1-1
  #            date home.team away.team home.score away.score     
  #         2020-12-23   Leganes   Sevilla          1          1