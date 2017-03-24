library(lubridate)
library(magrittr)
library(dplyr)
library(ggplot2)
library(zoo)
library(xts)
library(plotly)
library(readr)

water_year <- function(date) {
  ifelse(month(date) < 10, year(date)-1, year(date))
}

tempdata <- read_csv("cimis buntingville.csv", col_types = cols(`CIMIS Region` = col_skip(),
                                                                                   Date = col_date(format = "%m/%d/%Y")))
colnames(tempdata) <- c("id", "name", "date", "julian", "maxtemp", "qc1", "avgtemp", "qc2")
tempdata %<>% select(date, maxtemp, avgtemp)
tempdata %<>% mutate(avgtemp = ifelse(is.na(avgtemp), 51, avgtemp))

oro <- read_csv("C:/Users/U10543/Desktop/Oroville inflow.csv")
oro %<>% transmute(date = mdy(Date), inflow = as.numeric(Inflow), year = year(date), julian = yday(date),
                   wateryear = water_year(date))
oro <- left_join(oro, tempdata, by="date")
oro %<>% filter(!is.na(inflow), inflow >= 0, wateryear != 1993, wateryear != 2016) %>%
  group_by(wateryear) %>%
  mutate(cumflow = cumsum(inflow), cumdist = cumflow/max(cumflow), cumdiff = abs(cumdist - 0.5), wy_avgtemp = mean(avgtemp))
fif <- oro %>% filter(cumdiff == min(cumdiff))

ggplot(oro, aes(date, inflow)) + geom_line()
ggplot(fif, aes(wy_avgtemp, julian)) + geom_point()

l <- plot_ly(oro, x=~date, y=~cumflow, type="scatter", mode="lines", fill="tozeroy", color="darkred") %>%
  layout(xaxis = list(title = 'Inflow (cfs)'),
         yaxis = list(title = 'Date'))
l

l <- plot_ly(fif, x=~wy_avgtemp, y=~julian, text = ~year) %>%
     layout(title = "Oroville, date of peak reservoir inflow vs mean water year temperature",
            xaxis = list(title = 'Mean water year temperature (F)'),
            yaxis = list(title = 'Day of year'))
l


