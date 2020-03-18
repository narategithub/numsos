import datetime as dt
import time
from sosdb import Sos
from sosdb.DataSet import DataSet
from numsos.DataSource import SosDataSource
from numsos.Transform import Transform
from grafanaAnalysis import Analysis
import numpy as np
import pandas as pd
import sys

class rankMemByJob(Analysis):
    def __init__(self, cont, start, end, schema='meminfo', maxDataPoints=4096):
        self.schema = [ str(schema) ]
        self.cont = cont
        self.start = int(start)
        self.end = end
        self.mdp = 1000000
        self.src = SosDataSource()
        self.src.config(cont=cont)

        self.metrics = [ str(schema)+'[job_id]', str(schema)+'[component_id]',
                         str(schema)+'[timestamp]', str(schema)+'[MemTotal]',
                         str(schema)+'[MemAvailable]']

    def get_data(self, metricNames=None, job_id=None, params=None):
        ''' Handle parameters and call relevant method '''
        try:
            if 'summary' in params:
                if job_id == 0:
                    print(" You must provide a valid job_id > 1 ")
                    return None
                res = self._job_summary(job_id)
                return res
            if 'threshold' in params:
                threshold = int(params.split('=')[1])
            else:
                threshold = 5
            if 'idle' in params:
                if threshold < 0:
                    res = self._get_idle_low_mem(abs(threshold))
                else:
                    res = self._get_idle_high_mem(threshold+1)
            else:
                if threshold < 0:
                    res = self._get_low_mem(abs(threshold))
                else:
                    res = self._get_high_mem(threshold+1)
            return res
        except Exception as e:
            a, b, c = sys.exc_info()
            print(str(e)+' '+str(c.tb_lineno))
            return None

    def _mem_used_ratio(self):
        ''' Memory utilization ratio calculation '''
        try:
            self.xfrm = Transform(self.src, None, limit=self.mdp)
            resp = self.xfrm.begin()
            while resp is not None:
                resp = self.xfrm.next()
                if resp is not None:
                    self.xfrm.concat()

            data = self.xfrm.top()
            memUsedRatio = (data['MemTotal'] - data['MemAvailable']) / data['MemTotal'] >> 'Mem_Used_Ratio'
            self.stdd = memUsedRatio.std()
            self.mean = memUsedRatio.mean()
            memUsedRatio <<= data['timestamp']
            memUsedRatio <<= data['job_id']
            memUsedRatio <<= data['component_id']

            self.xfrm.push(memUsedRatio)
            return memUsedRatio
        except Exception as e:
            a, b, c = sys.exc_info()
            print(str(e)+' '+str(c.tb_lineno))
            return None

    def _get_job_times(self):
        ''' Get job times for job_id > 1 '''
        self.xfrm.dup()
        self.xfrm.dup()
        self.xfrm.min([ 'timestamp' ], group_name='job_id',
                      xfrm_suffix='')
        job_start = self.xfrm.pop()
        self.xfrm.max([ 'timestamp' ], group_name='job_id', xfrm_suffix='')
        job_end = self.xfrm.pop()
        self.xfrm.pop()
        job_times = job_start['timestamp'] >> 'job_start'
        job_times <<= job_end['timestamp'] >> 'job_end'
        return job_times

    def _job_summary(self, job_id):
        ''' Get summarized information about jobs across components '''
        where_ = [ [ 'job_id', Sos.COND_EQ, job_id ] ]
        self.src.select(self.metrics,
                        from_ = self.schema,
                        where = where_,
                        order_by = 'job_time_comp'
            )

        memUsedRatio = self._mem_used_ratio()
        if memUsedRatio is None:
            return None
        self.xfrm.push(memUsedRatio)
        res = self.xfrm.min([ 'Mem_Used_Ratio' ], group_name='job_id',
                            keep=['component_id'], xfrm_suffix='')
        self.xfrm.push(memUsedRatio)
        counts = [ len(res) ]
        _max = self.xfrm.max([ 'Mem_Used_Ratio' ], group_name='job_id',
                             keep=['component_id'], xfrm_suffix='')
        res = res.concat(_max)
        counts.append(len(_max))
        i = -2
        mem_used = []
        jid = []
        while i < 3:
            lim = self.mean[[0,0]] + float(i) * self.stdd[[0,0]]
            mem_used.append(lim)
            if i == 0:
                _count = []
            elif i < 0:
                _count = memUsedRatio < ('Mem_Used_Ratio', lim)
            else:
                _count = memUsedRatio > ('Mem_Used_Ratio', lim)

            counts.append(len(_count))
            del _count
            jid.append(job_id)
            i += 1
        _res = DataSet()
        _res.append_array(len(mem_used), 'Mem_Used_Ratio', mem_used)
        _res.append_array(5, 'job_id', jid)
        res = res.concat(_res)
        res.append_array(7, "Analysis", ["Min", "Max", "Stdd-2", "Stdd-1", "Mean", "Stdd+1", "Stdd+2" ])
        res.append_array(7, "Count", counts)
        return res

    def _get_high_mem(self, threshold):
        ''' Get high memory threshold nodes with running jobs '''
        where_ = [ [ 'job_id', Sos.COND_GT, 1 ],
                   [ 'timestamp', Sos.COND_GE, self.start ] ]
        if self.end > 0:
            where_.append([ 'timestamp', Sos.COND_LE, self.end ])
        self.src.select(self.metrics,
                       from_ = self.schema,
                       where = where_,
                       order_by = 'time_job_comp'
            )
        memUsedRatio = self._mem_used_ratio()
        if memUsedRatio is None:
            return None
        self.xfrm.dup()
        job_times = self._get_job_times()
        keep_ = [ 'component_id' ]
        self.xfrm.max([ 'Mem_Used_Ratio' ], group_name='job_id',
                      keep=keep_, xfrm_suffix='')
        memUsedRatio = self.xfrm.pop()
        memUsedRatio <<= job_times['job_start']
        memUsedRatio <<= job_times['job_end']
        top_jobs = np.sort(memUsedRatio.array('Mem_Used_Ratio'))
        if memUsedRatio.get_series_size() > threshold:
             memUsedRatio = memUsedRatio > ('Mem_Used_Ratio', top_jobs[len(top_jobs) - threshold])
        return memUsedRatio

    def _get_low_mem(self, threshold):
        ''' Get low memory threshold nodes with running jobs '''
        where_ = [ [ 'job_id', Sos.COND_GE, 1 ],
                   [ 'timestamp', Sos.COND_GE, self.start ] ]
        if self.end > 0:
            where_.append(['timestamp', Sos.COND_LE, self.end])
        self.src.select(self.metrics,
                        from_ = self.schema,
                        where = where_,
                        order_by = 'time_job_comp'
            )
        memUsedRatio = self._mem_used_ratio()
        if memUsedRatio is None:
            return None
        self.xfrm.dup()
        job_times = self._get_job_times()
        keep_ = [ 'component_id' ]
        self.xfrm.min([ 'Mem_Used_Ratio' ], group_name='job_id',
                                     keep=keep_, xfrm_suffix='')
        memUsedRatio = self.xfrm.pop()
        memUsedRatio <<= job_times['job_start']
        memUsedRatio <<= job_times['job_end']
        bot_jobs = np.sort(memUsedRatio.array('Mem_Used_Ratio'))
        if memUsedRatio.get_series_size() > threshold:
            memUsedRatio = memUsedRatio < ('Mem_Used_Ratio', bot_jobs[threshold])
        return memUsedRatio

    def _get_idle_high_mem(self, threshold):
        ''' Get high mem threshold for idle nodes '''
        where_ = [ [ 'job_id', Sos.COND_EQ, 0 ],
                   [ 'timestamp', Sos.COND_GE, self.start ] ]
        if self.end > 0:
            where_.append([ 'timestamp', Sos.COND_LE, self.end ])
        self.src.select(self.metrics,
                   from_ = self.schema,
                   where = where_,
                   order_by = 'time_comp'
            )
        memUsedRatio = self._mem_used_ratio()
        if memUsedRatio is None:
            return None
        self.xfrm.max([ 'Mem_Used_Ratio' ], group_name='component_id',
                      keep=['timestamp', 'job_id', 'component_id'])
        memUsedRatio = self.xfrm.pop()
        top_jobs = np.sort(memUsedRatio.array('Mem_Used_Ratio_max'))
        if memUsedRatio.get_series_size() > threshold:
            memUsedRatio = memUsedRatio > ('Mem_Used_Ratio_max', top_jobs[len(top_jobs) - threshold])
        return memUsedRatio

    def _get_idle_low_mem(self, threshold):
        ''' Get low mem threshold for idle nodes '''
        where_ = [ [ 'job_id', Sos.COND_EQ, 0 ],
                   [ 'timestamp', Sos.COND_GE, self.start ] ]
        if self.end > 0:
            where_.append([ 'timestamp', Sos.COND_LE, self.end ])
        self.src.select(self.metrics,
                   from_ = self.schema,
                   where = where_,
                   order_by = 'time_comp'
            )
        memUsedRatio = self._mem_used_ratio()
        if memUsedRatio is None:
            return None
        _min = self.xfrm.min([ 'Mem_Used_Ratio' ], group_name='component_id',
                             keep=['timestamp', 'job_id', 'component_id'])
        memUsedRatio = self.xfrm.pop()
        bot_jobs = np.sort(memUsedRatio.array('Mem_Used_Ratio_min'))
        if memUsedRatio.get_series_size() > threshold:
            memUsedRatio = memUsedRatio < ('Mem_Used_Ratio_min', bot_jobs[threshold])
        return memUsedRatio 

