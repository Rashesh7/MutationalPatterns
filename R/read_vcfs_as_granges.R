#' Read VCF files into a GRangesList
#'
#' This function reads Variant Call Format (VCF) files into a GRanges object
#' and combines them in a GRangesList.  In addition to loading the files, this
#' function applies the same seqlevel style to the GRanges objects as the
#' reference genome passed in the 'genome' parameter.
#'
#' @param vcf_files Character vector of VCF file names
#' @param sample_names Character vector of sample names
#' @param genome A string matching the name of a BSgenome library
#'               corresponding to the reference genome of your VCFs
#' @param group Selector for a seqlevel group.  All seqlevels outside
#'              of this group will be removed.  Possible values:
#'              * 'all' for all chromosomes;
#'              * 'auto' for autosomal chromosomes;
#'              * 'sex' for sex chromosomes;
#'              * 'auto+sex' for autosomal + sex chromosomes (default);
#'              * 'circular' for circular chromosomes;
#'              * 'none' for no filtering, which results in keeping all
#'                seqlevels from the VCF file.
#' @param type The mutation type that will be loaded. All other variants will be filtered out.
#'              Possible values:
#'              * 'snv'
#'              * 'indel'
#'              * 'dbs'
#'              * 'mbs'
#'              * 'all'
#'  This function assumes that dbs and mbs variants are present in the vcf as SNVs,
#'  which are positioned next to each other. If your dbs/mbs variants are called
#'  separately you should use type = 'all' to prevent incorrect filtering.
#'  In those cases SNVs could be selected per sample by something like:
#'  'gr[width(gr) == 1]'
#' @param change_seqnames Boolean. Whether to change the seqnamesStyle of the vcf
#' to that of the BSgenome object. (default = TRUE)
#'
#' @return A GRangesList containing the GRanges obtained from 'vcf_files'
#'
#' @importFrom magrittr %>%
#'
#' @examples
#' ## The example data set consists of three colon samples, three intestine
#' ## samples and three liver samples.  So, to map each file to its appropriate
#' ## sample name, we create a vector containing the sample names:
#' sample_names <- c(
#'   "colon1", "colon2", "colon3",
#'   "intestine1", "intestine2", "intestine3",
#'   "liver1", "liver2", "liver3"
#' )
#'
#' ## We assemble a list of files we want to load.  These files match the
#' ## sample names defined above.
#' vcf_files <- list.files(system.file("extdata",
#'   package = "MutationalPatterns"
#' ),
#' pattern = "sample.vcf", full.names = TRUE
#' )
#'
#' ## Get a reference genome BSgenome object.
#' ref_genome <- "BSgenome.Hsapiens.UCSC.hg19"
#' library("BSgenome")
#' library(ref_genome, character.only = TRUE)
#'
#' ## This function loads the files as GRanges objects.
#' ## For backwards compatability reasons it only loads SNVs by default
#' vcfs <- read_vcfs_as_granges(vcf_files, sample_names, ref_genome)
#'
#' ## To load all variant types use:
#' vcfs <- read_vcfs_as_granges(vcf_files, sample_names, ref_genome, type = "all")
#'
#' ## Loading only indels can be done like this.
#'
#' ## Select data containing indels.
#' vcf_fnames <- list.files(system.file("extdata", package = "MutationalPatterns"),
#'   pattern = "blood.*vcf", full.names = TRUE
#' )
#' sample_names <- c("AC", "ACC55", "BCH")
#'
#' ## Read data and select only the indels.
#' ## Other mutation types can be read in the same way.
#' read_vcfs_as_granges(vcf_fnames, sample_names, ref_genome, type = "indel")
#' @export
read_vcfs_as_granges <- function(vcf_files,
                                 sample_names,
                                 genome,
                                 group = c("auto+sex", "auto", "sex", "circular", "all", "none"),
                                 type = c("snv", "indel", "dbs", "mbs", "all"),
                                 change_seqnames = TRUE) {

  # Match argument
  type <- match.arg(type)
  group <- match.arg(group)

  # Check sample names
  if (length(vcf_files) != length(sample_names)) {
    stop("Please provide the same number of sample names as VCF files", call. = FALSE)
  }

  # Get the reference genome
  tryCatch(
    error = function(cnd) {
      stop("Please provide the name of a BSgenome object.", call. = FALSE)
    },
    {
      genome <- BSgenome::getBSgenome(genome)
    }
  )

  # Read vcfs
  grl <- purrr::map(vcf_files, read_single_vcf_as_grange, genome, group, change_seqnames) %>%
    GenomicRanges::GRangesList()

  # Filter for mutation type
  if (type != "all") {
    grl <- get_mut_type(grl, type)
  }

  # Set the provided names for the samples.
  names(grl) <- sample_names

  return(grl)
}

