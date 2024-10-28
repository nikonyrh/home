###############################################################################
# Utility functions, many of which are ported from Clojure
import random
from collections import defaultdict


def merge(*args):
    result = {}
    for arg in args:
        if arg:
            result.update(arg)
    return result


def shuffled(coll):
    coll = list(coll)
    random.shuffle(coll)
    return coll


def take(n, coll):
    for _, i in zip(range(n), coll):
        yield i


def take_nth(n, coll_arg=None):
    def f(coll):
        if n <= 1:
            yield from coll
            return
        
        coll = iter(coll)
        r    = range(n-1)
        
        for i in coll:
            yield i
            
            for _, j in zip(r, coll):
                pass
    return f if coll_arg is None else f(coll_arg)


def nth(n, coll):
    coll = iter(coll)
    for _, i in zip(range(n), coll):
        pass
    return next(coll)


def my_map(f):
    return lambda coll: map(f, coll)


def frequencies(coll):
    d = defaultdict(int)
    for i in coll:
        d[i] += 1
    return dict(d)


def chunk_split(value, chunk_len):
    # Based on http://stackoverflow.com/questions/312443/
    #              how-do-you-split-a-list-into-evenly-sized-chunks-in-python#comment5207946_1751478
    if not isinstance(value, (list, tuple, str)):
        value = tuple(value)
    
    return [value[i:i + chunk_len] for i in range(0, len(value), chunk_len)]


def partition_all(n, coll):
    return chunk_split(tuple(coll), int(n))


# This is the function's name in Clojure
def partition(n, coll):
    return filter(lambda i: len(i) == n, partition_all(n, coll))



def partition_by(key, coll):
    # https://clojuredocs.org/clojure.core/partition-by
    # Splits coll into chunks of having the same value, as specified by the `key` function.
    iterable = iter(coll)
    chunk = [next(iterable)]
    prev_key = key(chunk[0])
    
    for i in iterable:
        this_key = key(i)
        if this_key == prev_key:
            chunk.append(i)
        else:
            yield chunk
            chunk = [i]
            prev_key = this_key
    
    yield chunk



###############################################################################
# Video utilities
import os
import cv2
import subprocess
import re

def video_capture(fname):
    assert os.path.isfile(fname)
    
    cap = cv2.VideoCapture(fname)
    assert cap.isOpened()
    return cap


def get_frames(fname):
    cap = video_capture(fname)
    
    while cap.isOpened():
        ret, frame = cap.read()
        
        if not ret:
            break
        
        yield frame[:,:,::-1]


def min_delta(delta, agg):
    def f(coll):
        coll = iter(coll)
        prev = next(coll)
        yield prev
        
        prev = prev.astype(np.float32)
        
        for i in coll:
            i_float = i.astype(np.float32)
            if i.shape != prev.shape or \
               agg(np.abs(i_float - prev).mean(axis=2)) > delta:
                yield i
                prev = i_float
    
    return f


def video_stats(fname):
    return tuple(map(int, map(video_capture(fname).get,
                              [cv2.CAP_PROP_FRAME_HEIGHT,
                               cv2.CAP_PROP_FRAME_WIDTH,
                               cv2.CAP_PROP_FPS,
                               cv2.CAP_PROP_FRAME_COUNT])))

def lowpass(w, power, data):
    result = []
    x = np.arange(-w, w+1)
    A_inv = np.zeros(1)
    
    ixs = np.arange(data.size)
    for ix_ in ixs:
        ix = ix_ + x
        ix = ix[(ix >= 0) & (ix < data.size)]
        
        if A_inv.size != ix.size:
            tmp = ix - ix[np.argmin(abs(ix - ix_))]
            tmp = tmp / np.abs(tmp).max()
            A = np.vstack([tmp**i for i in range(1, power+1)] + [np.ones(tmp.size)]).T
            A_inv = (np.linalg.inv(A.T @ A) @ A.T)[-1,:]
        
        result.append(A_inv.dot(data[ix]))
    
    return np.array(result)


