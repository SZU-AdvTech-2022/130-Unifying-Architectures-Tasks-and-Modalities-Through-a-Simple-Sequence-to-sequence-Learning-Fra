#!/usr/bin/env

# The port for communication. Note that if you want to run multiple tasks on the same machine,
# you need to specify different port numbers.

log_dir=./stage1_logs
save_dir=./stage1_checkpoints
mkdir -p $log_dir $save_dir

bpe_dir=../../utils/BPE
user_dir=../../ofa_module

data_dir=../../dataset/wizviz
data=${data_dir}/annotations/train_wizviz.tsv,${data_dir}/annotations/val_wizviz.tsv
restore_file=./stage1_checkpoints/3_0.06_2500/checkpoint_best.pt
selected_cols=0,2,1

task=caption
arch=ofa_base
criterion=adjust_label_smoothed_cross_entropy
label_smoothing=0.1
lr=1e-5
max_epoch=2
warmup_ratio=0.06
batch_size=8
update_freq=4
resnet_drop_path_rate=0.0
encoder_drop_path_rate=0.1
decoder_drop_path_rate=0.1
dropout=0.1
attention_dropout=0.0
max_src_length=80
max_tgt_length=20
num_bins=1000
patch_image_size=480
eval_cider_cached=../../dataset/caption_data/cider_cached_tokens/coco-valid-words.p
tsb_logdir=./tsb
drop_worst_ratio=0.2
echo "max_epoch "${max_epoch}
warmup_ratio=0.06
echo "warmup_ratio "${warmup_ratio}
drop_worst_after=2500
echo "drop_worst_after "${drop_worst_after}
log_file=${log_dir}/${max_epoch}"_"${warmup_ratio}"_"${drop_worst_after}".log"
save_path=${save_dir}/${max_epoch}"_"${warmup_ratio}"_"${drop_worst_after}
mkdir -p $save_path
CUDA_VISIBLE_DEVICES=0 python  ../../train.py \
    $data \
    --selected-cols=${selected_cols} \
    --bpe-dir=${bpe_dir} \
    --user-dir=${user_dir} \
    --restore-file=${restore_file} \
    --reset-optimizer --reset-dataloader --reset-meters \
    --save-dir=${save_path} \
    --task=${task} \
    --arch=${arch} \
    --criterion=${criterion} \
    --label-smoothing=${label_smoothing} \
    --batch-size=${batch_size} \
    --update-freq=${update_freq} \
    --encoder-normalize-before \
    --decoder-normalize-before \
    --share-decoder-input-output-embed \
    --share-all-embeddings \
    --layernorm-embedding \
    --patch-layernorm-embedding \
    --code-layernorm-embedding \
    --resnet-drop-path-rate=${resnet_drop_path_rate} \
    --encoder-drop-path-rate=${encoder_drop_path_rate} \
    --decoder-drop-path-rate=${decoder_drop_path_rate} \
    --dropout=${dropout} \
    --attention-dropout=${attention_dropout} \
    --weight-decay=0.01 --optimizer=adam --adam-betas="(0.9,0.999)" --adam-eps=1e-08 --clip-norm=1.0 \
    --lr-scheduler=polynomial_decay --lr=${lr} \
    --max-epoch=${max_epoch} --warmup-ratio=${warmup_ratio} \
    --tensorboard-logdir=${tsb_logdir}\
    --log-format=simple --log-interval=10 \
    --fixed-validation-seed=7 \
    --no-epoch-checkpoints --keep-best-checkpoints=1 \
    --save-interval=1 --validate-interval=1 \
    --save-interval-updates=1000 --validate-interval-updates=1000 \
    --eval-bleu \
    --eval-args='{"beam":5,"max_len_b":16,"no_repeat_ngram_size":3}' \
    --best-checkpoint-metric=bleu --maximize-best-checkpoint-metric \
    --max-src-length=${max_src_length} \
    --max-tgt-length=${max_tgt_length} \
    --find-unused-parameters \
    --freeze-encoder-embedding \
    --freeze-decoder-embedding \
    --add-type-embedding \
    --scale-attn \
    --scale-fc \
    --scale-heads \
    --disable-entangle \
    --num-bins=${num_bins} \
    --patch-image-size=${patch_image_size} \
    --drop-worst-ratio=${drop_worst_ratio} \
    --drop-worst-after=${drop_worst_after} \
    --fp16 \
    --fp16-scale-window=512 \
    --num-workers=1 > ${log_file} 2>&1