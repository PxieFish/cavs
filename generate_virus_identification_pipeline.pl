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
my $sampleFile;
my $outputDir;
my $inputFAST5Dir;
my $makeFile = "virus_identification_pipeline.mk";
my $flowCell = "FLO-MIN106";
my $ligationKit = "SQK-LSK109";
my $barcodeKit = "EXP-NBD104";
my $dataDir;

#initialize options
Getopt::Long::Configure ('bundling');

if(!GetOptions ('h'=>\$help,
                'i=s'=>\$inputFAST5Dir,
                'd=s'=>\$dataDir,
                'f:s'=>\$flowCell,
                'l:s'=>\$ligationKit,
                'b:s'=>\$barcodeKit,
                's=s'=>\$sampleFile,
                'o=s'=>\$outputDir,
                'm:s'=>\$makeFile
               )
  || !defined($outputDir)
  || !defined($dataDir)
  || !defined($inputFAST5Dir)
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
my $guppyBaseCaller = "/usr/local/ont-guppy-4.5.4/bin/guppy_basecaller";
my $guppyBarcoder = "/usr/local/ont-guppy-4.5.4/bin/guppy_barcoder";
my $nanoplot = "/usr/local/bin/NanoPlot";

printf("generate_virus_identification_pipeline_makefile.pl\n");
printf("\n");
printf("options: output dir           %s\n", $outputDir);
printf("         make file            %s\n", $makeFile);
printf("         fast5 directory      %s\n", $inputFAST5Dir);
printf("         flow cell            %s\n", $flowCell);
printf("         ligation kit         %s\n", $ligationKit);
printf("         barcode kit          %s\n", $barcodeKit);
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
        my ($sampleID, $barcode) = split(/\s+/, $_);
        
        if (exists($SAMPLE{$sampleID}))
        {
            exit("$sampleID already exists. Please fix.");
        }
        
        $SAMPLE{$sampleID}{BARCODE} = $barcode;
        
        push(@SAMPLE, $sampleID);
    }
}
close(SA);

print "read in " . scalar(@SAMPLE) . " samples\n";

my $inputDir;

############################
#call bases from FAST5 files
############################
$inputDir = $inputFAST5Dir;
$tgt = "$outputDir/guppy_basecaller.OK";
$dep = "";
$log = "$outputDir/guppy_basecaller.log";
$err = "$outputDir/guppy_basecaller.err";
#for CPU calling
#@cmd = ("$guppyBasecaller -i $inputDir -r -s $outputDir --flowcell $flowcell --kit $barcodekit --num_callers 4 --cpu_threads_per_caller 2");
@cmd = ("$guppyBaseCaller -i $inputFAST5Dir -r -s $outputDir/basecalls --flowcell $flowCell --kit $ligationKit -x auto > $log 2> $err");
makeJob("local", $tgt, $dep, @cmd);
  
######################
#demultiplex sequences 
######################
$inputDir = $inputFAST5Dir;
$tgt = "$outputDir/guppy_barcoder.OK";
$dep = "$outputDir/guppy_basecaller.OK";
$log = "$outputDir/guppy_barcoder.log";
$err = "$outputDir/guppy_barcoder.err";
@cmd = ("$guppyBarcoder -i $outputDir/basecalls -r -s $outputDir/demux_fastq --barcode_kits $barcodeKit -t 2 > $log 2> $err");
makeJob("local", $tgt, $dep, @cmd);

#################################
#combine sequences and copy to 
#################################
mkpath("$outputDir/sample_fastq");
for my $i (0..$#SAMPLE)
{
    my $j = $i+1;
    my $sampleID = $SAMPLE[$i];
    my $fastqOutputDir = "$dataDir/" . $j . "_$sampleID"; 
    mkpath($fastqOutputDir);
    $inputDir = "$outputDir/demux_fastq/barcode" . ($j<=9? "0" : "") . $j;
    $tgt = "$outputDir/sample_fastq/$j.join.OK";
    $dep = "$outputDir/guppy_barcoder.OK";
    $err = "$outputDir/sample_fastq/$j.join.err";
    @cmd = ("cat $inputDir/*.fastq | bgzip -c > $fastqOutputDir/" . $j . "_$sampleID.fastq.gz  2> $err");
    makeJob("local", $tgt, $dep, @cmd);
}

#########################
#generate nanoplot output
#########################
for my $i (0..$#SAMPLE)
{
    my $j = $i+1;
    my $sampleID = $SAMPLE[$i];
    my $fastqOutputDir = "$dataDir/" . $j . "_$sampleID"; 
    my $inputFASTQFile = "$fastqOutputDir/" . $j . "_$sampleID.fastq.gz";
    my $outputNanoplotResultDir = "$fastqOutputDir/nanoplot_result";
    $tgt = "$outputDir/sample_fastq/$j.nanoplot.OK";
    $dep = "$outputDir/sample_fastq/$j.join.OK";
    $err = "$outputDir/sample_fastq/$j.nanoplot.err";
    @cmd = ("$nanoplot --fastq $inputFASTQFile -o $outputNanoplotResultDir 2> $err");
    makeJob("local", $tgt, $dep, @cmd);
}


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
