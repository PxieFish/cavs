#!/usr/bin/env python

from Bio import SeqIO
import os

outfile = open("genbank_viruses.fa", "w")

for path in os.listdir("."):
	if path.startswith("gbvrl") and path.endswith(".seq.gz"):
		print path
		os.system("gunzip -c %s > test.gb" % path)
		for record in SeqIO.parse("test.gb", "genbank"):
			print record.description
			outfile.write(">%s %s\n%s\n" % (record.id, record.description, record.seq))

outfile.close()

os.unlink("test.gb")
