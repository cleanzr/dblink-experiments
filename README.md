# dblink-experiments

This repository contains scripts, data and documentation for reproducing 
experiments in the following paper:

> Marchant, N. G., Kaplan, A., Elazar, D. N., Rubinstein, B. I. P. and 
> Steorts, R. C. (2021). d-blink: Distributed End-to-End Bayesian Entity 
> Resolution. _Journal of Computational and Graphical Statistics_, _30_(2), 
> 406–421. DOI: [10.1080/10618600.2020.1825451](https://doi.org/10.1080/10618600.2020.1825451)
> arXiv: [1909.06039](https://arxiv.org/abs/1909.06039).

which accompanies our [dblink](https://github.com/cleanzr/dblink) Spark 
package.

The workflow for reproducing the experiments involves:

1. Obtaining the five data sets. See the section [below](#data-sets) for 
details.
2. Obtaining/building the dblink Spark package. Instructions are provided 
in the dblink [repository](https://github.com/cleanzr/dblink).
3. Running the experiments on a Spark cluster. We tested dblink on a local 
server in pseudocluster mode (see `local` directory) and on a Spark cluster 
in AWS (see `aws` directory). 
4. After running the experiments, the plots in the paper can be generated 
using the R scripts in the `plots` directory.

## Directory structure
* `aws`: contains scripts/config files/results for experiments run on a 
YARN deployment of Spark using the Amazon Elastic MapReduce service. 
* `data`: contains two of the data sets used in the experiments.
* `local`: contains scripts/config files/results for experiments run on a 
local server in pseudocluster mode.
* `plots`: contains R scripts for generating the plots in the paper.

## Output of dblink
Each dblink experiment produces the following files which are used to 
populate the tables and generate the plots in the paper:
1. cluster-size-distribution.csv
2. diagnostics.csv
3. evaluation-results.txt
4. partition-sizes.csv
5. run.txt

Since running these experiments can be time consuming (some take approx. 24 
hours) we have included the results in the repository. 
See the `local/results/` and `aws/results` directories. 

For a full description of dblink output, see the documentation [here](https://github.com/cleanzr/dblink/blob/master/docs/guide.md). 

## Data sets
We evaluated d-blink on five data sets in our paper. 
Unfortunately, we are unable to make all of the data sets publicly available 
due to usage restrictions. 
Below we describe how to access each data set. 
Feel free to contact us for further information.

1. `ABSEmployee`. 
A synthetic data set used internally for linkage experiments at the Australian 
Bureau of Statistics (ABS). 
It simulates an employment census and two supplementary surveys. 
The data is available for download [here](data/ABSEmployee.zip).
2. `NCVR`. 
Two snapshots from the North Carolina Voter Registration database taken two 
months apart. 
The snapshots are filtered to include only those voters whose details changed 
over the two-month period. 
The data set was generously provided by Peter Christen. 
We are unable to share this publicly. 
3. `NLTCS`. 
A subset of the National Long-Term Care Survey comprising the 1982, 1989 and 
1994 waves. 
We use the SEX, DOB, STATE and REGOFF attributes. 
The data set is available from [NACDA](https://doi.org/10.3886/ICPSR09681.v5) 
after signing a data use agreement.
4. `SHIW0810`. 
A subset from the Bank of Italy's Survey on Household Income and Wealth 
comprising the 2008 and 2010 waves. 
Use of this data is subject to conditions described [here](https://www.bancaditalia.it/statistiche/tematiche/indagini-famiglie-imprese/bilanci-famiglie/distribuzione-microdati/index.html). 
We have written a script which downloads and pre-processes the data, available 
[here](https://github.com/ngmarchant/shiw).
5. `RLdata10000`. 
A synthetic data set provided with the RecordLinkage R package. 
We do not have permission to redistribute this data set, however we have 
written an R [script](data/RLdata10000.R) which saves the data in CSV format.

