test_that("format_citation abbreviates multiple authors with et al.", {
  x <- format_citation("Klammsteiner T, Walter A, Insam H.", 2020,
                       "The core gut microbiome", "Front Microbiol",
                       "10.3389/fmicb.2020.00993")
  expect_equal(x, "Klammsteiner T et al. (2020) The core gut microbiome. Front Microbiol. doi:10.3389/fmicb.2020.00993")
})

test_that("format_citation keeps a single author as is", {
  x <- format_citation("Klammsteiner T.", 2024, "A title?", "J Insects Food Feed", "10.1/x")
  expect_equal(x, "Klammsteiner T (2024) A title? J Insects Food Feed. doi:10.1/x")
})

test_that("format_citation removes HTML and escaped HTML tags from titles", {
  x <- format_citation("A B, C D", 2021,
                       "Larvae of &lt;i&gt;Hermetia illucens&lt;/i&gt; and <i>Musca</i>",
                       "Insects", "10.1/y")
  expect_match(x, "Larvae of Hermetia illucens and Musca.", fixed = TRUE)
  expect_no_match(x, "&lt;|<i>")
})
