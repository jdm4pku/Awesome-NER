#!/bin/bash
set -x

export CUDA_DEVICE_ORDER="PCI_BUS_ID"
export TRANSFORMERS_CACHE=/home/jindongming/.cache/huggingface/hub

port=$(shuf -i25000-30000 -n1)

# 最好令 bs_per_gpu * num_gpu * gradient_accumulation_steps = 256
# 学习率可以使用 5e-5
# param_num < 1b 10epoch, 3b 5epoch, 11b 5epoch
# 注意修改 CUDA_VISIBLE_DEVICES, model_name_or_path，output_dir, run_name, data_dir, task_config_dir, instruction_file
# 其余参数可与当前版本保持一致

# 3090 * 4 on t5-700M
# CUDA_VISIBLE_DEVICES=0,1,2,3 
deepspeed --include localhost:1,2,3,4 --master_port $port run_uie.py \
   --do_train \
   --do_predict \
   --predict_with_generate \
   --model_name_or_path google/flan-t5-base \
   --data_dir /home/jindongming/project/0-RequirementsExtraction/0-EntityExtraction/Awesome-NER/InstructUIE/data/IE_INSTRUCTIONS \
   --task_config_dir /home/jindongming/project/0-RequirementsExtraction/0-EntityExtraction/Awesome-NER/InstructUIE/configs/multi_task_configs \
   --instruction_file /home/jindongming/project/0-RequirementsExtraction/0-EntityExtraction/Awesome-NER/InstructUIE/configs/instruction_config.json \
   --instruction_strategy single \
   --output_dir /home/jindongming/project/0-RequirementsExtraction/0-EntityExtraction/Awesome-NER/InstructUIE/output/t5-700M-ie-single \
   --input_record_file flan-t5.record \
   --per_device_train_batch_size 8 \
   --per_device_eval_batch_size 16 \
   --gradient_accumulation_steps 8 \
   --learning_rate 5e-05 \
   --num_train_epochs 10 \
   --deepspeed /home/jindongming/project/0-RequirementsExtraction/0-EntityExtraction/Awesome-NER/InstructUIE/configs/ds_configs/stage0.config \
   --run_name t5-700M-mult-mi-experiment \
   --max_source_length 512 \
   --max_target_length 50 \
   --generation_max_length 50 \
   --max_num_instances_per_task 10000 \
   --max_num_instances_per_eval_task 200 \
   --add_task_name False \
   --add_dataset_name False \
   --num_examples 0 \
   --overwrite_output_dir \
   --overwrite_cache \
   --lr_scheduler_type constant \
   --warmup_steps 0 \
   --logging_strategy steps \
   --logging_steps 500 \
   --evaluation_strategy no \
   --save_strategy steps \
   --save_steps 2000
