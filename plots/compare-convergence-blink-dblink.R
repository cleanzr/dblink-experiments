library(dplyr)
library(tidyverse)
library(stringr)

expts <- list("d-blink" = "../local/results/RLdata10000_1partitions_PCG-I",
              "blink" = "../local/results/RLdata10000_1partitions_Gibbs-Seq")

update_geom_defaults("point", list(size=1.5))
theme_set(theme_bw(base_size=8))
plotWidth <- 3.349263889
plotHeight <- 2.6

diagnostics <- lapply(names(expts), function(name) {
  read.csv(paste(expts[[name]],"diagnostics.csv", sep="/")) %>%
    mutate(implementation = name,
           runtime = 1e-3*(systemTime.ms - systemTime.ms[1]))
}) %>% bind_rows()

pdf("convergence-num-ent-blink-dblink.pdf", height = plotHeight, width = 0.8*plotWidth)
diagnostics %>%
  select(runtime, implementation, numObservedEntities) %>% 
  ggplot(aes(x = runtime, y = numObservedEntities, col = implementation)) + 
  geom_line(aes(linetype = implementation), size=0.4) +
  scale_x_continuous(limits = c(0, 40000), labels = function(x) format(1e-4*x,digits = 2)) + 
  labs(x = expression(Time~('×'*10^{4}~sec)), y = "# observed entities", col = "Implementation", linetype = "Implementation") + 
  theme(legend.position="none", legend.margin=margin(0,0,0,0), legend.key.height = unit(10,"points"))
dev.off()

# Trace plot for attribute-level distortions
pdf("convergence-agg-dist-blink-dblink.pdf", height = plotHeight, width = plotWidth)
diagnostics %>%
  select(runtime, implementation, starts_with("aggDist")) %>%
  gather(field, numDistortions, starts_with("aggDist")) %>%
  mutate(field = str_match(field, "\\.(.+)")[,2]) %>% 
  ggplot(aes(x = runtime, y = numDistortions, col = implementation)) + 
  geom_line(aes(linetype = implementation), size=0.4) + 
  facet_grid(field~., scales = "free_y") +
  scale_x_continuous(limits = c(0, 40000), labels = function(x) format(1e-4*x,digits = 2)) + 
  labs(x = expression(Time~('×'*10^{4}~sec)), y = "Aggregate distortion", col = "Implementation", linetype = "Implementation") + 
  theme(legend.margin=margin(0,0,0,0), legend.key.height = unit(10,"points"))
dev.off()
