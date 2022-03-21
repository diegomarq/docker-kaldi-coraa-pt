#!/usr/bin/python3

import sys
import os
import pandas as pd
from pathlib import Path

def get_sample(file, fraction):
    df = pd.read_csv(file, sep=',', encoding='utf8')    
    print(f'Data :: Rows: {str(df.shape[0])}, Columns: {str(df.shape[1])}')

    df_sample = df.sample(frac=float(fraction), random_state=1234567)
    print(f'Sample :: Rows: {str(df_sample.shape[0])}, Columns: {str(df_sample.shape[1])}')
    output = os.path.join(str(Path(file).parent.absolute()), 'sample_' + os.path.basename(file))
    df_sample.to_csv(output, sep=',', encoding='utf8', index=False)

    print('Successful!')

if __name__ == '__main__':
    file = sys.argv[1:][0]
    fraction = sys.argv[1:][1]
    get_sample(file, fraction)

