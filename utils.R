library(dplyr)
library(data.table)
library(readxl)
library(openxlsx)

#' Load Clinical Data
#' 
#' Loads an Excel file, skips the first row (metadata), and converts to a data.table.
#' @param path Path to the Excel file.
#' @return A data.table.
load_clinical_data <- function(path) {
  if (!file.exists(path)) {
    stop(paste("File not found:", path))
  }
  df <- read_xlsx(path = path)
  df <- df[-1, ]
  return(as.data.table(df))
}

#' Clean Numeric Data
#' 
#' Replaces commas with dots and converts specified columns to numeric.
#' @param dt A data.table.
#' @param cols Vector of column names to clean.
#' @return A cleaned data.table.
clean_numeric_data <- function(dt, cols) {
  for (col in cols) {
    if (col %in% names(dt)) {
      dt[[col]] <- as.numeric(gsub(",", ".", dt[[col]]))
    }
  }
  return(dt)
}

#' Merge Domain with AE and MH
#' 
#' Merges a specific domain data (e.g., LB, EG, VS) with AE and MH data for a patient.
#' Uses a row-number based side-by-side join for clinical review.
#' @param domain_df Filtered domain data.
#' @param ae_df Adverse Events data.
#' @param mh_df Medical History data (optional).
#' @param id_col The column name for Patient ID (default 'USUBJID').
#' @param test_col The column name for the Test/Parameter (e.g., 'LBTEST').
#' @return A merged data.table.
merge_clinical_data <- function(domain_df, ae_df, mh_df = NULL, id_col = "USUBJID", test_col = NULL) {
  merged_table <- data.table()
  
  unique_ids <- unique(domain_df[[id_col]])
  
  for (id in unique_ids) {
    id_domain <- domain_df[get(id_col) == id]
    
    # Process by test if specified, otherwise by patient
    test_groups <- if (!is.null(test_col)) unique(id_domain[[test_col]]) else "All"
    
    for (test in test_groups) {
      sel_domain <- if (!is.null(test_col)) id_domain[get(test_col) == test] else id_domain
      sel_domain$Row_num <- seq_len(nrow(sel_domain))
      
      sel_ae <- ae_df[get(id_col) == id]
      sel_ae$Row_num <- seq_len(nrow(sel_ae))
      
      merged <- merge(sel_domain, sel_ae, by = "Row_num", all = TRUE)
      
      if (!is.null(mh_df)) {
        sel_mh <- mh_df[get(id_col) == id]
        sel_mh$Row_num <- seq_len(nrow(sel_mh))
        merged <- merge(merged, sel_mh, by = "Row_num", all = TRUE)
      }
      
      # Clean up patient ID after merge
      id_x_col <- paste0(id_col, ".x")
      if (id_x_col %in% names(merged)) {
        merged[[id_col]] <- id
        merged[[id_x_col]] <- NULL
      }
      
      id_y_col <- paste0(id_col, ".y")
      if (id_y_col %in% names(merged)) merged[[id_y_col]] <- NULL
      
      merged$Row_num <- NULL
      
      # Add an empty row for visual separation
      empty_row <- as.list(rep(NA, ncol(merged)))
      names(empty_row) <- names(merged)
      
      merged_table <- rbindlist(list(merged_table, merged, as.data.table(empty_row)), fill = TRUE)
    }
  }
  
  return(merged_table)
}

#' Get Boundary Violations
#' 
#' Identifies cases where a patient/test combination has inconsistent reference ranges (e.g., different units or limits).
#' @param dt Lab data.table.
#' @return A summary table of violations.
get_boundary_violations <- function(dt) {
  # Group by ID and Test to see how many unique unit/limit combinations exist
  violations <- dt[, .(unique_configs = uniqueN(paste(LBORRESU, LBORNRLO, LBORNRHI))), by = .(USUBJID, LBTEST)]
  return(violations[unique_configs >= 2])
}

#' Find Outliers Against Expected Values
#' 
#' Compares results against an external table of expected values.
#' @param dt Lab data.table.
#' @param expected_values Table with Test, Units, Low_limit, High_limit.
#' @return A list containing results and limits outliers.
find_outliers <- function(dt, expected_values) {
  # Clean column names in expected_values for easier merging
  setDT(expected_values)
  
  # Merge data with expected values
  merged <- merge(dt, expected_values, by.x = c("LBTEST", "LBORRESU"), by.y = c("Test", "Units"), all.x = TRUE)
  
  # Find results outside expected clinical limits
  results_outliers <- merged[LBORRES < Low_limit | LBORRES > High_limit]
  
  # Find cases where the site's reference limits are outside the expected range
  limits_outliers <- merged[LBORNRLO < Low_limit | LBORNRHI > High_limit]
  
  return(list(
    results_outliers = results_outliers,
    limits_outliers = limits_outliers
  ))
}
