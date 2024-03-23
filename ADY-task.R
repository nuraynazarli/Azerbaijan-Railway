library(readxl)
library(writexl)
library(dplyr)
library(tidyverse)
library(inspectdf)
library(timetk)
library(lubridate)
library(highcharter)
library(h2o)
library(tidymodels)
library(modeltime)

data <- read_xlsx("Texniki tapşırıq.xlsx")

# Sütun adlarının dəyişdirilməsi
# Sütun adlarındakı ilk hərfləri böyük yazılması
colnames(data) <- tools::toTitleCase(colnames(data))

# Adları arasındakı boşluqların silinməsi
colnames(data) <- gsub("\\s+", "", colnames(data))

# Uyğunsuz adların dəyişdirilməsi
data <- data %>%
  rename("İl" = "Year")

data$İl <- as.numeric(data$İl)
data$Ay <- as.numeric(data$Ay)
data$Ton <- as.numeric(data$Ton)

data %>% glimpse()

na_counts <- colSums(is.na(data))
columns_with_na <- names(na_counts[na_counts > 0])
total_nas <- sum(is.na(data))
unique_counts <- sapply(data, function(x) length(unique(x)))
unique_values <- lapply(data, unique)

# Datanın təmizlənməsi
data$Ay <- gsub(0.8,8,data$Ay)

data$YükQrupu <- gsub("  "," ",data$YükQrupu)
data$YükQrupu <- gsub("Təzə meyvə,giləmeyvə və tərəvəz.Fındıq","Meyvə-tərəvəz,giləmeyvə,fındıq",data$YükQrupu)
data$YükQrupu <- gsub("Təzə meyvə, giləmeyvə və tərəvəz. Fındıq","Meyvə-tərəvəz,giləmeyvə,fındıq",data$YükQrupu)

data$VaqonNövü <- gsub("\\$","",data$VaqonNövü)
data$VaqonNövü <- gsub("Kanteynr","Konteyner",data$VaqonNövü)

data$DaşınmaRejim <- gsub("idxal","İdxal",data$DaşınmaRejim)
data$DaşınmaRejim <- gsub("ıdxal","İdxal",data$DaşınmaRejim)
data$DaşınmaRejim <- gsub("Ixrac","İxrac",data$DaşınmaRejim)

data$GöndərənÖlkə <- gsub("Rus","Rusya",data$GöndərənÖlkə)
data$GöndərənÖlkə <- gsub("Rusyaiya","Rusya",data$GöndərənÖlkə)

data$TəyinatÖlkə <- gsub("Əfqanistan","Əfqanıstan",data$TəyinatÖlkə)

data$EkspeditorunAdı <- gsub("\"","",data$EkspeditorunAdı)
data$EkspeditorunAdı <- gsub(" A Z T R A N O I L  MƏHDUD MƏSULIYYƏTLI CƏMIYY","AZTRANSOIL MMC",data$EkspeditorunAdı)
data$EkspeditorunAdı <- gsub(" A Z T R A N S O I L  MƏHDUD MƏSULIYYƏTLI CƏMIYY","AZTRANSOIL MMC",data$EkspeditorunAdı)
data$EkspeditorunAdı <- gsub("Aztranoil MMC","AZTRANSOIL MMC",data$EkspeditorunAdı)
data$EkspeditorunAdı <- gsub("Marketinq və iqtisadi əməliyyatlar idarəsi","MARKETİNQ VƏ İQTİSADİ ƏMƏLİYYATLAR İDARƏSİ",data$EkspeditorunAdı)
data$EkspeditorunAdı <- gsub("MARKETINQ VƏ IQTISADI ƏMƏLIYYATLAR IDARƏSI","MARKETİNQ VƏ İQTİSADİ ƏMƏLİYYATLAR İDARƏSİ",data$EkspeditorunAdı)

