#!usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

PAIRSAM=$1
OUTPREFIX=$2
CHR_SIZES=$3

UNMAPPED_SAMPAIRS=${OUTPREFIX}.unmapped.sam.pairs.gz
NODUP_PAIRS=${OUTPREFIX}.nodup.pairs.gz
LOSSLESS_BAM=${OUTPREFIX}.lossless.bam
TEMPFILE=TEMP.gz
TEMPFILE1=TEMP1.gz

pairtools split --output-sam ${LOSSLESS_BAM} ${PAIRSAM}

pairtools select '(pair_type == "UU") or (pair_type == "UR") or (pair_type == "RU")' --output-rest ${UNMAPPED_SAMPAIRS} --output ${TEMPFILE} ${PAIRSAM}

pairtools split --output-pairs ${TEMPFILE1} ${TEMPFILE}

pairtools select 'True' --chrom-subset ${CHR_SIZES} --output ${NODUP_PAIRS} ${TEMPFILE}

pairix ${NODUP_PAIRS} 
