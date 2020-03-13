import SeismicMesh

fname = "vel_z6.25m_x12.5m_exact.segy"

# Construct mesh sizing object
ef = SeismicMesh.MeshSizeFunction(
    bbox=(-12e3, 0, 0, 67e3), wl=5, dt=0.001, segy=fname, hmin=10, grade=5
)

# Build mesh size function
ef = ef.build()

# Visualize mesh size function
ef.plot()

# Construct mesh generator
mshgen = SeismicMesh.MeshGenerator(SizingFunction=ef)

mshgen = mshgen.build()
