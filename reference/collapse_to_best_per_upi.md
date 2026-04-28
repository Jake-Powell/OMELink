# Collapse Multiple Candidate Rows to Best Row per Identifier

Keeps only the highest-ranked row for each unique identifier. This is
useful when
[`expand_name_variants()`](https://jake-powell.github.io/OMELink/reference/expand_name_variants.md)
creates multiple candidate rows per person.

## Usage

``` r
collapse_to_best_per_upi(df, UPI_column)
```

## Arguments

- df:

  Data frame of ranked candidate matches.

- UPI_column:

  Character scalar. Name of the unique identifier column.

## Value

Data frame with at most one row per unique value of `UPI_column`.

## Examples

``` r
df = data.frame(
  UPI = c("A", "A", "B"),
  match_score = c(0.9, 0.8, 0.7),
  match_confidence = c(0.9, 0.8, 0.7),
  mean_fuzzy = c(0.9, 0.8, 0.7)
)

collapse_to_best_per_upi(df, "UPI")
#>   UPI match_score match_confidence mean_fuzzy
#> 1   A         0.9              0.9        0.9
#> 2   B         0.7              0.7        0.7
```
