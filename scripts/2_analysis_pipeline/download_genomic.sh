#!/bin/bash

for acc in /banques/EvoDrivers/assemblies/*;
do
    wget -q -i /banques/EvoDrivers/assemblies/"$(basename '$acc')"/url_genomic.fna.txt -O /banques/EvoDrivers/assemblies/"$(basename '$acc')"/genomic.fna.gz
done