#!/usr/bin/env python3

import itertools
import sys
from functools import partial

import pandas as pd
from tqdm import tqdm

def process(filename: str):

    count = 0
    in_file = open(filename, 'r')
    start = 0
    stop = None
    line_count = 0

    print("Reading memory data from file...")
    data = []
    while True:

        for line in itertools.islice(in_file, start, stop):
            if 'region' in line:
                start = line_count + 1
                stop = start + int(line.split()[2])
                break
            line_count += 1

        if stop is None:
            break

        df = pd.read_csv(filename, sep=" ", names=["address", "size", "op"], skiprows=start, nrows=stop - start, converters={'address': partial(int, base=16)})
        data.append(df.groupby(["address", "op"]).sum().reset_index())

        # number of lines to skip
        line_count = stop
        start = stop - start
        stop = None

    print("Parsing memory data")
    iteration = 0
    read_addresses = set()
    write_addresses = set()
    result = []

    for i in tqdm(range(len(data))):

        df = data[i]
        iteration += 1

        read = df.loc[df['op'] == 0]['address'].unique()
        old_read_addresses_len = len(read_addresses)
        read_addresses.update(read)
        write = df.loc[df['op'] == 1]['address'].unique()
        old_write_addresses_len = len(write_addresses)
        write_addresses.update(write)

        result.append([i, len(read) * 4, (len(read_addresses) - old_read_addresses_len)*4, len(write) * 4, (len(write_addresses) - old_write_addresses_len) * 4])


    df = pd.DataFrame(data=result, columns=["iteration", "read_bytes", "new_read_bytes", "write_bytes", "new_write_bytes"])

    print(df)

if __name__ == "__main__":

    process(sys.argv[1])

