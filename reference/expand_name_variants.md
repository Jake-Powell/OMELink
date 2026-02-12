# Expand Rows by Name Variants

Splits first and last name columns (containing multiple names separated
by a delimiter) into multiple rows so that each row corresponds to a
single FN/LN pair. Other columns are repeated accordingly.

## Usage

``` r
expand_name_variants(data, FN_column, LN_column, sep = "---")
```

## Arguments

- data:

  A data frame containing at least the FN, LN, and UPI columns.

- FN_column:

  A string indicating the name of the first name/s column.

- LN_column:

  A string indicating the name of the last name/s column.

- sep:

  A string delimiter used to separate multiple names in a single cell
  (default is \`'—'\`).

## Value

A data frame where each row corresponds to a single combination of FN
and LN variant, with all original columns preserved and replicated as
necessary.

## Examples

``` r
botanists <- data.frame(
  FNs = c("Carl---Karl", "José", "Alexander---Alex---Alex", "Agnes", "  Jane  "),
  LNs = c("Linnaus---Linnaus", "Banks", "Humboldt---Humboldt---Humbouldt", "Arber", "Coldstream"),
  UPI = c("CL001", "JB002", "AH003", "AA004", "JC005"),
  stringsAsFactors = FALSE
)

expand_name_variants(botanists, FN_column = "FNs", LN_column = "LNs")
#>           FNs        LNs   UPI
#> 1        Carl    Linnaus CL001
#> 1.1      Karl    Linnaus CL001
#> 2        José      Banks JB002
#> 3   Alexander   Humboldt AH003
#> 3.1      Alex   Humboldt AH003
#> 3.2      Alex  Humbouldt AH003
#> 4       Agnes      Arber AA004
#> 5      Jane   Coldstream JC005
```
