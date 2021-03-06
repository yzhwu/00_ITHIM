###################### ITHIM application for Equity Analysis - Injury Module ################
############################ Two Race Categories Version ######################
library(ggplot2)

#set your working directory
setwd("~/Documents/02_Work/14_GitHub/00_ITHIM/01_Data/06_Equity Analysis")

# Prevent scientific notation
options(scipen = 100)

# number of traffic modes, injuried types, and road types
nTrafficModeV <- 6L #victim mode
nTrafficModeS <- 7L #striking mode (include one-party)
nInjuriedType <- 2L #fatal & serious
ModeNames <- c("bike","walk","motorcycle","car","truck","bus") #traffic mode
RoadTypes <- c("local","arterial","highway") # road type
nRoadType <- length(RoadTypes)

# disease burden
dbNames <- c('Deaths','DALYs')

# county names
countyNames <- c("El Dorado","Placer","Sacramento","Sutter","Yolo","Yuba")

# input the vehicle distance data
#PersonVehicleDist.2012 <- read.csv('06_PersonVehicleDistance/00_PersonVehicleDistance_Baseline.csv')
#PersonVehicleDist.2020 <- read.csv('06_PersonVehicleDistance/01_PersonVehicleDistance_2020.csv')
#PersonVehicleDist.2036 <- read.csv('06_PersonVehicleDistance/02_PersonVehicleDistance_2036.csv')
#PersonVehicleDist.2027 <- read.csv('06_PersonVehicleDistance/03_PersonVehicleDistance_2027.csv')
#PersonVehicleDist.S1 <- read.csv('06_PersonVehicleDistance/04_PersonVehicleDistance_S1.csv')
#PersonVehicleDist.S2 <- read.csv('06_PersonVehicleDistance/05_PersonVehicleDistance_S2.csv')
#PersonVehicleDist.S3 <- read.csv('06_PersonVehicleDistance/06_PersonVehicleDistance_S3.csv')
#PersonVehicleDist.C1 <- read.csv('06_PersonVehicleDistance/07_PersonVehicleDistance_Custom1.csv')
#PersonVehicleDist.C2 <- read.csv('06_PersonVehicleDistance/08_PersonVehicleDistance_Custom2.csv')
#PersonVehicleDist.C3 <- read.csv('06_PersonVehicleDistance/09_PersonVehicleDistance_Custom3.csv')

# input the population data for each race group
Pop.file.race <- read.csv("01_Population/02_Population_byRace_2012.csv")
Pop.file.twoRaces <- cbind(Pop.file.race[,c(2,3)],rowSums(Pop.file.race[,c(4,6,8)]),rowSums(Pop.file.race[,c(5,7,9)]))
colnames(Pop.file.twoRaces) <- c('male.white','female.white','male.other','female.other')

# input the US population
US.pop <- read.csv("01_Population/01_Population_US_EA.csv")
US.pop <- matrix(cbind(US.pop[,2],US.pop[,3]),16,1)

# input the GBD data
GBD.injury <- read.csv("04_GBD/14_GBD_US_TrafficInjury.csv")

#distribution of age and gender group
#age.gender.dist.injury <- matrix(1/16,53,4)
#colnames(age.gender.dist.injury) <- c('male.white','female.white','male.other','female.other')

#### function for reading csv files of injury data and VMT
# data source: SWITRS 2006-2016 (Statewide Integrated Traffic Reporting System)
# data source: Transportation Injury Mapping System (TIMS by US Berkeley)
# 11-year annual average number of road traffic injuries
input.csv <- function(countyID,scenarioID){
  #scenarioID: 0-2012,1-2020,2-2036,3-2027,4-S1,5-S2,6-S3,7-C1,8-C2,9-C3
  #countyID: 1-ELD,2-PLA,3-SAC,4-SUT,5-YOL,6-YUB
  
  #test
  #countyID = 2
  #scenarioID = 0
  #pop.file.names <- list.files(path = "01_Population")
  
  #filenames.injury <- readLines("05_baseline injury/01_filenames_twoRaces.txt")
  #temp.Other <- read.csv(filenames.injury[2*countyID]) 
  filenames.injury <- list.files(path = '05_baseline injury')[1:6]
  
  # build a list to store the baseline injury data sets for all races
  injury.list <- rep(list(matrix(NA,36,7)),2)
  temp <- read.csv(paste0('05_baseline injury/',filenames.injury[countyID])) 
  injury.list[[1]] <- temp[1:36,2:8] # non hispanic white
  injury.list[[2]] <- temp[38:73,2:8] # other three races

  names(injury.list)<- c('NHW','Others')
  
  # input the person & vehicle distance matrix
  # include the distance distribution for three road types and occupancy for each traffic mode
  # filenames.vmt <- readLines("06_PersonVehicleDistance/by county/01_filenames_twoRaces.txt")
  # 
  # person.vehicle.distance_input <- read.csv(filenames.vmt[countyID])
  # person.vehicle.distance_input.list <- rep(list(matrix(NA,34,1)),2)
  # for (i in 1:2){
  #   person.vehicle.distance_input.list[[i]]<-person.vehicle.distance_input[1:34,(6*i-3):(6*i+1)]
  # }
  # names(person.vehicle.distance_input.list)<- c('NHW','Others')
  
  filenames.dist <- list.files(path='06_PersonVehicleDistance')
  person.vehicle.distance_input.matrix <- matrix(NA,34,2)
  person.vehicle.distance_input <- read.csv(paste0('06_PersonVehicleDistance/',filenames.dist[scenarioID+1]))
  colnames(person.vehicle.distance_input.matrix)<- c('NHW','Others')
  
  #NHW
  person.vehicle.distance_input.matrix[,1]<-person.vehicle.distance_input[1:34,(4*countyID-1)]
  #Other three races
  person.vehicle.distance_input.matrix[,2]<-person.vehicle.distance_input[1:34,(4*countyID+1)]
  
  #GBD
  GBD.local.white <-GBD.injury[,2:5]*matrix(cbind(Pop.file.twoRaces[(9*countyID-8):(9*countyID-1),1],Pop.file.twoRaces[(9*countyID-8):(9*countyID-1),2]),16,1)/US.pop
  GBD.local.Other <-GBD.injury[,2:5]*matrix(cbind(Pop.file.twoRaces[(9*countyID-8):(9*countyID-1),3],Pop.file.twoRaces[(9*countyID-8):(9*countyID-1),4]),16,1)/US.pop
  
  return(list(
    injury.list=injury.list,
    person.vehicle.distance_input.matrix=person.vehicle.distance_input.matrix,
    GBD.local.white = GBD.local.white,
    GBD.local.Other = GBD.local.Other
  ))
}

