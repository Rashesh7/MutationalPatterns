#' Compare two indel mutation profiles
#'
#' Plots two indel mutation profiles and their difference, reports the residual
#' sum of squares (RSS).
#'
#' @param profile1 First mutation profile 
#' @param profile2 Second mutation profile
#' @param profile_names Character vector with names of the mutations profiles
#' used for plotting, default = c("profile 1", "profile 2")
#' @param Maximum value of y-axis (relative contribution) for
#' profile plotting. This can only be used to increase the y axis.
#' If bars fall outside this limit, the maximum value is
#' automatically increased. default = 0.2.
#' @param diff_ylim Y-axis limits for profile difference plot,
#' default = c(-0.1, 0.1)
#'
#' @return A ggplot2 object
#' @export
#'
#' @examples
#' 
#' ## Get the indel counts
#' ## See 'count_indel_contexts()' for more info on how to do this.
#' indel_counts <- readRDS(system.file("states/blood_indel_counts.rds",
#'                 package="MutationalPatterns"))
#'                 
#' ## Get indel refit info.
#' ## See 'fit_to_signatures()' for more info on how to do this.
#' fit_res <- readRDS(system.file("states/indel_refit.rds",
#'                 package="MutationalPatterns"))
#' 
#' ## Compare the reconstructed profile of sample 1 with the original profile
#' ## The same thing could be done with a reconstructed profile from NMF.
#' plot_compare_indels(indel_counts[,1], fit_res$reconstructed[,1])
#' 
#' ## You could also compare regular mutation profiles with eachother.
#' plot_compare_indels(indel_counts[,1],
#'                       indel_counts[,2])
#'
#' ## Or change the names of the profiles
#' plot_compare_indels(indel_counts[,1],
#'                       indel_counts[,2],
#'                       profile_names = c("Original", "Reconstructed"))
#'
#' ## You can also change the y limits.
#' ## This can be done separately for the profiles and the different facets.
#' plot_compare_indels(indel_counts[,1],
#'                         indel_counts[,2],
#'                         profile_ymax = 0.3,
#'                         diff_ylim = c(-0.03, 0.03))
#' 
plot_compare_indels = function(profile1, profile2, 
                               profile_names = c("profile 1", "profile 2"),
                               profile_ymax = 0.2,
                               diff_ylim = c(-0.1, 0.1)){
    # These variables use non standard evaluation.
    # To avoid R CMD check complaints we initialize them to NULL.
    count = muttype = muttype_sub = muttype_total = NULL
    
    
    #Create a comparison of the profiles.
    comp = create_profile_comparison(profile1, profile2, profile_names)
    
    #Separate muttype and muttype_sub. Then make data long
    counts = comp$matrix %>% 
        as.data.frame() %>% 
        tibble::rownames_to_column("muttype_total") %>% 
        tidyr::separate(muttype_total, c("muttype", "muttype_sub"), sep = "_(?=[:digit:])") %>% 
        dplyr::mutate(muttype = factor(muttype, levels = unique(muttype))) %>% 
        tidyr::gather(key = "sample", value = "count", -muttype, -muttype_sub) %>% 
        dplyr::mutate(sample = factor(sample, levels = unique(sample)))
    
    # Add dummy non_visible data points to force y axis limits per facet
    df_blank = create_dummy_limits(counts[,c("muttype", "muttype_sub")], profile_names, profile_ymax, diff_ylim)
    
    #Set colors
    colors = c("#FDBE6F", "#FF8001", "#B0DD8B", "#36A12E", "#FDCAB5","#FC8A6A", 
               "#F14432", "#BC141A", "#D0E1F2", "#94C4DF", "#4A98C9", "#1764AB", 
               "#E2E2EF", "#B6B6D8", "#8683BD", "#61409B")
    

    #Create figure
    fig = ggplot(counts, aes(x = muttype_sub, y = count, fill = muttype)) +
        geom_bar(stat = "identity") +
        geom_blank(data = df_blank, aes(x = muttype_sub, y = value)) +
        facet_grid(sample ~ muttype, scales = "free_y") +
        scale_fill_manual(values = colors) +
        labs(fill = "Mutation type", title = comp$title, y = "Relative contribution", x = "") +
        theme_minimal() +
        theme(panel.grid.major.x = element_blank(), strip.background =element_rect(fill="cadetblue"))
    
    return(fig)
}