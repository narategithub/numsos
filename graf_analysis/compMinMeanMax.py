import os, sys, traceback
import datetime as dt
from grafanaAnalysis import Analysis
from numsos.DataSource import SosDataSource
from numsos.Transform import Transform
from sosdb.DataSet import DataSet
from sosdb import Sos
import pandas as pd
import numpy as np

class compMinMeanMax(Analysis):
    def __init__(self, cont, start, end, schema='meminfo', maxDataPoints=4096):
        self.schema = schema
        self.src = SosDataSource()
        self.src.config(cont=cont)
        self.start = start
        self.send = end
        self.maxDataPoints = maxDataPoints

    def get_data(self, metric, job_id, params=None):
        metric = metric[0]
        if job_id == 0:
            return [ { 'target' : 'Error: Please specify valid job_id', 'datapoints' : [] } ]
        # Get components with data during given time range
        self.src.select(['component_id'],
                   from_ = [ self.schema ],
                   where = [
                       [ 'job_id', Sos.COND_EQ, job_id ],
                       [ 'timestamp', Sos.COND_GE, self.start ],
                       [ 'timestamp', Sos.COND_LE, self.send ]
                   ],
                   order_by = 'time_job_comp'
            )
        comps = self.src.get_results(limit=self.maxDataPoints)
        if not comps:
            return [ { 'target' : 'Error: component_id not found for Job '+str(job_id),
                       'datapoints' : [] } ]
        else:
            compIds = np.unique(comps['component_id'].tolist())
        result = []
        # select job by job_id
        self.src.select(['job_start', 'job_end'],
                   from_ = [ 'mt-slurm' ],
                   where = [[ 'job_id', Sos.COND_EQ, job_id ]],
                   order_by = 'job_rank_time'
            )
        job = self.src.get_results()
        if job is None:
            return [ { 'target' : 'Error: Job '+str(job_id)+' not found in mt-slurm schema',
                       'datapoints' : [] } ]
        job_start = job.array('job_start')[0]
        job_end = job.array('job_end')[0]
        datapoints = []
        for comp_id in compIds:
            where_ = [
                [ 'component_id', Sos.COND_EQ, comp_id ],
                [ 'job_id', Sos.COND_EQ, job_id ]
            ]
            self.src.select([ metric, 'timestamp' ],
                       from_ = [ self.schema ],
                       where = where_,
                       order_by = 'job_comp_time'
                )
            inp = None

            # default for now is dataframe - will update with dataset vs dataframe option
            res = self.src.get_df()
            if res is None:
                continue
            start_d = dt.datetime.utcfromtimestamp(job_start).strftime('%m/%d/%Y %H:%M:%S')
            end_d = dt.datetime.utcfromtimestamp(job_end).strftime('%m/%d/%Y %H:%M:%S')
            ts = pd.date_range(start=start_d, end=end_d, periods=len(res.values[0].flatten()))
            series = pd.DataFrame(res.values[0].flatten(), index=ts)
            rs = series.resample('S').ffill()
            datapoints.append(rs.values.flatten())
            tstamp = rs.index
        i = 0
        tstamps = []
        while i < len(tstamp):
            ts = pd.Timestamp(tstamp[i])
            ts = np.int_(ts.timestamp()*1000)
            tstamps.append(ts)
            i += 1

        res_ = DataSet()
        min_datapoints = np.min(datapoints, axis=0)
        mean_datapoints = np.mean(datapoints, axis=0)
        max_datapoints = np.max(datapoints, axis=0)
        res_.append_array(len(min_datapoints), 'min_'+metric, min_datapoints)
        res_.append_array(len(mean_datapoints), 'mean_'+metric, mean_datapoints)
        res_.append_array(len(max_datapoints), 'max_'+metric, max_datapoints)
        res_.append_array(len(tstamps), 'timestamp', tstamps)
        return res_
