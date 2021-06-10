#!/bin/bash

mkdir -p compiled images

for i in sources/*.txt tests/*.txt; do
	echo "Compiling: $i"
    fstcompile --isymbols=syms.txt --osymbols=syms.txt $i | fstarcsort > compiled/$(basename $i ".txt").fst
done


echo "Generating text2num.fst"
fstconcat compiled/horas.fst compiled/lig.fst > compiled/horas+lig.fst
fstconcat compiled/horas+lig.fst compiled/minutos.fst > compiled/text2num.fst

echo "Generating lazy2num.fst"
fstconcat compiled/horas.fst compiled/zeromin.fst > compiled/horas+zeromin.fst
fstunion compiled/text2num.fst compiled/horas+zeromin.fst > compiled/lazy2num.fst

echo "Generating rich2text.fst"
fstproject --project_type=input compiled/horas.fst > compiled/horast.fst
fstproject --project_type=input compiled/lig.fst > compiled/ligt.fst
fstconcat compiled/horast.fst compiled/ligt.fst > compiled/horast+ligt.fst
fstconcat compiled/horast+ligt.fst compiled/quartos.fst > compiled/horast+ligt+qtos.fst
fstconcat compiled/horast+ligt.fst compiled/meias.fst > compiled/horast+ligt+meias.fst
fstunion compiled/horast+ligt+qtos.fst compiled/horast+ligt+meias.fst > compiled/rich2text.fst

echo "Generating rich2num.fst"
fstcompose compiled/rich2text.fst compiled/text2num.fst > compiled/rich2num.fst

echo "Generating num2text.fst"
fstinvert compiled/text2num.fst > compiled/num2text.fst


for i in compiled/*.fst; do
	echo "Creating image: images/$(basename $i '.fst').pdf"
    fstdraw --portrait --isymbols=syms.txt --osymbols=syms.txt $i | dot -Tpdf > images/$(basename $i '.fst').pdf
done

for i in tests/*A*; do
    echo "Testing the transducer 'rich2num' with the input '${i}'"
    fstcompose compiled/$(basename $i '.txt').fst compiled/rich2num.fst | fstshortestpath | fstproject --project_type=output | fstrmepsilon | fsttopsort | fstprint --acceptor --isymbols=./syms.txt
done

for i in tests/*B*; do
    echo "Testing the transducer 'num2text' with the input '${i}'"
    fstcompose compiled/$(basename $i '.txt').fst compiled/num2text.fst | fstshortestpath | fstproject --project_type=output | fstrmepsilon | fsttopsort | fstprint --acceptor --isymbols=./syms.txt
done
