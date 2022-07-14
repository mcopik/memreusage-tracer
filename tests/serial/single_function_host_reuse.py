
import os
from tools.postprocessing import process

def run_processing():

    tracer_output = os.environ["TRACER_OUTPUT"]
    cacheline_size = int(os.environ["CACHELINE_SIZE"])
    df = process(tracer_output, cacheline_size)
    return df

def test_run_processing():

    df = run_processing()
    print(df.shape)
    assert df.shape[0] > 0