data$SifarişçininAdı <- gsub("\"","",data$SifarişçininAdı)
data$SifarişçininAdı <- gsub("\\.","",data$SifarişçininAdı)
data$SifarişçininAdı <- gsub("AZ TRANS RAIL MƏHDUD MƏSULIYYƏTLI CƏMIYYƏTI","AZTRANSOIL MƏHDUD MƏSULİYYƏTLİ CƏMİYYƏTİ",data$SifarişçininAdı)
data$SifarişçininAdı <- gsub("MARKETINQ VƏ IQTISADI ƏMƏLIYYATLAR IDARƏSI","MARKETİNQ VƏ İQTİSADİ ƏMƏLİYYATLAR İDARƏSİ",data$SifarişçininAdı)
data$SifarişçininAdı <- gsub("O R B I T A MƏHDUD MƏSULIYYƏTLI CƏMIYYƏTI","ORBİTA MMC",data$SifarişçininAdı)
data$SifarişçininAdı <- gsub("AZƏRBAYCAN ŞƏKƏR ISTEHSALAT BIRLIYI M.M.C.","AZƏRBAYCAN ŞƏKƏR İSTEHSALAT BİRLİYİ MMC",data$SifarişçininAdı)
data$SifarişçininAdı <- gsub(" A Z T R A N S O I L  MƏHDUD MƏSULIYYƏTLI CƏMIYY","AZTRANSOIL MMC",data$SifarişçininAdı)
data$SifarişçininAdı <- gsub("Marketinq və iqtisadi əməliyyatlar idarəsi","MARKETİNQ VƏ İQTİSADİ ƏMƏLİYYATLAR İDARƏSİ",data$SifarişçininAdı)
data$SifarişçininAdı <- gsub("O R B I T A MMC","ORBİTA MMC",data$SifarişçininAdı)
data$SifarişçininAdı <- gsub("AZƏRBAYCAN ŞƏKƏR ISTEHSALAT BIRLIYI MMC","AZƏRBAYCAN ŞƏKƏR İSTEHSALAT BİRLİYİ MMC",data$SifarişçininAdı)
data$SifarişçininAdı <- gsub("AZƏRNEFTYAĞ NEFT EMALI ZAVODU","AZƏRNEFTYAĞ",data$SifarişçininAdı)

data$Tarix <- as.Date(paste(data$İl, data$Ay, "01", sep = "-"), format = "%Y-%m-%d")
data <- subset(data, select = -c(İl, Ay))
data <- data[, c(ncol(data), 1:(ncol(data)-1))]

# Kateqorik dəyişənlərin NA’lərini 1 dəyişənənin faktorlarına görə "mode" ilə doldurulması
na_rows <- data[apply(is.na(data), 1, any), ]

data$YükQrupu <- data$YükQrupu %>% as.factor()
data$VaqonNövü <- data$VaqonNövü %>% as.factor()
data$DaşınmaRejim <- data$DaşınmaRejim %>% as.factor()
data$TəyinatStansiyası <- data$TəyinatStansiyası %>% as.factor()
data$GöndərənStansiya <- data$GöndərənStansiya %>% as.factor()
data$GöndərənÖlkə <- data$GöndərənÖlkə %>% as.factor()
data$TəyinatÖlkə <- data$TəyinatÖlkə %>% as.factor()

x <- data[which(data$GöndərənÖlkə=="Kanada"),"YükQrupu"][[1]]
x <- x[!is.na(x)]
ux=unique(x)
mode_inc <- ux[match(x,ux) %>% tabulate() %>% which.max()]
data[is.na(data$YükQrupu) & data$GöndərənÖlkə=="Kanada","YükQrupu"] <- mode_inc

x <- data[which(data$GöndərənÖlkə=="Qazaxıstan"),"YükQrupu"][[1]]
x <- x[!is.na(x)]
ux=unique(x)
mode_inc <- ux[match(x,ux) %>% tabulate() %>% which.max()]
data[is.na(data$YükQrupu) & data$GöndərənÖlkə=="Qazaxıstan","YükQrupu"] <- mode_inc

x <- data[which(data$GöndərənÖlkə=="Rusya"),"YükQrupu"][[1]]
x <- x[!is.na(x)]
ux=unique(x)
mode_inc <- ux[match(x,ux) %>% tabulate() %>% which.max()]
data[is.na(data$YükQrupu) & data$GöndərənÖlkə=="Rusya","YükQrupu"] <- mode_inc

x <- data[which(data$GöndərənÖlkə=="Latviya"),"YükQrupu"][[1]]
x <- x[!is.na(x)]
ux=unique(x)
mode_inc <- ux[match(x,ux) %>% tabulate() %>% which.max()]
data[is.na(data$YükQrupu) & data$GöndərənÖlkə=="Latviya","YükQrupu"] <- mode_inc

x <- data[which(data$GöndərənÖlkə=="ABŞ"),"YükQrupu"][[1]]
x <- x[!is.na(x)]
ux=unique(x)
mode_inc <- ux[match(x,ux) %>% tabulate() %>% which.max()]
data[is.na(data$YükQrupu) & data$GöndərənÖlkə=="ABŞ","YükQrupu"] <- mode_inc

