# Clean and Standardise School Names for Matching

Applies a series of transformations to standardise school names,
improving consistency for matching and linkage tasks.

## Usage

``` r
clean_school_name(x, rm_whit = FALSE)
```

## Arguments

- x:

  Character vector of school names to clean.

- rm_whit:

  Logical. If `TRUE`, all whitespace is removed from the cleaned string.
  If `FALSE` (default), whitespace is standardised but retained.

## Value

Character vector of cleaned school names.

## Details

This function performs the following steps:

- Converts text to lowercase

- Transliterates to ASCII (e.g. removes accents)

- Removes punctuation

- Normalises whitespace (collapses multiple spaces)

- Applies common domain-specific replacements (e.g. "math" →
  "mathematics")

- Optionally removes all whitespace

The function is designed for use in school name matching workflows,
ensuring that equivalent names with minor formatting differences are
more likely to match.

## Examples

``` r
clean_school_name("St. Inga's Primary School")
#> [1] "st ingas primary school"

clean_school_name("Ilex aquifolium Académy")
#> [1] "ilex aquifolium academy"

clean_school_name("The DS Maths School")
#> [1] "the ds mathematics school"
```
