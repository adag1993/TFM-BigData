#source("http://bioconductor.org/biocLite.R")
#biocLite(c("graph", "Rgraphviz"))
library(stats) 
library(caret)
library(gdata)
library(Amelia)
library(dplyr)
library(ROCR)
library(caret)
library(e1071)
library(boot)
library(rcompanion)
library(fmsb)
library(bnlearn)
library(ROCR) 
library(Metrics)
library(xlsx)

#cat("\014") 
rm(list = ls())
CRASH_data_1 <- read.csv("C:/Users/Marta.Rodriguez/Desktop/OneDrive/TFM/CRASH_data-1.csv",na.strings=c("","NA"))

#View(CRASH_data_1)
datos.modelo <- subset(CRASH_data_1, select = 
                         c(SEX,AGE,EO_Cause,EO_Major.EC.injury,GCS_EYE,GCS_MOTOR,GCS_VERBAL,
                           PUPIL_REACT_LEFT,PUPIL_REACT_RIGHT,EO_Head.CT.scan,EO_1.or.more.PH,
                           EO_Subarachnoid.bleed,EO_Obliteration.3rdVorBC,
                           EO_Midline.shift..5mm,EO_Non.evac.haem,EO_Evac.haem,EO_Outcome,
                           EO_Symptoms,TH_Cause,TH_Major.EC.injury,TH_Head.CT.scan,TH_1.or.more.PH,TH_Subarachnoid.bleed,
                           TH_Obliteration.3rdVorBC,TH_Midline.shift..5mm,TH_Non.evac.haem,TH_Evac.haem,TH_Outcome,TH_Symptoms,GOS5,GOS8))


#***********************************************************************************
# Nombre: PREPARACION DE DATOS. FASE 1
# Descripción:  
# Autor:                      Fecha:              Modificación:     
# Modificación: 
# ***********************************************************************************

#Preparamos la variable de outcome
datos.modelo$outcome<-NA
datos.modelo$outcome[which(!is.na(datos.modelo$GOS5))]<-as.character(datos.modelo$GOS5[which(!is.na(datos.modelo$GOS5))])
datos.modelo$outcome[which(!is.na(datos.modelo$GOS8))]<-as.character(datos.modelo$GOS8[which(!is.na(datos.modelo$GOS8))])


#Si el Outcome es 1 o los sintomas son 6, el paciente fallece
datos.modelo$outcome[which(datos.modelo$EO_Outcome=="1" | datos.modelo$EO_Symptoms=="6" | datos.modelo$TH_Outcome=="1" | datos.modelo$TH_Symptoms=="6")]<-"D"



#Si tienen Outcome 4 y synthom 1 en el TH, entonces estan vivos y sin resultados finales
datos.modelo$outcome[which(is.na(datos.modelo$outcome) & datos.modelo$TH_Outcome=="4" & datos.modelo$TH_Symptoms=="1")]<-"ALIVE"
datos.modelo$outcome[which(is.na(datos.modelo$outcome) & is.na(datos.modelo$TH_Symptoms)& is.na(datos.modelo$TH_Outcome) & datos.modelo$EO_Outcome=="4" & datos.modelo$EO_Symptoms=="1")]<-"ALIVE"

#Los que no tengan datos sobre los sintomas, deberan estar en NODATA
datos.modelo$outcome[which(is.na(datos.modelo$outcome) & is.na(datos.modelo$TH_Symptoms)& is.na(datos.modelo$EO_Symptoms))]<-"NODATA"
#Los que se hayan transferido a otro hospital y en dicho hospital no se tengan datos
datos.modelo$outcome[which(is.na(datos.modelo$outcome) & datos.modelo$EO_Outcome=="2" & is.na(datos.modelo$TH_Outcome))]<-"NODATA"  

#Si los sintomas son de 4 o 5, entonces le consideramos por D
datos.modelo$outcome[which(is.na(datos.modelo$outcome) & datos.modelo$TH_Symptoms=="5")]<-"D"
datos.modelo$outcome[which(is.na(datos.modelo$outcome) & datos.modelo$TH_Symptoms=="4")]<-"D"
datos.modelo$outcome[which(is.na(datos.modelo$outcome) & datos.modelo$EO_Symptoms=="5"& is.na(datos.modelo$TH_Outcome))]<-"D"
datos.modelo$outcome[which(is.na(datos.modelo$outcome) & datos.modelo$EO_Symptoms=="4"& is.na(datos.modelo$TH_Outcome))]<-"D"

