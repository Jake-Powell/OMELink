#' Match a Person's Name to a Data Frame of Individuals
#'
#' Attempts to match a person's first and last name to a row in a dataset using
#' exact, swapped, or fuzzy matching techniques.
#'
#' @param FN Character string. First name of the person to match.
#' @param LN Character string. Last name (surname) of the person to match.
#' @param data A data frame containing at least the columns for first name, last name, and UPI.
#' @param FN_column Character. Name of the column in `data` that contains first names. Default is `"FN"`.
#' @param LN_column Character. Name of the column in `data` that contains last names. Default is `"LN"`.
#' @param UPI_column Character. Name of the column in `data` that contains unique identifiers (UPI). Default is `"UPI"`.
#' @param max_dist Integer. Maximum string distance allowed for fuzzy matching. Default is `2`.
#' @param method Character. String distance method to use. Passed to [stringdist::stringdist()]. Default is `"osa"`.
#' @param show_all_fuzzy Logical. If `TRUE`, return all fuzzy matches instead of just the best match. Default is `FALSE`.
#' @param ... Additional parameters passed to [clean_name()] for name normalization.
#'
#' @return A list with the following components:
#' \describe{
#'   \item{UPI}{The matched UPI(s), or `NA` if no match.}
#'   \item{people}{The matched row(s) from `data`.}
#'   \item{message}{A character string describing the match type (e.g., `"EXACT"`, `"FUZZY MATCH"`).}
#' }
#'
#' @examples
#' botanists <- data.frame(
#'   FN = c("Carl", "José", "Alexander", "Agnes", "  Jane  "),
#'   LN = c("Linnæus", "Banks", "Humboldt", "Arber", "Coldstream"),
#'   UPI = c("CL001", "JB002", "AH003", "AA004", "JC005"),
#'   stringsAsFactors = FALSE
#' )
#'
#' # Exact match (accent-insensitive)
#' match_person_to_data("Jose", "Banks", botanists)
#'
#' # Name with extra spaces
#' match_person_to_data("Jane", "Coldstream", botanists)
#'
#' # Lowercase input, accented name in data
#' match_person_to_data("carl", "linnaeus", botanists)
#'
#' # Swapped names
#' match_person_to_data("Linnæus", "Carl", botanists)
#'
#' # No match
#' match_person_to_data("Greg", "Mendel", botanists)
#'
#' # Data with different column names
#' botanists2 <- data.frame(
#'   FN = c("Carl", "José", "Alexander", "Agnes", "  Jane  ", "Jake"),
#'   Surname = c("Linnæus", "Banks", "Humboldt", "Arber", "Coldstream", "Banks"),
#'   UPI = c("CL001", "JB002", "AH003", "AA004", "JC005", "CL002"),
#'   stringsAsFactors = FALSE
#' )
#'
#' # Last name only, with multiple entries
#' match_person_to_data("John", "Banks", botanists2,
#'                      FN_column = "FN", LN_column = "Surname")
#'
#'
#' @export

