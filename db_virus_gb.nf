//params.queries = ""
//queries = Channel.fromPath(params.queries) #path to multiple .fasta files
//
//process PsiBlast {
//
//    input:
//    file query from queries_psiblast
//    
//    output:
//    file top_hits
//    
//    """
//    blastpgp -d $db -i $query -j 2 -C ff.chd.ckp -Q pssm.out >> top_hits
//    """
//}

//#then there are others processes, not needed for my question. 


params.queries = "gbvrl1.seq.gz gbvrl2.seq.gz gbvrl3.seq.gz"
queries = params.queries

process PsiBlast {

    input:
    file query from queries
    
//    output:
//    file top_hits
 
//    wget ftp://ftp.ncbi.nlm.nih.gov/genbank/$
   
    """
    echo $query
    """
}