#Si el outcome es de 4 (alta) y el sintoma es de 9, entonces esta vivo, pero no tenemos resultados
datos.modelo$outcome[which(is.na(datos.modelo$outcome) & datos.modelo$EO_Outcome=="4" & datos.modelo$EO_Symptoms=="9"& is.na(datos.modelo$TH_Symptoms)& is.na(datos.modelo$TH_Outcome))]<-"ALIVE"
datos.modelo$outcome[which(is.na(datos.modelo$outcome) & datos.modelo$TH_Symptoms=="9")]<-"ALIVE"
datos.modelo$outcome[which(is.na(datos.modelo$outcome) & datos.modelo$EO_Symptoms=="9")]<-"ALIVE"

#Se han visto 3 elementos de NODATA, cuyos pacientes obtienen un estado de symptoma 4, 
#por lo que se envia a estado de fallecido, son datos anomalos.
datos.modelo$outcome[which(datos.modelo$outcome=="NODATA" & datos.modelo$TH_Symptoms=="4")]<-"D"

#Transformamos las variables a 2 unicas categorias D y MDGR que son las que se estudiaran.
datos.modelo$outcome[which(datos.modelo$outcome=="D")] <- "D"
datos.modelo$outcome[which(datos.modelo$outcome=="SD")] <- "D"
datos.modelo$outcome[which(datos.modelo$outcome=="SD-")] <- "D"
datos.modelo$outcome[which(datos.modelo$outcome=="SD*")] <- "D"
datos.modelo$outcome[which(datos.modelo$outcome=="SD+")] <- "D"
datos.modelo$outcome[which(datos.modelo$outcome=="GR")] <- "MDGR"
datos.modelo$outcome[which(datos.modelo$outcome=="GR-")] <- "MDGR"
datos.modelo$outcome[which(datos.modelo$outcome=="GR+")] <- "MDGR"
datos.modelo$outcome[which(datos.modelo$outcome=="MD")] <- "MDGR"
datos.modelo$outcome[which(datos.modelo$outcome=="MD-")] <- "MDGR"
datos.modelo$outcome[which(datos.modelo$outcome=="MD+")] <- "MDGR"
#datos.modelo$outcome[which(datos.modelo$outcome=="ALIVE")] <- "ALIVE"
factor(datos.modelo$outcome)


#datos.modeloNULL<-subset(datos.modelo, is.na(outcome))
#write.xlsx(datos.modeloNULL, "C:/Users/Marta.Rodriguez/Desktop/OneDrive/TFM/NULL.xlsx")
#datos.modeloNODATA<-subset(datos.modelo, outcome == "NODATA")
#write.xlsx(datos.modeloNODATA, "C:/Users/Marta.Rodriguez/Desktop/OneDrive/TFM/NODATA.xlsx")
#datos.modeloALIVE<-subset(datos.modelo, outcome == "ALIVE" )
#write.xlsx(datos.modeloALIVE, "C:/Users/Marta.Rodriguez/Desktop/OneDrive/TFM/ALIVE2.xlsx")
#datos.modeloDEATH<-subset(datos.modelo, outcome == "D")
#write.xlsx(datos.modeloDEATH, "C:/Users/Marta.Rodriguez/Desktop/OneDrive/TFM/DEATH.xlsx")
#datos.modeloMDGR<-subset(datos.modelo, outcome == "MDGR") 
#write.xlsx(datos.modeloMDGR, "C:/Users/Marta.Rodriguez/Desktop/OneDrive/TFM/MDGR.xlsx")

#factor(datos.modeloMDGR$TH_Symptoms)
#NROW(which(is.na(datos.modelo3$GOS5)&is.na(datos.modelo3$GOS8)))
#datos.modelo <- datos.modelo[is.na(datos.modelo$outcome),]

