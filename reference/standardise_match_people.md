# Standardise matched people output

This function subsets a data frame to retain only the original columns
provided along with selected matching metadata columns. It also resets
row names.

## Usage

``` r
standardise_match_people(df, original_columns)
```

## Arguments

- df:

  A data.frame containing matched people data.

- original_columns:

  A character vector of column names that should be retained from the
  original dataset.

## Value

A data.frame containing only the selected original columns and any
available matching metadata columns: `match_score`, `match_confidence`,
`match_method`, `match_orientation`.

## Examples

``` r
df <- data.frame(
  name = c("Alice", "Bob"),
  match_score = c(0.9, 0.8),
  extra = c(1, 2)
)
standardise_match_people(df, c("name"))
#>    name match_score
#> 1 Alice         0.9
#> 2   Bob         0.8
```
