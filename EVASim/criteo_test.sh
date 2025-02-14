#!/bin/bash
# Original code: https://github.com/rishucoding/reproduce_MICRO24_GPU_DLRM_inference

### outdir ### 
# OUT="results_ed_r_nt_lk_nb_bs"
OUT="results_test"
mkdir -p $OUT
##############

### dataset ###
data_path_dir="$(pwd)/datasets/"
# dataset_list=("dlrm/reuse_high_table_1M.txt" "dlrm/reuse_medium_table_1M.txt" "dlrm/reuse_low_table_1M.txt")
dataset_list=("criteo/day_5.txt")
###############

### simulation parameters ###
MEM_CFG=$1 # spad_naive
EMB_DIM=256
EMB_ROW=40000000
EMB_TBL=26 # 512
EMB_POOL=1
EMBS="$EMB_DIM,$EMB_ROW,$EMB_TBL,$EMB_POOL"

NUM_BATCH=2
BS=2048
##############################

### others ###
PyGenTbl='import sys; rows,tables=sys.argv[1:3]; print("-".join([rows]*int(tables)))'
OUTDIR="$(echo "$EMBS" | sed 's/,/_/g')"
echo $OUTDIR
OUTDIR="${OUT}/${OUTDIR}_${NUM_BATCH}_${BS}"
echo $OUTDIR
mkdir -p $OUTDIR
##############

for dataset in "${dataset_list[@]}"; do
    DATA_GEN_PATH=$data_path_dir$dataset
    OUTFILE=$(echo "$dataset" | sed 's/\//_/g')
    OUTFILE="$OUTDIR/$OUTFILE"
    for e in $EMBS; do
        IFS=','; set -- $e; EMB_DIM=$1; EMB_ROW=$2; EMB_TBL=$3; EMB_LS=$4; unset IFS;
        EMB_TBL=$(python3 -c "$PyGenTbl" "$EMB_ROW" "$EMB_TBL")
        python3 src/simulator.py --num-batches $NUM_BATCH --batch-size $BS --numeric-format-bits "8" \
            --lookups-per-sample $EMB_LS --arch-sparse-feature-size $EMB_DIM\
            --arch-embedding-size $EMB_TBL --data-generation=$DATA_GEN_PATH --memory-config=$MEM_CFG | tee $(pwd)/${OUTFILE}_${MEM_CFG}.log
    done
done
