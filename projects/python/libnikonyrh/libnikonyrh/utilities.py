###############################################################################
# Utility functions, many of which are ported from Clojure
import random
from collections import defaultdict

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


###############################################################################
# Video utilities
import os
import cv2

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

