setwd("~/work_on/packages/dblink-experiments/aws")

`library(ggplot2)
library(dplyr)`

# Assumes that you are in the AWS working directory
# Use PCG-I due to better performance
# ATTN: Remove hard coding
expts <- list(list(name = "NLTCS", numRecords = 57077, path = "../aws/results/NLTCS_16partitions_PCG-I"),
              list(name = "ABSEmployee", numRecords = 600000, path = "../aws/results/ABSEmployee_64partitions_PCG-I"), 
              list(name = "NCVR", numRecords = 448134, path = "../aws/results/NCVR_64partitions_PCG-I"),
              list(name = "SHIW0810", numRecords = 39743, path = "../aws/results/SHIW_8partitions_PCG-I"),
              list(name = "RLdata10000", numRecords = 10000, path = "../aws/results/RLdata10000_2partitions_PCG-I/"))

plotWidth <- 4.0
plotHeight <- 1.8

update_geom_defaults("point", list(size=1.5))
theme_set(theme_bw(base_size=9))

results <- lapply(expts, function(expt) {
  partitionSizes <- read.csv(paste(expt[['path']],"partition-sizes.csv", sep = "/")) %>% 
    filter(iteration <= 50000)
  balanced <- expt[['numRecords']] / (ncol(partitionSizes) - 1)
  absdev <- apply(partitionSizes[,-1], 1, function(x) sum(abs(x - balanced)))
  
  data.frame(iteration = partitionSizes$iteration, 
             dataset = rep_len(expt[['name']], nrow(partitionSizes)),
             absdev = absdev / expt[['numRecords']])
})

results.combined <- bind_rows(results)

#pdf("partition-sizes-plot.pdf", height = plotHeight, width = plotWidth)
results.combined %>%
  ggplot(aes(x = iteration)) + 
  geom_line(aes(y = absdev, col = dataset), alpha = 0.7, size = 0.2) + 
  labs(x = "Iteration", y = "Rel. abs. deviation", col = "Data set") + 
  theme(legend.margin=margin(0,0,0,0), legend.key.size = unit(10,"points"), legend.text = element_text(size = 6))
#ddev.off()