def gopro_gps(fname, vel3d_lowpass_w=16, acc_lowpass_w=32, lowpass_power=3, t_init_cutoff=0, low_g_limit=0.7, min_reg_g=0.4,
              verbose=False):
    assert os.path.exists(fname)
    
    parts = fname.split('/')
    path, fname = '/'.join(parts[:-1]), parts[-1]
    
    cmd = f"docker run --rm -i -v '{path}:/media' runsascoded/gpmf-parser '/media/{fname}' -a -f"
    if verbose:
        print(cmd)
    
    p = subprocess.Popen(cmd, cwd=path, shell=True, stdout=subprocess.PIPE)
    
    stdout, _ = p.communicate()
    stdout = list(filter(bool, (l.strip() for l in stdout.decode('utf-8', errors='replace').split('\n'))))
    
    
    datas = defaultdict(list)
    data, t_from, t_to = (None for _ in range(3))
    
    for line in stdout + [None]:
        if line is not None and line.startswith('COMPUTED SAMPLERATES'):
            break
        
        if line is None or line.endswith(' seconds'):
            if data:
                for k, v in data.items():
                    datas[k].append(np.hstack([np.linspace(t_from, t_to, len(v)+1)[:-1][:,None], np.array(v)]))
            
            if line == None:
                break
            
            t_from, _, t_to, *_ = line.split(' ')
            t_from, t_to = float(t_from), float(t_to)
            data = defaultdict(list)
        elif not line.startswith('SCEN '):
            fmt = line.split(' ')[0]
            if len(fmt) == 4:
                data[fmt].append(list(map(float, re.findall(r'-?[0-9.]+', line[5:]))))
    
    
    datas = {k: np.vstack(v) for k, v in datas.items()}
    
    df_gps = pd.DataFrame(datas['GPS5'], columns='time lat lon vert vel2d vel3d'.split(' '))
    df_acc = pd.DataFrame(datas['ACCL'], columns='time z x y'.split(' '))
    
    df_gps['vel3d_filt'] = lowpass(vel3d_lowpass_w, lowpass_power, df_gps.vel3d.values)
    df_gps['distance'] = (df_gps.vel3d_filt  * df_gps.time.diff()[1:].mean()).cumsum()
    
    
    df_acc['acc']      = ((df_acc[['x', 'y', 'z']].values / 9.81)**2).sum(axis=1)**0.5
    df_acc['acc_filt'] = lowpass(acc_lowpass_w, lowpass_power, df_acc.acc.values)
    df_acc['t_jump'] = 0.0
    df_acc['d_jump'] = 0.0
    
    
    dt = df_acc.time.diff()[1:].median()
    low_g = (df_acc.acc_filt < low_g_limit).values.astype(int)
    ix_froms = (np.where((low_g[1:] - low_g[:-1]) == 1)[0] + 1).tolist()
    ix_tos   = np.where((low_g[:-1] - low_g[1:]) == 1)[0].tolist()
    
    ix = 0
    while ix < len(ix_froms)-1:
        if dt * (ix_froms[ix+1] - ix_tos[ix]) < 0.3 and df_acc.acc_filt[ix_tos[ix]:ix_froms[ix+1]].max() < 1.5:
            ix_tos[ix] = ix_tos[ix+1]
            del ix_froms[ix+1]
            del ix_tos[ix+1]
        else:
            ix += 1
    
    
    jump_stats = []
    for ix_from, ix_to in zip(ix_froms, ix_tos):
        ix_from += int(t_init_cutoff / dt)
        if ix_from >= ix_to or df_acc.acc_filt.values[ix_from:ix_to+1].min() > min_reg_g:
            continue
        
        ts = df_acc.time[ix_from:ix_to+1].values
        
        d = [0]
        for t in ts:
            v = df_gps.vel3d_filt[np.argmin(np.abs(df_gps.time - t))]
            d.append(d[-1] + v * dt)
        
        t = ts[-1] - ts[0]
        
        if t > 0 or d[-1] > 0:
      # if t > 0.3 or d[-1] > 3:
            jump_stats.append((ts[0], ts[-1], t, d[-1]))
            df_acc.loc[ix_from:ix_to,'t_jump']
            df_acc.loc[ix_from:ix_to,'t_jump'] = ts - ts[0] + dt
            df_acc.loc[ix_from:ix_to,'d_jump'] = d[1:]
    
    return df_gps, df_acc, jump_stats


###############################################################################
# Tensorflow utilities
import time
import numpy as np
import tensorflow.keras.backend as K
from tensorflow.keras import callbacks


def get_model_memory_usage(batch_size, model):
    shapes_mem_count = 0
    internal_model_mem_count = 0
    for l in model.layers:
        layer_type = l.__class__.__name__
        if layer_type == 'Model':
            internal_model_mem_count += get_model_memory_usage(batch_size, l)
        single_layer_mem = 1
        out_shape = l.output_shape
        if type(out_shape) is list:
            out_shape = out_shape[0]
        for s in out_shape:
            if s is None:
                continue
            single_layer_mem *= s
        shapes_mem_count += single_layer_mem

    trainable_count = np.sum([K.count_params(p) for p in model.trainable_weights])
    non_trainable_count = np.sum([K.count_params(p) for p in model.non_trainable_weights])

    number_size = 4.0
    if K.floatx() == 'float16':
        number_size = 2.0
    if K.floatx() == 'float64':
        number_size = 8.0

    total_memory = number_size * (batch_size * shapes_mem_count + trainable_count + non_trainable_count)
    gbytes = np.round(total_memory / (1024.0 ** 3), 3) + internal_model_mem_count
    return gbytes


class MyCallback(callbacks.Callback):
    def __init__(self, plot, t_max=1000, t_between_plot=10):
        super().__init__()
        
        self.plot = plot
        self.t0 = time.time()
        self.history = {'time': []}
        self.t_prev_plot = 0
        self.t_max = t_max * 60*60
        self.t_between_plot = t_between_plot
    
    def on_train_batch_end(self, epoch, logs=None):
        t = time.time()
        if t - self.t_prev_plot > self.t_between_plot:
            self.t_prev_plot = t
            self.plot(self)
    
    def on_epoch_end(self, epoch, logs=None):
        self.logs = logs
        for k, v in logs.items():
            if k not in self.history:
                self.history[k] = [v]
            else:
                self.history[k].append(v)
        
        t = time.time()
        self.history['time'].append(t - self.t0)
        
        if t - self.t_prev_plot > self.t_between_plot:
            self.t_prev_plot = t
            self.plot(self)
        
        if t - self.t0 > self.t_max:
            self.model.stop_training = True


###############################################################################
# Pandas utilities

import pandas as pd

pd.options.display.width = 1200
pd.options.display.max_colwidth = 100
pd.options.display.max_columns = 100