##### Function of creating the matrix of baseline injuries #####
createBaselineInjury <- function(injury){
  # build the list of baseline injury data (the sheet "Baseline injuries" in ITHIM spreadsheet)
  injury.baseline <- list()
  for (n in 1:(nInjuriedType*nRoadType)){
    injury.baseline[[n]] <-injury[((n-1)*nTrafficModeV+1):(nTrafficModeV*n),1:(nTrafficModeS)]
  }
  injury.baseline <- lapply(injury.baseline,function(x) {
    row.names(x) <- ModeNames[1:6]
    return (x)
  })
  names(injury.baseline) <- c("local.fatal","arterial.fatal","highway.fatal","local.serious","arterial.serious","highway.serious")
  
  return(injury.baseline)
}

##### Function of create the Distribution of Person & Vehicle Distance by Road Types  #####

#create the sheet "Dist by road type" in ITHIM spreadsheet 
createScenarioInjuryMultiplier <- function(countyID,scenarioID){
  
  #test
  #person.vehicle.distance_input = person.vehicle.distance_input.list$NHW
  #countyID = 1
  #scenarioID=2
  
  ### for baseline ###
  # person distance for all modes (miles per day)
  # source: CHTS2012 & NHTS2009
  t.person.distance.baseline <- input.csv(countyID,scenarioID = 0)
  t.person.distance.baseline.NHW <- t.person.distance.baseline$person.vehicle.distance_input.matrix[1:6,1]
  t.person.distance.baseline.Other <- t.person.distance.baseline$person.vehicle.distance_input.matrix[1:6,2]
  
  # matrix of distance (person) distribution by road types and modes for baseline (%)
  # data source: for walk and bike, hard coded estimate; for other modes, CHTS2012
  percent.person.baseline.NHW <- percent.person.baseline.Other <- matrix(NA,nrow=6,ncol=3,dimnames=list(ModeNames,c("local","arterial","highway")))
  percent.person.baseline.NHW[,1]<-t.person.distance.baseline$person.vehicle.distance_input.matrix[8:13,1]
  percent.person.baseline.NHW[,2]<-t.person.distance.baseline$person.vehicle.distance_input.matrix[15:20,1]
  percent.person.baseline.NHW[,3]<-t.person.distance.baseline$person.vehicle.distance_input.matrix[22:27,1]
  
  percent.person.baseline.Other[,1]<-t.person.distance.baseline$person.vehicle.distance_input.matrix[8:13,2]
  percent.person.baseline.Other[,2]<-t.person.distance.baseline$person.vehicle.distance_input.matrix[15:20,2]
  percent.person.baseline.Other[,3]<-t.person.distance.baseline$person.vehicle.distance_input.matrix[22:27,2]
  
  # matrix of distance (person) by road types and modes for baseline (miles per day)
  distance.baseline.person.NHW <- t.person.distance.baseline.NHW * percent.person.baseline.NHW
  distance.baseline.person.Other <- t.person.distance.baseline.Other * percent.person.baseline.Other
  
  # matrix of occupancy
  # source: hard coded estimate & CHTS2012
  occ.baseline.NHW <- t.person.distance.baseline$person.vehicle.distance_input.matrix[29:34,1]
  occ.baseline.Other <- t.person.distance.baseline$person.vehicle.distance_input.matrix[29:34,2]
  
  ### for scenario ###
  # person distance (person) for all road types and all modes (miles per day)
  # data source: MTC Travel Model One
  t.person.distance.scenario <-input.csv(countyID,scenarioID = scenarioID)
    
  t.person.distance.scenario.NHW <- t.person.distance.scenario$person.vehicle.distance_input.matrix[1:6,1]
  t.person.distance.scenario.Other <- t.person.distance.scenario$person.vehicle.distance_input.matrix[1:6,2]
  
  # matrix of distance (person) distribution by road types and modes for scenario (%)
  # data source: for walk and bike, hard coded estimate; for other modes, MTC Travel Model One
  percent.person.scenario.NHW <- percent.person.scenario.Other <- matrix(NA,nrow=6,ncol=3,dimnames=list(ModeNames,c("local","arterial","highway")))
  percent.person.scenario.NHW[,1] <- t.person.distance.scenario$person.vehicle.distance_input.matrix[8:13,1]
  percent.person.scenario.NHW[,2] <- t.person.distance.scenario$person.vehicle.distance_input.matrix[15:20,1]
  percent.person.scenario.NHW[,3] <- t.person.distance.scenario$person.vehicle.distance_input.matrix[22:27,1]
  
  percent.person.scenario.Other[,1] <- t.person.distance.scenario$person.vehicle.distance_input.matrix[8:13,2]
  percent.person.scenario.Other[,2] <- t.person.distance.scenario$person.vehicle.distance_input.matrix[15:20,2]
  percent.person.scenario.Other[,3] <- t.person.distance.scenario$person.vehicle.distance_input.matrix[22:27,2]
  
  # matrix of distance (person) by road types for scenario (miles per day)
  distance.scenario.person.NHW <- t.person.distance.scenario.NHW * percent.person.scenario.NHW
  distance.scenario.person.Other <- t.person.distance.scenario.Other * percent.person.scenario.Other
  
  # matrix of occupancy
  # source: hard coded estimate & MTC Travel Model One
  occ.scenario.NHW <- t.person.distance.scenario$person.vehicle.distance_input.matrix[29:34,1]
  occ.scenario.Other <- t.person.distance.scenario$person.vehicle.distance_input.matrix[29:34,2]
  
  # matrix of distance (vehicle) by road types (miles per day)
  distance.baseline.vehicle.NHW <- distance.baseline.person.NHW/occ.baseline.NHW
  distance.baseline.vehicle.Other <- distance.baseline.person.Other/occ.baseline.Other
  
  distance.scenario.vehicle.NHW <- distance.scenario.person.NHW/occ.scenario.NHW
  distance.scenario.vehicle.Other <- distance.scenario.person.Other/occ.scenario.Other
  
  # combine those matrix into a list
  dist<-list(
    distance.baseline.person.NHW = distance.baseline.person.NHW,
    distance.baseline.person.Other = distance.baseline.person.Other,
    
    distance.scenario.person.NHW = distance.scenario.person.NHW,
    distance.scenario.person.Other = distance.scenario.person.Other,
    
    distance.baseline.vehicle.NHW = distance.baseline.vehicle.NHW,
    distance.baseline.vehicle.Other = distance.baseline.vehicle.Other,
    
    distance.scenario.vehicle.NHW = distance.scenario.vehicle.NHW,
    distance.scenario.vehicle.Other = distance.scenario.vehicle.Other
  )
  
  ### create the multiplier
  # safety factors (source: hard coded estimate)
  str.veh.safety.RR <- 0.5
  speed.safety <- 1.0
  other <- 1.0
  victim.safety <- 0.5
  
  # compute the list of scenario injury multiplier (i:row;j:col;k:road type)
  scenario.multiplier.NHW <- scenario.multiplier.Other <- rep(list((matrix(NA,nrow=nTrafficModeV,ncol=nTrafficModeS,dimnames=list(ModeNames,c(ModeNames,'one.party'))))), nRoadType)
  names(scenario.multiplier.NHW) <- names(scenario.multiplier.Other) <- RoadTypes
  
  # using different calculation method for different party numbers (1vs2)
  for (k in 1:3){ #road type
    for (i in 1:6){ #victim vehicle mode
      # for one party collisions
      scenario.multiplier.NHW[[k]][i,7]<- 
        (dist$distance.scenario.person.NHW[i,k]/dist$distance.baseline.person.NHW[i,k])^victim.safety*speed.safety*other
      scenario.multiplier.Other[[k]][i,7]<- 
        (dist$distance.scenario.person.Other[i,k]/dist$distance.baseline.person.Other[i,k])^victim.safety*speed.safety*other
      
      for (j in 1:6){ #striking vehicle mode
        scenario.multiplier.NHW[[k]][i,j] <- 
          (dist$distance.scenario.person.NHW[i,k]/dist$distance.baseline.person.NHW[i,k])^victim.safety*(dist$distance.scenario.vehicle.NHW[j,k]/dist$distance.baseline.vehicle.NHW[j,k])^str.veh.safety.RR*speed.safety*other
        scenario.multiplier.Other[[k]][i,j] <- 
          (dist$distance.scenario.person.Other[i,k]/dist$distance.baseline.person.Other[i,k])^victim.safety*(dist$distance.scenario.vehicle.Other[j,k]/dist$distance.baseline.vehicle.Other[j,k])^str.veh.safety.RR*speed.safety*other
        
      }
    }
  }
  return(list(
    scenario.multiplier.NHW=scenario.multiplier.NHW,
    scenario.multiplier.Other=scenario.multiplier.Other
  )
  )
  
}