x <- data[which(data$GöndərənÖlkə=="№3-cü ölkələr"),"YükQrupu"][[1]]
x <- x[!is.na(x)]
ux=unique(x)
mode_inc <- ux[match(x,ux) %>% tabulate() %>% which.max()]
data[is.na(data$YükQrupu) & data$GöndərənÖlkə=="№3-cü ölkələr","YükQrupu"] <- mode_inc

x <- data[which(data$TəyinatÖlkə=="Azərbaycan"),"YükQrupu"][[1]]
x <- x[!is.na(x)]
ux=unique(x)
mode_inc <- ux[match(x,ux) %>% tabulate() %>% which.max()]
data[is.na(data$YükQrupu) & data$TəyinatÖlkə=="Azərbaycan","YükQrupu"] <- mode_inc

x <- data[which(data$TəyinatÖlkə=="Rusiya"),"YükQrupu"][[1]]
x <- x[!is.na(x)]
ux=unique(x)
mode_inc <- ux[match(x,ux) %>% tabulate() %>% which.max()]
data[is.na(data$YükQrupu) & data$TəyinatÖlkə=="Rusiya","YükQrupu"] <- mode_inc

x <- data[which(data$GöndərənÖlkə=="Rusya"),"VaqonNövü"][[1]]
x <- x[!is.na(x)]
ux=unique(x)
mode_inc <- ux[match(x,ux) %>% tabulate() %>% which.max()]
data[is.na(data$VaqonNövü) & data$GöndərənÖlkə=="Rusya","VaqonNövü"] <- mode_inc

x <- data[which(data$GöndərənÖlkə=="ABŞ"),"DaşınmaRejim"][[1]]
x <- x[!is.na(x)]
ux=unique(x)
mode_inc <- ux[match(x,ux) %>% tabulate() %>% which.max()]
data[is.na(data$DaşınmaRejim) & data$GöndərənÖlkə=="ABŞ","DaşınmaRejim"] <- mode_inc

x <- data[which(data$GöndərənÖlkə=="Azərbaycan"),"DaşınmaRejim"][[1]]
x <- x[!is.na(x)]
ux=unique(x)
mode_inc <- ux[match(x,ux) %>% tabulate() %>% which.max()]
data[is.na(data$DaşınmaRejim) & data$GöndərənÖlkə=="Azərbaycan","DaşınmaRejim"] <- mode_inc

x <- data[which(data$GöndərənÖlkə=="Rusya"),"DaşınmaRejim"][[1]]
x <- x[!is.na(x)]
ux=unique(x)
mode_inc <- ux[match(x,ux) %>% tabulate() %>% which.max()]
data[is.na(data$DaşınmaRejim) & data$GöndərənÖlkə=="Rusya","DaşınmaRejim"] <- mode_inc

x <- data[which(data$GöndərənÖlkə=="Qazaxıstan"),"DaşınmaRejim"][[1]]
x <- x[!is.na(x)]
ux=unique(x)
mode_inc <- ux[match(x,ux) %>% tabulate() %>% which.max()]
data[is.na(data$DaşınmaRejim) & data$GöndərənÖlkə=="Qazaxıstan","DaşınmaRejim"] <- mode_inc

x <- data[which(data$GöndərənÖlkə=="Ukrayna"),"DaşınmaRejim"][[1]]
x <- x[!is.na(x)]
ux=unique(x)
mode_inc <- ux[match(x,ux) %>% tabulate() %>% which.max()]
data[is.na(data$DaşınmaRejim) & data$GöndərənÖlkə=="Ukrayna","DaşınmaRejim"] <- mode_inc

x <- data[which(data$GöndərənÖlkə=="№3-cü ölkələr"),"DaşınmaRejim"][[1]]
x <- x[!is.na(x)]
ux=unique(x)
mode_inc <- ux[match(x,ux) %>% tabulate() %>% which.max()]
data[is.na(data$DaşınmaRejim) & data$GöndərənÖlkə=="№3-cü ölkələr","DaşınmaRejim"] <- mode_inc

x <- data[which(data$GöndərənÖlkə=="Kanada"),"DaşınmaRejim"][[1]]
x <- x[!is.na(x)]
ux=unique(x)
mode_inc <- ux[match(x,ux) %>% tabulate() %>% which.max()]
data[is.na(data$DaşınmaRejim) & data$GöndərənÖlkə=="Kanada","DaşınmaRejim"] <- mode_inc

x <- data[which(data$GöndərənÖlkə=="Gürcüstan"),"DaşınmaRejim"][[1]]
x <- x[!is.na(x)]
ux=unique(x)
mode_inc <- ux[match(x,ux) %>% tabulate() %>% which.max()]
data[is.na(data$DaşınmaRejim) & data$GöndərənÖlkə=="Gürcüstan","DaşınmaRejim"] <- mode_inc

