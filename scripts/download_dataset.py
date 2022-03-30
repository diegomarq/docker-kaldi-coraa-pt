#!/usr/bin/python3

import sys
import os
import gdown
import zipfile
from pathlib import Path

if __name__ == '__main__':

    file1 = '/data/train.zip'
    file2 = '/data/dev.zip'
    path1 = '/data/train'
    path2 = '/data/dev'

    if not Path(file2).is_file():
        url2 = "https://drive.google.com/u/0/uc?id=1D1ft4F37zLjmGxQyhfkdjSs9cJzOL3nI"
        print(f"Downloading {file2}")
        gdown.download(url2, file2, quiet=False)

    if not Path(file1).is_file():
        url1 = "https://drive.google.com/u/0/uc?id=1deCciFD35EA_OEUl0MrEDa7u5O2KgVJM"
        print(f"Downloading {file1}")
        gdown.download(url1, file1, quiet=False)

    if not Path(file1).is_file():
        print(f'File: {file1} not downloaded!')
        quit()

    if not Path(file2).is_file():
        print(f'File: {file2} not downloaded!')
        quit()

    if not Path(path1).is_dir():
        with zipfile.ZipFile(file1, 'r') as zip_ref:
            zip_ref.extractall(path1)
            os.remove(file1)

    if not Path(path2).is_dir():
        with zipfile.ZipFile(file2, 'r') as zip_ref:
            zip_ref.extractall('/data')
            os.remove(file2)

    print('Data downloaded and extracted in /data dir!')