##### Scenario Injuries #####
#compute the scenario injuries (the product of baseline injury and scenario multiplier)
computeScenarioInjury <- function(injury.baseline,scenario.multiplier){
  
  injury.scenario.NHW <- mapply(function(x,y) x*y,injury.baseline$NHW,c(scenario.multiplier$scenario.multiplier.NHW,scenario.multiplier$scenario.multiplier.NHW),SIMPLIFY=FALSE)
  injury.scenario.Other <- mapply(function(x,y) x*y,injury.baseline$Other,c(scenario.multiplier$scenario.multiplier.Other,scenario.multiplier$scenario.multiplier.Other),SIMPLIFY=FALSE)
  
  return(list(
    injury.scenario.NHW = injury.scenario.NHW,
    injury.scenario.Other = injury.scenario.Other
  ))
}

##### Injuries results #####

# createInjuryResults <- function(injury.baseline,injury.scenario){
#   injury.number.2020 <- injury.number.2036 <- rep(list((matrix(NA,nrow=nTrafficModeV,ncol=nTrafficModeS,dimnames=list(ModeNames,c(ModeNames,'one.party'))))), 4)
#   names(injury.number.2020) <- names(injury.number.2036) <- c("baseline fatalities","baseline injuries","scenario fatalities","scenario injuries")
#   
#   #computing the total injury number
#   injury.number.2020[[1]] <- injury.baseline[[1]]+injury.baseline[[2]]+injury.baseline[[3]]#baseline fatalities
#   injury.number.2020[[2]] <- injury.baseline[[4]]+injury.baseline[[5]]+injury.baseline[[6]]#baseline serious injuries
#   injury.number.2020[[3]] <- injury.scenario$injury.scenario.2020[[1]]+injury.scenario$injury.scenario.2020[[2]]+injury.scenario$injury.scenario.2020[[3]]#scenario fatalities
#   injury.number.2020[[4]] <- injury.scenario$injury.scenario.2020[[4]]+injury.scenario$injury.scenario.2020[[5]]+injury.scenario$injury.scenario.2020[[6]]#scenario serious injuries
#   
#   injury.number.2036[[1]] <- injury.baseline[[1]]+injury.baseline[[2]]+injury.baseline[[3]]#baseline fatalities
#   injury.number.2036[[2]] <- injury.baseline[[4]]+injury.baseline[[5]]+injury.baseline[[6]]#baseline serious injuries
#   injury.number.2036[[3]] <- injury.scenario$injury.scenario.2036[[1]]+injury.scenario$injury.scenario.2036[[2]]+injury.scenario$injury.scenario.2036[[3]]#scenario fatalities
#   injury.number.2036[[4]] <- injury.scenario$injury.scenario.2036[[4]]+injury.scenario$injury.scenario.2036[[5]]+injury.scenario$injury.scenario.2036[[6]]#scenario serious injuries
#   
#   
#   # replace the NA with 0
#   injury.number.2020 <- lapply(injury.number.2020,function(x) {
#     x[is.na(x)]=0 
#     return(x)})
#   injury.number.2036 <- lapply(injury.number.2036,function(x) {
#     x[is.na(x)]=0 
#     return(x)})
#   
#   # compute the RR
#   injury.RR.2020 <- injury.RR.2036 <- rep(list((matrix(NA,nrow=nTrafficModeV+1,ncol=3,dimnames=list(c(ModeNames[1:6],"total"),c("baseline","scenario","RR"))))), 2)
#   names(injury.RR.2020) <- names(injury.RR.2036) <- c("fatalities","serious injuries") 
#   for (i in 1:2) {
#     injury.RR.2020[[i]][1:6,1] <- rowSums(injury.number.2020[[i]])
#     injury.RR.2020[[i]][1:6,2] <- rowSums(injury.number.2020[[i+2]])
#     injury.RR.2020[[i]][7,1:2] <- colSums(injury.RR.2020[[i]][1:6,1:2])
#     injury.RR.2020[[i]][,3] <- injury.RR.2020[[i]][,2]/injury.RR.2020[[i]][,1]
#     #injury.RR.2020[[i]][,3] <- replace(injury.RR.2020[[i]][,3],is.na(injury.RR.2020[[i]][,3]),1)
#     
#     injury.RR.2036[[i]][1:6,1] <- rowSums(injury.number.2036[[i]])
#     injury.RR.2036[[i]][1:6,2] <- rowSums(injury.number.2036[[i+2]])
#     injury.RR.2036[[i]][7,1:2] <- colSums(injury.RR.2036[[i]][1:6,1:2])
#     injury.RR.2036[[i]][,3] <- injury.RR.2036[[i]][,2]/injury.RR.2036[[i]][,1]
#     #injury.RR.2036[[i]][,3] <- replace(injury.RR.2036[[i]][,3],is.na(injury.RR.2036[[i]][,3]),1)
#     
#     
#   }
#   
#   return(list(
#     injury.number.2020=injury.number.2020,
#     injury.number.2036=injury.number.2036,
#     injury.RR.2020=injury.RR.2020,
#     injury.RR.2036=injury.RR.2036
#   ))
# }