match_person_to_data <- function(FN, LN, data,
                                 FN_column = 'FN', LN_column = 'LN', UPI_column = 'UPI',
                                 max_dist = 2, method = "osa", show_all_fuzzy = FALSE, ...) {
  if(!FN_column %in% names(data)) stop('FN_column does not exist in data')
  if(!LN_column %in% names(data)) stop('LN_column does not exist in data')
  if(!UPI_column %in% names(data)) stop('UPI_column does not exist in data')

  # Expand multiple names
  data = expand_name_variants(data, FN_column, LN_column)

    # Clean inputs
  FN <- clean_name(FN, ...)
  LN <- clean_name(LN, ...)
  data[[FN_column]] <- clean_name(data[[FN_column]], ...)
  data[[LN_column]] <- clean_name(data[[LN_column]], ...)

  # Exact match indices
  FN_index <- which(data[[FN_column]] == FN)
  LN_index <- which(data[[LN_column]] == LN)
  both_index <- intersect(FN_index, LN_index)

  # Swapped names
  FN_swap_index <- which(data[[FN_column]] == LN)
  LN_swap_index <- which(data[[LN_column]] == FN)
  both_swap_index <- intersect(FN_swap_index, LN_swap_index)

  # Return exact/swap matches first
  if (length(both_index) > 0) {
    return(list(UPI = data[[UPI_column]][both_index], people = data[both_index, ], message = 'EXACT'))
  }
  if (length(both_swap_index) > 0) {
    return(list(UPI = data[[UPI_column]][both_swap_index], people = data[both_swap_index, ], message = 'EXACT (Swap)'))
  }

  # FN or LN only exact matches
  if (length(LN_index) == 1 && length(FN_index) == 0) {
    return(list(UPI = data[[UPI_column]][LN_index], people = data[LN_index, ], message = 'LN only'))
  }
  if (length(FN_index) == 1 && length(LN_index) == 0) {
    return(list(UPI = data[[UPI_column]][FN_index], people = data[FN_index, ], message = 'FN only'))
  }

  # FN or LN only swapped exact matches
  if (length(LN_swap_index) == 1 && length(FN_swap_index) == 0) {
    return(list(UPI = data[[UPI_column]][LN_swap_index], people = data[LN_swap_index, ], message = 'LN only (Swap)'))
  }
  if (length(FN_swap_index) == 1 && length(LN_swap_index) == 0) {
    return(list(UPI = data[[UPI_column]][FN_swap_index], people = data[FN_swap_index, ], message = 'FN only (Swap)'))
  }

  # Fuzzy match distances
  FN_dists <- stringdist::stringdist(FN, data[[FN_column]], method = method)
  LN_dists <- stringdist::stringdist(LN, data[[LN_column]], method = method)

  both_fuzzy_matches <- which(FN_dists <= max_dist & LN_dists <= max_dist)
  FN_only_fuzzy_matches <- which(FN_dists <= max_dist)
  LN_only_fuzzy_matches <- which(LN_dists <= max_dist)

  if (length(both_fuzzy_matches) > 0) {
    if (show_all_fuzzy) {
      return(list(
        UPI = data[[UPI_column]][both_fuzzy_matches],
        people = data[both_fuzzy_matches, ],
        message = 'FUZZY MATCHES (both FN & LN)'
      ))
    } else {
      best <- both_fuzzy_matches[which.min(FN_dists[both_fuzzy_matches] + LN_dists[both_fuzzy_matches])]
      return(list(
        UPI = data[[UPI_column]][best],
        people = data[best, ],
        message = 'FUZZY MATCH (best both FN & LN)'
      ))
    }
  }

  # Allow partial fuzzy matching if full match fails
  partial_matches <- union(FN_only_fuzzy_matches, LN_only_fuzzy_matches)

  if (length(partial_matches) > 0) {
    best <- partial_matches[which.min(FN_dists[partial_matches] + LN_dists[partial_matches])]
    if (show_all_fuzzy) {
      return(list(
        UPI = data[[UPI_column]][best],
        people = data[partial_matches, ],
        message = 'FUZZY PARTIAL MATCHES (FN or LN)'
      ))
    } else {

      return(list(
        UPI = data[[UPI_column]][best],
        people = data[best, ],
        message = 'FUZZY PARTIAL MATCH (best FN or LN)'
      ))
    }
  }

  # Nothing matched
  d = data[1,]
  d[1,] = NA
  return(list(UPI = NA, people = d, message = 'No match'))
}


#' Match a Person to Grouped Data
#'
#' Attempts to match a person (first and last name) to a row in a data frame,
#' optionally within a specific grouping (e.g., Department, Team).
#'
#' @param FN First name
#' @param LN Last name
#' @param data Data frame containing name, UPI, and grouping columns
#' @param FN_column Column name for first names (default: "FN")
#' @param LN_column Column name for surnames (default: "LN")
#' @param UPI_column Column name for Unique Person Identifier (default: "UPI")
#' @param group_column (Optional) column name for grouping
#' @param group_value (Optional) value to filter by in the grouping column
#' @param max_dist Max string distance for fuzzy match (default: 2)
#' @param method Method for string distance (default: "osa")
#' @param show_all_fuzzy Show all fuzzy matches or just the best (default: FALSE)
#' @param ... Additional arguments passed to `clean_name()`
#'
#' @return A list with UPI, matching row(s), and a message
#' @export
#'
#' @examples
#' # Example data: Botanists grouped by expedition
#' botanists_grouped <- data.frame(
#'   FN = c("Carl", "Joseph", "Alexander", "Agnes", "Janet", "George"),
#'   LN = c("Linnaeus", "Banks", "von Humboldt", "Arber", "Browne", "Bentham"),
#'   UPI = c("CL001", "JB002", "AH003", "AA004", "JB003", "GB004"),
#'   Expedition = c("Sweden", "Endeavour", "South America", "UK", "UK", "Australia"),
#'   stringsAsFactors = FALSE
#' )
#'
#' # Exact match within correct group
#' match_person_to_grouped_data("Carl", "Linnaeus", botanists_grouped, group_value = "Sweden")
#'
#' # Will match Joseph Banks only within the "Endeavour" expedition
#' match_person_to_grouped_data("joseph", "banks", botanists_grouped, group_value = "Endeavour")
#'
#' # Swapped names still work within group
#' match_person_to_grouped_data("von Humboldt", "Alexander",
#'  botanists_grouped, group_value = "South America")
#'
#' # No match if group is incorrect, even if name is present elsewhere
#' match_person_to_grouped_data("George", "Bentham",
#'  botanists_grouped, group_value = "UK")  # returns NA
#'
match_person_to_grouped_data <- function(FN, LN, data,
                                         FN_column = 'FN',
                                         LN_column = 'LN',
                                         UPI_column = 'UPI',
                                         group_column = NULL,
                                         group_value = NULL,
                                         max_dist = 2,
                                         method = "osa",
                                         show_all_fuzzy = FALSE,
                                         ...) {
  # Filter by group if specified
  if (!is.null(group_column) && !is.null(group_value)) {
    data <- data[data[[group_column]] == group_value, ]
    if (nrow(data) == 0) {
      data[1,] = NA
      warning(paste("No individuals in group:", group_value))
      return(list(UPI = NA, people = data, message = paste("No individuals in group:", group_value)))
    }
  }

  # Delegate to the base function
  match_person_to_data(FN, LN, data,
                       FN_column = FN_column,
                       LN_column = LN_column,
                       UPI_column = UPI_column,
                       max_dist = max_dist,
                       method = method,
                       show_all_fuzzy = show_all_fuzzy,
                       ...)
}

