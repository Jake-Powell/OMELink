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
           "primary","secondary","high","the","of","and")

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
  x <- x |> stringr::str_replace_all(' maths | math ', ' mathematics ')

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
#' @param establishment_list Data frame of known establishments. Must contain
#' columns \code{EstablishmentName} and the specified \code{ID_column}.
#' @param school_name_column Character string. Name of the column in \code{data}
#' containing school names.
#' @param ID_column Character string. Name of the column in
#' \code{establishment_list} containing the establishment identifier.
#' Default is \code{"EstablishmentID"}.
#' @param token_match Character string specifying the token matching method.
#' One of \code{"exact"}, \code{"partial"}, or \code{"fuzzy"}.
#' @param get_token_weights Function that takes a character vector of tokens
#' and returns a numeric vector of weights of the same length. Defaults to
#' equal weighting for all tokens.
#'
#' @return A data frame with the following columns:
#' \itemize{
#'   \item \code{match_index} Index of the matched establishment in
#'   \code{establishment_list}. Set to \code{NA} when multiple matches exist,
#'   and \code{-1} when no valid school name is provided.
#'   \item \code{original_name} Original input school name.
#'   \item \code{match_name} Matched establishment name(s) formatted as
#'   \code{"ID: Name"}. Multiple matches are separated by newline characters.
#'   \item \code{establishment_ID} Matched establishment ID when a single match
#'   exists, otherwise \code{NA}.
#'   \item \code{match_method} Method used for matching
#'   (e.g. \code{"exact"}, \code{"token_exact"}, \code{"token_partial"},
#'   \code{"token_fuzzy"}, or \code{"NO SCHOOL NAME PROVIDED"}).
#'   \item \code{match_score} Matching score (token-based methods only; exact
#'   matches are assigned \code{Inf}).
#'   \item \code{n_matches} Number of matched establishments.
#' }
#'
#' @details
#' The matching process proceeds in stages:
#' \itemize{
#'   \item School names are cleaned using \code{\link{clean_school_name}}.
#'   \item Missing or empty names are flagged and not matched.
#'   \item Exact matching is attempted first on cleaned names.
#'   \item Remaining records are matched using token-based methods.
#' }
#'
#' Token matching compares words (tokens) in the input name against those in
#' establishment names. Matching can be:
#' \itemize{
#'   \item Exact token matching
#'   \item Partial matching using \code{stringr::str_detect()}
#'   \item Fuzzy matching using \code{stringdist::stringdist()}
#' }
#'
#' Token weights can be customised via \code{get_token_weights}, allowing
#' common or uninformative words (e.g. "school", "academy") to be downweighted.
#'
#' When multiple establishments achieve the same best score, all are returned
#' in \code{match_name}, and \code{establishment_ID} is set to \code{NA}.
#'
#' @examples
#' df <- data.frame(School = c("St Inga's Primary School", "Ilex aquifolium Centre", NA))
#'
#' establishments <- data.frame(
#'   EstablishmentName = c("St. Inga's Primary School",
#'    "Ilex aquifolium Academy",
#'    "The DS Maths School"),
#'   EstablishmentID = c(A, 1, 'I')
#' )
#'
#' link_establishment(
#'   data = df,
#'   establishment_list = establishments,
#'   school_name_column = "School"
#' )
#'
#' @export
link_establishment <- function(data,
                               establishment_list,
                               school_name_column,
                               ID_column = "EstablishmentID",
                               token_match = "exact",
                               get_token_weights = function(tokens) rep(1, length(tokens))
) {

  token_match <- match.arg(token_match,
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
    stringsAsFactors = FALSE
  )


  # STEP -1: INVALID
  invalid <- is.na(school_name) | school_name == ""

  result$match_method[invalid] <- "NO SCHOOL NAME PROVIDED"
  result$match_index[invalid] <- -1

  to_match <- which(!invalid)


  # STEP 0: EXACT
  exact_idx <- match(school_name[to_match], est_names)

  exact_rows <- to_match[!is.na(exact_idx)]

  result$match_index[exact_rows]  <- exact_idx[!is.na(exact_idx)]
  result$match_method[exact_rows] <- "exact"
  result$match_score[exact_rows]  <- Inf
  result$n_matches[exact_rows]    <- 1L

  result$establishment_ID[exact_rows] <- est_ids[exact_idx[!is.na(exact_idx)]]

  result$match_name[exact_rows] <- paste0(
    result$establishment_ID[exact_rows],
    ": ",
    establishment_list$EstablishmentName[exact_idx[!is.na(exact_idx)]]
  )


  # Remaining
  to_match <- which(is.na(result$match_index))
  if (length(to_match) == 0) return(result)


  # TOKENISE
  school_tokens <- school_name[to_match] |>
    stringr::str_split("\\s+", simplify = FALSE)

  est_tokens <- est_names |>
    stringr::str_split("\\s+", simplify = FALSE)


  # MATCH FUNCTION
  token_match_fun <- function(tokens_input, tokens_est) {

    if (token_match == "exact") {
      tokens_input %in% tokens_est

    } else if (token_match == "partial") {
      sapply(tokens_input, function(tok){
        any(stringr::str_detect(tokens_est, tok))
      })

    } else if (token_match == "fuzzy") {
      sapply(tokens_input, function(tok){
        any(stringdist::stringdist(tok, tokens_est) <= 1)
      })
    }
  }


  # SCORE
  score_one <- function(tokens_input) {

    weights <- get_token_weights(tokens_input)

    sapply(est_tokens, function(tokens_est){
      matches <- token_match_fun(tokens_input, tokens_est)
      sum(weights[matches])
    })
  }


  match_matrix <- do.call(rbind, lapply(school_tokens, score_one))


  # BEST MATCH
  best_matches_list <- lapply(seq_len(nrow(match_matrix)), function(i){
    row_scores <- match_matrix[i, ]
    max_score <- max(row_scores, na.rm = TRUE)
    list(idx = which(row_scores == max_score), score = max_score)
  })


  # FILL
  for (j in seq_along(to_match)) {

    row_idx <- to_match[j]

    match_ids <- best_matches_list[[j]]$idx
    score     <- best_matches_list[[j]]$score

    matched_ids   <- est_ids[match_ids]
    matched_names <- establishment_list$EstablishmentName[match_ids]

    matched_labels <- paste0(matched_ids, ": ", matched_names)

    result$match_name[row_idx] <- paste(matched_labels, collapse = "\n")
    result$match_score[row_idx] <- score
    result$n_matches[row_idx] <- length(match_ids)

    if (length(match_ids) == 1) {
      result$match_index[row_idx] <- match_ids
      result$establishment_ID[row_idx] <- matched_ids
    } else {
      result$match_index[row_idx] <- NA_integer_
      result$establishment_ID[row_idx] <- NA
    }

    result$match_method[row_idx] <- paste0("TOKEN (", token_match, ')')
  }


  return(result)
}