createInjuryResults <- function(countyID,scenarioID){
  #test
  #countyID=2
  #scenarioID=1
  
  injury.list <- input.csv(countyID = countyID,scenarioID = 0)[[1]]
  
  # baseline injury
  injury.baseline.byRace <-  lapply(injury.list,function(x) createBaselineInjury(x))
  
  # scenario multiplier
  scenario.multiplier.byRace <- createScenarioInjuryMultiplier(countyID = countyID,scenarioID = scenarioID)
  
  # scenario injury
  injury.scenario.byRace <- computeScenarioInjury(injury.baseline.byRace,scenario.multiplier.byRace)
  
  # compute the injury by race group
  total.injury.baseline.NHW <- lapply(injury.baseline.byRace$NHW,sum) 
  total.injury.baseline.Other <- lapply(injury.baseline.byRace$Others,sum) 
  
  total.injury.scenario.NHW <- lapply(injury.scenario.byRace$injury.scenario.NHW,sum) 
  total.injury.scenario.Other <- lapply(injury.scenario.byRace$injury.scenario.Other,sum) 
  
  # compute the relative risk of fatality for each race group
  RR.fatality.NHW <- (total.injury.scenario.NHW[[1]]+total.injury.scenario.NHW[[2]]+total.injury.scenario.NHW[[3]])/(total.injury.baseline.NHW[[1]]+total.injury.baseline.NHW[[2]]+total.injury.baseline.NHW[[3]])
  RR.fatality.Other <-(total.injury.scenario.Other[[1]]+total.injury.scenario.Other[[2]]+total.injury.scenario.Other[[3]])/(total.injury.baseline.Other[[1]]+total.injury.baseline.Other[[2]]+total.injury.baseline.Other[[3]])
  
  # compute the relative risk of serious injuries for each race group
  RR.serious.NHW <-(total.injury.scenario.NHW[[4]]+total.injury.scenario.NHW[[5]]+total.injury.scenario.NHW[[6]])/(total.injury.baseline.NHW[[4]]+total.injury.baseline.NHW[[5]]+total.injury.baseline.NHW[[6]])
  RR.serious.Other <- (total.injury.scenario.Other[[4]]+total.injury.scenario.Other[[5]]+total.injury.scenario.Other[[6]])/(total.injury.baseline.Other[[4]]+total.injury.baseline.Other[[5]]+total.injury.baseline.Other[[6]])
  
  # Reduction.fatality.NHW <- (total.injury.baseline.NHW[[1]]+total.injury.baseline.NHW[[2]]+total.injury.baseline.NHW[[3]])-
  #   (total.injury.scenario.NHW[[1]]+total.injury.scenario.NHW[[2]]+total.injury.scenario.NHW[[3]])
  # 
  # Reduction.fatality.Other <- total.injury.baseline.Other[[1]]+total.injury.baseline.Other[[2]]+total.injury.baseline.Other[[3]]-
  #   (total.injury.scenario.Other[[1]]+total.injury.scenario.Other[[2]]+total.injury.scenario.Other[[3]])
  # 
  # Reduction.serious.NHW <- total.injury.baseline.NHW[[4]]+total.injury.baseline.NHW[[5]]+total.injury.baseline.NHW[[6]]-
  #   (total.injury.scenario.NHW[[4]]+total.injury.scenario.NHW[[5]]+total.injury.scenario.NHW[[6]])
  # 
  # Reduction.serious.Other <- total.injury.baseline.Other[[4]]+total.injury.baseline.Other[[5]]+total.injury.baseline.Other[[6]]-
  #   (total.injury.scenario.Other[[4]]+total.injury.scenario.Other[[5]]+total.injury.scenario.Other[[6]])
  
  # GBD by race groups
  GBD.white.temp <- input.csv(countyID = countyID,scenarioID = 0)[[3]]
  GBD.other.temp <- input.csv(countyID = countyID,scenarioID = 0)[[4]]
  
  # compute the reduction of deaths and DALYs by using the RR computed above
  Reduction.Death.white.disaggr <- matrix(GBD.white.temp[,1]*(1-RR.fatality.NHW),16,1)
  Reduction.Death.other.disaggr <- matrix(GBD.other.temp[,1]*(1-RR.fatality.Other),16,1)

  Reduction.yll.white.disaggr <- matrix(GBD.white.temp[,2]*(1-RR.fatality.NHW),16,1)
  Reduction.yll.other.disaggr <- matrix(GBD.other.temp[,2]*(1-RR.fatality.Other),16,1)

  Reduction.yld.white.disaggr <- matrix(GBD.white.temp[,3]*(1-RR.serious.NHW),16,1)
  Reduction.yld.other.disaggr <- matrix(GBD.other.temp[,3]*(1-RR.serious.Other),16,1)

  Reduction.DALYs.white.disaggr <- Reduction.yll.white.disaggr+Reduction.yld.white.disaggr
  Reduction.DALYs.other.disaggr <- Reduction.yll.other.disaggr+Reduction.yld.other.disaggr
  
  return(list(
    # RR.fatality.NHW = RR.fatality.NHW,
    # RR.fatality.Other = RR.fatality.Other,
    # 
    # RR.serious.NHW =RR.serious.NHW,
    # RR.serious.Other = RR.serious.Other
  
    Reduction.Death.white=sum(Reduction.Death.white.disaggr),
    Reduction.Death.other=sum(Reduction.Death.other.disaggr),
    Reduction.DALYs.white=sum(Reduction.DALYs.white.disaggr),
    Reduction.DALYs.other=sum(Reduction.DALYs.other.disaggr),
    
    Reduction.Death.white.disaggr=Reduction.Death.white.disaggr,
    Reduction.Death.other.disaggr=Reduction.Death.other.disaggr,
    Reduction.DALYs.white.disaggr=Reduction.DALYs.white.disaggr,
    Reduction.DALYs.other.disaggr=Reduction.DALYs.other.disaggr
    
    
    
    # Reduction.fatality.NHW=Reduction.fatality.NHW,
    # Reduction.fatality.Other=Reduction.fatality.Other,
    # Reduction.serious.NHW=Reduction.serious.NHW,
    # Reduction.serious.Other=Reduction.serious.Other
  ))
}


