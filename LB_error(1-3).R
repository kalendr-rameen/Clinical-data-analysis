library(dplyr)
library(data.table)
library(openxlsx)
library(readxl)
####################################################################################################
# Load data and expected values for analysis

# Загрузка ожидаемых значений
expected_values <- read_excel(
  path = '~/Desktop/WORK/TNP-STEMI-III/2024.03.29_Ожидаемые значения лабораторных показателей.xlsx',
  col_names = c('Res_ID', 'Test_type', 'Test', 'Units', 'Low_limit', 'High_limit'),
  skip = 1
) %>% filter(Res_ID == 'TNP-STEMI-III')

# Загрузка и предобработка данных
DT <- read_excel('~/Desktop/WORK/TNP-STEMI-III/LB_20240325_121009.xlsx') %>%
  slice(2:n()) %>%
  clean_numeric_data() %>%
  .[LBCAT %in% c("Complete blood count", "Blood chemistry")]

####################################################################################################
#Get LABTEST AND Patient ID, where >=2  boundary exist

# Анализ нарушений границ
bad_data <- get_boundary_violations(DT)

####################################################################################################
# Get all result and limit outs of expected values 

# Получение всех строк с множественными границами
bad_data_details <- DT[DT[, .I[USUBJID %in% bad_data$USUBJID & 
                              LBTEST %in% bad_data$LBTEST & 
                              LBORRESU %in% bad_data$LBORRESU]]]

# Поиск выбросов
outliers <- find_outliers(DT, expected_values)

####################################################################################################
# Congragulations !!! If all previous rows of code are all executed you can save all files to '.xlsx' format

# Определение путей для сохранения
output_path <- '~/Desktop/WORK/TNP-STEMI-III/'

# Сохранение результатов
write.xlsx(bad_data_details, paste0(output_path, 'LB_limits_changed.xlsx'))
write.xlsx(outliers$results_outliers, paste0(output_path, 'LB_results_outliers.xlsx'))
write.xlsx(outliers$limits_outliers, paste0(output_path, 'LB_limits_outlier.xlsx'))
