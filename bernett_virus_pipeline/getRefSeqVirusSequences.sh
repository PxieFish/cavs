#!/bin/sh

# get the latest data from RefSeq
wget -N "ftp://ftp.ncbi.nlm.nih.gov/refseq/release/viral/viral.*.genomic.fna.gz"

# cat the FASTA to a single file
gunzip -c viral.*.genomic.fna.gz > refseq_viruses.fa

# process the header lines
grep "^>" refseq_viruses.fa | sed 's/^>//' | sed 's/ /\t/' > refseq_viruses.txt