#createInjuryResults(1,1)

# function for computing the age.std results
computeAgeStdOutput.injury <- function(scenario,countyID){
  #test
  #countyID = 2
  #scenario <- scenario.1
  
  #fatality.NHW.age.gender <- age.gender.dist.injury[((9*countyID-8):(9*countyID-1)),1:2]*scenario$Reduction.fatality.NHW/Pop.file.twoRaces[((9*countyID-8):(9*countyID-1)),1:2]*100000
  #fatality.Other.age.gender <- age.gender.dist.injury[((9*countyID-8):(9*countyID-1)),3:4]*scenario$Reduction.fatality.Other/Pop.file.twoRaces[((9*countyID-8):(9*countyID-1)),3:4]*100000
  
  #serious.NHW.age.gender <- age.gender.dist.injury[((9*countyID-8):(9*countyID-1)),1:2]*scenario$Reduction.serious.NHW/Pop.file.twoRaces[((9*countyID-8):(9*countyID-1)),1:2]*100000
  #serious.Other.age.gender <- age.gender.dist.injury[((9*countyID-8):(9*countyID-1)),3:4]*scenario$Reduction.serious.Other/Pop.file.twoRaces[((9*countyID-8):(9*countyID-1)),3:4]*100000
  
  fatality.NHW.age.gender <- scenario$Reduction.Death.white.disaggr/matrix(cbind(Pop.file.twoRaces[((9*countyID-8):(9*countyID-1)),1],Pop.file.twoRaces[((9*countyID-8):(9*countyID-1)),2]),16,1)*100000
  fatality.Other.age.gender <- scenario$Reduction.Death.other.disaggr/matrix(cbind(Pop.file.twoRaces[((9*countyID-8):(9*countyID-1)),3],Pop.file.twoRaces[((9*countyID-8):(9*countyID-1)),4]),16,1)*100000
  
  DALYs.NHW.age.gender <- scenario$Reduction.DALYs.white.disaggr/matrix(cbind(Pop.file.twoRaces[((9*countyID-8):(9*countyID-1)),1],Pop.file.twoRaces[((9*countyID-8):(9*countyID-1)),2]),16,1)*100000
  DALYs.Other.age.gender <- scenario$Reduction.DALYs.other.disaggr/matrix(cbind(Pop.file.twoRaces[((9*countyID-8):(9*countyID-1)),1],Pop.file.twoRaces[((9*countyID-8):(9*countyID-1)),2]),16,1)*100000
  
  age.std.fatality.NHW <- sum(fatality.NHW.age.gender * US.pop)/sum(US.pop)
  age.std.fatality.other <- sum(fatality.Other.age.gender * US.pop)/sum(US.pop)
  
  age.std.DALYs.NHW <- sum(DALYs.NHW.age.gender * US.pop)/sum(US.pop)
  age.std.DALYs.other <- sum(DALYs.Other.age.gender * US.pop)/sum(US.pop)
  
  return(list(
    age.std.fatality.NHW=age.std.fatality.NHW,
    age.std.fatality.other=age.std.fatality.other,
    age.std.DALYs.NHW =age.std.DALYs.NHW,
    age.std.DALYs.other=age.std.DALYs.other
  ))
  
}


