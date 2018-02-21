c.foo <-
function(..., recursive=FALSE) {
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
