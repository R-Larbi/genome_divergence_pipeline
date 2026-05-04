#!/bin/csh -e


if ($4 == "") then
   echo  " "
   echo "$0 : lance Aln_dNdS.csh sur chaque lignes d'un fichier"
   echo "Usage: $0 infile BLASTDB genetic_code outfile"
   exit
endif

set BLASTDB = $2
set pairing = $3
set genetic_code_1 = $4
set genetic_code_2 = $5
set outfile = $6
#set path_script = "./scripts/4_seaview_analysis/csh/Aln_dNdS.csh"
set path_script = "../genome_divergence_pipeline/scripts/4_seaview_analysis/csh/Aln_dNdS.csh"

set buf = `wc -l $1 `

set nb_line = $buf[1]

echo "Fichier $1 : $nb_line lignes a traiter."

set num = 0

echo "SeqA SeqB Ka Ks" > $outfile


while($num < $nb_line)

@ num = $num + 1

set buf = `head -$num $1 | tail -1`


echo ""
echo "##################################"
echo $num $buf

csh $path_script $buf $BLASTDB $genetic_code_1 $genetic_code_2 "$pairing"_tmp_KaKs
cat "$pairing"_tmp_KaKs >> $outfile
\rm "$pairing"_tmp_KaKs

end


exit