# barID: 1-future years,2-Scenarios,3-customized
# typeID: 1-raw,2-age.std
DFforFigure.injury <- function(barID,countyID,typeID){
  #test
  #barID = 1
  #countyID = 2
  #typeID = 1
  
  reduction.fatality.value <- reduction.DALYs.value <-matrix(NA,6,1)
  
  if (barID == 1){#future years
    scenario.1 <- createInjuryResults(countyID = countyID,scenarioID = 1)#2020
    scenario.2 <- createInjuryResults(countyID = countyID,scenarioID = 3)#2027
    scenario.3 <- createInjuryResults(countyID = countyID,scenarioID = 2)#2036
    
    scenario.name  <- rep(c('2020','2027','2036'),each= 2)
    
  }else if (barID==2){#scenarios
    scenario.1 <- createInjuryResults(countyID = countyID,scenarioID = 4)
    scenario.2 <- createInjuryResults(countyID = countyID,scenarioID = 5)
    scenario.3 <- createInjuryResults(countyID = countyID,scenarioID = 6)
    
    scenario.name  <- rep(c('S1','S2','S3'),each= 2)
    
  }else if(barID==3){#customized
    scenario.1 <- createInjuryResults(countyID = countyID,scenarioID = 7)
    scenario.2 <- createInjuryResults(countyID = countyID,scenarioID = 8)
    scenario.3 <- createInjuryResults(countyID = countyID,scenarioID = 9)
    
    scenario.name  <- rep(c('C1','C2','C3'),each= 2)
  }
  
  if (typeID == 2){
    scenario.1 <- computeAgeStdOutput.injury(scenario.1,countyID)
    scenario.2 <- computeAgeStdOutput.injury(scenario.2,countyID)
    scenario.3 <- computeAgeStdOutput.injury(scenario.3,countyID)
  }
  
  # matrix of death reduction
  reduction.fatality.value[1,1] <-scenario.1[[1]]
  reduction.fatality.value[2,1] <-scenario.1[[2]]
  reduction.fatality.value[3,1] <-scenario.2[[1]]
  reduction.fatality.value[4,1] <-scenario.2[[2]]
  reduction.fatality.value[5,1] <-scenario.3[[1]]
  reduction.fatality.value[6,1] <-scenario.3[[2]]
   
  # matrix of DALYs reduction
  reduction.DALYs.value[1,1] <-scenario.1[[3]]
  reduction.DALYs.value[2,1] <-scenario.1[[4]]
  reduction.DALYs.value[3,1] <-scenario.2[[3]]
  reduction.DALYs.value[4,1] <-scenario.2[[4]]
  reduction.DALYs.value[5,1] <-scenario.3[[3]]
  reduction.DALYs.value[6,1] <-scenario.3[[4]]
  
  # reduction.fatality.value[1,1] <-scenario.1$Reduction.fatality.NHW
  # reduction.fatality.value[2,1] <-scenario.1$Reduction.fatality.Other
  # reduction.fatality.value[3,1] <-scenario.2$Reduction.fatality.NHW
  # reduction.fatality.value[4,1] <-scenario.2$Reduction.fatality.Other
  # reduction.fatality.value[5,1] <-scenario.3$Reduction.fatality.NHW
  # reduction.fatality.value[6,1] <-scenario.3$Reduction.fatality.Other
  # 
  # reduction.serious.value[1,1] <-scenario.1$Reduction.serious.NHW
  # reduction.serious.value[2,1] <-scenario.1$Reduction.serious.Other
  # reduction.serious.value[3,1] <-scenario.2$Reduction.serious.NHW
  # reduction.serious.value[4,1] <-scenario.2$Reduction.serious.Other
  # reduction.serious.value[5,1] <-scenario.3$Reduction.serious.NHW
  # reduction.serious.value[6,1] <-scenario.3$Reduction.serious.Other
  
  raceGroup <- rep(c("1.White",'2.Other'),3)
  
  # build the data frame
  df.fatality <- data.frame(Scenario=scenario.name,DemogrGroup=raceGroup,V1 =(reduction.fatality.value))
  df.DALYs <- data.frame(Scenario=scenario.name,DemogrGroup=raceGroup,V1 =(reduction.DALYs.value))
  
  return(list(
    df.fatality=df.fatality,
    df.DALYs=df.DALYs
  ))
}
# 
# output.result <- function(countyID){
#   # countyID: 1-ELD,2-PLA,3-SAC,4-SUT,5-YOL,6-YUB
#   #countyID=1
#   injury.list <- input.csv(countyID = countyID)[[1]]
#   person.vehicle.distance_input.list <- input.csv(countyID = countyID)[[2]]
#   
#   #obtain the ITHIM sheet "Baseline injuries"
#   injury.baseline.byRace <-  lapply(injury.list,function(x) createBaselineInjury(x))
#   
#   #compute the "Scenario Injury Multiplier"
#   scenario.multiplier.byRace <- lapply(person.vehicle.distance_input.list,function(x) createScenarioInjuryMultiplier(x))
#   
#   #compute the scenario injuries
#   injury.scenario.byRace <- mapply(function(x,y) computeScenarioInjury(x,y),injury.baseline.byRace,scenario.multiplier.byRace,SIMPLIFY = FALSE)
#   
#   #Summarize the injury results
#   injury.result.byRace <- mapply(function(x,y) createInjuryResults(x,y),injury.baseline.byRace,injury.scenario.byRace,SIMPLIFY = FALSE)
#   
#   #format the output file  
#   cutting.line.col <- matrix(c('2020 fatal','2020 serious','2036 fatal','2036 serious',rep('',24)),7,4,byrow = TRUE)
#   NHW <- cbind(injury.result.byRace[[1]]$injury.RR.2020$fatalities,cutting.line.col[,1],injury.result.byRace[[1]]$injury.RR.2020$`serious injuries`,cutting.line.col[,2],
#                injury.result.byRace[[1]]$injury.RR.2036$fatalities,cutting.line.col[,3],injury.result.byRace[[1]]$injury.RR.2036$`serious injuries`,cutting.line.col[,4],matrix(c('NHW',rep('',6)),7,1))
#   Others <- cbind(injury.result.byRace[[2]]$injury.RR.2020$fatalities,cutting.line.col[,1],injury.result.byRace[[2]]$injury.RR.2020$`serious injuries`,cutting.line.col[,2],
#                injury.result.byRace[[2]]$injury.RR.2036$fatalities,cutting.line.col[,3],injury.result.byRace[[2]]$injury.RR.2036$`serious injuries`,cutting.line.col[,4],matrix(c('NHB',rep('',6)),7,1))
#   #NHO <- cbind(injury.result.byRace[[3]]$injury.RR.2020$fatalities,cutting.line.col[,1],injury.result.byRace[[3]]$injury.RR.2020$`serious injuries`,cutting.line.col[,2],
#    #            injury.result.byRace[[3]]$injury.RR.2036$fatalities,cutting.line.col[,3],injury.result.byRace[[3]]$injury.RR.2036$`serious injuries`,cutting.line.col[,4],matrix(c('NHO',rep('',6)),7,1))
#   #HO <-  cbind(injury.result.byRace[[4]]$injury.RR.2020$fatalities,cutting.line.col[,1],injury.result.byRace[[4]]$injury.RR.2020$`serious injuries`,cutting.line.col[,2],
#    #            injury.result.byRace[[4]]$injury.RR.2036$fatalities,cutting.line.col[,3],injury.result.byRace[[4]]$injury.RR.2036$`serious injuries`,cutting.line.col[,4],matrix(c('HO',rep('',6)),7,1))
#   
#   cutting.line.row <- matrix('',1,17)
#   output <- rbind(NHW,cutting.line.row,Others)
#   
#   return(output)
# }


