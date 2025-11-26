# Helpers to clear data objects while keeping functions

#' Clear all non-function objects from the global environment
#' 
#' @param exclude Character vector of object names to keep (optional)
#' @return Invisibly returns NULL
clear_data <- function(exclude = character()) {
  objs <- ls(envir = .GlobalEnv, all.names = TRUE)
  if (length(exclude)) {
    objs <- setdiff(objs, exclude)
  }
  to_rm <- objs[!vapply(objs, function(n) is.function(get(n, envir = .GlobalEnv)), logical(1))]
  if (length(to_rm)) {
    rm(list = to_rm, envir = .GlobalEnv)
  }
  invisible(NULL)
}

#' Clear typical "data-like" objects (data.frames, tibbles, matrices, vectors, lists)
#' Keeps functions and environments.
#'
#' @param exclude Character vector of object names to keep (optional)
#' @return Invisibly returns NULL
clear_data_like <- function(exclude = character()) {
  objs <- ls(envir = .GlobalEnv, all.names = TRUE)
  if (length(exclude)) {
    objs <- setdiff(objs, exclude)
  }
  predicate <- function(n) {
    obj <- get(n, envir = .GlobalEnv)
    if (is.function(obj) || is.environment(obj)) return(FALSE)
    is.data.frame(obj) || inherits(obj, c("tbl", "tbl_df", "data.table")) ||
      is.matrix(obj) || is.atomic(obj) || is.list(obj)
  }
  to_rm <- Filter(predicate, objs)
  if (length(to_rm)) {
    rm(list = to_rm, envir = .GlobalEnv)
  }
  invisible(NULL)
}

#' Remove everything except functions (and optionally keep some names)
#'
#' @param exclude Character vector of object names to keep (optional)
clear_except_functions <- function(exclude = character()) {
  clear_data(exclude = exclude)
}

message("✓ Loaded environment-clear helpers: clear_data(), clear_data_like(), clear_except_functions()")

