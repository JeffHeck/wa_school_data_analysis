source("chart_scatter.R")

#' genSBADataframe
#' Returns a dataframe with SBA data and demographics for each school for the selected grade.
#' Filter parameters include a min school enrollment, min number of test takers
#'
#' Input data files used:
#'   DataFilesRaw//1_2_Demographic Information by School 2015.csv
#'   DataFilesRaw//2_23_SBA Scores by School 2014-2015.csv
#'
#' @param aGrade: Grade to filter on
#' @param aMinEnrollment: Min enrollment for schools to filter schools on
#' @param aMinTestTakers: Min number of test takers to filter schools on
#'
#' @return sba_dem: A dataframe with merged SBA data and demographics
#' @export
#'
#' @examples
#' sba_dem <- genSBADataframe()
genSBADataframe <-
  function(aGrade = 8, aMinEnrollment = 200, aMinTestTakers = 10) {
    #Read demographics file
    demographics <-
      read.csv("DataFilesRaw//1_2_Demographic Information by School 2015.csv")
    #Reduce to pertinent columns
    demographics <-
      demographics[,c(
        "PercentFreeorReducedPricedMeals","District","School","BuildingNumber","TotalEnrollment"
      )]
    #Read sba file
    sba <-
      read.csv("DataFilesRaw//2_23_SBA Scores by School 2014-2015.csv")
    #Filter on grade specified
    sba_filtered <- sba[sba$GradeTested == aGrade,]
    #Reduce to pertinent columns
    sba_filtered <- sba_filtered[,c(
      "GradeTested",
      "MathPercentMetStandardIncludingPrevPass","MathPercentLevel4","MathTotalTested",
      "ELAPercentMetStandardIncludingPrevPass","ELAPercentLevel4","ELATotalTested",
      "BuildingNumber"
    )]
    
    #Merge files on building number
    sba_dem <-
      merge(sba_filtered, demographics, by = "BuildingNumber")
    
    #Filter on min size school and number of test takers
    sba_dem <- sba_dem[sba_dem$TotalEnrollment > aMinEnrollment,]
    sba_dem <- sba_dem[sba_dem$MathTotalTested > aMinTestTakers,]
    sba_dem <- sba_dem[sba_dem$ELATotalTested > aMinTestTakers,]
    #Remove rows with NA in school name
    sba_dem <- sba_dem[!is.na(sba_dem$School),]
    #Reduce to pertinent columns
    sba_dem <-
      sba_dem[,c(
        "BuildingNumber","PercentFreeorReducedPricedMeals","District","School",
        "MathPercentMetStandardIncludingPrevPass","MathPercentLevel4",
        "ELAPercentMetStandardIncludingPrevPass","ELAPercentLevel4",
        "TotalEnrollment"
      )]
    
    #Sort
    sba_dem <-
      sba_dem[order(sba_dem$PercentFreeorReducedPricedMeals),]
    sba_dem
  }

#' plotSBAData
#' Uses the genSBADataframe() function to generate a data frame to then create charts (using the chartScatter() method)
#' for each school district.
#' @param aMinEnrollment: Size of school to filter on
#' @param aGrade: Grade to filter on
#'
#' @return
#' @export
#'
#' @examples
#' plotSBAData()
plotSBAData <- function(aMinEnrollment = 100, aGrade=8) {
  #aGrade range 3-8
  gradeString = paste(aGrade,"th",sep = "")
  if (aGrade == 3) {
    gradeString = paste("3rd")
  }
  sba_dem <-
    genSBADataframe(
      aGrade = aGrade, aMinEnrollment = aMinEnrollment, aMinTestTakers = 10
    )
  #Get list of districts
  sba_dem_districts <- sba_dem$District
  sba_dem_districts <-
    sba_dem_districts[!duplicated(sba_dem_districts)]
  sba_dem_districts <- sort(sba_dem_districts)
  
  #Process all districts
  for (i in 1:length(sba_dem_districts)) {
    district = sba_dem_districts[i]
    sba_dem_subset <- sba_dem[sba_dem$District == district,]
    
    #If subset too large (e.g. Seattle), split into 2 charts
    MAX_SUBSET = 38
    pointer = 1
    remaining = nrow(sba_dem_subset)
    sba_dem_subset_saved <- sba_dem_subset
    iterationNum = 1
    iterationsNeeded = ceiling(remaining / MAX_SUBSET)
    while (remaining > 0) {
      quantityToProcess = min(remaining, MAX_SUBSET)
      sba_dem_subset <-
        sba_dem_subset_saved[pointer:(pointer + quantityToProcess - 1),]
      chartFilename = paste(
        "ReportsAutoGenerated//SBA ",district," Schools ",gradeString," Grade Math 2015.png",sep = ""
      )
      chartTitle = paste(
        "WA Public Schools with ", gradeString," Graders with ",aMinEnrollment,"+ Students \n 2015 SBA Results (",
        district," Schools Highlighted)",sep = ""
      )
      if (iterationsNeeded > 1) {
        chartFilename = paste(
          "ReportsAutoGenerated//SBA ",district," Schools ",gradeString," Grade Math 2015 ",iterationNum," of ",iterationsNeeded,".png",
          sep = ""
        )
        chartTitle = paste(
          "WA Public Schools with ", gradeString," Graders with ",aMinEnrollment,"+ Students \n 2015 SBA Results (",
          district," Schools Highlighted ",iterationNum," of ",iterationsNeeded,")",sep = ""
        )
      }
      
      chartScatter(
        aX = sba_dem$PercentFreeorReducedPricedMeals, aY = sba_dem$MathPercentMetStandardIncludingPrevPass,
        aTitle = chartTitle,
        aXLabel = "% low income students \n \n Source: Office of Superintendent of Public Instruction, Washington State",
        aYLabel = paste("% of",gradeString,"Graders that Met Standard in Math"),
        aSubsetX = sba_dem_subset$PercentFreeorReducedPricedMeals,
        aSubsetY = sba_dem_subset$MathPercentMetStandardIncludingPrevPass, aShowSubset = T, aColor = "lightgray",
        aShowLegend = T, aLegend = sba_dem_subset$School, aShowFittedLine = T,
        aSavePlotFilename = chartFilename,
        aSavePlot = T
      )
      
      remaining = remaining - quantityToProcess
      pointer = pointer + quantityToProcess
      iterationNum = iterationNum + 1
    }
  }
}

#' plotSBADataAll
#' Generate all plots for selected grades
#'
#' @return
#' @export
#'
#' @examples
#' plotSBADataAll()
plotSBADataAll <- function() {
  plotSBAData(aGrade = 8)
}
