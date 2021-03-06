generate_daily <- function(date = Sys.Date()) {
  usethis::ui_info("Creating directory and README for {date}...")

  fs::dir_create(date)
  readme_contents <- c(
    "---",
    paste0("title: \"", as.character(date), "\""),
    "output: github_document",
    "---",
    "",
    "# - i know this one!",
    "",
    "```{r old, echo = TRUE}",
    "",
    "```",
    "",
    "# - new to me!",
    "",
    "```{r new, echo = TRUE}",
    "",
    "```"
  )
  path <- paste0(date, "/README.Rmd")
  writeLines(readme_contents, path)
  rstudioapi::navigateToFile(path)
}

update_repo_readme <- function(date = Sys.Date()) {
  date_readme <- readLines(paste0(date, "/README.Rmd"))

  functions <- date_readme[grepl("# `", date_readme)]
  functions_split <- strsplit(functions, "`")
  functions_text <- c(functions_split[[1]][[2]], functions_split[[2]][[2]])

  base_link <- "https://github.com/sharlagelfand/twofunctionsmostdays/tree/master"
  functions_link <- gsub("# `|`|::|\\(\\)|!", "", functions)
  functions_link <- gsub(" ", "-", functions_link)
  functions_link <- paste0(base_link, "/", date, "#", functions_link)

  date_text <- paste0("* ", date, " [(tweet)]()")
  functions_text_and_link <- paste0("    * [", functions_text, "](", functions_link, ")")

  all_to_add <- c(date_text, functions_text_and_link)

  write(all_to_add, file = "README.md", append = TRUE)

  usethis::ui_done("README updated with functions from {date}: {glue::glue_collapse(functions_text, sep = ' and ')}!")
}

generate_carbon_images <- function(date = Sys.Date()) {
  usethis::ui_info("Pulling function code and generating carbon images...")

  `%>%` <- magrittr::`%>%`

  date_readme_md <- readLines(paste0(date, "/README.md"))

  functions_text <- date_readme_md %>%
    tibble::as_tibble() %>%
    dplyr::mutate(newline_after_chunk_end = value == "" & dplyr::lag(value) == "```") %>%
    dplyr::filter(!(value %in% c("``` r", "```")) & !newline_after_chunk_end) %>%
    dplyr::mutate(function_type = dplyr::case_when(
      stringr::str_detect(value, "i know this one") ~ "old",
      stringr::str_detect(value, "new to me") ~ "new"
    )) %>%
    tidyr::fill(function_type, .direction = "down") %>%
    dplyr::filter(!is.na(function_type)) %>%
    dplyr::filter(!stringr::str_detect(value, "i know this one|new to me")) %>%
    dplyr::mutate(value = stringr::str_replace(value, "    ##", "#>")) %>%
    dplyr::group_by(function_type) %>%
    dplyr::mutate(leading_or_trailing_newline = value == "" & dplyr::row_number() %in% c(1, dplyr::n())) %>%
    dplyr::filter(!leading_or_trailing_newline) %>%
    dplyr::ungroup()

  carbon_links <- functions_text %>%
    dplyr::group_split(function_type) %>%
    purrr::map(~ dplyr::pull(.x, value)) %>%
    purrr::map(~ carbonate::carbon$new(.x)) %>%
    purrr::map(~ {
      .x[["template"]] <- "a11y-dark"
      .x[["padding_vertical"]] <- .x[["padding_horizontal"]] <- 10
      .x[["font_size"]] <- "20"
      .x
    })

  for (i in seq_along(carbon_links)) {
    carbon_links[[i]]$browse()
  }

  usethis::ui_todo("Edit and save the images as you wish!")
}
