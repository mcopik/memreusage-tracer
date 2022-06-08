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
    data = []

    sum_read = 0

    files = list(glob.glob(f"{filename}*"))
    files.sort()

    print("Reading memory data")
    for i in tqdm(range(len(files))):

        name = files[i]
        iteration = int(name.split('.')[-1])
        in_file = open(name, 'r')
        line = in_file.readline()
        df = pd.read_table(in_file, sep=" ", names=["address", "size", "read", "write"], converters={'address': partial(int, base=16)})
        data.append((iteration, df)) #.groupby(["address", "op"]).sum().reset_index()))

    print(f"Read {len(data)} files")

    data.sort(key=lambda x: x[0])

    print("Parsing memory data")
    iteration = 0
    read_addresses = set()
    write_addresses = set()
    result = []

    for i in tqdm(range(len(data))):

        df = data[i][1]
        iteration += 1

        read = set()
        for val in df.loc[df['read'] > 0].itertuples():
            #[['address', 'size']]:
            for j in range(val.size):
                read.add(val.address + j)

        old_read_addresses_len = len(read_addresses)
        read_addresses.update(read)

        write = set()
        for val in df.loc[df['write'] > 0].itertuples():
            for j in range(val.size):
                write.add(val.address + j)

        old_write_addresses_len = len(write_addresses)
        write_addresses.update(write)

        result.append([i, len(read), (len(read_addresses) - old_read_addresses_len), len(write), (len(write_addresses) - old_write_addresses_len)])


    df = pd.DataFrame(data=result, columns=["iteration", "read_bytes", "new_read_bytes", "write_bytes", "new_write_bytes"])
    return df

if __name__ == "__main__":

    print(f"Reading data from {sys.argv[1]}")
    df = process(sys.argv[1])
    print(f"Writing results to {sys.argv[2]}")
    df.to_csv(sys.argv[2])

