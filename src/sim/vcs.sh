rm -rfv `ls |grep -v ".*\.sv\|.*\.sh"`;
vcs -Mupdate test_bench.sv  -o salida -full64 -debug_all -kdb -sverilog -l log_test +lint=TFIPC-L;
