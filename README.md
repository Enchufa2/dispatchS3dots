## Problem statement

This is a demo repository for the issue described in the [R-devel mailing list](https://stat.ethz.ch/pipermail/r-devel/2018-February/075613.html).

Suppose we have R objects of class `c("foo", "bar")`, and there are two S3 methods, `c.foo` and `c.bar`. In `c.foo`, we want to modify the arguments passed by `...` and forward the dispatch using `NextMethod`. The following code tries to solve this problem, but it results in an infinite recursion (!):

```r
c.foo <- function(..., recursive=FALSE) {
  message("calling c.foo...")
  dots <- list(...)
  # inspect and modify dots; for example:
  if (length(dots > 1))
    dots[[2]] <- 2
  do.call(
    function(..., recursive=FALSE) structure(NextMethod("c"), class="foo"),
    c(dots, recursive=recursive)
  )
}

c.bar <- function(..., recursive=FALSE) {
  message("calling c.bar...")
  NextMethod()
}

foobar <- 1
class(foobar) <- c("foo", "bar")

c(foobar, foobar)
#> calling c.foo...
#> ...
#> Error: C stack usage  7970788 is too close to the limit
```

The very same methods are deployed into two packages included in this repo. Let's install them and try the same operation:

```r
rm(c.foo, c.bar)
devtools::install("package.foo")
devtools::install("package.bar")
library(package.foo)
library(package.bar)

c(foobar, foobar)
#> calling c.foo...
#> [1] 1 2
#> attr(,"class")
#> [1] "foo"
```

and there's no recursion this time, but `c.bar` was not called (!).

## Workaround

A possible workaround for this is to reinitialise the dispatch stack by calling the generic again if any argument was modified, and finally call `NextMethod` cleanly. This works, but it means that `c.foo` will be called twice every time an argument is modified:

```r
c.foo <- function(..., recursive=FALSE) {
  message("calling c.foo...")
  modified <- FALSE
  dots <- list(...)
  # inspect and modify dots; for example:
  if (length(dots > 1) && dots[[2]] != 2) {
    dots[[2]] <- 2
    modified <- TRUE
  }
  if (modified)
    do.call(c, c(dots, recursive=recursive))
  else structure(NextMethod(), class="foo")
}

c(foobar, foobar)
#> calling c.foo...
#> calling c.foo...
#> calling c.bar...
#> [1] 1 2
#> attr(,"class")
#> [1] "foo"
```
