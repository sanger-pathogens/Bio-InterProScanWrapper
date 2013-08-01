Bio-InterProScanWrapper
=======================
This is a wrapper around InterProScan. It takes in a FASTA file of proteins, splits them up into smaller chunks,
processes them with individual instances of iprscan and then sticks it all back together again.
It can run in parallelised mode on a single host or over LSF.

Features:
Intermediate files cleaned up as soon as they are finished with,
It creates a GFF3 file that can be opened in Artemis (input proteins appended to the end of the annotation.

Dependancies:
A working version of IPRscan 5




    Annotate eukaryotes
  
    $script_name -a proteins.faa
    
    # Run on a single host with 10 instances - it needs 20 CPUs and 20GB of RAM to be reserved
    $script_name -a proteins.faa -p 10
    
    # Split up over multiple hosts using LSF where '-p' is the max number of jobs at any given time
    $script_name -a proteins.faa --use_lsf -p 10

    # This help message
    annotate_eukaryotes -h

