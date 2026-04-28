# Build First-Name and Last-Name Matching Breakdown

Applies
[`partial_fuzzy_match()`](https://jake-powell.github.io/OMELink/reference/partial_fuzzy_match.md)
separately to first names and last names in a candidate data frame, then
combines the results with the original data.

## Usage

``` r
matching_breakdown(FN, LN, data, FN_column, LN_column)
```

## Arguments

- FN:

  Character scalar. First name to match.

- LN:

  Character scalar. Last name to match.

- data:

  Data frame containing candidate people.

- FN_column:

  Character scalar. Name of the first-name column in `data`.

- LN_column:

  Character scalar. Name of the last-name column in `data`.

## Value

A data frame containing the original `data` plus prefixed first-name and
last-name matching columns.

## Examples

``` r
people = data.frame(
  FN = c("MATTHEW", "MATT", "JANET"),
  LN = c("JONES", "JONES", "BROWNE"),
  stringsAsFactors = FALSE
)

matching_breakdown("Matt", "Jones", people, FN_column = "FN", LN_column = "LN")
#>              FN     LN FN_given_name FN_data_name FN_exact FN_exact_token
#> MATTHEW MATTHEW  JONES          Matt      MATTHEW    FALSE          FALSE
#> MATT       MATT  JONES          Matt         MATT    FALSE          FALSE
#> JANET     JANET BROWNE          Matt        JANET    FALSE          FALSE
#>         FN_partial_start FN_partial_anywhere FN_initial_token  FN_fuzzy
#> MATTHEW             TRUE                TRUE             TRUE 0.8571429
#> MATT                TRUE                TRUE             TRUE 1.0000000
#> JANET              FALSE               FALSE            FALSE 0.6333333
#>         LN_given_name LN_data_name LN_exact LN_exact_token LN_partial_start
#> MATTHEW         Jones        JONES    FALSE          FALSE             TRUE
#> MATT            Jones        JONES    FALSE          FALSE             TRUE
#> JANET           Jones       BROWNE    FALSE          FALSE            FALSE
#>         LN_partial_anywhere LN_initial_token LN_fuzzy
#> MATTHEW                TRUE             TRUE      1.0
#> MATT                   TRUE             TRUE      1.0
#> JANET                 FALSE            FALSE      0.7
```
