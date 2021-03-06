context("test-rename_nmf_signatures")


# Load NMF data
nmf_res <- readRDS(system.file("states/nmf_res_data.rds",
  package = "MutationalPatterns"
))

# Load signatures
filename <- system.file("extdata/snv_signatures_probabilities.txt",
  package = "MutationalPatterns"
)
signatures <- read.table(filename, sep = "\t", header = TRUE)
signatures <- as.matrix(signatures[, -c(1, 2)])

# Run function
output <- rename_nmf_signatures(nmf_res, signatures)

# Change how similar the signatures have to be, before they are considered similar.
output_strict <- rename_nmf_signatures(nmf_res, signatures, cutoff = 0.95)

# Change the base_name of the signatures that end up with a letter name.
output_basename <- rename_nmf_signatures(nmf_res, signatures, cutoff = 0.95, base_name = "Signature_")

# Tests that nmf_res is still nmf_res
test_that("Outputs a list", {
  expect_true(inherits(output, c("list")))
  expect_true(inherits(output_strict, c("list")))
  expect_true(inherits(output_basename, c("list")))
})

test_that("Output contains signatures, contribution and reconstructed", {
  expect_identical(names(output), c("signatures", "contribution", "reconstructed"))
  expect_identical(names(output_strict), c("signatures", "contribution", "reconstructed"))
  expect_identical(names(output_basename), c("signatures", "contribution", "reconstructed"))
})

test_that("Output elements are matrixes", {
  expect_true(inherits(output$signatures, "matrix"))
  expect_true(inherits(output$contribution, "matrix"))
  expect_true(inherits(output$reconstructed, "matrix"))
  expect_true(inherits(output_strict$signatures, "matrix"))
  expect_true(inherits(output_strict$contribution, "matrix"))
  expect_true(inherits(output_strict$reconstructed, "matrix"))
  expect_true(inherits(output_basename$signatures, "matrix"))
  expect_true(inherits(output_basename$contribution, "matrix"))
  expect_true(inherits(output_basename$reconstructed, "matrix"))
})

# Test that names are correctly changed
test_that("New signature names are correct", {
  expect_equal(colnames(output$signatures), c("SBS5", "SBS1"))
  expect_equal(rownames(output$contribution), c("SBS5", "SBS1"))
  expect_equal(colnames(output_strict$signatures), c("SBSA", "SBSB"))
  expect_equal(rownames(output_strict$contribution), c("SBSA", "SBSB"))
  expect_equal(colnames(output_basename$signatures), c("Signature_A", "Signature_B"))
  expect_equal(rownames(output_basename$contribution), c("Signature_A", "Signature_B"))
})


# Test that an error is given when multiple signatures are matched to the same reference.
nmf_res2 <- nmf_res
nmf_res2$signatures[, 1] <- nmf_res2$signatures[, 2]
test_that("An error is given when multiple sigs are matched to the same ref sig", {
  expect_error(
    {
      rename_nmf_signatures(nmf_res2, signatures)
    },
    "You have multiple NMF signatures that are linked to the same existing signature"
  )
})
