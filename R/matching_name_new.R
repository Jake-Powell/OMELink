#' Compute Token-Based Jaro-Winkler Name Similarity
#'
#' Computes a similarity score between two names using token-level
#' Jaro-Winkler similarity. Names are first standardised to upper case,
#' punctuation is removed, and the strings are split into tokens. A
#' similarity matrix is then formed between tokens in each name, and for
#' each token in the longer name the best match in the shorter name is
#' taken. The final score is the mean of these best matches.
#'
#' This returns a value between \code{0} and \code{1}, where:
#' \itemize{
#'   \item \code{1} indicates an exact token-level match
#'   \item values closer to \code{0} indicate weaker similarity
#' }
#'
#' @param x Character string. First name string to compare.
#' @param y Character string. Second name string to compare.
#'
#' @return Numeric scalar between \code{0} and \code{1}, or \code{NA_real_}
#'   if either name has no valid tokens after cleaning.
#'
#' @examples
#' name_similarity_jw("Matthew", "Matt")
#' name_similarity_jw("Janet Brown", "Janet Browne")
#'
#' @export
name_similarity_jw = function(x, y) {
  tokenize = function(z) {
    z |>
      stringr::str_to_upper() |>
      stringr::str_replace_all("[[:punct:]]", " ") |>
      stringr::str_squish() |>
      stringr::str_split("\\s+") |>
      unlist() |>
      unique()
  }

  x_tokens = tokenize(x)
  y_tokens = tokenize(y)

  if (length(x_tokens) == 0 || length(y_tokens) == 0) {
    return(NA_real_)
  }

  if (length(x_tokens) >= length(y_tokens)) {
    ref_tokens = x_tokens
    cmp_tokens = y_tokens
  } else {
    ref_tokens = y_tokens
    cmp_tokens = x_tokens
  }

  sim_mat = outer(
    ref_tokens,
    cmp_tokens,
    Vectorize(function(a, b) {
      1 - stringdist::stringdist(a, b, method = "jw")
    })
  )

  best_sim = apply(sim_mat, 1, max)
  mean(best_sim)
}


#' Compute Partial and Fuzzy Matching Signals for a Single Name
#'
#' Compares a single input name to a vector of candidate names and returns
#' several matching signals. These include exact string match, token overlap,
#' prefix matching, substring matching, initial matching, and token-based
#' Jaro-Winkler fuzzy similarity.
#'
#' This function is designed to support downstream person linkage workflows
#' where first and last names are scored separately and then combined.
#'
#' @param name Character scalar. A single name to match.
#' @param all_names Character vector of candidate names to compare against.
#' @param do_clean_name Logical; if \code{TRUE}, applies \code{clean_name()}
#'   to \code{name} and \code{all_names} before matching.
#'
#' @return A data frame with one row per element of \code{all_names} and the
#'   following columns:
#'   \describe{
#'     \item{given_name}{The input \code{name}.}
#'     \item{data_name}{The candidate name from \code{all_names}.}
#'     \item{exact}{Logical; exact full-string match.}
#'     \item{exact_token}{Logical; at least one token matches exactly.}
#'     \item{partial_start}{Logical; at least one token matches at the start
#'       of a token in either direction.}
#'     \item{partial_anywhere}{Logical; at least one token matches anywhere
#'       within a token in either direction.}
#'     \item{initial_token}{Logical; at least one token shares an initial.}
#'     \item{fuzzy}{Numeric token-based Jaro-Winkler similarity between
#'       \code{0} and \code{1}.}
#'   }
#'
#' @examples
#' all_names = c("MATTHEW", "MATT", "MARK", "JANET")
#' partial_fuzzy_match("Matt", all_names)
#'
#' @export
partial_fuzzy_match = function(name, all_names, do_clean_name = FALSE) {
  if (do_clean_name) {
    name = clean_name(name)
    all_names = clean_name(all_names)
  }

  if (length(name) != 1) {
    stop("name must be a single character string.")
  }

  name_token = stringr::str_split(name, pattern = "\\s+") |> unlist()
  all_names_token = stringr::str_split(all_names, pattern = "\\s+")

  exact = all_names == name

  exact_token = vapply(
    all_names_token,
    function(tokens) any(tokens %in% name_token),
    logical(1)
  )

  pattern_start = paste0("^(", paste(escape_regex(name_token), collapse = "|"), ")")
  partial_start = vapply(
    all_names_token,
    function(tokens) {
      forward = any(grepl(pattern_start, tokens, ignore.case = TRUE))

      reverse = any(vapply(
        tokens,
        function(tok) any(grepl(paste0("^", escape_regex(tok)), name_token, ignore.case = TRUE)),
        logical(1)
      ))

      forward || reverse
    },
    logical(1)
  )

  pattern_anywhere = paste0("(", paste(escape_regex(name_token), collapse = "|"), ")")
  partial_anywhere = vapply(
    all_names_token,
    function(tokens) {
      forward = any(grepl(pattern_anywhere, tokens, ignore.case = TRUE))

      reverse = any(vapply(
        tokens,
        function(tok) any(grepl(escape_regex(tok), name_token, ignore.case = TRUE)),
        logical(1)
      ))

      forward || reverse
    },
    logical(1)
  )

  name_initials = substr(name_token, 1, 1)
  initial_pattern = paste0("^(", paste(escape_regex(name_initials), collapse = "|"), ")")
  initial_token = vapply(
    all_names_token,
    function(tokens) any(grepl(initial_pattern, tokens, ignore.case = TRUE)),
    logical(1)
  )

  fuzzy = vapply(
    all_names,
    function(x) name_similarity_jw(name, x),
    numeric(1)
  )

  data.frame(
    given_name = name,
    data_name = all_names,
    exact = exact,
    exact_token = exact_token,
    partial_start = partial_start,
    partial_anywhere = partial_anywhere,
    initial_token = initial_token,
    fuzzy = fuzzy,
    stringsAsFactors = FALSE
  )
}


