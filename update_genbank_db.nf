#!/usr/bin/env nextflow

params.str = 'Hello world!'


process splitLetters {

    output:
    file 'chunk_*' into letters

    """
    printf '${params.str}' | split -b 6 - chunk_
    """
}
