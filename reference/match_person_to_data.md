# Match a Person's Name to a Data Frame of Individuals

Attempts to match a person's first and last name to a row in a dataset
using exact, swapped, or fuzzy matching techniques.

## Usage

``` r
match_person_to_data(
  FN,
  LN,
  data,
  FN_column = "FN",
  LN_column = "LN",
  UPI_column = "UPI",
  max_dist = 2,
  method = "osa",
  show_all_fuzzy = FALSE,
  ...
)
```

## Arguments

- FN:

  Character string. First name of the person to match.

- LN:

  Character string. Last name (surname) of the person to match.

- data:

  A data frame containing at least the columns for first name, last
  name, and UPI.

- FN_column:

  Character. Name of the column in \`data\` that contains first names.
  Default is \`"FN"\`.

- LN_column:

  Character. Name of the column in \`data\` that contains last names.
  Default is \`"LN"\`.

- UPI_column:

  Character. Name of the column in \`data\` that contains unique
  identifiers (UPI). Default is \`"UPI"\`.

- max_dist:

  Integer. Maximum string distance allowed for fuzzy matching. Default
  is \`2\`.

- method:

  Character. String distance method to use. Passed to
  \[stringdist::stringdist()\]. Default is \`"osa"\`.

- show_all_fuzzy:

  Logical. If \`TRUE\`, return all fuzzy matches instead of just the
  best match. Default is \`FALSE\`.

- ...:

  Additional parameters passed to \[clean_name()\] for name
  normalization.

## Value

A list with the following components:

- UPI:

  The matched UPI(s), or \`NA\` if no match.

- people:

  The matched row(s) from \`data\`.

- message:

  A character string describing the match type (e.g., \`"EXACT"\`,
  \`"FUZZY MATCH"\`).

## Examples

``` r
botanists <- data.frame(
  FN = c("Carl", "José", "Alexander", "Agnes", "  Jane  "),
  LN = c("Linnæus", "Banks", "Humboldt", "Arber", "Coldstream"),
  UPI = c("CL001", "JB002", "AH003", "AA004", "JC005"),
  stringsAsFactors = FALSE
)

# Exact match (accent-insensitive)
match_person_to_data("Jose", "Banks", botanists)
#> $UPI
#> [1] "JB002"
#> 
#> $people
#>     FN    LN   UPI
#> 2 jose banks JB002
#> 
#> $message
#> [1] "EXACT"
#> 

# Name with extra spaces
match_person_to_data("Jane", "Coldstream", botanists)
#> $UPI
#> [1] "JC005"
#> 
#> $people
#>         FN         LN   UPI
#> 5   jane   coldstream JC005
#> 
#> $message
#> [1] "LN only"
#> 

# Lowercase input, accented name in data
match_person_to_data("carl", "linnaeus", botanists)
#> $UPI
#> [1] "CL001"
#> 
#> $people
#>     FN       LN   UPI
#> 1 carl linnaeus CL001
#> 
#> $message
#> [1] "EXACT"
#> 

# Swapped names
match_person_to_data("Linnæus", "Carl", botanists)
#> $UPI
#> [1] "CL001"
#> 
#> $people
#>     FN       LN   UPI
#> 1 carl linnaeus CL001
#> 
#> $message
#> [1] "EXACT (Swap)"
#> 

# No match
match_person_to_data("Greg", "Mendel", botanists)
#> $UPI
#> [1] NA
#> 
#> $people
#>     FN   LN  UPI
#> 1 <NA> <NA> <NA>
#> 
#> $message
#> [1] "No match"
#> 

# Data with different column names
botanists2 <- data.frame(
  FN = c("Carl", "José", "Alexander", "Agnes", "  Jane  ", "Jake"),
  Surname = c("Linnæus", "Banks", "Humboldt", "Arber", "Coldstream", "Banks"),
  UPI = c("CL001", "JB002", "AH003", "AA004", "JC005", "CL002"),
  stringsAsFactors = FALSE
)

# Last name only, with multiple entries
match_person_to_data("John", "Banks", botanists2,
                     FN_column = "FN", LN_column = "Surname")
#> $UPI
#> [1] "JB002"
#> 
#> $people
#>     FN Surname   UPI
#> 2 jose   banks JB002
#> 
#> $message
#> [1] "FUZZY MATCH (best both FN & LN)"
#> 

```
