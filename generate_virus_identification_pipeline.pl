#!/usr/bin/perl -w

use warnings;
use strict;
use POSIX;
use Getopt::Long;
use File::Path;
use File::Basename;
use Pod::Usage;

=head1 NAME

generate_virus_identification_pipeline_makefile

=head1 SYNOPSIS

 generate_virus_identification_pipeline_makefile [options]
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

This script implements the pipeline for extracting sequences from nanopore raw data.

=cut

my $help;
my $outputDir;
my $makeFile = "virus_identification_pipeline.mk";
my $forwardFASTQFile;
my $reverseFASTQFile;

#initialize options
Getopt::Long::Configure ('bundling');

if(!GetOptions ('h'=>\$help,
                '1:s'=>\$forwardFASTQFile,
                '2:s'=>\$reverseFASTQFile,
                'o=s'=>\$outputDir,
                'm:s'=>\$makeFile
               )
  || !defined($outputDir)
  || !defined($forwardFASTQFile)
  || !defined($reverseFASTQFile))
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
my $trimmomatic = "/usr/bin/java -jar /usr/local/Trimmomatic-0.39/trimmomatic-0.39.jar";
my $seqtk = "//usr/local/seqtk-1.3/seqtk";
my $diamond = "/usr/local/diamond-2.0.9/diamond";

printf("generate_virus_identification_pipeline_makefile.pl\n");
printf("\n");
printf("options: output dir           %s\n", $outputDir);
printf("         make file            %s\n", $makeFile);
printf("         forward FASTQ file   %s\n", $forwardFASTQFile);
printf("         reverse FASTQ file   %s\n", $reverseFASTQFile);
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


#download uniprot
#wget https://ftp.uniprot.org/pub/databases/uniprot/uniref/uniref90/uniref90.fasta.gz

#>UniqueIdentifier ClusterName n=Members Tax=TaxonName TaxID=TaxonIdentifier RepID=RepresentativeMember
#Where:
#
#UniqueIdentifier is the primary accession number of the UniRef cluster.
#ClusterName is the name of the UniRef cluster.
#Members is the number of UniRef cluster members.
#TaxonName is the scientific name of the lowest common taxon shared by all UniRef cluster members.
#TaxonIdentifier is the NCBI taxonomy identifier of the lowest common taxon shared by all UniRef cluster members.
#RepresentativeMember is the entry name of the representative member of the UniRef cluster.
#Example:
#
#>UniRef50_Q9K794 Putative AgrB-like protein n=2 Tax=Bacillus TaxID=1386 RepID=AGRB_BACHD
#
#cat uniref90.sequence_headers.txt | grep virus | cut -f1 -d " " | sed -e "s/^>//" > virus_genomes.txt
#
#seqtk subseq uniref90.fasta.gz virus_genomes.txt  | gzip -c > uniprot.virus.fasta.gz
#
#wget https://hgdownload.soe.ucsc.edu/goldenPath/susScr11/bigZips/susScr11.fa.gz
#
#bwa index -a bwtsw susScr11.fa.gz 
#
#bwa mem -t 2 -M ref/susScr11.fa.gz 1_SIV-Hoff/SIV-Hoff_S1_L001_R1_001.fastq.gz  1_SIV-Hoff/SIV-Hoff_S1_L001_R2_001.fastq.gz  -o siv_hoff.bam
#
#diamond blastp -d reference -q 1_SIV-Hoff/SIV-Hoff_S1_L001_R1_001.fastq.gz  -o p1_matches.tsv
#diamond blastx -d reference -q 1_SIV-Hoff/SIV-Hoff_S1_L001_R1_001.fastq.gz  -o x1_matches.tsv
#diamond blastx -d reference -q 1_SIV-Hoff/SIV-Hoff_S1_L001_R2_001.fastq.gz  -o x2_matches.tsv


my $inputDir;

###############
#trim sequences
###############
$tgt = "$outputDir/guppy_basecaller.OK";
$dep = "";
$log = "$outputDir/guppy_basecaller.log";
$err = "$outputDir/guppy_basecaller.err";
#for CPU calling
#@cmd = ("$guppyBasecaller -i $inputDir -r -s $outputDir --flowcell $flowcell --kit $barcodekit --num_callers 4 --cpu_threads_per_caller 2");
@cmd = ("$guppyBaseCaller -i $inputFAST5Dir -r -s $outputDir/basecalls --flowcell $flowCell --kit $ligationKit -x auto > $log 2> $err");
makeJob("local", $tgt, $dep, @cmd);








#######################
##demultiplex sequences 
#######################
#$inputDir = $inputFAST5Dir;
#$tgt = "$outputDir/guppy_barcoder.OK";
#$dep = "$outputDir/guppy_basecaller.OK";
#$log = "$outputDir/guppy_barcoder.log";
#$err = "$outputDir/guppy_barcoder.err";
#@cmd = ("$guppyBarcoder -i $outputDir/basecalls -r -s $outputDir/demux_fastq --barcode_kits $barcodeKit -t 2 > $log 2> $err");
#makeJob("local", $tgt, $dep, @cmd);
#
##################################
##combine sequences and copy to 
##################################
#mkpath("$outputDir/sample_fastq");
#for my $i (0..$#SAMPLE)
#{
#    my $j = $i+1;
#    my $sampleID = $SAMPLE[$i];
#    my $fastqOutputDir = "$dataDir/" . $j . "_$sampleID"; 
#    mkpath($fastqOutputDir);
#    $inputDir = "$outputDir/demux_fastq/barcode" . ($j<=9? "0" : "") . $j;
#    $tgt = "$outputDir/sample_fastq/$j.join.OK";
#    $dep = "$outputDir/guppy_barcoder.OK";
#    $err = "$outputDir/sample_fastq/$j.join.err";
#    @cmd = ("cat $inputDir/*.fastq | bgzip -c > $fastqOutputDir/" . $j . "_$sampleID.fastq.gz  2> $err");
#    makeJob("local", $tgt, $dep, @cmd);
#}
#
##########################
##generate nanoplot output
##########################
#for my $i (0..$#SAMPLE)
#{
#    my $j = $i+1;
#    my $sampleID = $SAMPLE[$i];
#    my $fastqOutputDir = "$dataDir/" . $j . "_$sampleID"; 
#    my $inputFASTQFile = "$fastqOutputDir/" . $j . "_$sampleID.fastq.gz";
#    my $outputNanoplotResultDir = "$fastqOutputDir/nanoplot_result";
#    $tgt = "$outputDir/sample_fastq/$j.nanoplot.OK";
#    $dep = "$outputDir/sample_fastq/$j.join.OK";
#    $err = "$outputDir/sample_fastq/$j.nanoplot.err";
#    @cmd = ("$nanoplot --fastq $inputFASTQFile -o $outputNanoplotResultDir 2> $err");
#    makeJob("local", $tgt, $dep, @cmd);
#}


#######################
#generate multiqc output?
#######################

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
