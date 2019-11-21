# dblink-experiments

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
  apart. The snapshots are filtered to include only those voters 
  whose details changed over the two-month period.
  We use the full name, age, gender and zip code attributes.
 3. NLTCS  A subset of the National Long-Term 
  Care Survey~\cite{manton_nltcs_2010} comprising the 
  1982, 1989 and 1994 waves. We use the SEX, DOB, STATE and REGOFF attributes.
  4. SHIW0810. A subset from the Bank of Italy's 
  Survey on Household Income and Wealth  
  comprising the 2008 and 2010 waves. We use 8 attributes: IREG, SESSO, ANASC, STUDIO, PAR, 
  STACIV, PERC and CFDIC.
  5. RLdata10000.  A synthetic data set provided 
  with the RecordLinkage R 
  package. We use all attributes except for fname\_c2 and lname\_c2.
 
 TODO: Make sure to give all references to the relevant citations and weblinks where the data can be found. 
