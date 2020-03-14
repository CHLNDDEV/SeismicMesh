import SeismicMesh
def test_hmin():
    fname = 'testing.segy'
    hmin = 100
    ef = SeismicMesh.MeshSizeFunction(
    bbox=(-1e3, 0, 0, 1e3), wl=5, segy=fname, hmin=hmin
    )
    ef = ef.build()
    hh = ef.hh
    assert hh.min() == hmin


if __name__ == "__main__":
    test_hmin()