#' Build First-Name and Last-Name Matching Breakdown
#'
#' Applies \code{partial_fuzzy_match()} separately to first names and last
#' names in a candidate data frame, then combines the results with the
#' original data.
#'
#' @param FN Character scalar. First name to match.
#' @param LN Character scalar. Last name to match.
#' @param data Data frame containing candidate people.
#' @param FN_column Character scalar. Name of the first-name column in
#'   \code{data}.
#' @param LN_column Character scalar. Name of the last-name column in
#'   \code{data}.
#'
#' @return A data frame containing the original \code{data} plus prefixed
#'   first-name and last-name matching columns.
#'
#' @examples
#' people = data.frame(
#'   FN = c("MATTHEW", "MATT", "JANET"),
#'   LN = c("JONES", "JONES", "BROWNE"),
#'   stringsAsFactors = FALSE
#' )
#'
#' matching_breakdown("Matt", "Jones", people, FN_column = "FN", LN_column = "LN")
#'
#' @export
matching_breakdown = function(FN, LN, data, FN_column, LN_column) {
  FN_matching = partial_fuzzy_match(
    name = FN,
    all_names = data[[FN_column]],
    do_clean_name = FALSE
  )
  names(FN_matching) = paste0("FN_", names(FN_matching))

  LN_matching = partial_fuzzy_match(
    name = LN,
    all_names = data[[LN_column]],
    do_clean_name = FALSE
  )
  names(LN_matching) = paste0("LN_", names(LN_matching))

  cbind(data, FN_matching, LN_matching)
}


#' Score Combined First-Name and Last-Name Matches
#'
#' Combines separate first-name and last-name matching signals into a single
#' composite score and a scaled confidence measure between \code{0} and
#' \code{1}.
#'
#' The score is heuristic rather than probabilistic. It is intended to rank
#' candidate matches and provide an interpretable confidence-like measure.
#'
#' @param partial_matching Data frame returned by
#'   \code{matching_breakdown()}.
#' @param w_exact_both Numeric weight applied when both first and last names
#'   exactly match.
#' @param w_exact_token_both Numeric weight applied when both first and last
#'   names have exact token matches.
#' @param w_partial_start_both Numeric weight applied when both first and
#'   last names partially match at the start of a token.
#' @param w_partial_anywhere_both Numeric weight applied when both first and
#'   last names partially match anywhere within a token.
#' @param w_initial_both Numeric weight applied when both first and last
#'   names share token initials.
#' @param w_fuzzy_mean Numeric weight applied to the mean first-name and
#'   last-name fuzzy similarity.
#'
#' @return The input data frame with additional columns:
#'   \describe{
#'     \item{mean_fuzzy}{Mean of \code{FN_fuzzy} and \code{LN_fuzzy}.}
#'     \item{match_score}{Composite matching score.}
#'     \item{match_confidence}{Scaled confidence between \code{0} and
#'       \code{1}.}
#'   }
#'
#' @examples
#' people = data.frame(
#'   FN = c("MATTHEW", "MATT"),
#'   LN = c("JONES", "JONES"),
#'   stringsAsFactors = FALSE
#' )
#'
#' x = matching_breakdown("Matt", "Jones", people, "FN", "LN")
#' score_name_matches(x)
#'
#' @export
score_name_matches = function(
    partial_matching,
    w_exact_both = 5,
    w_exact_token_both = 3,
    w_partial_start_both = 2,
    w_partial_anywhere_both = 1,
    w_initial_both = 0.5,
    w_fuzzy_mean = 3
) {
  partial_matching$mean_fuzzy = (
    partial_matching$FN_fuzzy + partial_matching$LN_fuzzy
  ) / 2

  partial_matching$match_score =
    w_exact_both * (partial_matching$FN_exact & partial_matching$LN_exact) +
    w_exact_token_both * (partial_matching$FN_exact_token & partial_matching$LN_exact_token) +
    w_partial_start_both * (partial_matching$FN_partial_start & partial_matching$LN_partial_start) +
    w_partial_anywhere_both * (partial_matching$FN_partial_anywhere & partial_matching$LN_partial_anywhere) +
    w_initial_both * (partial_matching$FN_initial_token & partial_matching$LN_initial_token) +
    w_fuzzy_mean * partial_matching$mean_fuzzy

  max_possible_score = w_exact_both +
    w_exact_token_both +
    w_partial_start_both +
    w_partial_anywhere_both +
    w_initial_both +
    w_fuzzy_mean

  partial_matching$match_confidence = pmin(
    1,
    pmax(0, partial_matching$match_score / max_possible_score)
  )

  partial_matching
}