# barID: 1-future years,2-Scenarios,3-customized
# yaxisID: 1-Death total; 2-Death age.std; 3-serious injury total; 4-serious injury age.std
# typeID : 1-raw,2-age.std
plot.shiny.app.injury <- function(countyID, barID, yaxisID){
  #test
  #countyID = 1
  #barID = 1
  #yaxisID = 1
  
  if (yaxisID == 1){ #death total
    
    
    if (countyID%in%c(1:6)){ # for county
      df.result.injury <- DFforFigure.injury(barID = barID,countyID = countyID,typeID = 1)
      
      plot.title <- paste0(countyNames[countyID],': Reduction in Total Deaths from Traffic Injury Module')
      
      ggplot(data = df.result.injury$df.fatality, mapping = aes(x = factor(DemogrGroup), y = V1,fill = Scenario)) + 
        geom_bar(stat = 'identity',width = 0.5, position = position_dodge(0.5))+xlab('Demographic Group')+ylab('Total Death Reduction')+
        geom_text(aes(label=round(V1,1)),color="black",size=3.5,vjust=-0.5,position = position_dodge(0.5))+
        ggtitle(plot.title)
      
    }else if (countyID==7){ #for region wide
      
      df.region <- NULL
      
      for (i in 1:6){
        df.temp <- DFforFigure.injury(barID = barID,i,typeID = 1)
        
        df.region <- rbind(df.region,df.temp$df.fatality)
        
      }
      df.region$county <- rep(countyNames,each = 6)
      plot.title <- paste0('Region Wide: Reduction in Total Deaths from Traffic Injury Module')
      
      ggplot(data = df.region, mapping = aes(x = factor(DemogrGroup), y = V1,fill = Scenario)) + 
        geom_bar(stat = 'identity',width = 0.5, position = position_dodge(0.5))+xlab('Demographic Group')+ylab('Total Death Reduction')+
        #geom_text(aes(label=round(V1,1)),color="black",size=3.5,vjust=-0.5,position = position_dodge(0.5))+
        facet_wrap(~county)+ggtitle(plot.title)
      
      
    }
    
    
  }else if (yaxisID == 2){ # death age.std
    
    if (countyID %in% c(1:6)){ # for county
      df.result.injury <- DFforFigure.injury(barID = barID,countyID = countyID,typeID = 2)
      
      plot.title <- paste0(countyNames[countyID],': Age-Standardized Reduction in Total Deaths from Traffic Injury Module')
      
      ggplot(data = df.result.injury$df.fatality, mapping = aes(x = factor(DemogrGroup), y = V1,fill = Scenario)) + 
        geom_bar(stat = 'identity',width = 0.5, position = position_dodge(0.5))+xlab('Demographic Group')+ylab('Death Reduction Rate (per 100,000 population)')+
        geom_text(aes(label=round(V1,1)),color="black",size=3.5,vjust=-0.5,position = position_dodge(0.5))+
        ggtitle(plot.title)
      
    }else if (countyID==7){ # for region wide
      df.region <- NULL
      
      for (i in 1:6){
        df.temp <- DFforFigure.injury(barID = barID,i,typeID = 2)
        
        df.region <- rbind(df.region,df.temp$df.fatality)
        
      }
      df.region$county <- rep(countyNames,each = 6)
      plot.title <- paste0('Region Wide: Age-Standardized Reduction in Total Deaths from Traffic Injury Module')
      
      ggplot(data = df.region, mapping = aes(x = factor(DemogrGroup), y = V1,fill = Scenario)) + 
        geom_bar(stat = 'identity',width = 0.5, position = position_dodge(0.5))+xlab('Demographic Group')+ylab('Death Reduction Rate (per 100,000 population)')+
        #geom_text(aes(label=round(V1,1)),color="black",size=3.5,vjust=-0.5,position = position_dodge(0.5))+
        facet_wrap(~county)+ggtitle(plot.title)
    }
    
    
  }else if (yaxisID == 3){ # DALYs total
    
    if (countyID%in%c(1:6)){
      df.result.injury <- DFforFigure.injury(barID = barID,countyID = countyID,typeID = 1)
      plot.title <- paste0(countyNames[countyID],': Reduction in Total DALYs from Traffic Injury Module')
      
      ggplot(data = df.result.injury$df.DALYs, mapping = aes(x = factor(DemogrGroup), y = V1,fill = Scenario)) + 
        geom_bar(stat = 'identity',width = 0.5, position = position_dodge(0.5))+xlab('Demographic Group')+ylab('Total DALYs Reduction')+
        geom_text(aes(label=round(V1,1)),color="black",size=3.5,vjust=-0.5,position = position_dodge(0.5))+
        ggtitle(plot.title)
      
    }else if (countyID ==7){
      df.region <- NULL
      
      for (i in 1:6){
        df.temp <- DFforFigure.injury(barID = barID,i,typeID = 1)
        
        df.region <- rbind(df.region,df.temp$df.DALYs)
        
      }
      df.region$county <- rep(countyNames,each = 6)
      plot.title <- paste0('Region Wide: Reduction in Total DALYs from Traffic Injury Module')
      
      ggplot(data = df.region, mapping = aes(x = factor(DemogrGroup), y = V1,fill = Scenario)) + 
        geom_bar(stat = 'identity',width = 0.5, position = position_dodge(0.5))+xlab('Demographic Group')+ylab('Total DALYs Reduction')+
        #geom_text(aes(label=round(V1,1)),color="black",size=3.5,vjust=-0.5,position = position_dodge(0.5))+
        facet_wrap(~county)+ggtitle(plot.title)
      
    }
    
    
  }else if (yaxisID ==4){ # DALYs age.std
    
    if (countyID%in%c(1:6)){
      df.result.injury <- DFforFigure.injury(barID = barID,countyID = countyID,typeID = 2)
      
      plot.title <- paste0(countyNames[countyID],': Age-Standardized Reduction in Total DALYs from Traffic Injury Module')
      
      ggplot(data = df.result.injury$df.DALYs, mapping = aes(x = factor(DemogrGroup), y = V1,fill = Scenario)) + 
        geom_bar(stat = 'identity',width = 0.5, position = position_dodge(0.5))+xlab('Demographic Group')+ylab('DALYs Reduction Rate (per 100,000 population)')+
        geom_text(aes(label=round(V1,1)),color="black",size=3.5,vjust=-0.5,position = position_dodge(0.5))+
        ggtitle(plot.title)
    }else if (countyID==7){
      
      df.region <- NULL
      
      for (i in 1:6){
        df.temp <- DFforFigure.injury(barID = barID,i,typeID = 2)
        
        df.region <- rbind(df.region,df.temp$df.DALYs)
        
      }
      df.region$county <- rep(countyNames,each = 6)
      plot.title <- paste0('Region Wide: Age-Standardized Reduction in Total DALYs from Traffic Injury Module')
      
      ggplot(data = df.region, mapping = aes(x = factor(DemogrGroup), y = V1,fill = Scenario)) + 
        geom_bar(stat = 'identity',width = 0.5, position = position_dodge(0.5))+xlab('Demographic Group')+ylab('DALYs Reduction Rate (per 100,000 population)')+
        #geom_text(aes(label=round(V1,1)),color="black",size=3.5,vjust=-0.5,position = position_dodge(0.5))+
        facet_wrap(~county)+ggtitle(plot.title)
      
    }
    
    
  }else{
    message('wrong input')
  }
}

