# -----------------------------------------------------------------------------
#  Copyright (C) 2020 Keith Roberts

#  Distributed under the terms of the GNU General Public License. You should
#  have received a copy of the license along with this program. If not,
#  see <http://www.gnu.org/licenses/>.
# -----------------------------------------------------------------------------


class MeshGenerator:
    """
    MeshGenerator: using sizng function and signed distance field build a mesh

    Usage
    -------
    >>>> obj = MeshGenerator(MeshSizeFunction_obj,method=DistMesh)


    Parameters
    -------
        MeshSizeFunction_obj: self-explantatory
                        **kwargs
        method: verbose name of mesh generation method to use  (default=DistMesh)


    Returns
    -------
        A mesh object


    Example
    ------
    msh = MeshSizeFunction(ef,fd)

    """

    def __init__(self, SizingFunction, method="DistMesh"):
        self.SizingFunction = SizingFunction
        self.method = method

    # SETTERS AND GETTERS
    @property
    def SizingFunction(self):
        return self.__SizingFunction

    @SizingFunction.setter
    def SizingFunction(self, value):
        self.__SizingFunction = value

    @property
    def method(self):
        return self.__method

    @method.setter
    def method(self, value):
        self.__method = value

    # PUBLIC METHODS
    def build(self):
        _method = self.method

        if _method == "DistMesh":
            print("Using the DistMesh method to generate mesh...")

        return 0
