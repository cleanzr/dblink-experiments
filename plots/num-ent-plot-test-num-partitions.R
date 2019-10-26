library(dplyr)
library(mcmcse)
library(ggplot2)
library(stringr)

expts <- list(list(numPartitions = 32, path = "../aws/results/NLTCS_32partitions_PCG-I"),
              list(numPartitions = 16, path = "../aws/results/NLTCS_16partitions_PCG-I"),
              list(numPartitions = 8, path = "../aws/results/NLTCS_8partitions_PCG-I"),
              list(numPartitions = 4, path = "../aws/results/NLTCS_4partitions_PCG-I"),
              list(numPartitions = 2, path = "../aws/results/NLTCS_2partitions_PCG-I"),
              list(numPartitions = 1, path = "../aws/results/NLTCS_1partitions_PCG-I"))

save.fname <- "num-ent-plot-test-num-partitions"
plotWidth <- 3.349263889
plotHeight <- 2.2
endTime <- 1000
numPoints <- 200

theme_set(theme_bw() + theme(text = element_text(size = 9)))

results <- lapply(expts, function(expt) {
  # Read diagnostic CSV files from experiment
  read.csv(paste(expt[['path']],"diagnostics.csv", sep="/")) %>% 
    mutate(time = (systemTime.ms - systemTime.ms[1]) * 1e-3, 
           numPartitions = expt[['numPartitions']]) %>% 
    filter(time <= endTime) %>% 
    select(iteration, time, numPartitions, numObservedEntities)-> diagnostics
})

results.combined <- bind_rows(results)

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

pdf(paste0(save.fname, ".pdf"), height = plotHeight, width = plotWidth)
results.combined %>% 
  mutate(numPartitions = as.factor(numPartitions)) %>%
  ggplot(aes(x = time, y = numObservedEntities, col = numPartitions)) + 
  geom_line(aes(shape = numPartitions)) + 
  scale_shape_manual(values = seq(0,7)) +
  scale_x_continuous(limits = c(0,600)) +
  labs(x = "Time (s)", y = "# observed entities", col = "# partitions", shape = "# partitions") +
  theme(legend.position="bottom", legend.margin=margin(0,0,0,0), legend.key.height = unit(10,"points"))
dev.off()