#***********************************************************************************
# Nombre: PREPARACION DE DATOS. SCANEADO DE MDGR
# Descripción:  
# Autor:                      Fecha:              Modificación:     
# Modificación: 
# ***********************************************************************************
#Si no tenemos datos de los scanner, los eliminamos.
datos.modelo$ESTADOESCANER<-NA

#Si esta escaneado 1 y no tiene datos de scanner, entonces lo ponemos a scaneado 2
datos.modelo$EO_Head.CT.scan[which((datos.modelo$outcome == "MDGR" | datos.modelo$outcome == "D") & datos.modelo$EO_Head.CT.scan=="1" 
                                   & is.na(datos.modelo$EO_1.or.more.PH)
                                   & is.na(datos.modelo$EO_Subarachnoid.bleed)
                                   & is.na(datos.modelo$EO_Obliteration.3rdVorBC)
                                   & is.na(datos.modelo$EO_Midline.shift..5mm)
                                   & is.na(datos.modelo$EO_Non.evac.haem)
                                   & is.na(datos.modelo$EO_Evac.haem)
                                     )]<-"2"

#Lo mismo con TH
datos.modelo$TH_Head.CT.scan[which((datos.modelo$outcome == "MDGR" | datos.modelo$outcome == "D") & datos.modelo$TH_Head.CT.scan=="1" 
                                   & is.na(datos.modelo$TH_1.or.more.PH)
                                   & is.na(datos.modelo$TH_Subarachnoid.bleed)
                                   & is.na(datos.modelo$TH_Obliteration.3rdVorBC)
                                   & is.na(datos.modelo$TH_Midline.shift..5mm)
                                   & is.na(datos.modelo$TH_Non.evac.haem)
                                   & is.na(datos.modelo$TH_Evac.haem)
)]<-"2"


datos.modelo$ESTADOESCANER[which((datos.modelo$outcome == "MDGR" | datos.modelo$outcome == "D") & datos.modelo$EO_Head.CT.scan=="1")]<-"SCANEADO"
datos.modelo$ESTADOESCANER[which((datos.modelo$outcome == "MDGR" | datos.modelo$outcome == "D") & datos.modelo$EO_Head.CT.scan=="2")]<-"NOSCANEADO"
datos.modelo$ESTADOESCANER[which((datos.modelo$outcome == "MDGR" | datos.modelo$outcome == "D") & is.na(datos.modelo$EO_Head.CT.scan) )]<-"ENANALISIS"



datos.modelo$ESTADOESCANER[which(datos.modelo$ESTADOESCANER == "SCANEADO" 
                           & datos.modelo$EO_Outcome=="2"
                           & is.na(datos.modelo$TH_1.or.more.PH)
                           & is.na(datos.modelo$TH_Subarachnoid.bleed)
                           & is.na(datos.modelo$TH_Obliteration.3rdVorBC)
                           & is.na(datos.modelo$TH_Midline.shift..5mm)
                           & is.na(datos.modelo$TH_Non.evac.haem)
                           & is.na(datos.modelo$TH_Evac.haem)
)]<-"ENANALISIS"

datos.modelo$ESTADOESCANER[which(datos.modelo$ESTADOESCANER == "NOSCANEADO" 
                           & datos.modelo$EO_Outcome=="2"
                           & !is.na(datos.modelo$TH_1.or.more.PH)
                           & !is.na(datos.modelo$TH_Subarachnoid.bleed)
                           & !is.na(datos.modelo$TH_Obliteration.3rdVorBC)
                           & !is.na(datos.modelo$TH_Midline.shift..5mm)
                           & !is.na(datos.modelo$TH_Non.evac.haem)
                           & !is.na(datos.modelo$TH_Evac.haem)
                          
)]<-"SCANEADO"


