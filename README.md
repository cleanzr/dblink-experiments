# dblink-experiments

`dblink` is a Spark package for performing unsupervised entity resolution 
(ER) on structured data. The open source code can be found at [`dblink`](https://github.com/cleanzr/dblink/) and the 
paper can be found at [(Marchant et al, 2019)](https://arxiv.org/abs/1909.06039). Unlike many ER algorithms, `dblink` approximates the full posterior distribution over clusterings of records (into entities).
This facilitates propagation of uncertainty to post-ER analysis, 
and provides a framework for answering probabilistic queries about entity 
membership. `dblink` approximates the posterior using Markov chain Monte Carlo.
It writes samples (of clustering configurations) to disk in Parquet format.
Diagnostic summary statistics are also written to disk in CSV format—these are 
useful for assessing convergence of the Markov chain.

In this repository, we reproduce the experiments in [(Marchant et al, 2019](https://arxiv.org/abs/1909.06039). 

Specifically, in [Marchant et al, 2019](https://arxiv.org/abs/1909.06039), two types of experiments are run, those on a local server and those on Amazon Web Services (AWS). In this repository, we replicates both sets of experiments, providing configurations files that will reproduce the experiments for the five data sets that were utilized in the paper. 

For example, for the local server and a data set, we provide a shell script run.sh as well as a configuration file dataset.config that produces the following output for each data set:

1. cluster-size-distribution.csv
2. diagnostics.csv
3. evaluation-results.csv
4. partition-sizes.csv
5. results.csv

A full description of these files can be found at [`dblink`](https://github.com/cleanzr/dblink/). 

In order to analyze the output of these files, we have provided scripts to aide the user, which can be found at 
[plots][INSERT PUBLIC LINK LATER], which produce the following plots:

1. Traceplots
2. Posterior Bias Plots
3. What Else? (The plot names are not very informative). 


TODO:
* Short summary: code for reproducing experiments in dblink paper
* Cite paper
* Link to dblink repo
* Explain the directory structure (ran experiments twice: once on local server, once on AWS)

## Data sets:

We evaluation dblink on five real and synthetic data sets, which we describe below. 

1. ABSEmployee. A synthetic data set used 
  internally for linkage experiments at [REDACTED].
  It simulates an employment census and two supplementary 
  surveys. 
2. NCVR. Two snapshots from the North Carolina 
  Voter Registration database taken two months 
  apart at [REDACTED]. The snapshots are filtered to include only those voters 
  whose details changed over the two-month period.
  We use the full name, age, gender and zip code attributes.
 3. NLTCS  A subset of the National Long-Term 
  Care Survey~\cite{manton_nltcs_2010} comprising the 
  1982, 1989 and 1994 waves. We use the SEX, DOB, STATE and REGOFF attributes.
  This data set can be accessed via https://www.nia.nih.gov/research/resource/national-long-term-care-survey-nltcs
  and registering through the webpage to access the data. (The data cannot be re-published online). 
  4. SHIW0810. A subset from the Bank of Italy's 
  Survey on Household Income and Wealth  
  comprising the 2008 and 2010 waves. We use 8 attributes: IREG, SESSO, ANASC, STUDIO, PAR, 
  STACIV, PERC and CFDIC.
  This dataset can be accessed at https://github.com/cleanzr/italy.
  5. RLdata10000.  A synthetic data set provided 
  with the RecordLinkage R 
  package. We use all attributes except for fname\_c2 and lname\_c2.
  This data set can be accessed via CRAN. TODO: Do we want to put this data set properly formatted on cleanzr for easy access?  
 
 TODO: Make sure to give all references to the relevant citations and weblinks where the data can be found. 
