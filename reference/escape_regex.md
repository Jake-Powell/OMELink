# Escape regular expression special characters

Escapes all regex metacharacters in a character vector so that the
resulting strings can be safely used in regular expression patterns.

## Usage

``` r
escape_regex(x)
```

## Arguments

- x:

  A character vector of strings to escape.

## Value

A character vector with regex metacharacters escaped.

## Details

The following characters are escaped: `[]{}()+*^$|\?.`

## Examples

``` r
escape_regex("a+b")   # returns "a\+b"
#> [1] "a\\+b"
escape_regex("file?.txt")  # returns "file\?\.txt"
#> [1] "file\\?\\.txt"
```
