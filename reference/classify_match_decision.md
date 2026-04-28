# Classify Match Decision and Review Requirement

Determines whether a candidate match should be automatically accepted or
flagged for manual review, based on the strength and uniqueness of the
match. This function operates on the top-ranked matches produced by the
matching pipeline and applies a set of heuristic rules using exact,
partial, and fuzzy matching signals.

## Usage

``` r
classify_match_decision(
  best_matches,
  all_partial,
  strong_fuzzy_threshold = 0.92,
  min_auto_confidence = 0.75
)
```

## Arguments

- best_matches:

  Data frame of the best candidate matches (typically the subset of
  matches with the highest confidence score).

- all_partial:

  Full data frame of all candidate matches prior to filtering, used for
  context (e.g. identifying ambiguity).

- strong_fuzzy_threshold:

  Numeric. Threshold above which fuzzy similarity is considered strong
  (default `0.92`).

- min_auto_confidence:

  Numeric. Minimum confidence required to allow automatic acceptance of
  a match (default `0.75`).

## Value

A list with components:

- match_method:

  Character string describing how the match was found (e.g. `"EXACT"`,
  `"PARTIAL START"`, `"FUZZY"`).

- match_decision:

  Character string describing whether the match is automatically
  accepted or requires review.

- review_required:

  Logical; `TRUE` if the match should be manually reviewed, `FALSE`
  otherwise.

## Details

The function distinguishes between:

- **Match method**: how the match was identified (e.g. exact, token
  match, fuzzy).

- **Match decision**: whether the match can be automatically accepted or
  should be reviewed.

- **Review flag**: a logical indicator of whether manual review is
  required.

Typical behaviour:

- Exact full matches are automatically accepted.

- Matches with exact surnames and a single strong first-name match
  (exact, token, partial start, or high fuzzy) are automatically
  accepted.

- Matches involving swapped names, multiple equally strong candidates,
  non-exact surnames, or weak fuzzy similarity are flagged for review.

## Examples

``` r
# Example using mock matching output
df = data.frame(
  FN_exact = c(TRUE),
  LN_exact = c(TRUE),
  FN_exact_token = c(TRUE),
  LN_exact_token = c(TRUE),
  FN_partial_start = c(TRUE),
  LN_partial_start = c(TRUE),
  FN_fuzzy = c(1),
  LN_fuzzy = c(1),
  match_confidence = c(1),
  match_method = c("EXACT"),
  match_orientation = c("STANDARD"),
  stringsAsFactors = FALSE
)

classify_match_decision(
  best_matches = df,
  all_partial = df
)
#> $match_method
#> [1] "EXACT"
#> 
#> $match_decision
#> [1] "AUTO: exact full match"
#> 
#> $review_required
#> [1] FALSE
#> 
```
