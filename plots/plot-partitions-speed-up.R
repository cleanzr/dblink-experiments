library(dplyr)
library(mcmcse)
library(ggplot2)
library(stringr)
library(scales)

expts <- list(list(numPartitions = 32, hardware = "local", path = "../local/results/NLTCS_32partitions_PCG-I"),
              list(numPartitions = 16, hardware = "local", path = "../local/results/NLTCS_16partitions_PCG-I"),
              list(numPartitions = 8, hardware = "local", path = "../local/results/NLTCS_8partitions_PCG-I"),
              list(numPartitions = 4, hardware = "local", path = "../local/results/NLTCS_4partitions_PCG-I"),
              list(numPartitions = 2, hardware = "local", path = "../local/results/NLTCS_2partitions_PCG-I"),
              list(numPartitions = 1, hardware = "local", path = "../local/results/NLTCS_1partitions_PCG-I"),
              list(numPartitions = 32, hardware = "aws", path = "../aws/results/NLTCS_32partitions_PCG-I"),
              list(numPartitions = 16, hardware = "aws", path = "../aws/results/NLTCS_16partitions_PCG-I"),
              list(numPartitions = 8, hardware = "aws", path = "../aws/results/NLTCS_8partitions_PCG-I"),
              list(numPartitions = 4, hardware = "aws", path = "../aws/results/NLTCS_4partitions_PCG-I"),
              list(numPartitions = 2, hardware = "aws", path = "../aws/results/NLTCS_2partitions_PCG-I"),
              list(numPartitions = 1, hardware = "aws", path = "../aws/results/NLTCS_1partitions_PCG-I"))

plotWidth <- 4.0
plotHeight <- 1.4

update_geom_defaults("point", list(size=1.5))
theme_set(theme_bw(base_size=8))

results <- function(expts, iterRange = c(0, 3000), burninSamples = 10) {
  lapply(expts, function(expt) {
    # Read diagnostic CSV files from experiment
    diagnostics <- read.csv(paste(expt[['path']],"diagnostics.csv", sep="/")) %>% 
      filter(iteration >= iterRange[1], iteration <= iterRange[2])
    clusters <- read.csv(paste(expt[['path']],"cluster-size-distribution.csv", sep="/")) %>% 
      filter(iteration >= iterRange[1], iteration <= iterRange[2])
    names(clusters) <- c(names(clusters)[1], 
                         paste0(str_replace(names(clusters)[-1], pattern="X", replacement=""),"-clusters"))
      
    # ESS for number of observed entities
    ess.numObservedEntities <- ess(diagnostics$numObservedEntities)
    
    # ESS for aggregate distortions
    ess.aggDist <- diagnostics %>% select(starts_with("aggDist")) %>% multiESS()
    
    # ESS for k-clusters
    clustSizes <- clusters %>% select(-starts_with("iteration"))
    freqs <- colSums(clustSizes)
    freqs <- freqs/sum(freqs)
    clustSizes <- clustSizes[,freqs > 1e-5]
    ess.clustSizeDist <- multiESS(clustSizes)
    
    runTime <- (max(diagnostics$systemTime.ms) - min(diagnostics$systemTime.ms)) * 1e-3
    
    data.frame("time" = rep(runTime, 3), 
               "num.partitions" = rep(expt[['numPartitions']], 3),
               "ess.variable" = c("# observed entities", "attribute distortion", "cluster size distribution"),
               "ess" = c(ess.numObservedEntities, ess.aggDist, ess.clustSizeDist))
  }) %>% bind_rows()
}

mult_format <- function() {
  function(x) format(10^-4*x,digits = 2) 
}

savePlot <- function(results, filename) {
  results %>% 
    group_by(ess.variable) %>%
    mutate(ess.rate = ess/time,
           speedup = ess.rate/sum(ess.rate*(num.partitions == 1))) %>%
    ggplot(aes(x = num.partitions, y = speedup, col = ess.variable)) + 
    geom_abline(slope = 1, intercept = 0) +
    geom_point(aes(shape = ess.variable)) +
    scale_y_continuous(limits = c(1, NA)) +
    guides(shape=guide_legend(ncol=1)) +
    labs(x = "# partitions", y = "Speed-up factor", col = "Summary stat.", shape = "Summary stat.") + 
    theme(legend.position="right", legend.margin=margin(0,0,0,0), legend.key.size = unit(10,"points"), legend.text = element_text(size = 6)) -> plt
  ggsave(filename, plt, width = plotWidth, height = plotHeight) 
}

savePlot(results(Filter(function(expt) expt[['hardware']] == 'aws', expts)), "plot-partitions-speed-up-aws.pdf")
savePlot(results(Filter(function(expt) expt[['hardware']] == 'local', expts)), "plot-partitions-speed-up-local.pdf")
