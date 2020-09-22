## code to prepare `africa_poly` dataset goes here
africa_url <- "http://download.openstreetmap.fr/polygons/africa.poly"
africa_con <- url(africa_url)
africa_poly <- readLines(africa_con)
close(africa_con)

usethis::use_data(africa_poly, overwrite = TRUE, version = 3)
