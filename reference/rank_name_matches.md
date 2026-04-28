# Rank Candidate Name Matches

Scores and ranks candidate matches from strongest to weakest, adding
both a composite score and a human-readable match method.

## Usage

``` r
rank_name_matches(partial_matching)
```

## Arguments

- partial_matching:

  Data frame returned by
  [`matching_breakdown()`](https://jake-powell.github.io/OMELink/reference/matching_breakdown.md).

## Value

Ranked data frame with `match_score`, `match_confidence`, and
`match_method`.

## Examples

``` r
people = data.frame(
  FN = c("MATTHEW", "MATT", "MARK"),
  LN = c("JONES", "JONES", "JONES"),
  stringsAsFactors = FALSE
)

x = matching_breakdown("Matt", "Jones", people, "FN", "LN")
rank_name_matches(x)
#>        FN    LN FN_given_name FN_data_name FN_exact FN_exact_token
#> 1    MATT JONES          Matt         MATT    FALSE          FALSE
#> 2 MATTHEW JONES          Matt      MATTHEW    FALSE          FALSE
#> 3    MARK JONES          Matt         MARK    FALSE          FALSE
#>   FN_partial_start FN_partial_anywhere FN_initial_token  FN_fuzzy LN_given_name
#> 1             TRUE                TRUE             TRUE 1.0000000         Jones
#> 2             TRUE                TRUE             TRUE 0.8571429         Jones
#> 3            FALSE               FALSE             TRUE 0.6666667         Jones
#>   LN_data_name LN_exact LN_exact_token LN_partial_start LN_partial_anywhere
#> 1        JONES    FALSE          FALSE             TRUE                TRUE
#> 2        JONES    FALSE          FALSE             TRUE                TRUE
#> 3        JONES    FALSE          FALSE             TRUE                TRUE
#>   LN_initial_token LN_fuzzy mean_fuzzy match_score match_confidence
#> 1             TRUE        1  1.0000000    6.500000        0.4482759
#> 2             TRUE        1  0.9285714    6.285714        0.4334975
#> 3             TRUE        1  0.8333333    3.000000        0.2068966
#>    match_method
#> 1 PARTIAL START
#> 2 PARTIAL START
#> 3 PARTIAL/FUZZY
```
