#!/usr/bin/env python3

import enum
import itertools
import json
import glob
import sys
import os

from collections import defaultdict
from functools import partial
from subprocess import check_output

import pandas as pd
from tqdm import tqdm

def wc(filename):
    return int(check_output(["wc", "-l", filename]).split()[0])

def read_trace(path):

    name = os.path.basename(path)
    iteration = int(name.split('.')[-1])
    region = name.split('.')[-2]
    in_file = open(path, 'r')
    line = in_file.readline()
    df = pd.read_table(in_file, sep=" ", names=["address", "read", "write"], converters={'address': partial(int, base=16)})

    return iteration, region, df

class ReuseType(enum.Enum):
    READ_HOST = 0,
    WRITE_HOST = 1

def find_reuse(host_df, region_df, reuse_type: ReuseType):

    df = pd.merge(region_df, host_df, how='left', on=['address'], suffixes=['', '_data_host'])

    if 'read_host' not in df.columns:
        df['read_host'] = 0
        df['write_host'] = 0


    # We look for cachelines written by the kernel and read by the host.
    if reuse_type == ReuseType.READ_HOST:
        df.loc[(df['write'] > 0 ) & (df['read_data_host'] > 0), 'read_host'] = 1
    # We look for cachelines read by the kernel and written by the host.
    else:
        df.loc[(df['read'] > 0 ) & (df['write_data_host'] > 0), 'write_host'] = 1


    df.drop(labels=['read_data_host', 'write_data_host'], axis=1, inplace=True)

    return df

def process(filename: str, cacheline: int):

    count = 0
    #lines = wc(filename)
    start = 0
    stop = None
    line_count = 0
    data = defaultdict(dict)

    sum_read = 0

    #files = list(glob.glob(f"{filename}*"))
    #files.sort()

    host_events = json.load(open(f"{filename}.host_events"))
    files = []
    for i in range(len(host_events)):
        files.append(f"{filename}.host.{i}")

    print("Reading memory data")
    before_df, before_region, before_iteration = (None, None, None)
    after_df = None
    for i in tqdm(range(len(files))):

        host_event = host_events[i]
        host_iteration, _, host_df = read_trace(files[i])

        # No 'before' in the first host event
        # No 'after' in the last host event
        if "after" in host_event:
            next_region = host_event["after"]["region"]
            next_iter = host_event["after"]["counter"]
            after_df_path = f"{filename}.{next_region}.{next_iter}"
            after_iteration, after_region, after_df = read_trace(after_df_path)

        else:
            after = None

        # First, we look for reused across this host event and the previous remote kernel.
        # We look for read-after-write (RAW) dependency.
        # If host has read data that was written by a kernel after an invocation, then it needs to be transferred
        # back from the remote endpoint.
        if before_df is not None:
            before_df = find_reuse(host_df, before_df, ReuseType.READ_HOST)
            data[before_region][before_iteration] = before_df

        # Then, we look for data reused between this host event and the following remote kernel.
        # We look for read-after-write (RAW) dependency.
        # If host has written the same data that is later read by a kernel invocation, then it needs
        # to be transferred from the host to the remote endpoint.
        if after_df is not None:
            after_df = find_reuse(host_df, after_df, ReuseType.WRITE_HOST)
            data[after_region][after_iteration] = after_df

        # 'after' dataframe becomes the next 'before'
        before_df, after_df = after_df, before_df
        before_region, after_region = after_region, before_region
        before_iteration, after_iteration = after_iteration, before_iteration

    #print("Reading host memory data")
    #for i in tqdm(range(len(files))):

    #    name = files[i]
    #    iteration = int(name.split('.')[-1])
    #    region = name.split('.')[-2]
    #    in_file = open(name, 'r')
    #    line = in_file.readline()
    #    df = pd.read_table(in_file, sep=" ", names=["address", "size", "read", "write"], converters={'address': partial(int, base=16)})

    #    if region not in data:
    #        data[region] = []
    #    data[region].append((iteration, df)) #.groupby(["address", "op"]).sum().reset_index()))

    total_files = 0
    for region, region_data in data.items():
        #region_data.sort(key=lambda x: x[0])
        total_files += len(region_data)

    print(f"Read {total_files} file(s) for {len(data)} region(s).")
    print("Parsing memory data")
    result = []

    with tqdm(total=total_files) as pb:

        for region, region_data in data.items():

            read_addresses = set()
            write_addresses = set()

            for iteration, df in region_data.items():

                read_host_addresses = set()
                write_host_addresses = set()

                read = set()
                for val in df.loc[df['read'] > 0].itertuples():
                    #[['address', 'size']]:
                    #for j in range(val.size):
                    #    read.add(val.address + j)
                    read.add(val.address)
                    if val.read_host > 0:
                        read_host_addresses.add(val.address)

                old_read_addresses_len = len(read_addresses)
                read_addresses.update(read)

                write = set()
                for val in df.loc[df['write'] > 0].itertuples():
                    #for j in range(val.size):
                    #    write.add(val.address + j)
                    write.add(val.address)
                    if val.write_host > 0:
                        write_host_addresses.add(val.address)

                old_write_addresses_len = len(write_addresses)
                write_addresses.update(write)

                result.append([
                    region, iteration,
                    len(read) * cacheline * 4,
                    (len(read_addresses) - old_read_addresses_len) * cacheline * 4,
                    len(write) * cacheline * 4,
                    (len(write_addresses) - old_write_addresses_len) * cacheline * 4,
                    len(read_host_addresses) * cacheline * 4,
                    len(write_host_addresses) * cacheline * 4
                ])

                pb.update(1)


    df = pd.DataFrame(data=result, columns=["region", "iteration", "read_bytes", "new_read_bytes", "write_bytes", "new_write_bytes", "host_read_bytes", "host_write_bytes"])
    return df

if __name__ == "__main__":

    print(f"Reading data from {sys.argv[1]} for cacheline size {sys.argv[2]}")
    df = process(sys.argv[1], int(sys.argv[2]))
    print(f"Writing results to {sys.argv[3]}")
    df.to_csv(sys.argv[3])