#' Derive Human-Readable Match Method Labels
#'
#' Converts combined first-name and last-name matching signals into a simple
#' text label describing the strongest observed matching mechanism.
#'
#' @param df Data frame produced by \code{score_name_matches()}.
#' @param fuzzy_only_threshold Numeric threshold used to classify a candidate
#'   as \code{"FUZZY"} or \code{"INITIAL + FUZZY"} when no stronger signal
#'   is present.
#'
#' @return Character vector of method labels, one per row.
#'
#' @examples
#' people = data.frame(
#'   FN = c("MATTHEW", "MATT"),
#'   LN = c("JONES", "JONES"),
#'   stringsAsFactors = FALSE
#' )
#'
#' x = matching_breakdown("Matt", "Jones", people, "FN", "LN")
#' x = score_name_matches(x)
#' derive_match_method(x)
#'
#' @export
derive_match_method = function(df, fuzzy_only_threshold = 0.90) {
  out = rep("PARTIAL/FUZZY", nrow(df))

  both_exact = df$FN_exact & df$LN_exact
  both_exact_token = df$FN_exact_token & df$LN_exact_token
  both_partial_start = df$FN_partial_start & df$LN_partial_start
  both_partial_anywhere = df$FN_partial_anywhere & df$LN_partial_anywhere
  both_initial = df$FN_initial_token & df$LN_initial_token
  high_fuzzy = df$mean_fuzzy >= fuzzy_only_threshold

  out[both_exact] = "EXACT"
  out[!both_exact & both_exact_token] = "TOKEN EXACT"
  out[!both_exact & !both_exact_token & both_partial_start] = "PARTIAL START"
  out[!both_exact & !both_exact_token & !both_partial_start & both_partial_anywhere] = "PARTIAL ANYWHERE"
  out[!both_exact & !both_exact_token & !both_partial_start & !both_partial_anywhere & both_initial & high_fuzzy] = "INITIAL + FUZZY"
  out[!both_exact & !both_exact_token & !both_partial_start & !both_partial_anywhere & high_fuzzy] = "FUZZY"

  out
}


#' Rank Candidate Name Matches
#'
#' Scores and ranks candidate matches from strongest to weakest, adding both
#' a composite score and a human-readable match method.
#'
#' @param partial_matching Data frame returned by
#'   \code{matching_breakdown()}.
#'
#' @return Ranked data frame with \code{match_score},
#'   \code{match_confidence}, and \code{match_method}.
#'
#' @examples
#' people = data.frame(
#'   FN = c("MATTHEW", "MATT", "MARK"),
#'   LN = c("JONES", "JONES", "JONES"),
#'   stringsAsFactors = FALSE
#' )
#'
#' x = matching_breakdown("Matt", "Jones", people, "FN", "LN")
#' rank_name_matches(x)
#'
#' @export
rank_name_matches = function(partial_matching) {
  partial_matching = score_name_matches(partial_matching)
  partial_matching$match_method = derive_match_method(partial_matching)

  partial_matching = partial_matching[
    order(
      -partial_matching$match_score,
      -partial_matching$match_confidence,
      -partial_matching$mean_fuzzy,
      -(partial_matching$FN_exact + partial_matching$LN_exact),
      -(partial_matching$FN_exact_token + partial_matching$LN_exact_token)
    ),
    ,
    drop = FALSE
  ]

  rownames(partial_matching) = NULL
  partial_matching
}


#' Collapse Multiple Candidate Rows to Best Row per Identifier
#'
#' Keeps only the highest-ranked row for each unique identifier. This is
#' useful when \code{expand_name_variants()} creates multiple candidate rows
#' per person.
#'
#' @param df Data frame of ranked candidate matches.
#' @param UPI_column Character scalar. Name of the unique identifier column.
#'
#' @return Data frame with at most one row per unique value of
#'   \code{UPI_column}.
#'
#' @examples
#' df = data.frame(
#'   UPI = c("A", "A", "B"),
#'   match_score = c(0.9, 0.8, 0.7),
#'   match_confidence = c(0.9, 0.8, 0.7),
#'   mean_fuzzy = c(0.9, 0.8, 0.7)
#' )
#'
#' collapse_to_best_per_upi(df, "UPI")
#'
#' @export
collapse_to_best_per_upi = function(df, UPI_column) {
  if (!UPI_column %in% names(df)) {
    return(df)
  }

  df = df[
    order(
      -df$match_score,
      -df$match_confidence,
      -df$mean_fuzzy
    ),
    ,
    drop = FALSE
  ]

  df = df[!duplicated(df[[UPI_column]]), , drop = FALSE]
  rownames(df) = NULL
  df
}


#' Format Top Candidate Matches for Manual Review
#'
#' Creates a single character string summarising the top candidate matches,
#' one per line, for manual review.
#'
#' @param df Ranked candidate match data frame.
#' @param UPI_column Character scalar. Name of the unique identifier column.
#' @param FN_column Character scalar. Name of the first-name column.
#' @param LN_column Character scalar. Name of the last-name column.
#' @param n Integer. Number of top candidates to include.
#' @param digits Integer. Number of decimal places to display for confidence.
#'
#' @return Character scalar containing top candidates separated by newline
#'   characters, or \code{NA_character_} if \code{df} has no rows.
#'
#' @examples
#' df = data.frame(
#'   UPI = c("A", "B"),
#'   FN = c("MATTHEW", "MARK"),
#'   LN = c("JONES", "SMITH"),
#'   match_confidence = c(0.95, 0.62),
#'   stringsAsFactors = FALSE
#' )
#'
#' format_top_matches(df, "UPI", "FN", "LN", n = 2)
#'
#' @export
format_top_matches = function(df,
                              UPI_column,
                              FN_column,
                              LN_column,
                              n = 5,
                              digits = 3) {
  if (nrow(df) == 0) {
    return(NA_character_)
  }

  top_df = utils::head(df, n)

  lines = paste0(
    top_df[[UPI_column]],
    ": ",
    top_df[[FN_column]],
    " ",
    top_df[[LN_column]],
    " = ",
    format(round(top_df$match_confidence, digits), nsmall = digits)
  )

  paste(lines, collapse = "\n")
}