#Nos hemos dado cuenta que existen datos anomalos, que contienen varios escaneres, pero sin embargo, no se indica como
#escaneado, son los registros: 2628,3276,3279,8469,8655, etc. (En total son 12)
datos.modelo$EO_Head.CT.scan[which(datos.modelo$ESTADOESCANER == "NOSCANEADO"  
                           & !is.na(datos.modelo$EO_1.or.more.PH)
                           & !is.na(datos.modelo$EO_Subarachnoid.bleed)
                           & !is.na(datos.modelo$EO_Obliteration.3rdVorBC)
                           & !is.na(datos.modelo$EO_Midline.shift..5mm)
                           & !is.na(datos.modelo$EO_Non.evac.haem)
                           & !is.na(datos.modelo$EO_Evac.haem)
)]<-"1"
datos.modelo$ESTADOESCANER[which(datos.modelo$ESTADOESCANER == "NOSCANEADO"  
                           & !is.na(datos.modelo$EO_1.or.more.PH)
                           & !is.na(datos.modelo$EO_Subarachnoid.bleed)
                           & !is.na(datos.modelo$EO_Obliteration.3rdVorBC)
                           & !is.na(datos.modelo$EO_Midline.shift..5mm)
                           & !is.na(datos.modelo$EO_Non.evac.haem)
                           & !is.na(datos.modelo$EO_Evac.haem)
                           )]<-"SCANEADO"

#Nos hemos dado cuenta que existen datos anomalos, que no contienen completamente la variable de scanner a 2,
#se contiene la variable de TH (han sido mandados a otro hospital) y las todas las variables del scanner
#se encuentran en NA, por lo tanto se ha decidido poner la variable de CT.Scan a 2, e interpretar que no se realizaron
#los escaneres
datos.modelo$TH_Head.CT.scan[which(datos.modelo$ESTADOESCANER == "ENANALISIS"  
                                   & !is.na(datos.modelo$EO_Cause) 
                                   & !is.na(datos.modelo$EO_Major.EC.injury)
                                   & !is.na(datos.modelo$TH_Major.EC.injury)
)]<-"2"

datos.modelo$ESTADOESCANER[which(datos.modelo$ESTADOESCANER == "ENANALISIS"  
                                   & !is.na(datos.modelo$EO_Cause) 
                                   & !is.na(datos.modelo$EO_Major.EC.injury)
                                   & !is.na(datos.modelo$TH_Major.EC.injury)
)]<-"SCANEADO"


#Eliminamos los que no tengan el EC Injury en el TH
datos.modelo$ESTADOESCANER[which(datos.modelo$ESTADOESCANER == "SCANEADO"  & datos.modelo$EO_Outcome=="2" & is.na(datos.modelo$TH_Major.EC.injury))]<-"ENANALISIS"
#Eliminamos los que no tengan el EC Injury en el EO
datos.modelo$ESTADOESCANER[which(datos.modelo$ESTADOESCANER == "SCANEADO"  & is.na(datos.modelo$EO_Major.EC.injury))]<-"ENANALISIS"
#Eliminamos los que no tengan el EO_Outcome
datos.modelo$ESTADOESCANER[which(datos.modelo$ESTADOESCANER == "SCANEADO"  & is.na(datos.modelo$EO_Outcome))]<-"ENANALISIS"

#Cambiamos los datos anomalos del EO_MAJOR.EC
datos.modelo$EO_Major.EC.injury[which(datos.modelo$ESTADOESCANER == "SCANEADO" & datos.modelo$EO_Major.EC.injury==-1 )]<-1

#Comprobamos que no existan variables que contengan nulos
datos.modelo$ESTADOESCANER[which(datos.modelo$ESTADOESCANER == "SCANEADO" & (is.na(datos.modelo$EO_Cause ) | is.na(datos.modelo$EO_Symptoms)))]<-"ENANALISIS"


scaneadoVIVOS<-subset(datos.modelo, ESTADOESCANER == "SCANEADO" & datos.modelo$outcome == "MDGR")
noscaneadoVIVOS<-subset(datos.modelo, ESTADOESCANER == "NOSCANEADO" & datos.modelo$outcome == "MDGR") 
enalisisVIVOS<-subset(datos.modelo, ESTADOESCANER == "ENANALISIS" & datos.modelo$outcome == "MDGR")
scaneadosDEATH<-subset(datos.modelo, ESTADOESCANER == "SCANEADO" & datos.modelo$outcome == "D")
noscaneadoDEATH<-subset(datos.modelo, ESTADOESCANER == "NOSCANEADO" & datos.modelo$outcome == "D") 
enanalisisDEATH<-subset(datos.modelo, ESTADOESCANER == "ENANALISIS" & datos.modelo$outcome == "D")

