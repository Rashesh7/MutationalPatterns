% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/count_dbs_contexts.R
\name{count_dbs_contexts}
\alias{count_dbs_contexts}
\title{Count DBS contexts}
\usage{
count_dbs_contexts(grl)
}
\arguments{
\item{grl}{GRanges or GRangesList object containing DBS mutations in which the context was added with get_dbs_context.}
}
\value{
A tibble containing the number of DBS per COSMIC context per gr.
}
\description{
Count DBS contexts
}
\details{
Counts the number of dbs per COSMIC context from a GRanges or GRangesList object containing dbs variants.
This function applies the count_dbs_contexts_gr function to each gr in its input.
It then combines the results in a single tibble and returns this.
}
\examples{
## Get a GRangesList or GRanges object with dbs contexts.
## See 'dbs_get_context' for more info on how to do this.
grl_dbs_context <- readRDS(system.file("states/blood_grl_dbs_context.rds",
  package = "MutationalPatterns"
))

# Count the dbs contexts
count_dbs_contexts(grl_dbs_context)
}
\seealso{
\code{\link{get_dbs_context}}

Other DBS: 
\code{\link{get_dbs_context}()},
\code{\link{plot_compare_dbs}()},
\code{\link{plot_dbs_contexts}()},
\code{\link{plot_main_dbs_contexts}()}
}
\concept{DBS}