#' Read a single VCF file into a GRanges object
#'
#' This function reads a Variant Call Format (VCF) file into a GRanges object
#' In addition to loading the files, this
#' function applies the same seqlevel style to the GRanges objects as the
#' reference genome passed in the 'genome' parameter.
#'
#' @param vcf_file A VCF file name
#' @param genome BSgenome object
#' @param group Selector for a seqlevel group.  All seqlevels outside
#'              of this group will be removed.  Possible values:
#'              * 'all' for all chromosomes;
#'              * 'auto' for autosomal chromosomes;
#'              * 'sex' for sex chromosomes;
#'              * 'auto+sex' for autosomal + sex chromosomes (default);
#'              * 'circular' for circular chromosomes;
#'              * 'none' for no filtering, which results in keeping all
#'                seqlevels from the VCF file.
#' @param change_seqnames Boolean. Whether to change the seqnamesStyle of the vcf
#' to that of the BSgenome object.
#' @return A GRanges object
#' @importFrom magrittr %>%
#' @noRd
#'
read_single_vcf_as_grange <- function(vcf_file, genome, group, change_seqnames) {

  # Use VariantAnnotation's readVcf, but only store the
  # GRanges information in memory.  This speeds up the
  # loading significantly.
  # Muffle the warning about duplicate keys.
  genome_name <- GenomeInfoDb::genome(genome)[[1]]
  withCallingHandlers(
    {
      gr <- GenomicRanges::granges(VariantAnnotation::readVcf(vcf_file, genome_name))
    },
    warning = function(w) {
      if (grepl("duplicate keys in header will be forced to unique rownames", conditionMessage(w))) {
        invokeRestart("muffleWarning")
      }
    }
  )


  # Throw a warning when a file is empty.
  # Return a empty GR, to prevent errors with changing the seqlevels.
  if (!length(gr)) {
    warning(paste0(
      "There were 0 variants (before filtering) found in the vcf file: ", vcf_file,
      "\nYou might want to remove this sample from your analysis."
    ), call. = FALSE)
    return(gr)
  }

  # Convert to a single chromosome naming standard.
  if (change_seqnames == TRUE) {
    tryCatch(
      error = function(cnd) {
        message(conditionMessage(cnd))
        stop("The seqlevelStyle of the vcf could not be changed to that of the reference.
                     You can run this function with `change_seqnames = F` and `group = 'all'`, 
                     to prevent this error.
                     However, you then have to make sure that the seqnames (chromosome names) are
                     the same between your vcfs and the reference BSgenome object.
                     (The message of the internal error causing this problem is shown above.)", 
             call. = FALSE)
      },
      {
        GenomeInfoDb::seqlevelsStyle(gr) <- GenomeInfoDb::seqlevelsStyle(genome)[1]
      }
    )
  }

  # Filter for variants with the correct seqlevels
  if (group != "all") {
    tryCatch(
      error = function(cnd) {
        message(conditionMessage(cnd))
        stop("The vcf could not be filtered for the specific seqlevels group.
                     You can run this function with `group = 'all'`, to prevent this error.
                     (The message of the internal error causing this problem is shown above.)",
          call. = FALSE
        )
      },
      {
        gr <- filter_seqlevels(gr, group, genome)
      }
    )
  }

  # Check for duplicate variants
  nr_duplicated <- gr %>%
    duplicated() %>%
    sum()
  if (nr_duplicated) {
    warning(paste0(
      "There were ", nr_duplicated, " duplicated variants in vcf file: ",
      vcf_file,
      " They have been filtered out."
    ), call. = FALSE)
    gr <- BiocGenerics::unique(gr)
  }

  return(gr)
}

#' Filter a GRanges object based on seqlevels
#'
#' This function filters a GRanges object based on a group of seqnames.
#'
#' @param gr GRanges object
#' @param group Selector for a seqlevel group.  All seqlevels outside
#'              of this group will be removed.  Possible values:
#'              * 'auto' for autosomal chromosomes;
#'              * 'sex' for sex chromosomes;
#'              * 'auto+sex' for autosomal + sex chromosomes (default);
#'              * 'circular' for circular chromosomes;
#'              * 'none' for no filtering, which results in keeping all
#'                seqlevels from the VCF file.
#' @param genome BSgenome object
#' @return A GRanges object
#' @noRd
#'
filter_seqlevels <- function(gr, group, genome) {
  groups <- c()
  # These variables are needed to extract the possible seqlevels
  ref_style <- GenomeInfoDb::seqlevelsStyle(genome)
  ref_organism <- GenomeInfoDb::organism(genome)

  if (group == "auto+sex") {
    groups <- c(
      GenomeInfoDb::extractSeqlevelsByGroup(
        species = ref_organism,
        style = ref_style,
        group = "auto"
      ),
      GenomeInfoDb::extractSeqlevelsByGroup(
        species = ref_organism,
        style = ref_style,
        group = "sex"
      )
    )

    # In some cases, the seqlevelsStyle returns multiple styles.
    # In this case, we need to do a little more work to extract
    # a vector of seqlevels from it.
    groups_names <- names(groups)
    if (!is.null(groups_names)) {
      # The seqlevels in the groups are now duplicated.
      # The following code deduplicates the list items, so that
      # creating a data frame will work as expected.
      unique_names <- unique(groups_names)
      groups <- lapply(unique_names, function(x) groups[groups_names == x])
      groups <- lapply(groups, unlist, recursive = FALSE)

      # In case there are multiple styles applied, we only use the first.
      groups <- unique(as.vector(groups[[1]]))
    }
  }
  else {
    groups <- GenomeInfoDb::extractSeqlevelsByGroup(
      species = ref_organism,
      style = ref_style,
      group = group
    )
    groups <- unique(as.vector(t(groups)))
  }

  # The provided VCF files may not contain all chromosomes that are
  # available in the reference genome.  Therefore, we only take the
  # chromosomes that are actually available in the VCF file,
  # belonging to the filter group.
  groups <- BiocGenerics::intersect(groups, GenomeInfoDb::seqlevels(gr))

  # We use 'pruning.mode = "tidy"' to minimize the deleterious effect
  # on variants, yet, remove all variants that aren't in the filter
  # group.  By default, keepSeqlevels would produce an error.
  gr <- GenomeInfoDb::keepSeqlevels(gr, groups, pruning.mode = "tidy")

  return(gr)
}
