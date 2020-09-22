#' Convert .poly file into sfc object
#'
#' @param poly Character string representing the path of a `.poly` file. A URL
#'   can be specified using `url()`. See examples.
#'
#' @details The Polygon Filter File Format (`.poly`) is defined
#'   [here](https://wiki.openstreetmap.org/wiki/Osmosis/Polygon_Filter_File_Format).
#'   The code behind the function was inspired by `parse_poly` function defined
#'   [here](https://wiki.openstreetmap.org/wiki/Osmosis/Polygon_Filter_File_Python_Parsing).
#'
#'
#' @return A `sfc` object.
#' @export
#'
#' @examples
#' # Starting from text lines stored in an R object
#' convert_poly_to_sfc(africa_poly)
#'
#' # Starting from a path pointing to an existing file
#' africa_path <- system.file("africa.poly", package = "polyread")
#' convert_poly_to_sfc(africa_path)
#'
#' # Starting from a connection
#' \dontrun{
#' my_url <- "http://download.openstreetmap.fr/polygons/africa.poly"
#' my_con <- url(my_url)
#' my_poly <- readLines(my_con)
#' close(my_con) # don't forget to close the connection
#' convert_poly_to_sfc(my_poly)
#' }
#'
#'
convert_poly_to_sfc <- function(poly) {
  # If poly is a character vector of length 1 or a connection, then it should
  # represent a path to a file
  if (
    length(poly) == 1L &&
      (inherits(poly, "connection") || is.character(poly))
  ) {
    poly <- readLines(poly)
  }

  # I will store all polygon(s) (with their ring(s)) in a list called
  # multipolygon_list
  multipolygon_list <- list()
  index_multipolygon <- 1L

  # I will store each polygon with its ring(s) in a list called
  # polygon_list
  polygon_list <- list()
  index_polygon <- 1L

  # I will store each matrix of coordinates in a list called coords_list
  coords_list <- list()

  # The following is used to skip the lines containing a name which begins a
  # section that define an individual polygon or ring
  skip_line <- FALSE

  # Loop over all rows in the .poly file. They should follow the structure described
  # here: https://wiki.openstreetmap.org/wiki/Osmosis/Polygon_Filter_File_Format

  # The for loop starts from 3 since I ignore the first line because it contains
  # the name of the file (without any consistent naming convention) and the
  # second line is just the name of the polygon in the first section.

  for (i in seq.int(from = 3, to = length(poly))) {

    # Ignore the lines containing a name which begins a section defining an
    # individual polygon.
    if (skip_line) {
      skip_line <- FALSE
      next
    }

    if (poly[i] != "END") {
      # When poly[[i]] == "END", then we reached the end of the polygon/ring.
      # Now we are working on the coordinates, which, in the .poly file, are
      # divided by some blank character (space or tab, I think).
      # The coordinates will be divided into two.
      # coords_list is now a list of character coordinates.
      coords_list[i] <- strsplit(trimws(poly[[i]]), "[[:blank:]]+")
      next()
    }

    # Now we reached a line with "END", so we must transform the character
    # coordinates into a numeric matrix
    coord_matrix <- do.call("rbind", coords_list)
    coord_matrix <- apply(coord_matrix, 2, as.numeric)

    # Check that the polygon/ring is closed
    if (any(coord_matrix[1, ] != coord_matrix[nrow(coord_matrix), ])) {
      coord_matrix <- rbind(coord_matrix, coord_matrix[1, ])
    }

    # Add the numeric matrix into polygon_list
    polygon_list[index_polygon] <- list(coord_matrix)
    index_polygon <- index_polygon + 1L

    # Check if we reached the EOF
    if (poly[i + 1] == "END") {
      multipolygon_list[index_multipolygon] <- list(polygon_list)
      break()
    }

    # Check if the next section represents a polygon
    if (!grepl("!", poly[i + 1L])) {
      # Write the polygon into multipolygon_list
      multipolygon_list[index_multipolygon] <- list(polygon_list)
      index_multipolygon <- index_multipolygon + 1L


      # Reset values
      polygon_list <- list()
      index_polygon <- 1L
      coords_list <- list()

      # skip one line
      skip_line <- TRUE
      next
    }

    # Check if next section represents a ring
    if (grepl("!", poly[i + 1L])) {
      # reset values
      coords_list <- list()

      # skip one line
      skip_line <- TRUE
      next
    }
  }

  # Format result as sfc object
  sf::st_sfc(
    sf::st_multipolygon(multipolygon_list),
    crs = 4326
  )
}
