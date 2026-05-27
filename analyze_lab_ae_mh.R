source("utils.R")

# --- Configuration ---
paths <- list(
  lb = '~/Desktop/UKM-рабочее/LB_20240325_073918.xlsx',
  ae = '~/Desktop/UKM-рабочее/AE_20240325_070654.xlsx',
  mh = '~/Desktop/UKM-рабочее/MH_20240325_080702.xlsx',
  output = '~/Desktop/UKM-рабочее/res/LBAEMH.xlsx'
)

# --- Load Data ---
message("Loading Lab, AE, and MH data...")
lb_df <- load_clinical_data(paths$lb)
ae_df <- load_clinical_data(paths$ae)
mh_df <- load_clinical_data(paths$mh)

# --- Filter Lab for Clinically Significant Results ---
message("Filtering for clinically significant lab results...")
lb_cols <- c('USUBJID', 'LBTEST', 'LBORRES', 'LBORRESU', 'LBORNRLO', 'LBORNRHI', 'LBNRIND', 'VISIT', 'LBDTC', 'LBDY', 'LBCLSIG', 'LBCAT')
lb_df <- lb_df[, ..lb_cols]

# Identify patients/tests with clinically significant findings
positive_findings <- lb_df[LBCLSIG == 'Yes', .(USUBJID, LBTEST, LBCAT)] %>% distinct()

# Filter full dataset to keep all records for those specific patient-test combinations
sel_data <- lb_df[USUBJID %in% positive_findings$USUBJID & LBTEST %in% positive_findings$LBTEST & LBCAT %in% positive_findings$LBCAT]

# --- Merge with AE and MH ---
message("Merging with Adverse Events and Medical History...")
ae_sel_cols <- ae_df[, .(USUBJID, AETERM, AESEV, AESTDTC, AEENDTC, AESTDY, AEENDY, AEENRF, AESEQ)]
mh_sel_cols <- mh_df[, .(USUBJID, MHTERM, MHSTDTC, MHENDTC, MHENRF)]

merged_table <- merge_clinical_data(
  domain_df = sel_data, 
  ae_df = ae_sel_cols, 
  mh_df = mh_sel_cols, 
  test_col = "LBTEST"
)

# Move LBCAT to the front for better readability
if ("LBCAT" %in% names(merged_table)) {
  setcolorder(merged_table, c("LBCAT", setdiff(names(merged_table), "LBCAT")))
}

# --- Save Results ---
message("Saving results to: ", paths$output)
write.xlsx(merged_table, paths$output)
message("Done.")
