# dblink-experiments

TODO:
* Short summary: code for reproducing experiments in dblink paper
* Cite paper
* Link to dblink repo
* Explain the directory structure (ran experiments twice: once on local server, once on AWS)

## Data sets:

We evaluation dblink on five real and synthetic data sets, which we describe below. 

\begin{itemize}
  \item \texttt{ABSEmployee}. A synthetic data set used 
  internally for linkage experiments at [REDACTED].
  It simulates an employment census and two supplementary 
  surveys.\footnote{\texttt{ABSEmployee} is available from the 
    authors by request. 
    It is not derived from any real data sources.}
  \item \texttt{NCVR}. Two snapshots from the North Carolina 
  Voter Registration database taken two months 
  apart~\cite{christen_preparation_2014}.
  The snapshots are filtered to include only those voters 
  whose details changed over the two-month period.
  We use the full name, age, gender and zip code attributes.
  \item \texttt{NLTCS}. A subset of the National Long-Term 
  Care Survey~\cite{manton_nltcs_2010} comprising the 
  1982, 1989 and 1994 waves.
  We use the SEX, DOB, STATE and REGOFF attributes.
  \item \texttt{SHIW0810}. A subset from the Bank of Italy's 
  Survey on Household Income and Wealth~\cite{bancaitalia_2010} 
  comprising the 2008 and 2010 waves. We use 8 attributes: IREG, SESSO, ANASC, STUDIO, PAR, 
  STACIV, PERC and CFDIC.
    \item \texttt{RLdata10000}. A synthetic data set provided 
  with the \texttt{RecordLinkage} R 
  package~\cite{sariyar_recordlinkage_2010}.
  We use all attributes except for fname\_c2 and lname\_c2.
  \end{itemize}


TODO: Describe how to obtain each data set (include external links). Include scripts if any pre-processing is required.
* NLTCS
* NCVR
* RLdata10000
* SHIW0810
* ABSEmployee
