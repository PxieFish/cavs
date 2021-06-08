#!/usr/bin/perl -w

use warnings;
use strict;
use POSIX;
use Getopt::Long;
use File::Path;
use File::Basename;
use Pod::Usage;

=head1 NAME

generate_download_virus_databases_pipeline_makefile

=head1 SYNOPSIS

 generate_download_virus_databases_pipeline_makefile [options]
  -m     make file name
  -d     database (refseq|genbank)
  -t     taxa 
         refseq (archaea|bacteria|fungi|invertebrate|
           mitochondrion|plant|plasmid|protozoa|plastid|
           viral|vertebrate_mammalian|vertebrate_other)
         genbank (bct|vrl|phg|inv|pln|mam|vrt|pri|rod|)

=head1 DESCRIPTION

This script implements the pipeline for downloading virus database.

=cut

my $help;
my $database;
my $outputDir = "/home/cavs/db_download";
my $makeFile = "download_virus_databases_pipeline.mk";

#structure of reference databases
#/ref
#/ref/refseq
my $refSeqCurrentVersionOutputDir = "$outputDir/ref/refseq/";
                
#initialize options
Getopt::Long::Configure ('bundling');

if(!GetOptions ('h'=>\$help,
                'd=s'=>\$database,
                'm:s'=>\$makeFile
               )
  || !defined($makeFile))
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

printf("generate_download_virus_databases_pipeline_makefile.pl\n");
printf("\n");
printf("options: make file            %s\n", $makeFile);
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

###############################
#get current version of genbank 
###############################
unless (-e "$outputDir/prep_virus_files.OK")
{
    my $gbv = int(`curl ftp://ftp.ncbi.nlm.nih.gov/genbank/GB_Release_Number`);
    mkpath("$outputDir/genbank/$gbv/virus");   
    `curl ftp://ftp.ncbi.nlm.nih.gov/genbank/ --user ftp: > "$outputDir/genbank/$gbv/list.txt"`;
    `touch "$outputDir/prep_virus_files.OK"`;
}

if ($database wq "refseq")
{
    $version = `curl https://ftp.ncbi.nlm.nih.gov/refseq/release/RELEASE_NUMBER`;

    print $version;
}
elsif ($database wq "genbank")
{

}
else
{
    die "Database: $database not recognized";
}



exit;
#https://ftp.ncbi.nlm.nih.gov/refseq/release/RELEASE_NUMBER


#cat files.txt | grep seq | tr -s ' ' '\t' | cut -f 9 | grep vrl | sort -V

#################
#read file list 
################

#curl ftp://ftp.ncbi.nlm.nih.gov/genbank/ --user ftp: > files.list.txt







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
