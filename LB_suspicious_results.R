df = readxl::read_xlsx(path = '~/Desktop/UKM-рабочее/LB_20240325_073918.xlsx')
df <- df[-1,]
df = data.table::data.table(df)
df$LBORRES <- as.numeric(df$LBORRES)
df$mean_val_screen <- 0
df$std_screen <- 0

########################################################################################
# Convert units
# df[df$LBTEST == 'Гематокрит' & df$LBORRESU == 'л/л',]$LBORRES <-
#   df[df$LBTEST == 'Гематокрит' & df$LBORRESU == 'л/л',]$LBORRES * 100


df[df$LBTEST == 'Hemoglobin' & df$LBORRESU == 'g/dL',]$LBORRES <-
  df[df$LBTEST == 'Hemoglobin' & df$LBORRESU == 'g/dL',]$LBORRES * 10

########################################################################################

for (i in unique(df$LBTEST)){
  sel_data <- df[df$LBTEST == i & df$VISITNUM == '1',]
  if (nrow(sel_data) > 0){
    MEAN <- mean(sel_data$LBORRES, na.rm = TRUE)
    SD <- sd(sel_data$LBORRES, na.rm = TRUE)
    df[df$LBTEST == i,]$mean_val_screen <- MEAN
    df[df$LBTEST == i,]$std_screen <- SD
  }
}

df$z <- (df$LBORRES - df$mean_val_screen)/df$std_screen
out <- df[(df$z > 3.5 | df$z < -3.5) & df$LBNRIND != 'Normal' & df$LBCLSIG %in% 'No',]

########################################################################################

# out[out$LBTEST == 'Гематокрит' & out$LBORRESU == 'л/л',]$LBORRES <-
#   out[out$LBTEST == 'Гематокрит' & out$LBORRESU == 'л/л',]$LBORRES / 100


out[out$LBTEST == 'Hemoglobin' & out$LBORRESU == 'g/dL',]$LBORRES <-
  out[out$LBTEST == 'Hemoglobin' & out$LBORRESU == 'g/dL',]$LBORRES / 10

########################################################################################

out <- subset(out, select = -c(mean_val_screen:z))
openxlsx::write.xlsx(out,'~/Desktop/UKM-рабочее/res/LB_suspicious_results.xlsx')