final <- merge(scaneadoVIVOS, scaneadosDEATH, all=TRUE) 

#write.xlsx(final, "C:/Users/Marta.Rodriguez/Desktop/OneDrive/TFM/FINAL.xlsx")                   
#write.xlsx(scaneadosDEATH, "C:/Users/Marta.Rodriguez/Desktop/OneDrive/TFM/ESCANEADO_DEATHS.xlsx")
#write.xlsx(scaneadoVIVOS, "C:/Users/Marta.Rodriguez/Desktop/OneDrive/TFM/ESCANEADO.xlsx")
#write.xlsx(enanalisisDEATH, "C:/Users/Marta.Rodriguez/Desktop/OneDrive/TFM/ENANALISIS_DEATHS.xlsx")
#write.xlsx(enalisisVIVOS, "C:/Users/Marta.Rodriguez/Desktop/OneDrive/TFM/ENANALISIS.xlsx")
#write.xlsx(datos.modeloNOSCANEADO, "C:/Users/Marta.Rodriguez/Desktop/OneDrive/TFM/NOESCANEADO.xlsx")
#write.xlsx(datos.modeloENANALISIS, "C:/Users/Marta.Rodriguez/Desktop/OneDrive/TFM/ENANALISIS.xlsx")



#***********************************************************************************
# Nombre: PREPARACION DE DATOS. FASE 3
# Descripción:  
# Autor:                      Fecha:              Modificación:     
# Modificación: 
# ***********************************************************************************

#Creamos una columna con la union de las pupilas
final$pupils<-NA
final$pupils[which(final$PUPIL_REACT_LEFT=="1" & final$PUPIL_REACT_RIGHT=="1")] <- 1 #both reactive
final$pupils[which(final$PUPIL_REACT_LEFT=="3" & final$PUPIL_REACT_RIGHT=="1")] <- 1 #both reactive
final$pupils[which(final$PUPIL_REACT_LEFT=="1" & final$PUPIL_REACT_RIGHT=="3")] <- 1 #both reactive
final$pupils[which(final$PUPIL_REACT_LEFT=="1" & final$PUPIL_REACT_RIGHT=="2")] <- 2 #no response unilateral
final$pupils[which(final$PUPIL_REACT_LEFT=="2" & final$PUPIL_REACT_RIGHT=="1")] <- 2 #no response unilateral
final$pupils[which(final$PUPIL_REACT_LEFT=="3" & final$PUPIL_REACT_RIGHT=="2")] <- 2 #no response unilateral 
final$pupils[which(final$PUPIL_REACT_LEFT=="2" & final$PUPIL_REACT_RIGHT=="3")] <- 2 #no response unilateral 
final$pupils[which(final$PUPIL_REACT_LEFT=="2" & final$PUPIL_REACT_RIGHT=="2")] <- 3 #no response
final$pupils[which(final$PUPIL_REACT_LEFT=="3" & final$PUPIL_REACT_RIGHT=="3")] <- 4 #unable to asseses
factor(final$pupils)
#final <- final[,c(8,9,33)]
#write.xlsx(final, "C:/Users/Marta.Rodriguez/Desktop/OneDrive/TFM/ANALISISPUPILAR.xlsx")
NROW(final$pupils[which(final$pupils==1)])
NROW(final$pupils[which(final$pupils==2)])
NROW(final$pupils[which(final$pupils==3)])
NROW(final$pupils[which(final$pupils==4)])


NROW(final$EO_Outcome[which(final$EO_Outcome==2)])


#PHM
final$phm<-NA
final$phm[which(final$EO_Outcome=="2" & final$TH_Head.CT.scan=="1")] <- final$TH_1.or.more.PH[which(final$EO_Outcome=="2" & final$TH_Head.CT.scan=="1")]
final$phm[which(final$EO_Outcome!="2"  | final$TH_Head.CT.scan!="1")] <- final$EO_1.or.more.PH[which(final$EO_Outcome!="2" | final$TH_Head.CT.scan!="1")]

