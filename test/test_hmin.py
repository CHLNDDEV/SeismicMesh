import numpy as np

import SeismicMesh


def test_hmin():
    hmin = 100
    hh_m = 100
    assert min(hh_m) == hmin


if __name__ == "__main__":
    test_hmin()
