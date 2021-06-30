#!/usr/bin/perl -w

use warnings;
use strict;
use POSIX;
use Getopt::Long;
use File::Path;
use File::Basename;
use Pod::Usage;

=head1 NAME

generate_nanopore_16S_analyses_pipeline

=head1 SYNOPSIS

 generate_nanopore_16S_analyses_pipeline [options]
  -i     FAST5 directory
  -s     sample file     
         column 1: sample ID
         column 2: nanopore barcode
  -f     flow cell 
  -l     ligation kit
  -b     barcode kit
  -o     output directory
  -m     make file name
                
=head1 DESCRIPTION

This script implements the pipeline for mapping the reads against a 16S rRNA database.

=cut

my $help;
my $sampleFile;
my $outputDir;
my $inputFAST5Dir;
my $makeFile = "nanopore_16S_rRNA_blast_analysis.mk";
my $dataDir;

#initialize options
Getopt::Long::Configure ('bundling');

if(!GetOptions ('h'=>\$help,
                's=s'=>\$sampleFile,
                'o=s'=>\$outputDir,
                'm:s'=>\$makeFile
               )
  || !defined($outputDir)
  || !defined($sampleFile))
{
    if ($help)
    {
        pod2usage(-verbose => 2);
    }
    else
    {
        pod2usage(1);
    }
}

$makeFile = "$outputDir/$makeFile";

#programs
my $blastn= "/usr/local/ont-guppy-4.5.4/bin/guppy_basecaller";
my $guppyBarcoder = "/usr/local/ont-guppy-4.5.4/bin/guppy_barcoder";
my $nanoplot = "/usr/local/bin/NanoPlot";

printf("generate_nanopore_fastqc_pipeline.pl\n");
printf("\n");
printf("options: output dir           %s\n", $outputDir);
printf("         make file            %s\n", $makeFile);
printf("         fast5 directory      %s\n", $inputFAST5Dir);
printf("         data directory       %s\n", $dataDir);
printf("         sample file          %s\n", $sampleFile);
printf("\n");

################################################
#Helper data structures for generating make file
################################################
my @tgts = ();
my @deps = ();
my @cmds = ();
my $tgt;
my $dep;
my $log;
my $err;
my @cmd;

#################
#Read sample file 
#################
my %SAMPLE = ();
my @SAMPLE = ();
open(SA,"$sampleFile") || die "Cannot open $sampleFile\n";
while (<SA>)
{
    s/\r?\n?$//;
    if(!/^#/)
    {
        my ($sampleID, $fastqFile) = split(/\s+/, $_);
        
        if (exists($SAMPLE{$sampleID}))
        {
            exit("$sampleID already exists. Please fix.");
        }
        
        
        #count files
        
        push(@SAMPLE, $sampleID);
    }
}
close(SA);

print "read in " . scalar(@SAMPLE) . " samples\n";

my $inputDir;

############################
#call bases from FAST5 files
############################
#$inputDir = $inputFAST5Dir;
#$tgt = "$outputDir/guppy_basecaller.OK";
#$dep = "";
#$log = "$outputDir/guppy_basecaller.log";
#$err = "$outputDir/guppy_basecaller.err";
##for CPU calling
##@cmd = ("$guppyBasecaller -i $inputDir -r -s $outputDir --flowcell $flowcell --kit $barcodekit --num_callers 4 --cpu_threads_per_caller 2");
#@cmd = ("$guppyBaseCaller -i $inputFAST5Dir -r -s $outputDir/basecalls --flowcell $flowCell --kit $ligationKit -x auto > $log 2> $err");
#makeJob("local", $tgt, $dep, @cmd);

#NCBI 16S rRNA
#esearch -db nucleotide -query "33175[BioProject] OR 33317[BioProject] " | efetch -format fasta > out.fasta
#makeblastdb -in 21940seq_16s.fasta  -dbtype nucl -parse_seqids
 
#export BLASTDB=/usr/local/ncbi-blast-2.11.0+/bin
#seqtk seq -a
#seqtk sample
# 
#blastn -db db/21940seq_16s.fasta -query 8_sambardeer_faeces.fasta -outfmt "6 stitle pident" -out 8.out -max_target_seqs 1  -num_threads 6

#summarise results
#cat 8.out | cut -f1  | perl -lane '{/([^\s]+) ([^\s]+)/; print "$1 $2"}' | sort | uniq -c | sort -nrk1

#store top 10,000 reads.


############################
#call bases from FAST5 files
############################
#$inputDir = $inputFAST5Dir;
#$tgt = "$outputDir/guppy_basecaller.OK";
##$dep = "";
#$log = "$outputDir/guppy_basecaller.log";
#$err = "$outputDir/guppy_basecaller.err";
##for CPU calling
##@cmd = ("$guppyBasecaller -i $inputDir -r -s $outputDir --flowcell $flowcell --kit $barcodekit --num_callers 4 --cpu_threads_per_caller 2");
#@cmd = ("$guppyBaseCaller -i $inputFAST5Dir -r -s $outputDir/basecalls --flowcell $flowCell --kit $ligationKit -x auto > $log 2> $err");
#makeJob("local", $tgt, $dep, @cmd);
  




#*******************
#Write out make file
#*******************
GENERATE_MAKEFILE:
print "\nwriting makefile\n";

open(MAK,">$makeFile") || die "Cannot open $makeFile\n";
print MAK ".DELETE_ON_ERROR:\n\n";
print MAK "all: @tgts\n\n";

#clean
push(@tgts, "clean");
push(@deps, "");
push(@cmds, "\t-rm -rf $outputDir/*.* $outputDir/intervals/*.*");

for(my $i=0; $i < @tgts; ++$i) {
    print MAK "$tgts[$i] : $deps[$i]\n";
    print MAK "$cmds[$i]\n";
}
close MAK;

##########
#Functions
##########

#run a job either locally or by pbs
sub makeJob
{
    my ($method, @others) = @_;

    if ($method eq "local")
    {
        my ($tgt, $dep, @rest) = @others;
        makeLocalStep($tgt, $dep, @rest);
    }
    else
    {
        die "unrecognized method of job creation : $method\n";
    }
}

sub makeLocalStep
{
    my ($tgt, $dep, @cmd) = @_;

    push(@tgts, $tgt);
    push(@deps, $dep);
    my $cmd = "";
    for my $c (@cmd)
    {
        if ($cmd =~ /\|/)
        {
            $cmd .= "\tset -o pipefail; " . $c . "\n";
        }
        else
        {
            $cmd .= "\t$c\n";
        }
    }
    $cmd .= "\ttouch $tgt\n";
    push(@cmds, $cmd);
}
