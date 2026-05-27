source("utils.R")

# --- Configuration ---
paths <- list(
  lb = '~/Desktop/UKM-рабочее/LB_20240325_073918.xlsx',
  ae = '~/Desktop/UKM-рабочее/AE_20240325_070654.xlsx',
  output = '~/Desktop/UKM-рабочее/res/LBAE.xlsx'
)

# --- Load Data ---
message("Loading Lab and AE data...")
lb_df <- load_clinical_data(paths$lb)
ae_df <- load_clinical_data(paths$ae)

# --- Filter Lab for Out-of-Range Results ---
message("Filtering for lab results outside normal ranges...")
lb_cols <- c('USUBJID', 'LBTEST', 'LBORRES', 'LBORRESU', 'LBORNRLO', 'LBORNRHI', 'LBNRIND', 'VISIT', 'LBDTC', 'LBDY')
lb_df <- lb_df[, ..lb_cols]

# Identify patients/tests with "High" or "Low" results
positive_findings <- lb_df[LBNRIND %in% c('High', 'Low'), .(USUBJID, LBTEST)] %>% distinct()

# Filter full dataset to keep all records for those specific patient-test combinations
sel_data <- lb_df[USUBJID %in% positive_findings$USUBJID & LBTEST %in% positive_findings$LBTEST]

# --- Merge with AE ---
message("Merging with Adverse Events...")
ae_sel_cols <- ae_df[, .(USUBJID, AETERM, AESEV, AESTDTC, AEENDTC, AESTDY, AEENDY, AEENRF, AESEQ)]

merged_table <- merge_clinical_data(
  domain_df = sel_data, 
  ae_df = ae_sel_cols, 
  test_col = "LBTEST"
)

# --- Save Results ---
message("Saving results to: ", paths$output)
write.xlsx(merged_table, paths$output)
message("Done.")
