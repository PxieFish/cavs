#!/usr/bin/env python3

import argparse
import subprocess
import os

parser = argparse.ArgumentParser(description='Generates a pipeine for downloading viral sequences from GenBank and RefSeq.')
#parser.add_argument('integers', metavar='N', type=int, nargs='+',
  #                  help='an integer for the accumulator')
#parser.add_argument('--sum', dest='accumulate', action='store_const',
 #                   const=sum, default=max,
 #                   help='sum the integers (default: find the max)')

args = parser.parse_args()
#print(args.accumulate(args.integers))

#get genbank version number
print("Getting version number from genbank ... ", flush=True ,end=" ")
#result = subprocess.check_output("curl ftp://ftp.ncbi.nlm.nih.gov/genbank/GB_Release_Number --user ftp:".split(), 
#                                 stderr = subprocess.DEVNULL)
result = 242
print(int(result))

#create directories
path = "data/ref/virus/genbank/" + str(int(result))
if not os.path.exists(path):
    print("Creating directory ...  ", path)
    try:
        os.makedirs(path)
    except OSError:
        print("Creation of %s failed" % path)
    else:
        print("Creation of %s successful" % path)
else:
    print(path, "exists")  

def run(cmd):
    os.environ['PYTHONUNBUFFERED'] = "1"
    proc = subprocess.Popen(cmd,
        stdout = subprocess.PIPE,
        stderr = subprocess.STDOUT,
    )
    stdout, stderr = proc.communicate()
 
    return proc.returncode, stdout, stderr
 
#code, out, err = run("curl ftp://ftp.ncbi.nlm.nih.gov/genbank/GB_Release_Number --user ftp:".split())


#result = subprocess.run("curl ftp://ftp.ncbi.nlm.nih.gov/genbank/GB_Release_Number --user ftp:".split(), stdout = subprocess.PIPE, stderr = subprocess.STDOUT)
#type(int(result.stdout.decode("utf-8").split("\n")[3]))
#result.returncode

 
#print("out: '{}'".format(out))
#print("err: '{}'".format(err))
#print("exit: {}".format(code))
# 
#print(out.split("\n")[1]) 
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