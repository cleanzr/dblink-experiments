library(dplyr)
library(ggplot2)
library(stringr)

expts <- list(list(name = "ABSEmployee", burnin = 10000, numRecords = 600000, trueNumEntities = 400000, path = "../aws/results/ABSEmployee_64partitions_PCG-I"),
              list(name = "NCVR", burnin = 210000, numRecords = 448134, trueNumEntities = 296433, path = "../aws/results/NCVR_64partitions_PCG-I"),
              list(name = "NLTCS", burnin = 10000, numRecords = 57077, trueNumEntities = 34945, path = "../aws/results/NLTCS_16partitions_PCG-I"),
              list(name = "RLdata10000", burnin = 10000, numRecords = 10000, trueNumEntities = 9000, path = "../aws/results/RLdata10000_2partitions_PCG-I"),
              list(name = "SHIW0810", burnin = 10000, numRecords = 39743, trueNumEntities = 28584, path = "../aws/results/SHIW_8partitions_PCG-I"))

save.fname <- "posterior-bias-plot.pdf"
plotWidth <- 4.0
plotHeight <- 2.0

update_geom_defaults("point", list(size=1.5))
theme_set(theme_bw(base_size=9))

results <- lapply(expts, function(expt) {
  # Read diagnostic CSV files from experiment
  diagnostics <- read.csv(paste(expt[['path']],"diagnostics.csv", sep="/"))
  
  # Get number of entities
  numEntities <- diagnostics %>% filter(iteration < expt[['burnin']]) %>% .$numObservedEntities
  
  data.frame(numEntities = numEntities, expt, stringsAsFactors = FALSE)
}) %>% bind_rows()

## add true counts
results %>%
  mutate(percError = 100 * (numEntities - trueNumEntities) / trueNumEntities) %>% 
  group_by(name) %>%
  summarise(priorError = 100 * ((1-1/exp(1))*(unique(numRecords)) - unique(trueNumEntities))/unique(trueNumEntities), 
            mean = mean(percError), ll = quantile(percError, .025), ul = quantile(percError, .975)) %>%
  ggplot() +
  geom_segment(aes(name, xend = name, y = ll, yend = ul), position = position_nudge(x = .1), colour = "red4") +
  geom_point(aes(name, mean, colour = "post"), position = position_nudge(x = .1), size = 0.5) +
  geom_point(aes(name, priorError, colour = "prior"), position = position_nudge(x = -.1), size = 0.5) +
  geom_hline(aes(yintercept = 0), lty = 2) +
  xlab("Data set") + ylab("Error %") +
  scale_colour_manual(name="Estimate",
                      values=c(post="red", prior="blue"),
                      labels=c("Posterior", "Prior")) +
  coord_flip() + 
  theme(legend.margin=margin(0, 0, 0, 0), legend.key.size = unit(10,"points"), legend.text = element_text(size = 6)) -> posterior_bias.p

ggsave("posterior-bias-plot-dark.pdf", posterior_bias.p, width = plotWidth, height = plotHeight)

## add legend -----

results %>%
  mutate(percError = 100 * (numEntities - trueNumEntities) / trueNumEntities) %>% 
  group_by(name) %>%
  summarise(priorError = 100 * ((1-1/exp(1))*(unique(numRecords)) - unique(trueNumEntities))/unique(trueNumEntities), 
            mean = mean(percError), ll = quantile(percError, .025), ul = quantile(percError, .975)) %>%
  ggplot() +
  geom_segment(aes(name, xend = name, y = ll, yend = ul, colour = "post-ci"), position = position_nudge(x = .1)) +
  geom_point(aes(name, mean, colour = "post"), position = position_nudge(x = .1), size = 0.5) +
  geom_point(aes(name, priorError, colour = "prior"), position = position_nudge(x = -.1), size = 0.5) +
  geom_hline(aes(yintercept = 0), lty = 2) +
  xlab("Data set") + ylab("Error %") +
  scale_colour_manual(name="Estimate",
                      values=c(post="red", `post-ci`="red4", prior="blue"),
                      labels=c("Posterior", "95% CI", "Prior")) +
  coord_flip() + 
  theme(legend.margin=margin(0, 0, 0, 0), legend.key.size = unit(10,"points"), legend.text = element_text(size = 6)) -> posterior_bias.p

ggsave("posterior-bias-plot-dark-legend.pdf", posterior_bias.p, width = plotWidth, height = plotHeight)

# grey ci ----

results %>%
  mutate(percError = 100 * (numEntities - trueNumEntities) / trueNumEntities) %>% 
  group_by(name) %>%
  summarise(priorError = 100 * ((1-1/exp(1))*(unique(numRecords)) - unique(trueNumEntities))/unique(trueNumEntities), 
            mean = mean(percError), ll = quantile(percError, .025), ul = quantile(percError, .975)) %>%
  ggplot() +
  geom_segment(aes(name, xend = name, y = ll, yend = ul), position = position_nudge(x = .1), colour = "grey50") +
  geom_point(aes(name, mean, colour = "post"), position = position_nudge(x = .1), size = 0.5) +
  geom_point(aes(name, priorError, colour = "prior"), position = position_nudge(x = -.1), size = 0.5) +
  geom_hline(aes(yintercept = 0), lty = 2) +
  xlab("Data set") + ylab("Error %") +
  scale_colour_manual(name="Estimate",
                      values=c(post="red", prior="blue"),
                      labels=c("Posterior", "Prior")) +
  coord_flip() + 
  theme(legend.margin=margin(0, 0, 0, 0), legend.key.size = unit(10,"points"), legend.text = element_text(size = 6)) -> posterior_bias.p

ggsave("posterior-bias-plot-grey.pdf", posterior_bias.p, width = plotWidth, height = plotHeight)

## grey legend -----

results %>%
  mutate(percError = 100 * (numEntities - trueNumEntities) / trueNumEntities) %>% 
  group_by(name) %>%
  summarise(priorError = 100 * ((1-1/exp(1))*(unique(numRecords)) - unique(trueNumEntities))/unique(trueNumEntities), 
            mean = mean(percError), ll = quantile(percError, .025), ul = quantile(percError, .975)) %>%
  ggplot() +
  geom_segment(aes(name, xend = name, y = ll, yend = ul, colour = "post-ci"), position = position_nudge(x = .1)) +
  geom_point(aes(name, mean, colour = "post"), position = position_nudge(x = .1), size = 0.5) +
  geom_point(aes(name, priorError, colour = "prior"), position = position_nudge(x = -.1), size = 0.5) +
  geom_hline(aes(yintercept = 0), lty = 2) +
  xlab("Data set") + ylab("Error %") +
  scale_colour_manual(name="Estimate",
                      values=c(post="red", `post-ci`="grey50", prior="blue"),
                      labels=c("Posterior", "95% CI", "Prior")) +
  coord_flip() + 
  theme(legend.margin=margin(0, 0, 0, 0), legend.key.size = unit(10,"points"), legend.text = element_text(size = 6)) -> posterior_bias.p

ggsave("posterior-bias-plot-grey-legend.pdf", posterior_bias.p, width = plotWidth, height = plotHeight)


  
