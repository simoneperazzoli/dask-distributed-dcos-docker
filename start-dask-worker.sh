#!/usr/bin/env bash

set -o errexit -o pipefail

source "$HOME/.bash_profile"
source activate dask-distributed

if [ \( -n "${MARATHON_APP_ID-}" \) -a \( -n "${MARATHON_APP_RESOURCE_CPUS-}" \) \
    -a \( -n "${MESOS_TASK_ID-}" \) -a \( -n "${LIBPROCESS_IP-}" \) \
    -a \( -n "${PORT1-}" \) -a \( -n "${PORT2-}" \) -a \( -n "${PORT3-}" \) ]
then
    VIP_PREFIX=$(python -c \
        "import os; print(''.join(os.environ['MARATHON_APP_ID'].split('/')[:-1]))" \
    )
    echo "DC/OS Named VIP Prefix: ${VIP_PREFIX}"

    NPROCS=$(python -c \
        "import os,math; print(int(math.ceil(os.environ['MARATHON_APP_RESOURCE_CPUS'])))" \
    )
    echo "Dask Number of Processes: ${NPROCS}"

    if [ -n "${DASK_FRAMEWORK_NAME-}" ]
    then
        FW_NAME="${DASK_FRAMEWORK_NAME}"
    else
        FW_NAME="marathon"
    fi

    DASK_SCHEDULER="${VIP_PREFIX}dask-scheduler.${FW_NAME}.l4lb.thisdcos.directory:8786"
    echo "Dask Scheduler: ${DASK_SCHEDULER}"

    dask-worker \
        --worker-port "${PORT1}" \
        --http-port "${PORT2}" \
        --nanny-port "${PORT3}" \
        --host "${LIBPROCESS_IP}" \
        --nthreads 1 \
        --nprocs "${NPROCS}" \
        --name "${MESOS_TASK_ID}" \
        "${DASK_SCHEDULER}"
else
    dask-worker "$@"
fi
