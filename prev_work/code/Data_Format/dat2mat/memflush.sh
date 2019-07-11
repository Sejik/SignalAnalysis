#!/bin/bash
sync; echo 3 | tee /proc/sys/vm/drop_caches > /dev/null
