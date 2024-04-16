
configfile: "config.yaml"
print("Config is:", config)

# Define global variables
DATA_FILES = config["data"]
GENOME = config["genome"]

# Rule for all targets
rule all:
   input:
	expand("mapped_reads/{file}.bam", file=DATA_FILES),
        expand("mapped_reads/sorted/{file}.sam.pairs.gz", file=DATA_FILES),
        "mapped_reads/sorted/merged_reads/merged.sam.pairs.gz",
        "mapped_reads/sorted/merged_reads/dupmarked/dupmarked.sam.pairs.gz",
        "nodupreads/final.nodup.pairs.gz",
        "nodupreads/final.unmapped.sam.pairs.gz",
        "nodupreads/final.lossless.bam",
	"nodupreads/final.nodup.pairs.gz.px2",
        expand("index/{genome}.chromSizes", genome=GENOME),
        expand("index/{genome}.fasta.gz{index}", genome=GENOME, index=[".amb", ".ann", ".bwt", ".pac", ".sa"]),
        expand("index/{genome}.fasta.gz", genome=GENOME)


# Rule to create BWA index
rule make_index:
    input:
        genome="index/{genome}.fasta.gz"
    output:
        index=multiext("index/{genome}.fasta.gz", ".amb", ".ann", ".bwt", ".pac", ".sa")
    shell:
        "bwa index {input.genome}"

# Rule to create chromosome size file
rule make_chromsize:
    input:
        genome=expand("index/{genome}.fasta.gz", genome=GENOME)
    output:
        chrsize="index/{genome}.chromSizes"
    shell:
        "perl index/chromSizes.pl {input.genome} > {output.chrsize}"

# Rule for BWA mapping
rule bwa_map:
    input:
        index=expand("index/{genome}.fasta.gz", genome=GENOME),
        index_files=expand("index/{genome}.fasta.gz{index}", genome=GENOME, index=[".amb", ".ann", ".bwt", ".pac", ".sa"]),
        reads=lambda wildcards: expand("../data/{file}_{read}_001.fastq.gz", file=wildcards.file, read=["R1", "R2"])
    output:
        "mapped_reads/{file}.bam"
    threads: 64
    shell:
        "bwa mem -t {threads} -SP5M {input.index} {input.reads} | samtools view -Shb - > {output}"

# Rule for filtering mapped reads
rule mapped_reads_filter:
    input:
        mapped_reads="mapped_reads/{file}.bam", 
        chrsizes=expand("index/{genome}.chromSizes", genome=GENOME),
    params:
        outdir="{file}",
        logfile="logfiles/{file}.pairsam-parse-sort.log"
    output:
        sorted_reads="mapped_reads/sorted/{file}.sam.pairs.gz",
    threads: 64
    shell:
        "bash run-pairsam-parse-sort.sh {input.mapped_reads} {input.chrsizes} mapped_reads/sorted/ {params.outdir} {threads} lz4c &> {params.logfile}"

# Rule for merging pairsam files
rule pairsam_merge:
    input:
        sorted_reads=expand("mapped_reads/sorted/{file}.sam.pairs.gz", file=DATA_FILES)
    params:
        logfile="logfiles/pairsam-merge.log"
    output:
        merged_reads="mapped_reads/sorted/merged_reads/merged.sam.pairs.gz"
    shell:
        "pairtools merge --output {output.merged_reads} {input.sorted_reads} &> {params.logfile}"

# Rule for deduplicating pairsam files
rule dedup:
    input:
        merged="mapped_reads/sorted/merged_reads/merged.sam.pairs.gz"
    output:
        dupmarked="mapped_reads/sorted/merged_reads/dupmarked/dupmarked.sam.pairs.gz",
        logfile="logfiles/dupmarked.log",
	stats="logfiles/dupmarked.stats.txt"
    threads: 64
    shell:
        "pairtools dedup --output-stats {output.stats} --mark-dups -o {output.dupmarked} {input.merged} &> {output.logfile}"

# Rule for selecting pairs
rule selectpairs:
    input:
        dupmark="mapped_reads/sorted/merged_reads/dupmarked/dupmarked.sam.pairs.gz",
        chrsizes=expand("index/{genome}.chromSizes", genome=GENOME)
    output:
        nodup="nodupreads/final.nodup.pairs.gz",
        unmappedreads="nodupreads/final.unmapped.sam.pairs.gz",
        lossless_bam="nodupreads/final.lossless.bam",
	pairix="nodupreads/final.nodup.pairs.gz.px2"
    params:
        outdir="nodupreads/final",
        logfile="logfiles/final.nodup.log"
    threads: 64
    shell:
        "bash run-pairsam-select.sh {input.dupmark} {params.outdir} {input.chrsizes} {threads} &> {params.logfile}"
