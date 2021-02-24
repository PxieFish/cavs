#!/usr/bin/env python

import os
import sys
import argparse
import subprocess
import string
import ConfigParser

# determine the actual directory of this script which will hold the data required for analysis
dirname = os.path.dirname(os.path.realpath(sys.argv[0]))

# get the configuration
config = ConfigParser.ConfigParser()
config.read(os.path.join(dirname, "VirusNgsWorkflow.conf"))

# update the settings with the configuration items
settings = dict(config.items("paths"))
settings.update(config.items("settings"))
settings["refseq_database"] = os.path.join(dirname, "refseq_viruses.fa")
settings["genbank_database"] = os.path.join(dirname, "genbank_viruses.fa")

# configure the command line parser
parser = argparse.ArgumentParser(description='NGS virus workflow')
parser.add_argument("-1", "--read1", action="store", type=str, help="Single end FASTQ file or the first pair", required=True)
parser.add_argument("-2", "--read2", action="store", type=str, help="Single end FASTQ file or the first pair", required=False)
parser.add_argument("-o", "--output", action="store", type=str, help="Output basename", required=True)
opt = parser.parse_args()

settings["output"] = opt.output
settings["read1"] = opt.read1
settings["read2"] = opt.read2

print settings

# check that the files exists
if not os.path.exists(opt.read1):
	print "Read 1 file %s does not exists" % opt.read1
	sys.exit(1)
if opt.read2 != None and not os.path.exists(opt.read2):
	print "Read 2 file %s does not exists" % opt.read2
	sys.exit(1)

# symlink the fastq files
if os.path.lexists("%(output)s_r1.fastq.gz" % settings):
	os.unlink("%(output)s_r1.fastq.gz" % settings)
os.system("ln -s %(read1)s %(output)s_r1.fastq.gz" % settings)
if opt.read2 != None:
	if os.path.lexists("%(output)s_r2.fastq.gz" % settings):
		os.unlink("%(output)s_r2.fastq.gz" % settings)
	os.system("ln -s %(read2)s %(output)s_r2.fastq.gz" % settings)

# run fastqc first
os.system("%(fastqc)s %(output)s_r1.fastq.gz" % settings)
if opt.read2 != None:
	os.system("%(fastqc)s %(output)s_r2.fastq.gz" % settings)

# gunzip the fastq files for trinity
os.system("gunzip -c %(output)s_r1.fastq.gz > %(output)s_r1.fq" % settings)
if opt.read2 != None:
	os.system("gunzip -c %(output)s_r2.fastq.gz > %(output)s_r2.fq" % settings)

# run the Trinity assembler
if opt.read2 != None:
	os.system("%(trinity)s --seqType fq --left %(output)s_r1.fq --right %(output)s_r2.fq --CPU %(cpu)s --max_memory %(memory)s --output %(output)s_trinity" % settings)
else:
	os.system("%(trinity)s --seqType fq --single %(output)s_r1.fq --CPU %(cpu)s --max_memory %(memory)s --output %(output)s_trinity" % settings)

# remove the fastq files
os.unlink("%(output)s_r1.fq" % settings)
if opt.read2 != None:
	os.unlink("%(output)s_r2.fq" % settings)

# create the bowtie2 indexes for the search
os.system("%(bowtie2-build)s %(output)s_trinity/Trinity.fasta %(output)s_trinity_bowtie2_index" % settings)

# align the reads to the assembly
if opt.read2 != None:
	os.system("%(bowtie2)s -x %(output)s_trinity_bowtie2_index -1 %(output)s_r1.fastq.gz -2 %(output)s_r2.fastq.gz -S %(output)s_trinity_alignment.sam" % settings)
else:
	os.system("%(bowtie2)s -x %(output)s_trinity_bowtie2_index -U %(output)s_r1.fastq.gz -S %(output)s_trinity_alignment.sam" % settings)

# convert to BAM
os.system("%(samtools)s view -b %(output)s_trinity_alignment.sam | %(samtools)s sort -O bam -T tmp - > %(output)s_trinity_alignment.bam" % settings)
os.system("%(samtools)s index %(output)s_trinity_alignment.bam" % settings)

# remove the SAM file
os.unlink("%(output)s_trinity_alignment.sam" % settings)

# blat against the refseq virus sequences
os.system("%(blat)s %(refseq_database)s %(output)s_trinity/Trinity.fasta %(output)s_refseq_alignments.psl" % settings)

# blat against the genbank virus sequences
os.system("%(blat)s %(genbank_database)s %(output)s_trinity/Trinity.fasta %(output)s_genbank_alignments.psl" % settings)

# prepare the report

# get the number of reads from the samtools
lines = subprocess.check_output([settings["samtools"], "flagstat", "%s_trinity_alignment.bam" % opt.output]).split("\n")
total_reads = int(lines[0].split(" ")[0])

# get the contigs and the reads mapped to it
contigs = {}
lines = subprocess.check_output([settings["samtools"], "idxstats", "%s_trinity_alignment.bam" % opt.output]).split("\n")
for line in lines:
	if line != "":
		fields = line.split("\t")
		if fields[0] != "*":
			contigs[fields[0]] = {
				"contig" : fields[0],
				"length" : int(fields[1]),
				"mapped_reads" : int(fields[2]),
				}
mapped_reads = sum(map(lambda x: contigs[x]["mapped_reads"], contigs.keys()))

def alignmentSortFunc(a, b):
	if a["matches"] > b["matches"]:
		return -1
	elif a["matches"] < b["matches"]:
		return 1
	else:
		if a["mismatches"] <= b["mismatches"]:
			return -1
		else:
			return 1

