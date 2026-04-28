# Match a Person to a Candidate Data Set Using Exact, Partial, and Fuzzy Matching

Matches a single person to a candidate data set. The function first
checks for exact first-name and last-name matches, including swapped
names. If no exact match is found, it falls back to partial and fuzzy
matching using a combination of token overlap, prefix matching,
substring matching, initial matching, and token-level Jaro-Winkler
similarity.

## Usage

``` r
match_person_to_data2(
  FN,
  LN,
  data,
  FN_column = "FN",
  LN_column = "LN",
  UPI_column = "UPI",
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

  Data frame containing the reference data to match against.

- FN_column:

  Character scalar. Name of the first-name column in `data`. Default is
  `"FN"`.

- LN_column:

  Character scalar. Name of the last-name column in `data`. Default is
  `"LN"`.

- UPI_column:

  Character scalar. Name of the unique person identifier column in
  `data`. Default is `"UPI"`.

- min_partial_confidence:

  Numeric between `0` and `1`. Minimum confidence required for a
  partial/fuzzy match to be retained.

- allow_partial_swap:

  Logical; if `TRUE`, also considers partial and fuzzy matching with
  first and last names swapped.

- return_all_best:

  Logical; if `TRUE`, returns all tied best matches. If `FALSE`, only
  the first best match is returned.

- top_n_manual:

  Integer. Number of top candidate matches to summarise for manual
  review.

- ...:

  Additional arguments reserved for future extensions.

## Value

A list with components:

- UPI:

  Matched identifier(s), or `NA` if no match is found.

- people:

  Data frame of matched people.

- message:

  Character string describing how the match was found.

- confidence:

  Numeric confidence between `0` and `1`.

- top_matches:

  Character string listing the top candidate matches for manual review.

## Details

Matching is performed after expanding name variants and cleaning names
with
[`clean_name()`](https://jake-powell.github.io/OMELink/reference/clean_name.md).

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

match_person_to_data2(
  FN = "Karl",
  LN = "Linnaeus",
  data = botanist_db
)
#> $UPI
#> [1] "CL001"
#> 
#> $people
#>     UPI   FN       LN Expedition match_score match_confidence match_method
#> 1 CL001 karl linnaeus     Sweden           1                1        EXACT
#>   match_orientation
#> 1          STANDARD
#> 
#> $message
#> [1] "EXACT"
#> 
#> $confidence
#> [1] 1
#> 
#> $top_matches
#> [1] "CL001: karl linnaeus = 1.000"
#> 

match_person_to_data2(
  FN = "Janet",
  LN = "Brown",
  data = botanist_db
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
