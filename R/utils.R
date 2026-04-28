#' Clean names
#'
#' @param x name to clean
#'
#' @return cleaned name
#' @export
#'
#' @examples
#'  clean_name('John Leonard Knapp')
#'  clean_name('Pierre-Joseph Redouté')
#'
#' @details
#' "Cleans" name by changing to lower case and translating to Latin-ASCII (i.e removing accents, etc). Can also remove whitespace by setting rm_whit = T.
clean_name <- function(x){
  x = x |>
    tolower() |>
    stringi::stri_trans_general(id = "Latin-ASCII") |>
    stringr::str_replace_all('-', ' ') |>
    stringr::str_squish()
  x
}

#' Expand Rows by Name Variants
#'
#' Splits first and last name columns (containing multiple names separated by a delimiter)
#' into multiple rows so that each row corresponds to a single FN/LN pair.
#' Other columns are repeated accordingly.
#'
#' @param data A data frame containing at least the FN, LN, and UPI columns.
#' @param FN_column A string indicating the name of the first name/s column.
#' @param LN_column A string indicating the name of the last name/s column.
#' @param sep A string delimiter used to separate multiple names in a single cell (default is `'---'`).
#' @param verbose Logical; whether to print progress messages.
#'
#' @return A data frame where each row corresponds to a single combination of FN and LN variant,
#'         with all original columns preserved and replicated as necessary.
#' @export
#'
#' @examples
#' botanists <- data.frame(
#'   FNs = c("Carl---Karl", "José", "Alexander---Alex---Alex", "Agnes", "  Jane  "),
#'   LNs = c("Linnaus---Linnaus", "Banks", "Humboldt---Humboldt---Humbouldt", "Arber", "Coldstream"),
#'   UPI = c("CL001", "JB002", "AH003", "AA004", "JC005"),
#'   stringsAsFactors = FALSE
#' )
#'
#' expand_name_variants(botanists, FN_column = "FNs", LN_column = "LNs")
expand_name_variants <- function(data, FN_column, LN_column, sep = '---', verbose = F) {
  if(verbose) cli::cli_alert_info('Explanding name variants') ; lapply = pbapply::pblapply
  need_expand = which(grepl('---', data[[FN_column]]) | grepl('---', data[[LN_column]]))
  if(length(need_expand) == 0){ return(data)}

  out = data[-need_expand,]
  to_expand = data[need_expand,]

  rows <- lapply(seq_len(nrow(to_expand)), function(i) {
    fns <- unlist(strsplit(to_expand[[FN_column]][i], sep))
    lns <- unlist(strsplit(to_expand[[LN_column]][i], sep))

    # Ensure equal length by recycling shorter vector
    len <- max(length(fns), length(lns))
    if (length(fns) != len) fns <- rep(fns, length.out = len)
    if (length(lns) != len) lns <- rep(lns, length.out = len)

    # Repeat all other columns
    base_row <- to_expand[i, , drop = FALSE]
    replicated_rows <- base_row[rep(1, len), , drop = FALSE]

    # Replace FN and LN with variants
    replicated_rows[[FN_column]] <- fns
    replicated_rows[[LN_column]] <- lns

    return(replicated_rows)
  })
  expanded = do.call(rbind, rows)

  rbind(out, expanded)
}
