#' Basic Token Weighting Function for School Name Matching
#'
#' Assigns weights to a vector of tokens, downweighting common,
#' non-informative words (e.g. "school", "academy") to improve
#' matching performance in token-based linkage algorithms.
#'
#' @param tokens Character vector of tokens (e.g. split words from a school name).
#'
#' @return Numeric vector of weights of the same length as \code{tokens}.
#' Tokens deemed uninformative are assigned a lower weight (default 0.1),
#' while all other tokens receive weight 1.
#'
#' @details
#' This function is intended for use within token-based matching workflows,
#' where common words (e.g. "school", "college") can otherwise dominate
#' similarity scores without providing meaningful discrimination.
#'
#' The current implementation uses a simple rule-based approach:
#' \itemize{
#'   \item Common words are assigned weight 0.1
#'   \item All other tokens are assigned weight 1
#' }
#'
#' Users may wish to extend this function to use more advanced weighting
#' schemes such as frequency-based (TF-IDF) or domain-specific rules.
#'
#' @examples
#' tokens <- c("st", "marys", "school")
#' get_weights_basic(tokens)
#'
#' @export
get_weights_basic <- function(tokens){
  low <- c("school","academy","college","sixth","form",
           "primary","secondary","high","the","of","and",
           "centre", "catholic")

  w <- rep(1, length(tokens))
  w[tokens %in% low] <- 0.1
  w
}


#' Clean and Standardise School Names for Matching
#'
#' Applies a series of transformations to standardise school names,
#' improving consistency for matching and linkage tasks.
#'
#' @param x Character vector of school names to clean.
#' @param rm_whit Logical. If \code{TRUE}, all whitespace is removed from the
#' cleaned string. If \code{FALSE} (default), whitespace is standardised but retained.
#'
#' @return Character vector of cleaned school names.
#'
#' @details
#' This function performs the following steps:
#' \itemize{
#'   \item Converts text to lowercase
#'   \item Transliterates to ASCII (e.g. removes accents)
#'   \item Removes punctuation
#'   \item Normalises whitespace (collapses multiple spaces)
#'   \item Applies common domain-specific replacements (e.g. "math" → "mathematics")
#'   \item Optionally removes all whitespace
#' }
#'
#' The function is designed for use in school name matching workflows,
#' ensuring that equivalent names with minor formatting differences are
#' more likely to match.
#'
#' @examples
#' clean_school_name("St. Inga's Primary School")
#'
#' clean_school_name("Ilex aquifolium Académy")
#'
#' clean_school_name("The DS Maths School")
#'
#' @export
clean_school_name <- function(x, rm_whit = FALSE) {
  x <- stringi::stri_trans_general(
    str = tolower(x),
    id = "Latin-ASCII"
  )

  x <- stringr::str_remove_all(x, "[:punct:]")
  x <- stringr::str_squish(x)

  # Special cases which occur commonly
  x <- x |>
    stringr::str_replace_all(' maths | math ', ' mathematics ') |>
    stringr::str_replace_all(' abbey gate ', ' abbeygate ')

  if (rm_whit) {
    x <- stringr::str_remove_all(x, "\\s+")
  }

  x
}

