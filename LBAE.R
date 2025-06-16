library(dplyr)
library(data.table)
df <- readxl::read_xlsx(path = '~/Desktop/UKM-рабочее/LB_20240325_073918.xlsx')
df <- df[-1,]
df <- df[,c('USUBJID','LBTEST','LBORRES','LBORRESU','LBORNRLO','LBORNRHI','LBNRIND','VISIT','LBDTC','LBDY')]
positive_table <- df[df$LBNRIND %in% c('High','Low'),]
positive_table <- positive_table[,c('USUBJID','LBTEST')]
positive_table <- positive_table %>% distinct()

sel_data <- data.frame(matrix(nrow = 0, ncol = length(df)))
colnames(sel_data) <-colnames(df)

for (i in 1:nrow(positive_table)){
  ID <- positive_table[i,]$USUBJID
  TEST <- positive_table[i,]$LBTEST
  sel_rows <- df[df$USUBJID == ID & df$LBTEST == TEST,]
  sel_data <- rbind(sel_data,sel_rows)
}

rm(df)

ae_df <- readxl::read_xlsx(path = '~/Desktop/UKM-рабочее/AE_20240325_070654.xlsx')
ae_df <- ae_df[-1,]
ae_df <- ae_df[,c('USUBJID','AETERM','AESEV','AESTDTC','AEENDTC','AESTDY','AEENDY','AEENRF','AESEQ')]

#####

merged_table <- tibble()
colnames(merged_table) <- colnames(new)

for (i in unique(sel_data$USUBJID)){
  sel_1 <- sel_data[sel_data$USUBJID == i,]
  for (j in unique(sel_1$LBTEST)){
    sel_2 <- sel_1[sel_1$LBTEST == j,]
    sel_2$Row_num <- seq_len(nrow(sel_2))
    ae_df_sel <- ae_df[ae_df$USUBJID == i,]
    ae_df_sel$Row_num <- seq_len(nrow(ae_df_sel))
    merged <- merge(sel_2, ae_df_sel, by = 'Row_num', all=TRUE)
    merged$USUBJID.x <- i
    merged[nrow(merged)+1,] <- NA
    merged_table <- rbindlist(list(merged_table, merged), fill = TRUE)
  }
}

merged_table$LBDY <- as.integer(merged_table$LBDY)
merged_table[order(merged_table$USUBJID.x,merged_table$LBTEST,merged_table$LBDY)]
merged_table$USUBJID.y <- NULL
#merged_table$USUBJID <- NULL
merged_table$Row_num <- NULL
colnames(merged_table)[colnames(merged_table) == "USUBJID.x"] <- "USUBJID"
openxlsx::write.xlsx(merged_table,'~/Desktop/UKM-рабочее/res/LBAE.xlsx')