#' Match a Person to a Candidate Data Set Using Exact, Partial, and Fuzzy Matching
#'
#' Matches a single person to a candidate data set. The function first checks
#' for exact first-name and last-name matches, including swapped names. If no
#' exact match is found, it falls back to partial and fuzzy matching using a
#' combination of token overlap, prefix matching, substring matching, initial
#' matching, and token-level Jaro-Winkler similarity.
#'
#' Matching is performed after expanding name variants and cleaning names with
#' \code{clean_name()}.
#'
#' @param FN Character scalar. First name of the person to match.
#' @param LN Character scalar. Last name of the person to match.
#' @param data Data frame containing the reference data to match against.
#' @param FN_column Character scalar. Name of the first-name column in
#'   \code{data}. Default is \code{"FN"}.
#' @param LN_column Character scalar. Name of the last-name column in
#'   \code{data}. Default is \code{"LN"}.
#' @param UPI_column Character scalar. Name of the unique person identifier
#'   column in \code{data}. Default is \code{"UPI"}.
#' @param min_partial_confidence Numeric between \code{0} and \code{1}.
#'   Minimum confidence required for a partial/fuzzy match to be retained.
#' @param allow_partial_swap Logical; if \code{TRUE}, also considers partial
#'   and fuzzy matching with first and last names swapped.
#' @param return_all_best Logical; if \code{TRUE}, returns all tied best
#'   matches. If \code{FALSE}, only the first best match is returned.
#' @param top_n_manual Integer. Number of top candidate matches to summarise
#'   for manual review.
#' @param ... Additional arguments reserved for future extensions.
#'
#' @return A list with components:
#'   \describe{
#'     \item{UPI}{Matched identifier(s), or \code{NA} if no match is found.}
#'     \item{people}{Data frame of matched people.}
#'     \item{message}{Character string describing how the match was found.}
#'     \item{confidence}{Numeric confidence between \code{0} and \code{1}.}
#'     \item{top_matches}{Character string listing the top candidate matches
#'       for manual review.}
#'   }
#'
#' @examples
#' botanist_db = data.frame(
#'   UPI = c("CL001", "JB002", "AH003", "AA004", "JB003", "GB004"),
#'   FN = c("Carl---Karl", "Joseph", "Alexander---Alex", "Agnes", "Janet", "George"),
#'   LN = c("Linnaeus---Linnaeus", "Banks", "von Humboldt---von Humboldt",
#'     "Arber", "Browne", "Bentham"),
#'   Expedition = c("Sweden", "Endeavour", "South America", "UK", "UK", "Australia"),
#'   stringsAsFactors = FALSE
#' )
#'
#' match_person_to_data2(
#'   FN = "Karl",
#'   LN = "Linnaeus",
#'   data = botanist_db
#' )
#'
#' match_person_to_data2(
#'   FN = "Janet",
#'   LN = "Brown",
#'   data = botanist_db
#' )
#'
#' @export
match_person_to_data2 = function(FN, LN, data,
                                 FN_column = "FN",
                                 LN_column = "LN",
                                 UPI_column = "UPI",
                                 min_partial_confidence = 0.35,
                                 allow_partial_swap = TRUE,
                                 return_all_best = TRUE,
                                 top_n_manual = 5,
                                 ...) {
  if (!FN_column %in% names(data)) stop("FN_column does not exist in data")
  if (!LN_column %in% names(data)) stop("LN_column does not exist in data")

  if (!UPI_column %in% names(data)) {
    UPI_column = "UPI_column"
    data$UPI_column = seq_len(nrow(data))
  }

  original_columns = names(data)

  data = expand_name_variants(data, FN_column, LN_column)

  FN = clean_name(FN)
  LN = clean_name(LN)
  data[[FN_column]] = clean_name(data[[FN_column]])
  data[[LN_column]] = clean_name(data[[LN_column]])

  FN_index = which(data[[FN_column]] == FN)
  LN_index = which(data[[LN_column]] == LN)
  both_index = intersect(FN_index, LN_index)

  FN_swap_index = which(data[[FN_column]] == LN)
  LN_swap_index = which(data[[LN_column]] == FN)
  both_swap_index = intersect(FN_swap_index, LN_swap_index)

  if (length(both_index) > 0) {
    people = data[both_index, , drop = FALSE]
    people$match_score = 1
    people$match_confidence = 1
    people$match_method = "EXACT"
    people$match_orientation = "STANDARD"

    people = people[order(people[[UPI_column]]), , drop = FALSE]
    people = standardise_match_people(people, original_columns)

    return(list(
      UPI = people[[UPI_column]],
      people = people,
      message = "EXACT",
      confidence = 1,
      top_matches = format_top_matches(
        df = people,
        UPI_column = UPI_column,
        FN_column = FN_column,
        LN_column = LN_column,
        n = top_n_manual
      )
    ))
  }

  if (length(both_swap_index) > 0) {
    people = data[both_swap_index, , drop = FALSE]
    people$match_score = 1
    people$match_confidence = 1
    people$match_method = "EXACT (Swap)"
    people$match_orientation = "SWAP"

    people = people[order(people[[UPI_column]]), , drop = FALSE]
    people = standardise_match_people(people, original_columns)

    return(list(
      UPI = people[[UPI_column]],
      people = people,
      message = "EXACT (Swap)",
      confidence = 1,
      top_matches = format_top_matches(
        df = people,
        UPI_column = UPI_column,
        FN_column = FN_column,
        LN_column = LN_column,
        n = top_n_manual
      )
    ))
  }

  standard_matches = matching_breakdown(
    FN = FN,
    LN = LN,
    data = data,
    FN_column = FN_column,
    LN_column = LN_column
  )

  standard_matches = rank_name_matches(standard_matches)
  standard_matches$match_orientation = "STANDARD"

  if (allow_partial_swap) {
    swap_matches = matching_breakdown(
      FN = LN,
      LN = FN,
      data = data,
      FN_column = FN_column,
      LN_column = LN_column
    )

    swap_matches = rank_name_matches(swap_matches)
    swap_matches$match_orientation = "SWAP"

    all_partial = rbind(standard_matches, swap_matches)
  } else {
    all_partial = standard_matches
  }

  all_partial = collapse_to_best_per_upi(all_partial, UPI_column = UPI_column)

  all_partial = all_partial[
    order(
      -all_partial$match_score,
      -all_partial$match_confidence,
      -all_partial$mean_fuzzy
    ),
    ,
    drop = FALSE
  ]
  rownames(all_partial) = NULL

  all_partial = all_partial[
    all_partial$match_confidence >= min_partial_confidence,
    ,
    drop = FALSE
  ]

  if (nrow(all_partial) == 0) {
    empty_people = data[0, , drop = FALSE]
    empty_people = standardise_match_people(empty_people, original_columns)

    return(list(
      UPI = NA,
      people = empty_people,
      message = "NO MATCH",
      confidence = 0,
      top_matches = NA_character_
    ))
  }

  best_conf = max(all_partial$match_confidence, na.rm = TRUE)
  best_matches = all_partial[
    all_partial$match_confidence == best_conf,
    ,
    drop = FALSE
  ]

  if (!return_all_best) {
    best_matches = best_matches[1, , drop = FALSE]
  }

  method_text = unique(best_matches$match_method)
  orientation_text = unique(best_matches$match_orientation)

  message = paste0(
    "PARTIAL/FUZZY: ",
    paste(method_text, collapse = " / "),
    if ("SWAP" %in% orientation_text) " (Swap considered)" else ""
  )

  best_matches = standardise_match_people(best_matches, original_columns)

  list(
    UPI = best_matches[[UPI_column]],
    people = best_matches,
    message = message,
    confidence = best_conf,
    top_matches = format_top_matches(
      df = all_partial,
      UPI_column = UPI_column,
      FN_column = FN_column,
      LN_column = LN_column,
      n = top_n_manual
    )
  )
}


