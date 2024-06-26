#' @importFrom dplyr left_join select filter mutate %>%
#'
calcINNOPATHS <- function() {

  mapping <- toolGetMapping("Mapping_INNOPATHS.csv", type = "reportingVariables", where = "mrremind") %>%
    filter(!is.na(!!sym("REMIND"))) %>%
    mutate(
      !!sym("REMIND_unit") := gsub("\\)", "", gsub(".*\\(", "", !!sym("REMIND"))),
      !!sym("REMIND") := gsub(" \\(.*", "", !!sym("REMIND")),
      !!sym("INNOPATHS") := gsub(" \\(.*", "", !!sym("Variable")),
      !!sym("INNOPATHS_unit") := gsub("\\)", "", gsub(".*\\(", "", !!sym("Variable")))
    ) %>%
    select(
      "INNOPATHS", "INNOPATHS_unit", "REMIND", "REMIND_unit", "factor"
    )

  data <- readSource("INNOPATHS") %>%
    as.data.frame() %>%
    as_tibble() %>%
    select(
      "region" = "Region", "variable" = "Data1",
      "unit" = "Data2", "year" = "Year", "value" = "Value"
    )

  x <- left_join(
    data,
    mapping,
    by = c("variable" = "INNOPATHS")
  ) %>%
    filter(!!sym("REMIND") != "") %>%
    mutate(
      !!sym("value") := !!sym("value") * !!sym("factor"),
      !!sym("year") := as.numeric(as.character(!!sym("year"))),
      !!sym("REMIND") := paste0(!!sym("REMIND"), " (", !!sym("REMIND_unit"), ")")
    ) %>%
    select("region", "year", "variable" = "REMIND", "value") %>%
    as.magpie()

  weights <- x
  weights[, , ] <- NA
  weights[, , "US$2005", pmatch = TRUE] <- 1
  weights[, , "GDP|MER (billion US$2005/yr)"] <- NA

  return(list(
    x = x,
    weight = weights,
    mixed_aggregation = TRUE,
    unit = "Various",
    description = "INNOPATHS projections as REMIND variables"
  ))
}
