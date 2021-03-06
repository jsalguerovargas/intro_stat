# CONFIGURACIONES

library(tidyverse); library(UsingR)
options(scipen = 999)

# ============= UNIDAD 1 COMPARACI�N DE MEDIAS T-TEST ==============

# importar la data de la muestra
dat <- read.csv("femaleMiceWeights.csv")

# crear vector de control y tratamiento
control <- dat$Bodyweight[dat$Diet=="chow"] %>% mean()
tratamiento <- dat$Bodyweight[dat$Diet=="hf"] %>% mean()

# calcular diferencias 
obsdiff <- mean(tratamiento) - mean(control)

# obtener diferencias medias
mean(obsdiff) # <- variable aleatoria

# importar la data de "la poblaci�n"
poblacion <- read.csv("femaleControlsPopulation.csv")

# extraemos aleatoriamente 12 sujetos, e imprimimos medias para ver diferencias
for (i in 1:3) {
  temp.samp <- sample(poblacion$Bodyweight, 12)
  print(mean(temp.samp))
  rm(temp.samp)
}

# == LA HIPOTESIS NULA (Ho)

control <- sample(poblacion$Bodyweight, 12)
tratamiento <- sample(poblacion$Bodyweight, 12)

tratamiento - control # imprimimos media bajo Ho

# Simulaci�n Monte Carlo 10.000 muestreos aleatorios. 
# Esto nos dar� la distribuci�n bajo Ho
null.dist <- replicate(10000,{
  control <- sample(poblacion$Bodyweight, 12)
  tratamiento <- sample(poblacion$Bodyweight, 12)
  mean(tratamiento) - mean(control) 
})


# Y llegamos al gran tema �probabilidad de obtener un resultado m�s extremo
# asumiendo que Ho = TRUE ??
mean(null.dist >= obsdiff) # <- p.valor


# == LAS DISTRIBUCIONES

data("father.son")

father.son <- father.son %>% na.omit()

# qu� es una distribuci�n??
father.son$sheight %>% sample(10) %>% round(1)

# = VISUALIZANDO DISTRIBUCIONES

# Funci�n de distribuci�n acumulada, F(a) ~ P(X <= a)
ggplot(father.son, aes(sheight)) +
  stat_ecdf() +
  labs(x = "Altura del hijo", y = "Frecuencia acumulada")

# Histograma (bins determinado por m�quina)
ggplot(father.son, aes(sheight)) +
  geom_histogram() +
  labs(x = "Altura del hijo", y = "Frecuencia")

# == DISTRIBUCI�N DE PROBABILIDADES

# Simulaci�n de Monte Carlo y ploteo de distribuci�n nula
null.dist <- replicate(100, {
  control <- sample(poblacion$Bodyweight,12)
  tratamiento <- sample(poblacion$Bodyweight,12)
  mean(tratamiento) - mean(control)
})

# convertir vector a df
null.dist <- as.data.frame(null.dist)

# plotear histograma de distribuci�n nula
ggplot(null.dist, aes(null.dist)) +
  geom_histogram() +
  labs(x="Peso", y = "Frecuencia")


# == DISTRIBUCI�N NORMAL
# rnorm(), solo requiere N, media y ds
# pnorm(), chance de obtener valor m�s extremo dado meadia y ds

pnorm(obsdiff, mean(null.dist$null.dist), 
               sd(null.dist$null.dist), 
               lower.tail = F)


# == POBLACIONES, MUESTRAS Y ESTIMACIONES

library(rafalib) # usaremos esta librer�a pa trabajar con sd y varianza
                 # poblacionales

# importar datos de ratas, ante experimento de dieta normal vs high fat
dat <- read.csv("mice_pheno.csv")

# capturar hembras en dieta de control
control.pop <- dat %>% filter(Sex == "F", Diet == "chow") %>%
  dplyr::select(Bodyweight) %>% unlist() # se sobrepone select() con librer�a MASS

# capturar hembras bajo hf
tratamiento.pop <- dat %>% filter(Sex == "F", Diet == "hf") %>%
  dplyr::select(Bodyweight) %>% unlist()

mean(tratamiento.pop) - mean(control.pop)

# teorema central del l�mite (CLT)
pnorm(2, mean = 0, sd = 1, lower.tail = F)

# solo conociendo media y sd poblacional, en una dist normal, podemos
# conocer que tan extremo es un valor (estimamos a partir de muestras)
# Y bajo CLT operamos por ley de grandes Numeros

# creamos data solo de ratas hembras
dat.f <- dat %>% filter(Sex == "F")

# ploteamos diferencias en pesos
ggplot(dat.f,aes(Bodyweight)) +
  geom_histogram(binwidth = 3.0) +
  geom_density(aes(y= 2.5 * ..count.., colour = "red"), 
               size = 1) +
  theme(legend.position = "none") +
  facet_grid(.~ Diet) +
  labs(x = "Pesos de ratas hembras", y = "frecuencia")

