# Bio-InterProScanWrapper
Wrapper around InterProScan

[![Build Status](https://travis-ci.org/sanger-pathogens/Bio-InterProScanWrapper.svg?branch=master)](https://travis-ci.org/sanger-pathogens/Bio-InterProScanWrapper)   
[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-brightgreen.svg)](https://github.com/sanger-pathogens/Bio-InterProScanWrapper/blob/master/GPL-LICENSE)   

## Contents
  * [Introduction](#introduction)
    * [Features](#features)
  * [Installation](#installation)
    * [Required dependencies](#required-dependencies)
    * [Using <a href="https://github\.com/miyagawa/cpanminus">cpanm</a>](#using-cpanm)
    * [From Source](#from-source)
    * [Running the tests](#running-the-tests)
  * [Usage](#usage)
  * [License](#license)
  * [Feedback/Issues](#feedbackissues)
  * [Further Information](#further-information)

## Introduction
This is a wrapper around InterProScan. It takes in a FASTA file of proteins, splits them up into smaller chunks, processes them with individual instances of iprscan and then sticks it all back together again. It can run in parallelised mode on a single host or over LSF.
### Features
* Annotates using InterProScan 5.
* Intermediate files cleaned up as soon as they are finished with.
* Creates a GFF3 file with the input sequences at the end.

## Installation
Bio-InterProScanWrapper has the following dependencies:

### Required dependencies
* [IPRscan 5](http://www.ebi.ac.uk/interpro/interproscan.html)

Details for installing Bio-InterProScanWrapper are provided below. If you encounter an issue when installing Bio-InterProScanWrapper please contact your local system administrator. If you encounter a bug please log it [here](https://github.com/sanger-pathogens/Bio-InterProScanWrapper/issues) or email us at path-help@sanger.ac.uk.

### Using cpanm
First install [cpanm](https://github.com/miyagawa/cpanminus), then install Bio-InterProScanWrapper:
```
cpanm Bio::InterProScanWrapper
```
### From Source
Clone the latest version of this repository and cd into it. Then:
```
dzil authordeps | cpanm
dzil listdeps | cpanm
dzil build
```
### Running the tests
The test can be run with dzil from the top level directory:  
  
`dzil test`  

## Usage
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

## License
Bio-InterProScanWrapper is free software, licensed under [GPLv3](https://github.com/sanger-pathogens/Bio-InterProScanWrapper/blob/master/GPL-LICENSE).

## Feedback/Issues
Please report any issues to the [issues page](https://github.com/sanger-pathogens/Bio-InterProScanWrapper/issues) or email path-help@sanger.ac.uk.

## Further Information
Sanger Institute staff should refer to the [wiki](http://mediawiki.internal.sanger.ac.uk/index.php/Pathogen_Informatics_InterProScan_Wrapper) for further information.