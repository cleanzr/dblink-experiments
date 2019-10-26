library(dplyr)
library(mcmcse)
library(ggplot2)
library(stringr)

expts <- list(list(sampler = 'PCG-I', hardware = "local", path = "../local/results/NLTCS_16partitions_PCG-I"),
              list(sampler = 'Gibbs', hardware = "local", path = "../local/results/NLTCS_16partitions_Gibbs"),
              list(sampler = 'PCG-II', hardware = "local", path = "../local/results/NLTCS_16partitions_PCG-II"),
              list(sampler = 'PCG-I', hardware = "aws", path = "../aws/results/NLTCS_16partitions_PCG-I"),
              list(sampler = 'Gibbs', hardware = "aws", path = "../aws/results/NLTCS_16partitions_Gibbs"),
              list(sampler = 'PCG-II', hardware = "aws", path = "../aws/results/NLTCS_16partitions_PCG-II"))

plotWidth <- 4.0
plotHeight <- 1.2

update_geom_defaults("point", list(size=1.5))
theme_set(theme_bw(base_size=8))

results <- function(expts, rangeIter = c(0, 3000), burninSamples = 10) {
  lapply(expts, function(expt) {
    # Read CSV files from experiment directory
    diagnostics <- read.csv(paste(expt[['path']],"diagnostics.csv", sep="/")) %>% 
      filter(iteration >= rangeIter[1] & iteration <= rangeIter[2])
    clusters <- read.csv(paste(expt[['path']],"cluster-size-distribution.csv", sep="/")) %>% 
      filter(iteration >= rangeIter[1] & iteration <= rangeIter[2])
    
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
               "sampler" = rep(expt[['sampler']], 3),
               "ess.variable" = c("# observed entities", "attribute distortion", "cluster size distribution"),
               "ess" = c(ess.numObservedEntities, ess.aggDist, ess.clustSizeDist))
  }) %>% bind_rows()
}

log_breaks = function(maj, radix=10) {
  function(x) {
    minx         = floor(min(logb(x,radix), na.rm=T)) - 1
    maxx         = ceiling(max(logb(x,radix), na.rm=T)) + 1
    n_major      = maxx - minx + 1
    major_breaks = seq(minx, maxx, by=1)
    if (maj) {
      breaks = major_breaks
    } else {
      steps = logb(1:(radix-1),radix)
      breaks = rep(steps, times=n_major) +
        rep(major_breaks, each=radix-1)
    }
    radix^breaks
  }
}

savePlot <- function(results, filename) {
  results %>% 
    mutate(ess.rate = ess/time) %>%
    ggplot(aes(x = sampler, y = ess.rate, col = ess.variable)) + 
    geom_point(aes(shape = ess.variable)) + 
    guides(shape=guide_legend(ncol=1)) + 
    scale_y_continuous(trans = 'log10', limits = c(NA, 0.5), breaks = c(0.005,0.01,0.05,0.1,0.5), minor_breaks = log_breaks(FALSE)) + 
    labs(x = "Sampler", y = "Efficiency (ESS/sec)", col = "Summary stat.", shape = "Summary stat.") + 
    coord_flip() +
    theme(legend.position="right", legend.margin=margin(0,0,0,0), legend.key.size = unit(10,"points"), legend.text = element_text(size = 6)) -> plt
  ggsave(filename, plt, height = plotHeight, width = plotWidth)
}

savePlot(results(Filter(function(expt) expt[['hardware']] == 'aws', expts)), "plot-sampler-speed-up-aws.pdf")
savePlot(results(Filter(function(expt) expt[['hardware']] == 'local', expts)), "plot-sampler-speed-up-local.pdf")
