library(dplyr)
library(ggplot2)
library(stringr)
library(mcmcse)
library(tidyr)

# Details of each experiment
expts <- list(list(name = "ABSEmployee", path = "../local/results/ABSEmployee_64partitions_PCG-I", burnin = 10000),
              list(name = "NCVR", path = "../local/results/NCVR_64partitions_PCG-I", burnin = 210000),
              list(name = "NLTCS", path = "../local/results/NLTCS_16partitions_PCG-I", burnin = 10000),
              list(name = "RLdata10000", path = "../local/results/RLdata10000_2partitions_PCG-I", burnin = 10000),
              list(name = "SHIW", path = "../local/results/SHIW_8partitions_PCG-I", burnin = 10000))

update_geom_defaults("point", list(size=1.5))
theme_set(theme_bw(base_size=8))
plot.width <- 8
plot.height <- 1
plot.x <- 1

# Define a function to produce autocorrelation plots
acfGrid <- function(df, key, value) {
  df.grouped <- df %>% select(one_of(c(key, value))) %>%
    group_by((!!as.symbol(key)))
  
  df.acf <- df.grouped %>%
    summarise(list_acf=list(acf(eval(parse(text=value)), plot=FALSE))) %>%
    mutate(acf_vals=purrr::map(list_acf, ~as.numeric(.x$acf))) %>% 
    select(-list_acf) %>% 
    unnest() %>% 
    group_by((!!as.symbol(key))) %>% 
    mutate(lag=row_number() - 1) # assumes already sorted by iteration
  
  df.ci <- df.grouped %>%
    summarise(ci = qnorm((1 + 0.95)/2)/sqrt(n()))
  
  ggplot(df.acf, aes(x=lag, y=acf_vals)) +
    geom_bar(stat="identity") +
    geom_hline(yintercept = 0) +
    geom_hline(data = df.ci, aes(yintercept = -ci), color="blue", linetype="dotted") +
    geom_hline(data = df.ci, aes(yintercept = ci), color="blue", linetype="dotted") +
    labs(x="Lag", y="ACF") +
    facet_grid(as.formula(paste0(key, "~.")), scales = "free_y")
}

