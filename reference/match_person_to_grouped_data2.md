# Match a Person to Grouped Data Using Exact, Partial, and Fuzzy Matching

Matches a single person to a reference data set, optionally restricted
to a specified group such as a department, team, or expedition. This is
a grouped wrapper around
[`match_person_to_data2()`](https://jake-powell.github.io/OMELink/reference/match_person_to_data2.md).

## Usage

``` r
match_person_to_grouped_data2(
  FN,
  LN,
  data,
  FN_column = "FN",
  LN_column = "LN",
  UPI_column = "UPI",
  group_column = NULL,
  group_value = NULL,
  min_partial_confidence = 0.35,
  allow_partial_swap = TRUE,
  return_all_best = TRUE,
  top_n_manual = 5,
  ...
)
```

## Arguments

- FN:

  Character scalar. First name of the person to match.

- LN:

  Character scalar. Last name of the person to match.

- data:

  Data frame containing the reference data.

- FN_column:

  Character scalar. First-name column in `data`.

- LN_column:

  Character scalar. Last-name column in `data`.

- UPI_column:

  Character scalar. Unique person identifier column in `data`.

- group_column:

  Optional character scalar. Grouping column in `data`.

- group_value:

  Optional scalar. Group value to filter to before matching.

- min_partial_confidence:

  Numeric between `0` and `1`. Minimum confidence required for a
  partial/fuzzy match.

- allow_partial_swap:

  Logical; if `TRUE`, considers partial/fuzzy swapped-name matching.

- return_all_best:

  Logical; if `TRUE`, returns all tied best matches.

- top_n_manual:

  Integer. Number of top candidate matches to summarise for manual
  review.

- ...:

  Additional arguments passed to
  [`match_person_to_data2()`](https://jake-powell.github.io/OMELink/reference/match_person_to_data2.md).

## Value

A list in the same format as
[`match_person_to_data2()`](https://jake-powell.github.io/OMELink/reference/match_person_to_data2.md).

## Examples

``` r
botanist_db = data.frame(
  UPI = c("CL001", "JB002", "AH003", "AA004", "JB003", "GB004"),
  FN = c("Carl---Karl", "Joseph", "Alexander---Alex", "Agnes", "Janet", "George"),
  LN = c("Linnaeus---Linnaeus", "Banks", "von Humboldt---von Humboldt",
    "Arber", "Browne", "Bentham"),
  Expedition = c("Sweden", "Endeavour", "South America", "UK", "UK", "Australia"),
  stringsAsFactors = FALSE
)

match_person_to_grouped_data2(
  FN = "Janet",
  LN = "Brown",
  data = botanist_db,
  group_column = "Expedition",
  group_value = "UK"
)
#> $UPI
#> [1] "JB003"
#> 
#> $people
#>     UPI    FN     LN Expedition match_score match_confidence  match_method
#> 1 JB003 janet browne         UK    6.416667        0.4425287 PARTIAL START
#>   match_orientation
#> 1          STANDARD
#> 
#> $message
#> [1] "PARTIAL/FUZZY: PARTIAL START"
#> 
#> $confidence
#> [1] 0.4425287
#> 
#> $top_matches
#> [1] "JB003: janet browne = 0.443"
#> 
```
