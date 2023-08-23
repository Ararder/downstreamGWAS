parse_yaml_paths <- function() {
  yaml::read_yaml("filepaths.yml")
}

system_paths <- parse_yaml_paths()
