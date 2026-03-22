# scripts/00_create_project_structure.R

# This makes the whole repo skeleton in one go so you don't have to click around
# making folders like it's 2007.

project_dirs <- c(
  "data/raw/hvfhv",
  "data/raw/reference",
  "data/processed",
  "data/derived",
  "output/figures",
  "output/tables",
  "output/model_objects",
  "R",
  "scripts",
  "analysis"
)

invisible(
  lapply(
    project_dirs,
    dir.create,
    recursive = TRUE,
    showWarnings = FALSE
  )
)

message("Project structure created.")