#' Match a Person to Grouped Data Using Exact, Partial, and Fuzzy Matching
#'
#' Matches a single person to a reference data set, optionally restricted to
#' a specified group such as a department, team, or expedition. This is a
#' grouped wrapper around \code{match_person_to_data2()}.
#'
#' @param FN Character scalar. First name of the person to match.
#' @param LN Character scalar. Last name of the person to match.
#' @param data Data frame containing the reference data.
#' @param FN_column Character scalar. First-name column in \code{data}.
#' @param LN_column Character scalar. Last-name column in \code{data}.
#' @param UPI_column Character scalar. Unique person identifier column in
#'   \code{data}.
#' @param group_column Optional character scalar. Grouping column in
#'   \code{data}.
#' @param group_value Optional scalar. Group value to filter to before
#'   matching.
#' @param min_partial_confidence Numeric between \code{0} and \code{1}.
#'   Minimum confidence required for a partial/fuzzy match.
#' @param allow_partial_swap Logical; if \code{TRUE}, considers partial/fuzzy
#'   swapped-name matching.
#' @param return_all_best Logical; if \code{TRUE}, returns all tied best
#'   matches.
#' @param top_n_manual Integer. Number of top candidate matches to summarise
#'   for manual review.
#' @param ... Additional arguments passed to \code{match_person_to_data2()}.
#'
#' @return A list in the same format as \code{match_person_to_data2()}.
#'
#' @examples
#' botanist_db = data.frame(
#'   UPI = c("CL001", "JB002", "AH003", "AA004", "JB003", "GB004"),
#'   FN = c("Carl---Karl", "Joseph", "Alexander---Alex", "Agnes", "Janet", "George"),
#'   LN = c("Linnaeus---Linnaeus", "Banks", "von Humboldt---von Humboldt",
#'     "Arber", "Browne", "Bentham"),
#'   Expedition = c("Sweden", "Endeavour", "South America", "UK", "UK", "Australia"),
#'   stringsAsFactors = FALSE
#' )
#'
#' match_person_to_grouped_data2(
#'   FN = "Janet",
#'   LN = "Brown",
#'   data = botanist_db,
#'   group_column = "Expedition",
#'   group_value = "UK"
#' )
#'
#' @export
match_person_to_grouped_data2 = function(FN, LN, data,
                                         FN_column = "FN",
                                         LN_column = "LN",
                                         UPI_column = "UPI",
                                         group_column = NULL,
                                         group_value = NULL,
                                         min_partial_confidence = 0.35,
                                         allow_partial_swap = TRUE,
                                         return_all_best = TRUE,
                                         top_n_manual = 5,
                                         ...) {

  # Filter by group if specified
  if (!is.null(group_column) && !is.null(group_value)) {
    data = data[which(data[[group_column]] == group_value), , drop = FALSE]

    if (nrow(data) == 0) {
      out = data.frame(matrix(NA, nrow = 1, ncol = ncol(data)))
      names(out) = names(data)

      warning(paste("No individuals in group:", group_value))

      return(list(
        UPI = NA,
        people = out,
        message = paste("No individuals in group:", group_value),
        confidence = 0,
        top_matches = NA_character_
      ))
    }
  }

  # Delegate to main matching function
  match_person_to_data2(
    FN = FN,
    LN = LN,
    data = data,
    FN_column = FN_column,
    LN_column = LN_column,
    UPI_column = UPI_column,
    min_partial_confidence = min_partial_confidence,
    allow_partial_swap = allow_partial_swap,
    return_all_best = return_all_best,
    top_n_manual = top_n_manual,
    ...
  )
}