x <- data[which(data$GöndərənÖlkə=="ABŞ"),"TəyinatStansiyası"][[1]]
x <- x[!is.na(x)]
ux=unique(x)
mode_inc <- ux[match(x,ux) %>% tabulate() %>% which.max()]
data[is.na(data$TəyinatStansiyası) & data$GöndərənÖlkə=="ABŞ","TəyinatStansiyası"] <- mode_inc

x <- data[which(data$TəyinatÖlkə=="Azərbaycan"),"GöndərənStansiya"][[1]]
x <- x[!is.na(x)]
ux=unique(x)
mode_inc <- ux[match(x,ux) %>% tabulate() %>% which.max()]
data[is.na(data$GöndərənStansiya) & data$TəyinatÖlkə=="Azərbaycan","GöndərənStansiya"] <- mode_inc

x <- data[which(data$TəyinatÖlkə=="Qazaxıstan"),"GöndərənStansiya"][[1]]
x <- x[!is.na(x)]
ux=unique(x)
mode_inc <- ux[match(x,ux) %>% tabulate() %>% which.max()]
data[is.na(data$GöndərənStansiya) & data$TəyinatÖlkə=="Qazaxıstan","GöndərənStansiya"] <- mode_inc

# Maşın öyrənməsi alqoritmlərinin dataya tətbiqi 
data <- data %>% 
  filter(YükAdı == "Баранина свежая, края хребтовые спинной и почечной частей, необваленные") %>% 
  select(Tarix, Ton)

data_tk <- data %>% tk_augment_timeseries_signature()

data_tk %>% glimpse()
data_tk %>% inspect_na()

df <- data_tk %>% 
  select(-contains("hour"),
         -contains("day"),
         -minute,-second,-am.pm) %>% 
  mutate_if(is.ordered,as.character) %>% 
  mutate_if(is.character,as.factor)

splits <- df %>% 
  time_series_split(assess = "6 month",cumulative = T)

train <- splits %>% training()
test <- splits %>% testing()

h2o.init()

train_h2o <- train %>% as.h2o()
test_h2o <- test %>% as.h2o()

y <- "Ton"
x <- df %>% select(-Ton) %>% names()

model_h2o <- h2o.automl(
  x=x,y=y,
  training_frame = train_h2o,
  validation_frame = test_h2o,
  stopping_metric = "RMSE",
  seed = 123,nfolds = 10,
  exclude_algos = "GLM",
  max_runtime_secs = 360
)

model_h2o@leaderboard %>% as.data.frame()
h2o_leader <- model_h2o@leader

pred_h2o <- h2o_leader %>% h2o.predict(test_h2o)

h2o_leader %>% 
  h2o.rmse(train = T,
           valid = T,
           xval = T)

error_tbl <- df %>% 
  filter(Tarix>=min(test$Tarix)) %>% 
  add_column(pred=pred_h2o %>% as_tibble() %>% pull(predict)) %>% 
  rename(actual=Ton) %>% 
  select(Tarix,actual,pred)

highchart() %>% 
  hc_xAxis(categories=error_tbl$Tarix) %>% 
  hc_add_series(data=error_tbl$actual,type='line',color='green',name='Actual') %>% 
  hc_add_series(data=error_tbl$pred,type='line',color='red',name='Predicted') %>% 
  hc_title(text='Predict')

new_data <- seq(as.Date("2014-12-01"),as.Date("2015-06-01"),"week") %>% 
  as_tibble() %>% 
  add_column(Ton=0) %>% 
  rename(Tarix=value) %>% 
  tk_augment_timeseries_signature() %>% 
  select(-contains("hour"),
         -contains("day"),
         -minute,-second,-am.pm) %>% 
  mutate_if(is.ordered,as.character) %>% 
  mutate_if(is.character,as.factor)

new_h2o <- new_data %>% as.h2o()

new_predictions <- h2o_leader %>% 
  h2o.predict(new_h2o) %>% 
  as_tibble() %>% 
  add_column(Tarix=new_data$Tarix) %>% 
  select(Tarix,Ton=predict)

df %>% 
  bind_rows(new_predictions) %>% 
  mutate(colors=c(rep('Actual',nrow(df)),rep('Predicated',nrow(new_predictions)))) %>% 
  hchart("line",hcaes(Tarix,Ton,group=colors)) %>% 
  hc_title(text='Forecast') %>% 
  hc_colors(colors = c('green','red'))
