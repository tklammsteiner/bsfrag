test_that("jats_to_markdown keeps title, abstract and nested headings", {
  md <- jats_to_markdown(test_path("fixtures", "mini.xml"))
  expect_type(md, "character")
  expect_length(md, 1)
  expect_match(md, "^# Test article on Hermetia illucens")
  expect_match(md, "## Abstract\n\nLarvae were reared on chicken feed.", fixed = TRUE)
  expect_match(md, "## Methods", fixed = TRUE)
  expect_match(md, "### Sequencing", fixed = TRUE)
  expect_match(md, "## Results\n\nEnterococcus dominated the gut.", fixed = TRUE)
})

test_that("jats_to_markdown drops the reference list", {
  md <- jats_to_markdown(test_path("fixtures", "mini.xml"))
  expect_no_match(md, "A cited paper", fixed = TRUE)
})

test_that("jats_to_markdown fails on an empty file", {
  f <- withr::local_tempfile(fileext = ".xml")
  file.create(f)
  expect_error(jats_to_markdown(f))
})