#' Standardise matched people output
#'
#' This function subsets a data frame to retain only the original columns
#' provided along with selected matching metadata columns. It also resets
#' row names.
#'
#' @param df A data.frame containing matched people data.
#' @param original_columns A character vector of column names that should be
#' retained from the original dataset.
#'
#' @return A data.frame containing only the selected original columns and any
#' available matching metadata columns:
#' \code{match_score}, \code{match_confidence}, \code{match_method},
#' \code{match_orientation}.
#'
#' @examples
#' df <- data.frame(
#'   name = c("Alice", "Bob"),
#'   match_score = c(0.9, 0.8),
#'   extra = c(1, 2)
#' )
#' standardise_match_people(df, c("name"))
#'
#' @export
standardise_match_people = function(df, original_columns) {
  keep_meta = c(
    "match_score",
    "match_confidence",
    "match_method",
    "match_orientation"
  )

  keep_cols = c(
    original_columns[original_columns %in% names(df)],
    keep_meta[keep_meta %in% names(df)]
  )

  df = df[, keep_cols, drop = FALSE]
  rownames(df) = NULL
  df
}


#' Escape regular expression special characters
#'
#' Escapes all regex metacharacters in a character vector so that the resulting
#' strings can be safely used in regular expression patterns.
#'
#' @param x A character vector of strings to escape.
#'
#' @return A character vector with regex metacharacters escaped.
#'
#' @details
#' The following characters are escaped: \code{[]{}()+*^$|\\?.}
#'
#' @examples
#' escape_regex("a+b")   # returns "a\\+b"
#' escape_regex("file?.txt")  # returns "file\\?\\.txt"
#'
#' @export
escape_regex = function(x) {
  gsub("([][{}()+*^$|\\\\?.])", "\\\\\\1", x)
}
#' Classify Match Decision and Review Requirement
#'
#' Determines whether a candidate match should be automatically accepted or
#' flagged for manual review, based on the strength and uniqueness of the
#' match. This function operates on the top-ranked matches produced by the
#' matching pipeline and applies a set of heuristic rules using exact,
#' partial, and fuzzy matching signals.
#'
#' The function distinguishes between:
#' \itemize{
#'   \item \strong{Match method}: how the match was identified (e.g. exact,
#'     token match, fuzzy).
#'   \item \strong{Match decision}: whether the match can be automatically
#'     accepted or should be reviewed.
#'   \item \strong{Review flag}: a logical indicator of whether manual review
#'     is required.
#' }
#'
#' Typical behaviour:
#' \itemize{
#'   \item Exact full matches are automatically accepted.
#'   \item Matches with exact surnames and a single strong first-name match
#'     (exact, token, partial start, or high fuzzy) are automatically accepted.
#'   \item Matches involving swapped names, multiple equally strong candidates,
#'     non-exact surnames, or weak fuzzy similarity are flagged for review.
#' }
#'
#' @param best_matches Data frame of the best candidate matches (typically the
#'   subset of matches with the highest confidence score).
#' @param all_partial Full data frame of all candidate matches prior to filtering,
#'   used for context (e.g. identifying ambiguity).
#' @param strong_fuzzy_threshold Numeric. Threshold above which fuzzy similarity
#'   is considered strong (default \code{0.92}).
#' @param min_auto_confidence Numeric. Minimum confidence required to allow
#'   automatic acceptance of a match (default \code{0.75}).
#'
#' @return A list with components:
#'   \describe{
#'     \item{match_method}{Character string describing how the match was found
#'       (e.g. \code{"EXACT"}, \code{"PARTIAL START"}, \code{"FUZZY"}).}
#'     \item{match_decision}{Character string describing whether the match is
#'       automatically accepted or requires review.}
#'     \item{review_required}{Logical; \code{TRUE} if the match should be
#'       manually reviewed, \code{FALSE} otherwise.}
#'   }
#'
#' @examples
#' # Example using mock matching output
#' df = data.frame(
#'   FN_exact = c(TRUE),
#'   LN_exact = c(TRUE),
#'   FN_exact_token = c(TRUE),
#'   LN_exact_token = c(TRUE),
#'   FN_partial_start = c(TRUE),
#'   LN_partial_start = c(TRUE),
#'   FN_fuzzy = c(1),
#'   LN_fuzzy = c(1),
#'   match_confidence = c(1),
#'   match_method = c("EXACT"),
#'   match_orientation = c("STANDARD"),
#'   stringsAsFactors = FALSE
#' )
#'
#' classify_match_decision(
#'   best_matches = df,
#'   all_partial = df
#' )
#'
#' @export
classify_match_decision = function(best_matches,
                                   all_partial,
                                   strong_fuzzy_threshold = 0.92,
                                   min_auto_confidence = 0.75) {

  n_best = nrow(best_matches)
  top = best_matches[1, , drop = FALSE]

  is_swap = identical(top$match_orientation, "SWAP")

  fn_strong =
    isTRUE(top$FN_exact) ||
    isTRUE(top$FN_exact_token) ||
    isTRUE(top$FN_partial_start) ||
    (!is.na(top$FN_fuzzy) && top$FN_fuzzy >= strong_fuzzy_threshold)

  ln_exact = isTRUE(top$LN_exact)
  ln_token = isTRUE(top$LN_exact_token)
  high_conf = !is.na(top$match_confidence) && top$match_confidence >= min_auto_confidence

  if (isTRUE(top$FN_exact) && isTRUE(top$LN_exact) && !is_swap) {
    return(list(
      match_method = "EXACT",
      match_decision = "AUTO: exact full match",
      review_required = FALSE
    ))
  }

  if (isTRUE(top$FN_exact) && isTRUE(top$LN_exact) && is_swap) {
    return(list(
      match_method = "EXACT (Swap)",
      match_decision = "REVIEW: exact full match after swapping first and last names",
      review_required = TRUE
    ))
  }

  if (n_best > 1) {
    return(list(
      match_method = top$match_method,
      match_decision = "REVIEW: multiple equally strong candidate matches",
      review_required = TRUE
    ))
  }

  if (ln_exact && fn_strong && high_conf && !is_swap) {
    return(list(
      match_method = top$match_method,
      match_decision = "AUTO: exact surname and unique strong first-name match",
      review_required = FALSE
    ))
  }

  if (ln_token && isTRUE(top$FN_exact) && high_conf && !is_swap) {
    return(list(
      match_method = top$match_method,
      match_decision = "AUTO: exact first name and strong surname token match",
      review_required = FALSE
    ))
  }

  if (is_swap) {
    return(list(
      match_method = top$match_method,
      match_decision = "REVIEW: match depends on swapped first and last names",
      review_required = TRUE
    ))
  }

  if (ln_exact && !fn_strong) {
    return(list(
      match_method = top$match_method,
      match_decision = "REVIEW: exact surname but first name match is weak",
      review_required = TRUE
    ))
  }

  if (!ln_exact) {
    return(list(
      match_method = top$match_method,
      match_decision = "REVIEW: surname is not an exact match",
      review_required = TRUE
    ))
  }

  if (!high_conf) {
    return(list(
      match_method = top$match_method,
      match_decision = "REVIEW: low-confidence partial or fuzzy match",
      review_required = TRUE
    ))
  }

  list(
    match_method = top$match_method,
    match_decision = "REVIEW: partial or fuzzy match",
    review_required = TRUE
  )
}