# plot de curva de cuantiles (qq plot)
ggplot(dat.f,aes(sample = Bodyweight)) +
  geom_qq() +
  geom_qq_line() +
  theme(legend.position = "none") +
  facet_grid(.~ Diet) +
  labs(x = "Cuantiles te�ricos", y = "Cuantiles observados")


# Simulamos distribuci�n para m�ltiples muestreos bajo supuesto de 
# poblaci�n conocida, y por lo tanto su desviaci�n
Ns <- c(3, 12, 25, 50)
res <- sapply(Ns, function(n){
  replicate(10000, {
    mean(sample(tratamiento.pop, n))-mean(sample(control.pop, n))
  })
})

# reconvertir a data frame
res <- res %>% as.data.frame()
n.label <- c("N_3", "N_12", "N_25", "N_50")
lista <- list()
for (i in seq(along=n.label)) {
  temp.res <- res[,i] %>% as.data.frame()
  temp.res$N <- n.label[i]
  lista[[i]] <- temp.res
}

# convertir lista a df y reorganizar factores
df.res <- do.call("rbind", lista)
df.res$N <- df.res$N %>% as.factor()
df.res$N <- factor(df.res$N, levels(df.res$N)[c(3,1,2,4)])

# borar objetos que no ulitzaremos
rm(i, n.label, res, lista, temp.res)

# qq plot para m�ltiples N
ggplot(df.res, aes(sample =.)) +
  geom_qq() +
  geom_qq_line() +
  facet_wrap(.~N, nrow = 2) +
  labs(x = "Cuantiles te�ricos", y = "Cuantiles observados")

# Pero bajo supuesto de poblaci�n desconocida,con desviaci�n 
# est�ndar estimada <- t de student

t.student.diff.n <- function(n){
  y <- sample(tratamiento.pop,n)
  x <- sample(control.pop,n)
  t.test(y, x)$statistic
}

# simulaci�n de Monte Carlo de t de student, para distintos N
res <- sapply(Ns, function(n){
  replicate(10000, t.student.diff.n(n))
})

# reconvertir a data frame
res <- res %>% as.data.frame()
n.label <- c("N_3", "N_12", "N_25", "N_50")
lista <- list()
for (i in seq(along=n.label)) {
  temp.res <- res[,i] %>% as.data.frame()
  temp.res$N <- n.label[i]
  lista[[i]] <- temp.res
}

# convertir lista a df y reorganizar factores
df.res <- do.call("rbind", lista)
df.res$N <- df.res$N %>% as.factor()
df.res$N <- factor(df.res$N, levels(df.res$N)[c(3,1,2,4)])

# eliminar objetos a no ultilizar
rm(t.student.diff.n)
rm(i, n.label, res, lista, temp.res)

# qq plot estimada por t de student, para distintos N
ggplot(df.res, aes(sample =.)) +
  geom_qq() +
  geom_qq_line() +
  facet_wrap(.~N, nrow = 2) +
  labs(x = "Cuantiles te�ricos", y = "Cuantiles observados t-student")


# == PRUEBA T DE STUDENT
# (dataset espec�fico de ratas hembras)
dat <- read.csv("femaleMiceWeights.csv")

# capturar hembras en dieta de control
control.pop <- dat %>% filter(Diet == "chow") %>%
  dplyr::select(Bodyweight) %>% unlist() 

# capturar hembras bajo hf
tratamiento.pop <- dat %>% filter(Diet == "hf") %>%
  dplyr::select(Bodyweight) %>% unlist()

# analizando funci�n t de student, t.test()
resultado <-t.test(dat$Bodyweight[dat$Diet=="hf"], 
                   dat$Bodyweight[dat$Diet=="chow"])

# imprimir resultado
resultado

# como se ve �sta diferencia bajo distribuci�n normal??
pnorm(resultado$statistic, lower.tail = F) * 2 # por 2 porque distribuci�n es
                                               # sim�trica

# diferencias?? Si, supuestos de CLT y t-student son distintos. 
# CLT -> dice que hay efecto cuando no lo hay (error de tipo I)
# t student -> dice que NO hay efecto cuando SI lo hay (error de tipo II)

# == INTERVALOS DE CONFIANZA EN T DE STUDENT

# imprimir CI
resultado$conf.int

# calculando CI a mano
# recorda que operamos bajo int�rvalo de 
# \bar{X}-Q*\frac{s_x}{\sqrt{N}}\leq\mu_x\leq\bar{X}+Q*\frac{s_x}{\sqrt{N}}  

# importamos poblaci�n de ratas
dat <- read.csv("mice_pheno.csv")

# extramos poblaci�n de ratas femeninas en dieta normal
pop.control <- dat %>% 
  filter(Sex == "F", Diet == "chow") %>% 
  dplyr::select(Bodyweight)

# muestra de ratas
muestra <- sample(pop.control$Bodyweight, 30)

# calculamos par�metros
media <- mean(muestra) # \bar{X}
Q <- qnorm(1 - 0.05/2) # Q
se <- sd(muestra)/sqrt(30) # \frac{s_x}{\sqrt{N}}
intervalo <- c(media - Q*se, media + Q*se) # \mu_x\pm\bar{X}+Q*\frac{s_x}{\sqrt{N}} 













