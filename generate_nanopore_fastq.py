#Brief workflow for Nanopore data analysis 
#
#Workflow 1
#Basecalling using Guppy (to convert FAST5 file to FASTQ file) → Debarcode the samples using Guppy  → Map the reads to all viruses in GenBank using minimap2 → Extract the reads which map to targeted virus genome  → assemble the reads into contigs using Canu →  Select the best contig by number of mapped reads used for assembly (if there are multiple to represent the segment) → Map the complete sample reads to the new assembled best contigs to determine read mapping percentages as well as coverage to the assembled contigs
#Workflow 2
#Basecalling using Guppy (to convert FAST5 file to FASTQ file) → Debarcode the samples using Guppy  → Genome Detective using Fastq files
#Basecalling by Guppy
#
#Guppy codes
#
#Bernet’s codes: 
#
#
#Nanopore community:
#guppy_basecaller --input_path /data/my_folder/reads --save_path /data/output_folder/basecall --flowcell FLO-MIN106 --kit SQK-LSK109
#
#Test Guppy run of AHSV FAST5 data run on 16 April 2020
#guppy_basecaller -i /var/lib/MinKNOW/data/20200416/AHSV-Bento/20200416_0647_MN29953_FAL08047_5aa03c6b -r -s OUTPUT/var/lib/Minknow/data/20200416 --flowcell FLO-MIN106 --kit SQK-LSK109 --num_callers 12 --cpu_threads_per_caller 2
#Notes: FAST5 files are located at /var/lib/MinKNOW/data/20200416/AHSV-Bento/20200416_0647_MN29953_FAL08047_5aa03c6b 
#OUTPUT files are at Home/OUTPUT
#Highlighted part is not necessary
#
#Demultiplexing by Guppy
#
#Bernet’s codes: 
#guppy_barcoder -i OUTPUT_DIR -s OUTPUT_DEBARCODE_DIR --barcode_kits BARCODE_KIT -t 12
#Nanopore community:
#guppy_barcoder --input_path <folder containing FASTQ files> --save_path <output folder> --config configuration.cfg --barcode_kits EXP-NBD104
#Test debarcode run of 28 FASTQ files on 15 May 2020
#guppy_barcoder -i OUTPUT -s OUTPUT3 --barcode_kits EXP-NBD104 -t 12
#Notes: Output file is at HOME/OUTPUT3; FastQ files are at Home/OUTPUT
#Barcode 01, 02, 03 are seperated.  
#
#Combine FastQ files into one file
#
#
#Transfe the above scripts to the demultiplexed folder
#Open Terminal at this folder
#Type Code: dos2unix concatAndBGzipNanoporeDeBarcodedFastqFiles.sh
#Type Code: bash concatAndBGzipNanoporeDeBarcodedFastqFiles.sh
#A combind Fastq file will be generated in this folder
#
#Fastq file can be uploaded to Genome Detective Virus Tool for analysis (www.genomedetective.com)
#
#
ONT calling

nohup /usr/local/ont-guppy-cpu/bin/guppy_basecaller -i /data/ngs/ONT11/fast5 -r -s /home/cavs/20200226_nanopore_fastq_generation/gbc_output --flowcell FLO-MIN106 --kit SQK-LSK109 --num_callers 4 --cpu_threads_per_caller 2 > gbc.log 2> gbc.err &

nohup /usr/local/ont-guppy-cpu/bin/guppy_barcoder -i gbc_output -s guppy_barcoder_output --barcode_kits EXP-NBD104 -t 8 > guppy_barcoder.log 2> guppy_barcoder.err &


#!/bin/sh

for i in barcode*
do
	if [ -d $i ]
	then
		sample=${i/barcode/}
		echo "Processing barcode directory ${i} for sample ${sample}"
		cat "${i}/"*.fastq > "B${sample}.fastq"
		bgzip -f "B${sample}.fastq"
	fi
done
