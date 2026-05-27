source("utils.R")

# --- Configuration ---
paths <- list(
  lb = '~/Desktop/WORK/TNP-STEMI-III/LB_20240325_121009.xlsx',
  output = '~/Desktop/WORK/TNP-STEMI-III/res/LB_units.xlsx'
)

# --- Load Data ---
message("Loading Lab data for unit check...")
dt <- load_clinical_data(paths$lb)

# Clean numeric results for consistency
dt <- clean_numeric_data(dt, c("LBORNRLO", "LBORNRHI", "LBORRES"))

# --- Analyze Units ---
message("Summarizing units...")

# All units table
all_units <- dt[!is.na(LBORRESU), .(count_num = .N), by = .(LBCAT, LBTEST, LBORRESU)]

# Identify records with missing units but having a result
empty_units <- dt[is.na(LBORRESU) & !is.na(LBORRES) & LBTEST != 'pH', 
                  .(count_num = .N), by = .(LBCAT, LBTEST, LBORRESU)]

# Combine and sort
final_units_table <- rbindlist(list(all_units, empty_units))
setorder(final_units_table, LBCAT, LBTEST)

# --- Save Results ---
message("Saving results to: ", paths$output)
write.xlsx(final_units_table, paths$output)
message("Done.")
