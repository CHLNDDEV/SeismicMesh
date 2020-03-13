import numpy as np

from SeismicMesh import FastHJ


def hj(fun, elen, grade, imax):
    """ A wrapper to call the cpp gradient limiter code """
    # TODO ADD CHECKS HERE
    _nz, _nx = np.shape(fun)
    ffun = fun.flatten("F")
    ffun_list = ffun.tolist()
    tmp = FastHJ.limgrad([_nz, _nx, 1], elen, grade, imax, ffun_list)
    tmp = np.asarray(tmp)
    fun_s = np.reshape(tmp, (_nz, _nx), "F")
    return fun_s