#' Match Multiple People to a Reference Data Set
#'
#' Matches multiple people from an input data frame to a reference data set,
#' optionally within groups such as teams, departments, or expeditions. This
#' is a batch wrapper around \code{match_person_to_grouped_data2()}.
#'
#' The output includes the original input columns, the matching method,
#' match decision, numeric match confidence, review flag, optional top
#' candidate summaries for manual review, and matched reference data columns
#' prefixed with \code{"NameDB_"}.
#'
#' @param to_match Data frame of people to match.
#' @param data Data frame containing the reference data to match against.
#' @param FN_column Character scalar. First-name column in \code{data}.
#' @param LN_column Character scalar. Last-name column in \code{data}.
#' @param UPI_column Character scalar. Unique person identifier column in
#'   \code{data}.
#' @param group_column Optional character scalar. Grouping column in
#'   \code{data}.
#' @param group_value Optional scalar. If supplied, uses this fixed group
#'   value for all rows of \code{to_match}.
#' @param to_match_FN_column Character scalar. First-name column in
#'   \code{to_match}. Defaults to \code{FN_column}.
#' @param to_match_LN_column Character scalar. Last-name column in
#'   \code{to_match}. Defaults to \code{LN_column}.
#' @param to_match_group_column Optional character scalar. Grouping column in
#'   \code{to_match}. Used when \code{group_column} is supplied.
#' @param include_non_matched Logical; if \code{TRUE}, rows with no match are
#'   retained in the output.
#' @param include_top_n_matches Logical; if \code{TRUE}, adds a
#'   \code{TopNMatches} column for manual review.
#' @param top_n_manual Integer. Number of top candidate matches to include in
#'   \code{TopNMatches}.
#' @param min_partial_confidence Numeric between \code{0} and \code{1}.
#'   Minimum confidence required for a partial/fuzzy match.
#' @param allow_partial_swap Logical; if \code{TRUE}, allows partial/fuzzy
#'   swapped-name matching.
#' @param return_all_best Logical; if \code{TRUE}, returns all tied best
#'   matches for each input row.
#' @param verbose Logical; if \code{TRUE}, shows a progress bar via
#'   \pkg{pbapply}.
#' @param ... Additional arguments passed to
#'   \code{match_person_to_grouped_data2()}.
#'
#' @return A data frame of matched people. Includes:
#'   \describe{
#'     \item{Method}{How the match was found.}
#'     \item{MatchDecision}{Whether the match is auto-accepted or should be
#'       reviewed.}
#'     \item{MatchConfidence}{Numeric confidence between \code{0} and
#'       \code{1}.}
#'     \item{ReviewRequired}{Logical flag indicating whether manual review is
#'       required.}
#'     \item{TopNMatches}{Optional manual review summary.}
#'     \item{NameDB_*}{Matched reference data columns.}
#'   }
#'
#' @examples
#' to_match = data.frame(
#'   FN = c("Karl", "Janet"),
#'   LN = c("Linnaeus", "Brown"),
#'   stringsAsFactors = FALSE
#' )
#'
#' botanist_db = data.frame(
#'   UPI = c("CL001", "JB002", "AH003", "AA004", "JB003", "GB004"),
#'   FN = c("Carl---Karl", "Joseph", "Alexander---Alex", "Agnes", "Janet", "George"),
#'   LN = c("Linnaeus---Linnaeus", "Banks", "von Humboldt---von Humboldt",
#'     "Arber", "Browne", "Bentham"),
#'   Expedition = c("Sweden", "Endeavour", "South America", "UK", "UK", "Australia"),
#'   stringsAsFactors = FALSE
#' )
#'
#' match_people_to_data2(
#'   to_match = to_match,
#'   data = botanist_db,
#'   include_non_matched = TRUE,
#'   include_top_n_matches = TRUE,
#'   top_n_manual = 3,
#'   verbose = FALSE
#' )
#'
#' @export
match_people_to_data2 = function(to_match, data,
                                 FN_column = "FN",
                                 LN_column = "LN",
                                 UPI_column = "UPI",
                                 group_column = NULL,
                                 group_value = NULL,
                                 to_match_FN_column = FN_column,
                                 to_match_LN_column = LN_column,
                                 to_match_group_column = group_column,
                                 include_non_matched = FALSE,
                                 include_top_n_matches = FALSE,
                                 top_n_manual = 5,
                                 min_partial_confidence = 0.35,
                                 allow_partial_swap = TRUE,
                                 return_all_best = TRUE,
                                 verbose = TRUE,
                                 ...) {
  if (verbose) {
    requireNamespace("pbapply", quietly = TRUE)
    apply_fun = pbapply::pblapply
  } else {
    apply_fun = lapply
  }

  results = apply_fun(seq_len(nrow(to_match)), function(index) {
    d = to_match[index, , drop = FALSE]

    FN = d[[to_match_FN_column]]
    LN = d[[to_match_LN_column]]

    current_group_value = NULL
    if (!is.null(group_column) && !is.null(to_match_group_column)) {
      current_group_value = d[[to_match_group_column]]
    } else if (!is.null(group_value)) {
      current_group_value = group_value
    }

    out = match_person_to_grouped_data2(
      FN = FN,
      LN = LN,
      data = data,
      FN_column = FN_column,
      LN_column = LN_column,
      UPI_column = UPI_column,
      group_column = group_column,
      group_value = current_group_value,
      min_partial_confidence = min_partial_confidence,
      allow_partial_swap = allow_partial_swap,
      return_all_best = return_all_best,
      top_n_manual = top_n_manual,
      ...
    )

    ret = out$people

    if (nrow(ret) == 0 && !include_non_matched) {
      return(NULL)
    }

    if (nrow(ret) == 0 && include_non_matched) {
      ret = data.frame(matrix(NA, nrow = 1, ncol = length(names(data))))
      names(ret) = names(data)
    }

    input_df = d[rep(1, nrow(ret)), , drop = FALSE]

    meta_df = data.frame(
      Method = rep(
        if (!is.null(out$match_method)) out$match_method else out$message,
        nrow(ret)
      ),
      MatchDecision = rep(out$message, nrow(ret)),
      MatchConfidence = rep(out$confidence, nrow(ret)),
      ReviewRequired = rep(
        if (!is.null(out$review_required)) out$review_required else (out$confidence < 1),
        nrow(ret)
      ),
      stringsAsFactors = FALSE
    )

    if (include_top_n_matches) {
      meta_df$TopNMatches = rep(out$top_matches, nrow(ret))
    }

    names(ret) = paste0("NameDB_", names(ret))

    out_df = cbind(
      input_df,
      meta_df,
      ret,
      stringsAsFactors = FALSE
    )

    out_df
  })

  results = Filter(Negate(is.null), results)

  if (length(results) == 0) {
    return(data.frame())
  }

  all_cols = unique(unlist(lapply(results, names)))

  results = lapply(results, function(x) {
    missing_cols = setdiff(all_cols, names(x))
    if (length(missing_cols) > 0) {
      for (col in missing_cols) {
        x[[col]] = NA
      }
    }
    x = x[, all_cols, drop = FALSE]
    x
  })

  out = do.call(rbind, results)
  rownames(out) = NULL
  out
}