#SAH
final$sah<-NA
final$sah[which(final$EO_Outcome=="2" & final$TH_Head.CT.scan=="1")] <- final$TH_Subarachnoid.bleed[which(final$EO_Outcome=="2" & final$TH_Head.CT.scan=="1")]
final$sah[which(final$EO_Outcome!="2"  | final$TH_Head.CT.scan!="1")] <- final$EO_Subarachnoid.bleed[which(final$EO_Outcome!="2"  | final$TH_Head.CT.scan!="1")]

#OBLT
final$oblt<-NA
final$oblt[which(final$EO_Outcome=="2" & final$TH_Head.CT.scan=="1")] <- final$TH_Obliteration.3rdVorBC[which(final$EO_Outcome=="2" & final$TH_Head.CT.scan=="1")]
final$oblt[which(final$EO_Outcome!="2"  | final$TH_Head.CT.scan!="1")] <- final$EO_Obliteration.3rdVorBC[which(final$EO_Outcome!="2"  | final$TH_Head.CT.scan!="1")]

#mdls
final$mdls<-NA
final$mdls[which(final$EO_Outcome=="2" & final$TH_Head.CT.scan=="1")] <- final$TH_Midline.shift..5mm[which(final$EO_Outcome=="2" & final$TH_Head.CT.scan=="1")]
final$mdls[which(final$EO_Outcome!="2"  | final$TH_Head.CT.scan!="1")] <- final$EO_Midline.shift..5mm[which(final$EO_Outcome!="2"  | final$TH_Head.CT.scan!="1")]

#hmt
final$hmt<-NA
final$hmt[which(final$EO_Outcome=="2" & final$TH_Head.CT.scan=="1")] <- final$TH_Non.evac.haem[which(final$EO_Outcome=="2" & final$TH_Head.CT.scan=="1")]
final$hmt[which(final$EO_Outcome!="2"  | final$TH_Head.CT.scan!="1")] <- final$EO_Non.evac.haem[which(final$EO_Outcome!="2"  | final$TH_Head.CT.scan!="1")]


#write.xlsx(final, "C:/Users/Marta.Rodriguez/Desktop/OneDrive/TFM/FINALAUNADOS.xlsx")

#Reemplazamos las variables de outcome de categoricas a variables numericas 0 y 1
final$outcome[which(final$outcome=="D")] <- "1" #Fallece
final$outcome[which(final$outcome=="MDGR")] <- "0" #Vive
final$outcome<- as.integer(final$outcome)

#Eliminamos las variables que no necesitemos
final <- subset(final, select = 
                         c(SEX,AGE,EO_Cause,EO_Major.EC.injury,GCS_EYE,GCS_MOTOR,GCS_VERBAL,
                           pupils,phm,sah,oblt,mdls,hmt,outcome))

#Cambiamos los nombres de las variables
colnames(final)[colnames(final)=="SEX"] <- "sex"
colnames(final)[colnames(final)=="AGE"] <- "age"
colnames(final)[colnames(final)=="EO_Cause"] <- "cause"
colnames(final)[colnames(final)=="EO_Major.EC.injury"] <- "ec"
colnames(final)[colnames(final)=="GCS_EYE"] <- "eye"
colnames(final)[colnames(final)=="GCS_MOTOR"] <- "motor"
colnames(final)[colnames(final)=="GCS_VERBAL"] <- "verbal"

#write.xlsx(final, "C:/Users/Marta.Rodriguez/Desktop/OneDrive/TFM/FINALAUNADOS.xlsx")

#final <- final[which(!is.na(final$TH_Major.EC.injury) & (final$EO_Major.EC.injury != final$TH_Major.EC.injury)),c(4,19)]
#QUe diferencia hay entre los dos evac.haem?

#Borramos todos los NA
final<-na.omit(final)
NROW(final)

write.table(final, file = "C:/Users/Marta.Rodriguez/Desktop/OneDrive/TFM/TraumaticData.csv",row.names=FALSE, na="",col.names=TRUE, sep=",")

#datos.modelo[datos.modelo$AGE == -1, ]

#Vemos los valores nulos de cada variable
sapply(final,function(x) sum(is.na(x)))
sapply(final, function(x) length(unique(x)))
missmap(final, main = "Missing values vs observed")
NROW(final )