#' Link School Names to an Establishment List
#'
#' Matches school names from an input dataset to a reference establishment
#' list using a combination of exact and token-based matching methods.
#'
#' @param data Data frame containing school names to be matched.
#' @param establishment_list Data frame of known establishments.
#' Must contain \code{EstablishmentName} and \code{ID_column}.
#' @param school_name_column Character string. Column in \code{data}.
#' @param ID_column Character string. ID column in establishment list.
#' @param token_method One of \code{"exact"}, \code{"partial"}, \code{"fuzzy"}.
#' @param fuzzy_threshold Numeric in [0,1] for fuzzy similarity cutoff.
#' @param get_token_weights Function returning weights per token.
#' @param keep_top_n Integer. Number of matches stored in \code{top_n_matches}.
#' @param min_score Numeric. Minimum score required to accept a match.
#'
#' @return Data frame with match results and diagnostics.
#'
#' @export
link_establishment <- function(data,
                               establishment_list,
                               school_name_column,
                               ID_column = "EstablishmentID",
                               token_method = "fuzzy",
                               fuzzy_threshold = 0.5,
                               get_token_weights = OMELink::get_weights_basic,
                               keep_top_n = 3,
                               min_score = 0.5
) {

  token_method <- match.arg(token_method,
                            choices = c("exact", "partial", "fuzzy"))

  n <- nrow(data)

  # CLEAN
  school_name_raw <- data[[school_name_column]]
  school_name <- clean_school_name(school_name_raw, rm_whit = FALSE)

  est_names <- establishment_list$EstablishmentName |>
    clean_school_name(rm_whit = FALSE)

  est_ids <- establishment_list[[ID_column]]

  # INITIALISE
  result <- data.frame(
    match_index  = rep(NA_integer_, n),
    original_name = data[[school_name_column]],
    match_name   = rep(NA_character_, n),
    establishment_ID = rep(NA, n),
    match_method = rep(NA_character_, n),
    match_score  = rep(NA_real_, n),
    n_matches    = rep(NA_integer_, n),
    top_n_matches = rep(NA_character_, n),
    stringsAsFactors = FALSE
  )

  # INVALID
  invalid <- is.na(school_name) | school_name == ""
  result$match_method[invalid] <- "NO SCHOOL NAME PROVIDED"
  result$match_index[invalid] <- -1

  to_match <- which(!invalid)

  # EXACT MATCH
  exact_idx <- match(school_name[to_match], est_names)
  exact_rows <- to_match[!is.na(exact_idx)]

  result$match_index[exact_rows]  <- exact_idx[!is.na(exact_idx)]
  result$match_method[exact_rows] <- "EXACT"
  result$match_score[exact_rows]  <- Inf
  result$n_matches[exact_rows]    <- 1L
  result$establishment_ID[exact_rows] <- est_ids[exact_idx[!is.na(exact_idx)]]

  result$match_name[exact_rows] <- paste0(
    result$establishment_ID[exact_rows], ": ",
    establishment_list$EstablishmentName[exact_idx[!is.na(exact_idx)]]
  )

  # REMAINING
  to_match <- which(is.na(result$match_index))
  if (length(to_match) == 0) return(result)

  # TOKENISE
  school_tokens <- school_name[to_match] |>
    stringr::str_split("\\s+", simplify = FALSE)

  est_tokens <- est_names |>
    stringr::str_split("\\s+", simplify = FALSE)

  # MATCH FUNCTION
  token_match_fun <- function(tokens_input, tokens_est) {

    if (token_method == "exact") {
      as.numeric(tokens_input %in% tokens_est)

    } else if (token_method == "partial") {
      sapply(tokens_input, function(tok){
        as.numeric(any(stringr::str_detect(tokens_est, tok)))
      })

    } else if (token_method == "fuzzy") {
      sapply(tokens_input, function(tok){
        sims <- 1 - stringdist::stringdist(tok, tokens_est, method = "jw")
        sims[sims < fuzzy_threshold] <- 0
        max(sims, na.rm = TRUE)
      })
    }
  }

  # SCORE
  score_one <- function(tokens_input) {
    weights <- get_token_weights(tokens_input)

    sapply(est_tokens, function(tokens_est){
      sim <- token_match_fun(tokens_input, tokens_est)
      sum(weights * sim)
    })
  }

  match_matrix <- do.call(rbind, lapply(school_tokens, score_one))

  # FILL
  for (j in seq_along(to_match)) {

    row_idx <- to_match[j]
    row_scores <- match_matrix[j, ]

    max_score <- max(row_scores, na.rm = TRUE)

    # --- TOP N (always computed for diagnostics)
    ord <- order(row_scores, decreasing = TRUE, na.last = NA)
    top_ids <- ord[seq_len(min(keep_top_n, length(ord)))]

    top_labels <- paste0(
      est_ids[top_ids], ": ",
      establishment_list$EstablishmentName[top_ids],
      " = ",
      round(row_scores[top_ids], 3)
    )

    result$top_n_matches[row_idx] <- paste(top_labels, collapse = "\n")

    # --- MIN SCORE CHECK
    if (max_score < min_score) {
      result$match_method[row_idx] <- "NO GOOD MATCH"
      result$match_index[row_idx] <- -1
      result$match_score[row_idx] <- max_score
      result$n_matches[row_idx] <- 0
      next
    }

    # --- STANDARD MATCH (unchanged)
    match_ids <- which(row_scores == max_score)

    matched_ids   <- est_ids[match_ids]
    matched_names <- establishment_list$EstablishmentName[match_ids]

    result$match_name[row_idx] <- paste(
      paste0(matched_ids, ": ", matched_names),
      collapse = "\n"
    )

    result$match_score[row_idx] <- max_score
    result$n_matches[row_idx] <- length(match_ids)

    if (length(match_ids) == 1) {
      result$match_index[row_idx] <- match_ids
      result$establishment_ID[row_idx] <- matched_ids
    } else {
      result$match_index[row_idx] <- NA_integer_
      result$establishment_ID[row_idx] <- NA
    }

    result$match_method[row_idx] <- paste0("TOKEN (", token_method, ")")
  }

  return(result)
}
