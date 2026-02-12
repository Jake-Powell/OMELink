# Match a Person to Grouped Data

Attempts to match a person (first and last name) to a row in a data
frame, optionally within a specific grouping (e.g., Department, Team).

## Usage

``` r
match_person_to_grouped_data(
  FN,
  LN,
  data,
  FN_column = "FN",
  LN_column = "LN",
  UPI_column = "UPI",
  group_column = NULL,
  group_value = NULL,
  max_dist = 2,
  method = "osa",
  show_all_fuzzy = FALSE,
  ...
)
```

## Arguments

- FN:

  First name

- LN:

  Last name

- data:

  Data frame containing name, UPI, and grouping columns

- FN_column:

  Column name for first names (default: "FN")

- LN_column:

  Column name for surnames (default: "LN")

- UPI_column:

  Column name for Unique Person Identifier (default: "UPI")

- group_column:

  (Optional) column name for grouping

- group_value:

  (Optional) value to filter by in the grouping column

- max_dist:

  Max string distance for fuzzy match (default: 2)

- method:

  Method for string distance (default: "osa")

- show_all_fuzzy:

  Show all fuzzy matches or just the best (default: FALSE)

- ...:

  Additional arguments passed to \`clean_name()\`

## Value

A list with UPI, matching row(s), and a message

## Examples

``` r
# Example data: Botanists grouped by expedition
botanists_grouped <- data.frame(
  FN = c("Carl", "Joseph", "Alexander", "Agnes", "Janet", "George"),
  LN = c("Linnaeus", "Banks", "von Humboldt", "Arber", "Browne", "Bentham"),
  UPI = c("CL001", "JB002", "AH003", "AA004", "JB003", "GB004"),
  Expedition = c("Sweden", "Endeavour", "South America", "UK", "UK", "Australia"),
  stringsAsFactors = FALSE
)

# Exact match within correct group
match_person_to_grouped_data("Carl", "Linnaeus", botanists_grouped, group_value = "Sweden")
#> $UPI
#> [1] "CL001"
#> 
#> $people
#>     FN       LN   UPI Expedition
#> 1 carl linnaeus CL001     Sweden
#> 
#> $message
#> [1] "EXACT"
#> 

# Will match Joseph Banks only within the "Endeavour" expedition
match_person_to_grouped_data("joseph", "banks", botanists_grouped, group_value = "Endeavour")
#> $UPI
#> [1] "JB002"
#> 
#> $people
#>       FN    LN   UPI Expedition
#> 2 joseph banks JB002  Endeavour
#> 
#> $message
#> [1] "EXACT"
#> 

# Swapped names still work within group
match_person_to_grouped_data("von Humboldt", "Alexander",
 botanists_grouped, group_value = "South America")
#> $UPI
#> [1] "AH003"
#> 
#> $people
#>          FN           LN   UPI    Expedition
#> 3 alexander von humboldt AH003 South America
#> 
#> $message
#> [1] "EXACT (Swap)"
#> 

# No match if group is incorrect, even if name is present elsewhere
match_person_to_grouped_data("George", "Bentham",
 botanists_grouped, group_value = "UK")  # returns NA
#> $UPI
#> [1] "GB004"
#> 
#> $people
#>       FN      LN   UPI Expedition
#> 6 george bentham GB004  Australia
#> 
#> $message
#> [1] "EXACT"
#> 
```
