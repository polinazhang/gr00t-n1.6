#!/bin/bash
#SBATCH --job-name=GR00T-Train
#SBATCH --output=/coc/testnvme/xzhang3205/vla-adaptation/slurms/gr00t-train-%J.out
#SBATCH --error=/coc/testnvme/xzhang3205/vla-adaptation/slurms/gr00t-train-%J.err
#SBATCH --partition="kira-lab"
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=64
#SBATCH --gpus-per-node="a40:8"
#SBATCH --qos="long"
#SBATCH --time="6-23:59:59"
#SBATCH --exclude="clippy,spd-13"
#SBATCH --mem-per-gpu=45G

source ~/.bashrc
set -euo pipefail

REPO_ROOT="/coc/testnvme/xzhang3205/vla-adaptation"
GR00T_ROOT="${REPO_ROOT}/models/gr00t-n1.6"
SLURM_LOG_DIR="${REPO_ROOT}/slurms"
SCRATCH_ROOT="/coc/pskynet4/xzhang3205/test/gr00t-training"
JOB_ID="${SLURM_JOB_ID:-manual}"

mkdir -p "${SLURM_LOG_DIR}" "${SCRATCH_ROOT}/tmp/${JOB_ID}"
cd "${GR00T_ROOT}"
source "${GR00T_ROOT}/.venv/bin/activate"

: "${CHECKPOINT_DIR:?Set CHECKPOINT_DIR to the GR00T start checkpoint directory.}"
: "${DATASET_DIR:?Set DATASET_DIR to the LeRobot dataset directory.}"
: "${OUTPUT_DIR:?Set OUTPUT_DIR to the finetuning output directory.}"

export NUM_GPUS="${NUM_GPUS:-8}"
export MASTER_PORT="${MASTER_PORT:-$((29500 + (${SLURM_JOB_ID:-0} % 1000)))}"
export SAVE_STEPS="${SAVE_STEPS:-1000}"
export MAX_STEPS="${MAX_STEPS:-10000}"
export USE_WANDB="${USE_WANDB:-1}"
export WANDB_PROJECT="${WANDB_PROJECT:-finetune-gr00t-n1d6}"
export DATALOADER_NUM_WORKERS="${DATALOADER_NUM_WORKERS:-8}"
export GLOBAL_BATCH_SIZE="${GLOBAL_BATCH_SIZE:-64}"
export SHARD_SIZE="${SHARD_SIZE:-1024}"
export NUM_SHARDS_PER_EPOCH="${NUM_SHARDS_PER_EPOCH:-100000}"
export EPISODE_SAMPLING_RATE="${EPISODE_SAMPLING_RATE:-0.1}"

export PYTHONPATH="${GR00T_ROOT}:${REPO_ROOT}:${PYTHONPATH:-}"
export XDG_CACHE_HOME="/coc/testnvme/xzhang3205/.cache"
export HF_HOME="/coc/testnvme/xzhang3205/huggingface"
export TRANSFORMERS_CACHE="/coc/testnvme/xzhang3205/huggingface"
export WANDB_DIR="${OUTPUT_DIR}/wandb"
export TMPDIR="${SCRATCH_ROOT}/tmp/${JOB_ID}"
export PIP_CONSTRAINT=""
export LD_LIBRARY_PATH="/usr/local/cuda-12.4/lib64:/usr/lib/x86_64-linux-gnu:/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-}"

mkdir -p "${OUTPUT_DIR}" "${WANDB_DIR}"

bash examples/finetune.sh \
    --base-model-path "${CHECKPOINT_DIR}" \
    --dataset-path "${DATASET_DIR}" \
    --embodiment-tag ROBOCASA_PANDA_OMRON \
    --modality-config-path "${GR00T_ROOT}/gr00t/configs/data/robocasa_panda_omron_config.py" \
    --output-dir "${OUTPUT_DIR}" \
    --experiment-name "${EXPERIMENT_NAME:-robocasa-panda-omron}" \
    --wandb-project "${WANDB_PROJECT}"
