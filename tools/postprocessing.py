#!/usr/bin/env python3

import itertools
import glob
import sys
from functools import partial
from subprocess import check_output

import pandas as pd
from tqdm import tqdm

def wc(filename):
        return int(check_output(["wc", "-l", filename]).split()[0])

def process(filename: str):

    count = 0
    #lines = wc(filename)
    start = 0
    stop = None
    line_count = 0
    data = {}

    sum_read = 0

    files = list(glob.glob(f"{filename}*"))
    files.sort()

    print("Reading memory data")
    for i in tqdm(range(len(files))):

        name = files[i]
        iteration = int(name.split('.')[-1])
        region = name.split('.')[-2]
        in_file = open(name, 'r')
        line = in_file.readline()
        df = pd.read_table(in_file, sep=" ", names=["address", "size", "read", "write", "read_host", "write_host"], converters={'address': partial(int, base=16)})

        if region not in data:
            data[region] = []
        data[region].append((iteration, df)) #.groupby(["address", "op"]).sum().reset_index()))


    total_files = 0
    for region, region_data in data.items():
        region_data.sort(key=lambda x: x[0])
        total_files += len(region_data)

    print(f"Read {total_files} files for {len(data)} regions")
    print("Parsing memory data")
    result = []

    with tqdm(total=total_files) as pb:

        for region, region_data in data.items():

            read_addresses = set()
            write_addresses = set()
            read_host_addresses = set()
            write_host_addresses = set()

            for data in region_data:
                df = data[1]
                iteration = data[0]


                read = set()
                for val in df.loc[df['read'] > 0].itertuples():
                    #[['address', 'size']]:
                    for j in range(val.size):
                        read.add(val.address + j)
                    if val.read_host > 0:
                        read_host_addresses.add(val.address + j)

                old_read_addresses_len = len(read_addresses)
                read_addresses.update(read)

                write = set()
                for val in df.loc[df['write'] > 0].itertuples():
                    for j in range(val.size):
                        write.add(val.address + j)
                    if val.write_host > 0:
                        write_host_addresses.add(val.address + j)

                old_write_addresses_len = len(write_addresses)
                write_addresses.update(write)

                result.append([region, iteration, len(read), (len(read_addresses) - old_read_addresses_len), len(write), (len(write_addresses) - old_write_addresses_len), len(read_host_addresses), len(write_host_addresses)])

                pb.update(1)


    df = pd.DataFrame(data=result, columns=["region", "iteration", "read_bytes", "new_read_bytes", "write_bytes", "new_write_bytes", "host_read_bytes", "host_write_bytes"])
    return df

if __name__ == "__main__":

    print(f"Reading data from {sys.argv[1]}")
    df = process(sys.argv[1])
    print(f"Writing results to {sys.argv[2]}")
    df.to_csv(sys.argv[2])