#' Match Multiple People to Grouped Data
#'
#' Matches a set of individuals (first and last names in a data frame) to a target dataset,
#' optionally within groupings such as teams, departments, or expeditions. This is a batch
#' version of `match_person_to_grouped_data()`.
#'
#' @param to_match A data frame of people to match, with at least first and last name columns.
#' @param data A data frame containing the reference data to match against (must contain names, UPI, and optional group column).
#' @param FN_column Column name for first names in `data` (default: `"FN"`).
#' @param LN_column Column name for last names in `data` (default: `"LN"`).
#' @param UPI_column Column name for Unique Person Identifier in `data` (default: `"UPI"`).
#' @param group_column Optional. Column name in `data` representing a grouping (e.g., Department, Team).
#' @param group_value Optional. If specified, filters `data` to just this group before matching.
#' @param max_dist Maximum allowed string distance for fuzzy matching (default: `2`).
#' @param method Method used for computing string distance. Passed to `stringdist::stringdist()` (default: `"osa"`).
#' @param show_all_fuzzy Logical; if `TRUE`, shows all fuzzy matches instead of just the best (default: `FALSE`).
#' @param to_match_FN_column Column name for first names in the `to_match` data frame (default: same as `FN_column`).
#' @param to_match_LN_column Column name for last names in the `to_match` data frame (default: same as `LN_column`).
#' @param to_match_group_column Column name in `to_match` that specifies the group (if applicable). Used only when `group_column` is also specified.
#' @param include_non_matched Logical; if `TRUE`, includes rows from `to_match` even if no match is found (default: `FALSE`).
#' @param verbose Logical; if `TRUE`, include console messaging.
#' @param ... Additional arguments passed to `clean_name()` or internal matching functions.
#'
#' @return A data frame of matched people. Includes input first and last names as `inputFN` and `inputLN`.
#'         If `include_non_matched = TRUE`, rows with no match will still be returned (likely with NAs).
#'

#' @export
match_people_to_data <- function(to_match, data,
                                         FN_column = 'FN',
                                         LN_column = 'LN',
                                         UPI_column = 'UPI',
                                         group_column = NULL,
                                         group_value = NULL,
                                         max_dist = 2,
                                         method = "osa",
                                         show_all_fuzzy = FALSE,
                                         to_match_FN_column = FN_column,
                                         to_match_LN_column = LN_column,
                                         to_match_group_column = group_column,
                                         include_non_matched = FALSE,
                                         verbose = T,
                                         ...) {

  if(verbose) requireNamespace("pbapply", quietly = TRUE) ; lapply = pbapply::pblapply

  check = lapply(1:nrow(to_match), function(index){
    d = to_match[index,]
    FN = d[[to_match_FN_column]] ; LN = d[[to_match_LN_column]]
    out = OMELink::match_person_to_grouped_data(FN =FN,
                                                  LN = LN,
                                                  data = data,
                                                  FN_column = FN_column,
                                                  LN_column = LN_column,
                                                  UPI_column = UPI_column,
                                                  group_column = group_column,
                                                  group_value = d[[to_match_group_column]],
                                                  max_dist = max_dist,
                                                  method = method,
                                                  ...)


    ret = out$people
    data_names = paste0('NameDB_',names(ret))
    method = out$message
    # if(is.null(ret) & !include_non_matched) return(ret)
    # if(is.null(ret) & include_non_matched) return(ret)
    ret = data.frame(d  |> as.vector(),
                     method,
                     ret)
    names(ret) = c(names(d), 'Method', data_names)
    ret
  })
  check = do.call(rbind, check)

}


