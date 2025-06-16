library(dplyr)
library(data.table)
####################################################################################################
# Load data and expected values for analysis

expected_values <- readxl::read_excel(path = '~/Desktop/WORK/TNP-STEMI-III/2024.03.29_Ожидаемые значения лабораторных показателей.xlsx', 
                                      col_names = c('Res_ID','Test_type','Test','Units','Low_limit','High_limit'), skip = 1)

expected_values <- expected_values[expected_values$Res_ID == 'TNP-STEMI-III',]

DT <- readxl::read_excel(path = '~/Desktop/WORK/TNP-STEMI-III/LB_20240325_121009.xlsx')

DT <- DT %>% slice(2:nrow(DT))
DT <- data.frame(lapply(DT, function(x) {gsub(",", ".", x)}))
DT <- transform(DT, LBORNRLO = as.numeric(LBORNRLO)
                , LBORNRHI = as.numeric(LBORNRHI)
                , LBORRES = as.numeric(LBORRES))
DT <- data.table(DT)

####################################################################################################
# Get all units w' count and test names

all_units_table <- DT %>% group_by(LBTEST,LBORRESU,LBCAT) %>% summarise(count_num = n())
all_units_table <- all_units_table[!is.na(all_units_table$LBORRESU),]

empty_units_table <- DT[is.na(DT$LBORRESU) & !is.na(DT$LBORRES) & DT$LBTEST != 'pH',] %>%
  group_by(LBTEST,LBORRESU,LBCAT) %>% summarise(count_num = n())

all_units_table <- rbindlist(list(all_units_table,empty_units_table))
all_units_table <- all_units_table[order(all_units_table$LBCAT,all_units_table$LBTEST),c(3,1,2,4)]

openxlsx::write.xlsx(all_units_table,'~/Desktop/WORK/TNP-STEMI-III/res/LB_units.xlsx')
