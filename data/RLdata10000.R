library(RecordLinkage)

data("RLdata10000")
df <- RLdata10000
df['rec_id'] <- 1:nrow(df)
df['ent_id'] <- identity.RLdata10000

write.csv(df, file="RLdata10000.csv", row.names = FALSE)