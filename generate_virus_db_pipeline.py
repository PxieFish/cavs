#!/usr/bin/env python3

import argparse
import subprocess

parser = argparse.ArgumentParser(description='Generates a pipeine for downloading data from GenBank and RefSeq.')
parser.add_argument('integers', metavar='N', type=int, nargs='+',
                    help='an integer for the accumulator')
parser.add_argument('--sum', dest='accumulate', action='store_const',
                    const=sum, default=max,
                    help='sum the integers (default: find the max)')

args = parser.parse_args()
print(args.accumulate(args.integers))

# get files from 

#make temporary directory

#out = subprocess.run(["cat", "/home/cavs/demofile3.txt"], capture_output=True)
#print("program output:", out)

#download files to temporary directoy
#curl ftp://ftp.ncbi.nlm.nih.gov/genbank/ --user ftp: > files.list.txt

#get 


out = subprocess.run(["curl", "ftp://ftp.ncbi.nlm.nih.gov/genbank/", "--user", "ftp:"], capture_output=True)
print("program output:", out)


def execute() :
	

#curl ftp://ftp.ncbi.nlm.nih.gov/genbank/ --user ftp: > files.list.txt
#cat files.list.txt   | grep -P "gbvrl\d+.seq.gz"  | grep gbvrl1.seq.gz
#wget ftp://ftp.ncbi.nlm.nih.gov/genbank/gbvrl1.seq.gz


#f = open("demofile3.txt", "w")
#f.write("Woops! I have deleted the content!")
#f.close()