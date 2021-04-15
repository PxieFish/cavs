#!/usr/bin/env nextflow


Channel
    .from( 'a', 'b', 'aa', 'bc', 3, 4.5 )
    .filter( ~/^a.*/ )
    .view()
    
Channel
    .from( [1,[2,3]], 4, [5,[6]] )
    .flatten()
    .view()    

//Channel
//    .from( [1,[2,3]], 4, [5,[6]] )
//    .view()        