############################calculation example#################################


# barID: 1-future years,2-Scenarios,3-customized
# df.result.injury <- DFforFigure.injury(barID = 1,countyID = 3)
# ggplot(data = df.result.injury$df.serious, mapping = aes(x = factor(DemogrGroup), y = v,fill = Scenario)) + 
#   geom_bar(stat = 'identity',width = 0.5, position = position_dodge(0.5))+xlab('Demographic Group')+ylab('Fatalities')+
#   ggtitle("Reduction in total injuries")

plot.shiny.app.injury(countyID = 7, barID = 2,yaxisID = 1)

#write.csv(output.result(countyID=1),file = '00_HealthOutcome/00_Injury/11 year SWITRS updated/ELD.injuryresult_twoRaces.csv')
#write.csv(output.result(countyID=2),file = '00_HealthOutcome/00_Injury/11 year SWITRS updated/PLA.injuryresult_twoRaces.csv')
#write.csv(output.result(countyID=3),file = '00_HealthOutcome/00_Injury/11 year SWITRS updated/SAC.injuryresult_twoRaces.csv')
#write.csv(output.result(countyID=4),file = '00_HealthOutcome/00_Injury/11 year SWITRS updated/SUT.injuryresult_twoRaces.csv')
#write.csv(output.result(countyID=5),file = '00_HealthOutcome/00_Injury/11 year SWITRS updated/YOL.injuryresult_twoRaces.csv')
#write.csv(output.result(countyID=6),file = '00_HealthOutcome/00_Injury/11 year SWITRS updated/YUB.injuryresult_twoRaces.csv')
