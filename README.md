# Bio-InterProScanWrapper
Wrapper around InterProScan

[![Build Status](https://travis-ci.org/sanger-pathogens/Bio-InterProScanWrapper.svg?branch=master)](https://travis-ci.org/sanger-pathogens/Bio-InterProScanWrapper)   
[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-brightgreen.svg)](https://github.com/sanger-pathogens/Bio-InterProScanWrapper/blob/master/GPL-LICENSE)   

## Contents
  * [Introduction](#introduction)
    + [Features](#features)
  * [Installation](#installation)
  * [Running](#running)
    + [Downloading the interproscan data](#downloading-the-interproscan-data)
    + [Setup interproscan.properties](#setup-interproscanproperties)
    + [Download the gene ontology](#download-the-gene-ontology)
    + [Running the container](#running-the-container)
    + [LSF](#lsf)
    + [Usage](#usage)
  * [Building and unit testing](#building-and-unit-testing)
    + [Building](#building)
    + [Testing](#testing)
  * [License](#license)
  * [Feedback/Issues](#feedback-issues)
  * [Further Information](#further-information)

## Introduction
This is a wrapper around InterProScan. It takes in a FASTA file of proteins, splits them up into smaller chunks, processes them with individual instances of iprscan and then sticks it all back together again. It can run in parallelised mode on a single host or over LSF.
### Features
* Annotates using InterProScan 5.
* Intermediate files cleaned up as soon as they are finished with.
* Creates a GFF3 file with the input sequences at the end.

## Installation
Bio-InterProScanWrapper has many dependencies, including [IPRscan 5](https://www.ebi.ac.uk/interpro/about/interproscan/).    Please look at the Dockerfile if you wish to install it from scratch.

A docker image of Bio-InterProScanWrapper is provided on docker as ```sangerpathogens/interproscan``` and this shoud be the preferred way to run it.

## Running
As the objective of this wrapper is to run interproscan on compute clusters, therefore, the ```data``` directory and the ```interproscan.properties``` of the interproscan distribution are not provided with the image.  Instead these are soft linked.

### Downloading the interproscan data
Use ```download_db.sh``` to download the data.
```
download_db.sh -v <version> -o <output directory>
```
This will download the data in the subdirectory ```<output directory>/interproscan-<version>/data```.   

The output directory can be specified in the environment variable ```INTERPROSCAN_DATA_DIR```.

### Setup interproscan.properties
interproscan requires specific setup in file ```interproscan.properties```.  A base version can be obtained in the interproscan download. 

### Download the gene ontology
The gene ontology file ```go-basic.obo``` can be downloaded from [geneontology.org](http://geneontology.org/docs/download-ontology/).  Once downloaded, specify its location in the environment variable ```GO_OBO```:
```
export GO_OBO=/path/to/go-basic.obo
```

### Running the container
The ```data`` directory should be mounted as ```/interproscan/data```.  The directory containing ```interproscan.properties``` should be mounted as ```/interproscan/config```.  
To run interproscan in docker:  
```
docker run -v /path/to/config:/interproscan/config -v /path/to/data:/interproscan/data -v <other volume like current dir> -it sangerpathogens/interproscan:<version desired> interproscan.sh
```

To run farm_interproscan in docker:  
```
docker run -v /path/to/config:/interproscan/config -v /path/to/data:/interproscan/data -v <other volume like current dir> -it sangerpathogens/interproscan:<version desired> farm_interproscan
```

### LSF
LSF executable will need to be provided to the container to use ```farm_interproscan``` on ```lsf```.


### Usage
```
Usage: farm_interproscan [options]
Run InterProScan on the farm. It is limited to using 400 CPUs at once on the farm.

# Run InterProScan using LSF
farm_interproscan -a proteins.faa

# Provide an output file name
farm_interproscan -a proteins.faa -o output.gff

# Create 200 jobs at a time, writing out intermediate results to a file
farm_interproscan -a proteins.faa -p 200

# Run on a single host (no LSF). '-p x' needs x*2 CPUs and x*2GB of RAM to be available
farm_interproscan -a proteins.faa --no_lsf -p 10

# Run InterProScan using LSF with GFF input (standard genetic code for translation)
farm_interproscan -a annotation.gff -g

# Run InterProScan using LSF with GFF input (bacterial code for translation)
farm_interproscan -a annotation.gff -g -c 11

# This help message
farm_interproscan -h
```

## Building and unit testing
### Building
Bio-InterProScanWrapper is built using dzil:
```
dzil authordeps | cpanm
dzil listdeps | cpanm
dzil build
```

### Testing
The test can be run with dzil from the top level directory:  

`dzil test`  

## License
Bio-InterProScanWrapper is free software, licensed under [GPLv3](https://github.com/sanger-pathogens/Bio-InterProScanWrapper/blob/master/GPL-LICENSE).

## Feedback/Issues
Please report any issues to the [issues page](https://github.com/sanger-pathogens/Bio-InterProScanWrapper/issues).

## Further Information
[Interpro] (https://www.ebi.ac.uk/interpro/about/interpro/)   
[Interproscan wiki] (https://github.com/ebi-pf-team/interproscan/wiki)   
[geneontology.org](http://geneontology.org/)   
