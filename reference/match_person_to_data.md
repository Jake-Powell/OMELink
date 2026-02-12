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

A list with components:

- UPI:

  The matched UPI(s), or \`NA\` if no match is found.

- people:

  The matched row(s) from \`data\`. If no match is found, a single row
  of \`NA\`s is returned.

- message:

  Character string describing the match type.

## Matching hierarchy

Matching is performed in the following order:

1.  Exact match on first and last name

2.  Exact match with names swapped

3.  Unique single-field exact match

4.  Fuzzy match on both fields

5.  Fuzzy match on either field

The first successful match type in this hierarchy is returned.

## Match message values

The returned list contains a \`message\` element describing the match
result. Possible values are:

**Exact matches**

- `"EXACT"` – Exact match on first and last name.

- `"EXACT (Swap)"` – Exact match with first and last names swapped.

**Single-field exact matches**

- `"FN only"` – Unique exact match on first name only.

- `"LN only"` – Unique exact match on last name only.

- `"FN only (Swap)"` – Unique exact match using swapped first name.

- `"LN only (Swap)"` – Unique exact match using swapped last name.

**Fuzzy matches (within \`max_dist\`)**

- `"FUZZY MATCH (best both FN & LN)"` – Best fuzzy match where both
  names are within tolerance.

- `"FUZZY MATCHES (both FN & LN)"` – All fuzzy matches where both names
  are within tolerance (\`show_all_fuzzy = TRUE\`).

- `"FUZZY PARTIAL MATCH (best FN or LN)"` – Best fuzzy match where only
  one name is within tolerance.

- `"FUZZY PARTIAL MATCHES (FN or LN)"` – All partial fuzzy matches
  (\`show_all_fuzzy = TRUE\`).

**No match**

- `"No match"` – No exact or fuzzy match found.

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
```
