library(dplyr)
library(data.table)
df <- readxl::read_xlsx(path = '~/Desktop/UKM-рабочее/EG_20240325_073355.xlsx')
df <- df[-1,]
df <- df[,c('USUBJID','EGTEST','EGORRES','EGORRESU','VISIT','EGDTC','EGDY','EGCLSIG')]
positive_table <- df[df$EGCLSIG %in% c('Yes'),]
positive_table <- positive_table[,c('USUBJID','EGTEST')]
positive_table <- positive_table %>% distinct()

sel_data <- data.frame(matrix(nrow = 0, ncol = length(df)))
colnames(sel_data) <-colnames(df)

for (i in 1:nrow(positive_table)){
  ID <- positive_table[i,]$USUBJID
  TEST <- positive_table[i,]$EGTEST
  sel_rows <- df[df$USUBJID == ID & df$EGTEST == TEST,]
  sel_data <- rbind(sel_data,sel_rows)
}

rm(df)

ae_df <- readxl::read_xlsx(path = '~/Desktop/UKM-рабочее/AE_20240325_070654.xlsx')
ae_df <- ae_df[-1,]
ae_df <- ae_df[,c('USUBJID','AETERM','AESEV','AESTDTC','AEENDTC','AESTDY','AEENDY','AEENRF','AESEQ')]

mh_df <- readxl::read_xlsx(path = '~/Desktop/UKM-рабочее/MH_20240325_080702.xlsx')
mh_df <- mh_df[-1,]
mh_df <- mh_df[,c('USUBJID','MHTERM','MHSTDTC','MHENDTC','MHENRF')]

#####

merged_table <- tibble()
colnames(merged_table) <- colnames(new)

for (i in unique(sel_data$USUBJID)){
  sel_1 <- sel_data[sel_data$USUBJID == i,]
  for (j in unique(sel_1$EGTEST)){
    sel_2 <- sel_1[sel_1$EGTEST == j,]
    sel_2$Row_num <- seq_len(nrow(sel_2))
    ae_df_sel <- ae_df[ae_df$USUBJID == i,]
    ae_df_sel$Row_num <- seq_len(nrow(ae_df_sel))
    mh_df_sel <- mh_df[mh_df$USUBJID == i,]
    mh_df_sel$Row_num <- seq_len(nrow(mh_df_sel))
    merged <- merge(sel_2, ae_df_sel, by = 'Row_num', all=TRUE)
    merged_2 <- merge(merged, mh_df_sel, by = 'Row_num', all=TRUE)
    merged_2$USUBJID.x <- i
    merged_2[nrow(merged_2)+1,] <- NA
    merged_table <- rbindlist(list(merged_table, merged_2), fill = TRUE)
  }
}

merged_table$EGDY <- as.integer(merged_table$EGDY)
merged_table[order(merged_table$USUBJID.x,merged_table$EGTEST,merged_table$EGDY)]
merged_table$USUBJID.y <- NULL
merged_table$USUBJID <- NULL
merged_table$Row_num <- NULL
colnames(merged_table)[colnames(merged_table) == "USUBJID.x"] <- "USUBJID"
openxlsx::write.xlsx(merged_table,'~/Desktop/UKM-рабочее/res/EGAEMH.xlsx')