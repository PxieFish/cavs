/* The MIT License
   Copyright (c) 2021 Adrian Tan <adriantks@gmail.com>
   Permission is hereby granted, free of charge, to any person obtaining a copy
   of this software and associated documentation files (the "Software"), to deal
   in the Software without restriction, including without limitation the rights
   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
   copies of the Software, and to permit persons to whom the Software is
   furnished to do so, subject to the following conditions:
   The above copyright notice and this permission notice shall be included in
   all copies or substantial portions of the Software.
   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
   THE SOFTWARE.
*/
#!/usr/bin/env python3

import argparse
import subprocess
import os

parser = argparse.ArgumentParser(description='Generates a pipeline for downloading virus data from GenBank.')
parser.add_argument('integers', metavar='N', type=int, nargs='+',
                    help='an integer for the accumulator')
parser.add_argument('--sum', dest='accumulate', action='store_const',
                    const=sum, default=max,
                    help='sum the integers (default: find the max)')

args = parser.parse_args()
print(args.accumulate(args.integers))
    
 
#get genbank current release version
result = subprocess.run("curl ftp://ftp.ncbi.nlm.nih.gov/genbank/GB_Release_Number --user ftp:".split(), stdout = subprocess.PIPE, stderr = subprocess.STDOUT)
if results.returncode == 0:


type(int(result.stdout.decode("utf-8").split("\n")[3]))
result.returncode

#download to /data/ref/virus/genbank/<release_version>

#if all done. no need to download


#
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



# get files from 

#make temporary directory

#out = subprocess.run(["cat", "/home/cavs/demofile3.txt"], capture_output=True)
#print("program output:", out)


#create temporary files directory


#download files to temporary directoy
#curl ftp://ftp.ncbi.nlm.nih.gov/genbank/ --user ftp: > files.list.txt

	
def run(cmd):
    os.environ['PYTHONUNBUFFERED'] = "1"
    proc = subprocess.Popen(cmd,
        stdout = subprocess.PIPE,
        stderr = subprocess.STDOUT,
    )
    stdout, stderr = proc.communicate()
 
    return proc.returncode, stdout, stderr
 
code, out, err = run("curl ftp://ftp.ncbi.nlm.nih.gov/genbank/GB_Release_Number --user ftp:".split())


result = subprocess.run("curl ftp://ftp.ncbi.nlm.nih.gov/genbank/GB_Release_Number --user ftp:".split(), stdout = subprocess.PIPE, stderr = subprocess.STDOUT)
type(int(result.stdout.decode("utf-8").split("\n")[3]))
result.returncode

 
print("out: '{}'".format(out))
print("err: '{}'".format(err))
print("exit: {}".format(code))
 
print(out.split("\n")[1]) 
#print("GB version: '{}'".format(out.split("\n")[1]))
	
#out = subprocess.run(["curl", "ftp://ftp.ncbi.nlm.nih.gov/genbank/", "--user", "ftp:"], capture_output=True)
#print("program output:", out)


#def execute() :
	

#curl ftp://ftp.ncbi.nlm.nih.gov/genbank/ --user ftp: > files.list.txt
#cat files.list.txt   | grep -P "gbvrl\d+.seq.gz"  | grep gbvrl1.seq.gz
#wget ftp://ftp.ncbi.nlm.nih.gov/genbank/gbvrl1.seq.gz


#f = open("demofile3.txt", "w")
#f.write("Woops! I have deleted the content!")
#f.close()