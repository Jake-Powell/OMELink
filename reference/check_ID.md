# Check ID Column Format and Establishment Number Consistency

This function checks that all IDs in the specified ID column of a data
frame:

- Have exactly 10 characters in length.

- Contain a substring from position 3 to 5 that matches the
  corresponding value in the establishment number column.

## Usage

``` r
check_ID(data, ID_column, estab_no_column)
```

## Arguments

- data:

  A data frame containing the ID and establishment number columns.

- ID_column:

  A string specifying the name of the ID column in \`data\`.

- estab_no_column:

  A string specifying the name of the establishment number column in
  \`data\`.

## Value

A list containing messages and row indices of any rows with issues. If
no issues are found, the function returns \`NULL\`.

## Examples

``` r
data <- data.frame(ID = c('1233344444', '3455666666'),
                   estab_no = c('333', '555'))
check_ID(data, "ID", "estab_no")
#> Warning: Digits 3-5 of ID do not match establishment number
#> [[1]]
#> [[1]]$message
#> [1] "Digits 3-5 of ID do not match establishment number"
#> 
#> [[1]]$index
#> [1] 2
#> 
#> 
```
