source("utils.R")

# --- Configuration ---
paths <- list(
  vs = '~/Desktop/UKM-рабочее/VS_20240325_083417.xlsx',
  ae = '~/Desktop/UKM-рабочее/AE_20240325_070654.xlsx',
  mh = '~/Desktop/UKM-рабочее/MH_20240325_080702.xlsx',
  output = '~/Desktop/UKM-рабочее/res/VSAEMH.xlsx'
)

# --- Load Data ---
message("Loading Vital Signs, AE, and MH data...")
vs_df <- load_clinical_data(paths$vs)
ae_df <- load_clinical_data(paths$ae)
mh_df <- load_clinical_data(paths$mh)

# --- Filter VS for Clinically Significant Results ---
message("Filtering for clinically significant vital signs...")
vs_cols <- c('USUBJID', 'VSTEST', 'VSORRES', 'VSORRESU', 'VISIT', 'VSDTC', 'VSDY', 'VSCLSIG')
vs_df <- vs_df[, ..vs_cols]

# Identify patients/tests with clinically significant findings
positive_findings <- vs_df[VSCLSIG == 'Yes', .(USUBJID, VSTEST)] %>% distinct()

# Filter full dataset to keep all records for those specific patient-test combinations
sel_data <- vs_df[USUBJID %in% positive_findings$USUBJID & VSTEST %in% positive_findings$VSTEST]

# --- Merge with AE and MH ---
message("Merging with Adverse Events and Medical History...")
ae_sel_cols <- ae_df[, .(USUBJID, AETERM, AESEV, AESTDTC, AEENDTC, AESTDY, AEENDY, AEENRF, AESEQ)]
mh_sel_cols <- mh_df[, .(USUBJID, MHTERM, MHSTDTC, MHENDTC, MHENRF)]

merged_table <- merge_clinical_data(
  domain_df = sel_data, 
  ae_df = ae_sel_cols, 
  mh_df = mh_sel_cols, 
  test_col = "VSTEST"
)

# --- Save Results ---
message("Saving results to: ", paths$output)
write.xlsx(merged_table, paths$output)
message("Done.")
