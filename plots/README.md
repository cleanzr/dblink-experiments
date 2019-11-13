This directory contains R scripts for producing the plots in the paper. The dependencies are:
* ggplot2
* ddplyr
* stringr
* mcmcse
* scales

The scripts reference files in the `local/results` and `aws/results` directories. 

To run one of the scripts, ensure you have changed directory to this folder, then execute
```bash
Rscript <script-name>.R
```

To run all of the scripts, execute
```bash
for f in ./*.R; do
    Rscript "$f"
done
```
