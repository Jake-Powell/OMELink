# Match Multiple People to a Reference Data Set

Matches multiple people from an input data frame to a reference data
set, optionally within groups such as teams, departments, or
expeditions. This is a batch wrapper around
[`match_person_to_grouped_data2()`](https://jake-powell.github.io/OMELink/reference/match_person_to_grouped_data2.md).

## Usage

``` r
match_people_to_data2(
  to_match,
  data,
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
  ...
)
```

## Arguments

- to_match:

  Data frame of people to match.

- data:

  Data frame containing the reference data to match against.

- FN_column:

  Character scalar. First-name column in `data`.

- LN_column:

  Character scalar. Last-name column in `data`.

- UPI_column:

  Character scalar. Unique person identifier column in `data`.

- group_column:

  Optional character scalar. Grouping column in `data`.

- group_value:

  Optional scalar. If supplied, uses this fixed group value for all rows
  of `to_match`.

- to_match_FN_column:

  Character scalar. First-name column in `to_match`. Defaults to
  `FN_column`.

- to_match_LN_column:

  Character scalar. Last-name column in `to_match`. Defaults to
  `LN_column`.

- to_match_group_column:

  Optional character scalar. Grouping column in `to_match`. Used when
  `group_column` is supplied.

- include_non_matched:

  Logical; if `TRUE`, rows with no match are retained in the output.

- include_top_n_matches:

  Logical; if `TRUE`, adds a `TopNMatches` column for manual review.

- top_n_manual:

  Integer. Number of top candidate matches to include in `TopNMatches`.

- min_partial_confidence:

  Numeric between `0` and `1`. Minimum confidence required for a
  partial/fuzzy match.

- allow_partial_swap:

  Logical; if `TRUE`, allows partial/fuzzy swapped-name matching.

- return_all_best:

  Logical; if `TRUE`, returns all tied best matches for each input row.

- verbose:

  Logical; if `TRUE`, shows a progress bar via pbapply.

- ...:

  Additional arguments passed to
  [`match_person_to_grouped_data2()`](https://jake-powell.github.io/OMELink/reference/match_person_to_grouped_data2.md).

## Value

A data frame of matched people. Includes:

- Method:

  How the match was found.

- MatchDecision:

  Whether the match is auto-accepted or should be reviewed.

- MatchConfidence:

  Numeric confidence between `0` and `1`.

- ReviewRequired:

  Logical flag indicating whether manual review is required.

- TopNMatches:

  Optional manual review summary.

- NameDB\_\*:

  Matched reference data columns.

## Details

The output includes the original input columns, the matching method,
match decision, numeric match confidence, review flag, optional top
candidate summaries for manual review, and matched reference data
columns prefixed with `"NameDB_"`.

## Examples

``` r
to_match = data.frame(
  FN = c("Karl", "Janet"),
  LN = c("Linnaeus", "Brown"),
  stringsAsFactors = FALSE
)

botanist_db = data.frame(
  UPI = c("CL001", "JB002", "AH003", "AA004", "JB003", "GB004"),
  FN = c("Carl---Karl", "Joseph", "Alexander---Alex", "Agnes", "Janet", "George"),
  LN = c("Linnaeus---Linnaeus", "Banks", "von Humboldt---von Humboldt",
    "Arber", "Browne", "Bentham"),
  Expedition = c("Sweden", "Endeavour", "South America", "UK", "UK", "Australia"),
  stringsAsFactors = FALSE
)

match_people_to_data2(
  to_match = to_match,
  data = botanist_db,
  include_non_matched = TRUE,
  include_top_n_matches = TRUE,
  top_n_manual = 3,
  verbose = FALSE
)
#>      FN       LN                       Method                MatchDecision
#> 1  Karl Linnaeus                        EXACT                        EXACT
#> 2 Janet    Brown PARTIAL/FUZZY: PARTIAL START PARTIAL/FUZZY: PARTIAL START
#>   MatchConfidence ReviewRequired                  TopNMatches NameDB_UPI
#> 1       1.0000000          FALSE CL001: karl linnaeus = 1.000      CL001
#> 2       0.4425287           TRUE  JB003: janet browne = 0.443      JB003
#>   NameDB_FN NameDB_LN NameDB_Expedition NameDB_match_score
#> 1      karl  linnaeus            Sweden           1.000000
#> 2     janet    browne                UK           6.416667
#>   NameDB_match_confidence NameDB_match_method NameDB_match_orientation
#> 1               1.0000000               EXACT                 STANDARD
#> 2               0.4425287       PARTIAL START                 STANDARD
```
