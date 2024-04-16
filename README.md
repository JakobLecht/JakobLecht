In order to run the pipeline snakemake must be installed: https://snakemake.readthedocs.io/en/stable/getting_started/installation.html

copy the file environment.yaml in the working directory:

Afterwards, create an environment using 

mamba env create --name hic --file environment.yaml

activate the environment with "conda activate hic"

Copy the snakefile, config.yaml and scripts into your working directory and make sure to edit the config.yaml according to your data

