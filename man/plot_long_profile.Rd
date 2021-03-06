% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/plot_long_profile.R
\name{plot_long_profile}
\alias{plot_long_profile}
\title{Plot 96 trinucleotide profile per subgroup}
\usage{
plot_long_profile(
  mut_matrix,
  mode = c("relative_sample", "relative_sample_feature", "absolute"),
  colors = NULL,
  ymax = 0.2,
  condensed = FALSE
)
}
\arguments{
\item{mut_matrix}{Mutation matrix}

\item{mode}{'relative_sample', 'relative_sample_feature' or 'absolute'
When 'relative_sample', the number of variants will be shown
divided by the total number of variants in that sample.
When 'relative_sample_feature', the number of variants will be shown
divided by the total number of variants in that sample. and genomic region.}

\item{colors}{6 value color vector}

\item{ymax}{Y axis maximum value, default = 0.2}

\item{condensed}{More condensed plotting format. Default = FALSE.}
}
\value{
96 trinucleotide profile plot per region
}
\description{
Plot relative contribution of 96 trinucleotides per subgroup.
This can be genomic regions but could also be other subsets.
The function uses a matrix generated by 'lengthen_mut_matrix()'
as its input.
}
\examples{
## See the 'lengthen_mut_matrix()' example for how we obtained the
## mutation matrix information:
mut_mat_long <- readRDS(system.file("states/mut_mat_longregions.rds",
  package = "MutationalPatterns"
))

## Plot the 96-profile of three samples
plot_long_profile(mut_mat_long[, c(1, 4, 7)])
}
\seealso{
\code{\link{mut_matrix}}

Other genomic_regions: 
\code{\link{lengthen_mut_matrix}()},
\code{\link{plot_spectrum_region}()},
\code{\link{split_muts_region}()}
}
\concept{genomic_regions}