# refseq alignment results
refseqAlignments = {}
infile = open("%s_refseq_alignments.psl" % opt.output)
for line in infile:
	line = line.strip()
	if line != "" and line[0].isdigit():
		fields = line.split("\t")
		aln = {
			"contig" : fields[9],
			"contig_start" : int(fields[11])+1,
			"contig_end" : int(fields[12])+1,
			"matches" : int(fields[0]),
			"mismatches" : int(fields[1]),
			"hit" : fields[13],
			"hit_length" : int(fields[14]),
			"hit_start" : int(fields[15])+1,
			"hit_end" : int(fields[16])+1,
			}
		if not refseqAlignments.has_key(aln["contig"]):
			refseqAlignments[aln["contig"]] = []
		refseqAlignments[aln["contig"]].append(aln)
# sort the alignments
for key in refseqAlignments.keys():
	refseqAlignments[key].sort(alignmentSortFunc)
	refseqAlignments[key] = refseqAlignments[key][0]

# genbank alignment results
genbankAlignments = {}
infile = open("%s_genbank_alignments.psl" % opt.output)
for line in infile:
	line = line.strip()
	if line != "" and line[0].isdigit():
		fields = line.split("\t")
		aln = {
			"contig" : fields[9],
			"contig_start" : int(fields[11])+1,
			"contig_end" : int(fields[12])+1,
			"matches" : int(fields[0]),
			"mismatches" : int(fields[1]),
			"hit" : fields[13],
			"hit_length" : int(fields[14]),
			"hit_start" : int(fields[15])+1,
			"hit_end" : int(fields[16])+1,
			}
		if not genbankAlignments.has_key(aln["contig"]):
			genbankAlignments[aln["contig"]] = []
		genbankAlignments[aln["contig"]].append(aln)
# sort the alignments
for key in genbankAlignments.keys():
	genbankAlignments[key].sort(alignmentSortFunc)
	genbankAlignments[key] = genbankAlignments[key][0]

# read the refseq name mapping
refseqs = {}
infile = open(os.path.join(dirname, "refseq_viruses.txt"))
for line in infile:
	line = line.strip()
	if line != "":
		fields = line.split("\t")
		refseqs[fields[0]] = fields[1]

# read the genbank name mapping
genbanks = {}
infile = open(os.path.join(dirname, "genbank_viruses.txt"))
for line in infile:
	line = line.strip()
	if line != "":
		fields = line.split("\t")
		genbanks[fields[0]] = fields[1]

for contig in contigs.keys():
	if refseqAlignments.has_key(contig):
		contigs[contig]["refseq_hit"] = refseqAlignments[contig]["hit"]
		contigs[contig]["refseq_name"] = refseqs[refseqAlignments[contig]["hit"]]
		contigs[contig]["refseq_hit_length"] = refseqAlignments[contig]["hit_length"]
		contigs[contig]["refseq_contig_start"] = refseqAlignments[contig]["contig_start"]
		contigs[contig]["refseq_contig_end"] = refseqAlignments[contig]["contig_end"]
		contigs[contig]["refseq_hit_start"] = refseqAlignments[contig]["hit_start"]
		contigs[contig]["refseq_hit_end"] = refseqAlignments[contig]["hit_end"]
		contigs[contig]["refseq_hit_matches"] = refseqAlignments[contig]["matches"]
		contigs[contig]["refseq_hit_mismatches"] = refseqAlignments[contig]["mismatches"]
		contigs[contig]["refseq_hit_identity"] = float(refseqAlignments[contig]["matches"]) / contigs[contig]["length"] * 100
	if genbankAlignments.has_key(contig):
		contigs[contig]["genbank_hit"] = genbankAlignments[contig]["hit"]
		contigs[contig]["genbank_name"] = genbanks[genbankAlignments[contig]["hit"]]
		contigs[contig]["genbank_hit_length"] = genbankAlignments[contig]["hit_length"]
		contigs[contig]["genbank_contig_start"] = genbankAlignments[contig]["contig_start"]
		contigs[contig]["genbank_contig_end"] = genbankAlignments[contig]["contig_end"]
		contigs[contig]["genbank_hit_start"] = genbankAlignments[contig]["hit_start"]
		contigs[contig]["genbank_hit_end"] = genbankAlignments[contig]["hit_end"]
		contigs[contig]["genbank_hit_matches"] = genbankAlignments[contig]["matches"]
		contigs[contig]["genbank_hit_mismatches"] = genbankAlignments[contig]["mismatches"]
		contigs[contig]["genbank_hit_identity"] = float(genbankAlignments[contig]["matches"]) / contigs[contig]["length"] * 100
	contigs[contig]["mapped_reads_percentage"] = float(contigs[contig]["mapped_reads"]) / total_reads * 100

# write out the results
outfile = open("%s_results.txt" % opt.output, "w")
headers = ("contig", "length", "mapped_reads", "mapped_reads_percentage", "refseq_hit", "refseq_name", "refseq_hit_length", "refseq_hit_identity", "refseq_hit_matches", "refseq_hit_mismatches", "refseq_contig_start", "refseq_contig_end", "refseq_hit_start", "refseq_hit_end", "genbank_hit", "genbank_name", "genbank_hit_length", "genbank_hit_identity", "genbank_hit_matches", "genbank_hit_mismatches", "genbank_contig_start", "genbank_contig_end", "genbank_hit_start", "genbank_hit_end")
outfile.write(string.join(headers, "\t") + "\n")
keys = contigs.keys()
keys.sort(lambda a, b: -cmp(contigs[a]["mapped_reads"], contigs[b]["mapped_reads"]))
for key in keys:
	outfile.write(string.join(map(str, map(lambda x: contigs[key].has_key(x) and contigs[key][x] or "", headers)), "\t") + "\n")
outfile.close()
