#!/bin/sh

# get the data first
wget -N "ftp://ftp.ncbi.nlm.nih.gov/genbank/gbvrl*.seq.gz"

# process to FASTA file
./processGenBankVirusFiles.py

# process the header lines
grep "^>" genbank_viruses.fa | sed 's/^>//' | sed 's/ /\t/' > genbank_viruses.txt