# Read in data for each experiment and produce diagnostic plots
for (expt in expts) {
  message("Processing experiment ", expt[['name']], ":")
  
  diagnostics <- read.csv(paste(expt[['path']],"diagnostics.csv", sep="/"))
  clusters <- read.csv(paste(expt[['path']],"cluster-size-distribution.csv", sep="/"))
  names(clusters) <- c(names(clusters)[1], 
                       str_remove(names(clusters)[-1], pattern="X"))
  
  # Remove burnin iterations
  diagnostics <- diagnostics %>% filter(iteration >= expt[['burnin']])
  clusters <- clusters %>% filter(iteration >= expt[['burnin']])
  
  # Trace plot for observed number of entities
  diagnostics %>%
    ggplot(aes(x=iteration, y=numObservedEntities)) +
    geom_line() +
    xlab("Iteration") +
    ylab("Population size") +
    ggtitle("Trace plot of observed population size")
  
  ess <- ess(diagnostics$numObservedEntities)
  message("- Number of observed entities: ",nrow(diagnostics)," raw samples; ESS is ", ess)
  
  # Trace plot for attribute-level distortions
  diagnostics %>%
    select(iteration, starts_with("aggDist")) %>%
    gather(field, num.distortions, starts_with("aggDist")) %>%
    mutate(field = str_match(field, "\\.(.+)")[,2]) -> aggDist.df
  
  aggDist.df %>% ggplot(aes(x=iteration, y=num.distortions)) + 
    geom_line(size=0.1) + facet_grid(field~., scales = "free_y") + 
    theme(legend.position = "none") +
    xlab("Iteration") + ylab("Aggregate distortion") -> attributeDistortionsPlot
  ggsave(paste0(expt[['name']], "_attribute-distortions.pdf"), 
         attributeDistortionsPlot, 
         width = plot.width, 
         height = 1.5*plot.height * length(unique(attributeDistortionsPlot$data$field)) + plot.x,
         units = "cm")
  
  acfGrid(aggDist.df, "field", "num.distortions") -> attributeDistortionsACFPlot
  ggsave(paste0(expt[['name']], "_attribute-distortions-acf.pdf"), 
         attributeDistortionsACFPlot, 
         width = plot.width, 
         height = 1.5*plot.height * length(unique(attributeDistortionsACFPlot$data$field)) + plot.x,
         units = "cm")
  
  diagnostics %>%
    select(starts_with("aggDist")) %>%
    multiESS() -> ess
  message("- Aggregate distortion: ",nrow(diagnostics)," raw samples; ESS is ", ess)
  
  # Trace plots for record distortions
  diagnostics %>% 
    select(iteration, starts_with("recDistortion")) %>%
    gather(num.distorted.fields, num.records, starts_with("recDistortion")) %>%
    mutate(num.distorted.fields = 
             as.integer(str_remove(num.distorted.fields, "^.*?[.]"))) -> recDist.df
  
  recDist.df %>% ggplot(aes(x=iteration, y=num.records)) + 
    geom_line(size=0.1) + facet_grid(num.distorted.fields~., scales = "free_y") + 
    xlab("Iteration") + ylab("Frequency") -> recordDistortionsPlot
  ggsave(paste0(expt[['name']], "_record-distortions.pdf"), 
         recordDistortionsPlot, 
         width = plot.width, 
         height = plot.height * length(unique(recordDistortionsPlot$data$num.distorted.fields)) + plot.x, 
         units = "cm")
  
  acfGrid(recDist.df, "num.distorted.fields", "num.records") -> recordDistortionsACFPlot
  ggsave(paste0(expt[['name']], "_record-distortions-acf.pdf"), 
         recordDistortionsACFPlot, 
         width = plot.width, 
         height = plot.height * length(unique(recordDistortionsACFPlot$data$num.distorted.fields)) + plot.x, 
         units = "cm")
  
  recDistortions <- diagnostics %>% select(starts_with("recDistortion"))
  freq <- colSums(recDistortions)
  freq <- freq/sum(freq)
  recDistortions <- recDistortions[,freq > 1e-6]
  ess <- multiESS(recDistortions)
  message("- Distribution over distortion counts per record: ",nrow(diagnostics)," raw samples; ESS is ", ess)
  
  # Trace plots for cluster size distribution
  clusters %>% 
    gather(cluster.size, num.clusters, -iteration) %>%
    mutate(cluster.size = as.integer(str_remove(cluster.size, "-clusters"))) -> clust.df
  
  clust.df %>%
    ggplot(aes(x=iteration, y=num.clusters)) + 
    geom_line(size=0.1) + facet_grid(cluster.size~., scales = "free_y") + 
    xlab("Iteration") + ylab("Frequency") -> clusterSizePlot
  ggsave(paste0(expt[['name']], "_cluster-size-distribution.pdf"), 
         clusterSizePlot, 
         width = plot.width, 
         height = plot.height * length(unique(clusterSizePlot$data$cluster.size)) + plot.x, 
         units = "cm")
  
  acfGrid(clust.df, "cluster.size", "num.clusters") -> clusterSizeACFPlot
  ggsave(paste0(expt[['name']], "_cluster-size-distribution-acf.pdf"), 
         clusterSizeACFPlot, 
         width = plot.width, 
         height = plot.height * length(unique(clusterSizeACFPlot$data$cluster.size)) + plot.x, 
         units = "cm")
  
  clustSizes <- clusters %>% select(-starts_with("iteration"))
  freqs <- colSums(clustSizes)
  freqs <- freqs/sum(freqs)
  clustSizes <- clustSizes[,freqs > 1e-6]
  ess <- multiESS(clustSizes)
  message("- Distribution over cluster sizes: ",nrow(diagnostics)," raw samples; ESS is ", ess)
}
