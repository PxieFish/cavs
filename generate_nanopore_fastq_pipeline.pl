#!/usr/bin/perl -w

use warnings;
use strict;
use POSIX;
use Getopt::Long;
use File::Path;
use File::Basename;
use Pod::Usage;

=head1 NAME

generate_nanopore_fastq_pipeline_makefile

=head1 SYNOPSIS
 generate_nanopore_fastq_pipeline_makefile [options]
  -s     sample file list giving the location of each sample
         column 1: sample name
         column 2: path of bam file
  -w     interval width
  -o     output directory
  -m     make file name
=head1 DESCRIPTION
This script implements the pipeline for extracting sequences from nanopore raw data.
=cut

my $help;
my $sampleFile;
my $outputDir;
my $inputFAST5Dir;
my $makeFile = "generate_nanopore_fastq.mk";
my $flowCell = "FLO-MIN106";
my $ligationKit = "SQK-LSK109";
my $barcodeKit = "EXP-NBD104";

#initialize options
Getopt::Long::Configure ('bundling');

if(!GetOptions ('h'=>\$help,
                'i=s'=>\$inputFAST5Dir,
                'f:s'=>\$flowCell,
                'l:s'=>\$ligationKit,
                'b:s'=>\$barcodeKit,
                's=s'=>\$sampleFile,
                'o=s'=>\$outputDir,
                'm:s'=>\$makeFile
               )
  || !defined($outputDir)
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
my $guppy_base_caller = "/usr/local/ont-guppy-4.5.4/bin/guppy_basecaller";
my $guppy_barcoder = "/usr/local/ont-guppy-4.5.4/bin/guppy_barcoder";

printf("generate_nanopore_fastqc_pipeline_makefile.pl\n");
printf("\n");
printf("options: output dir           %s\n", $outputDir);
printf("         make file            %s\n", $makeFile);
printf("         fast5 directory      %s\n", $inputFAST5Dir);
printf("         flow cell            %s\n", $flowCell);
printf("         ligation kit         %s\n", $ligationCell);
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

############################
#call bases from FAST5 files
############################
$inputDir = $inputFAST5Dir;
$tgt = "$outputDir/guppy_basecalls";
$dep = "";
$log = "$outputDir/split.log";
$err = "$outputDir/split.err";
#for CPU calling
#@cmd = ("$guppyBasecaller -i $inputDir -r -s $outputDir --flowcell $flowcell --kit $barcodekit --num_callers 4 --cpu_threads_per_caller 2");
@cmd = ("$guppyBasecaller -i $inputDir -r -s $outputDir --flowcell $flowCell --kit $barcodekit -x auto");
makeJob("local", $tgt, $dep, $log, $err, @cmd);
  
######################
#demultiplex sequences 
######################
$inputDir = $inputFAST5Dir;
$outputDir = $inputFAST5Dir;
$tgt = "$outputDir/guppy_basecalls";
$dep = "";
$log = "$outputDir/split.log";
$err = "$outputDir/split.err";


#guppy_barcoder --input_path <folder containing FASTQ files> --save_path <output folder> --config configuration.cfg --barcode_kits EXP-NBD104

@cmd = ("$guppyBarcoder -i $inputDir -r -s $outputDir --flowcell $flowCell --kit $barcodekit");
makeJob("local", $tgt, $dep, $log, $err, @cmd);

##################
#combine sequences 
##################
for my $sample (@SAMPLES)
{
    $inputDir = $inputFAST5Dir;
    $outputDir = $inputFAST5Dir;
    $tgt = "$outputDir/guppy_basecalls";
    $dep = "";
    $log = "$outputDir/split.log";
    $err = "$outputDir/split.err";
    @cmd = ("cat "$SAMPLES{BARCODE}/"*.fastq | bgzip -c > "B${sample}.fastq.gz"");
    makeJob("local", $tgt, $dep, $log, $err, @cmd);
}

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
        $cmd .= "\tset -o pipefail; " . $c . "\n";
    }
    $cmd .= "\ttouch $tgt\n";
    push(@cmds, $cmd);
}
