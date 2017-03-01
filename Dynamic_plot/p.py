import vtk
from numpy import random, genfromtxt, size
import os


class VtkPointCloud:
    def __init__(self, zMin=-10.0, zMax=10.0, maxNumPoints=1e6):
        self.maxNumPoints = maxNumPoints
        self.vtkPolyData = vtk.vtkPolyData()
        self.clearPoints()
        mapper = vtk.vtkPolyDataMapper()
        mapper.SetInput(self.vtkPolyData)
        mapper.SetColorModeToDefault()
        mapper.SetScalarRange(zMin, zMax)
        mapper.SetScalarVisibility(1)
        self.vtkActor = vtk.vtkActor()
        self.vtkActor.SetMapper(mapper)

    def addPoint(self, point):
        if self.vtkPoints.GetNumberOfPoints() < self.maxNumPoints:
            pointId = self.vtkPoints.InsertNextPoint(point[:])
            self.vtkDepth.InsertNextValue(point[2])
            self.vtkCells.InsertNextCell(1)
            self.vtkCells.InsertCellPoint(pointId)
        else:
            r = random.randint(0, self.maxNumPoints)
            self.vtkPoints.SetPoint(r, point[:])
        self.vtkCells.Modified()
        self.vtkPoints.Modified()
        self.vtkDepth.Modified()

    def clearPoints(self):
        self.vtkPoints = vtk.vtkPoints()
        self.vtkCells = vtk.vtkCellArray()
        self.vtkDepth = vtk.vtkDoubleArray()
        self.vtkDepth.SetName('DepthArray')
        self.vtkPolyData.SetPoints(self.vtkPoints)
        self.vtkPolyData.SetVerts(self.vtkCells)
        self.vtkPolyData.GetPointData().SetScalars(self.vtkDepth)
        self.vtkPolyData.GetPointData().SetActiveScalars('DepthArray')


def load_data(filename, pointCloud):
    data = genfromtxt(filename,delimiter=',' ,dtype=float, usecols=[0, 1, 2])

    for k in xrange(size(data, 0)):
        point = data[k]  # 20*(random.rand(3)-0.5)
        pointCloud.addPoint(point)

    return pointCloud


if __name__ == '__main__':
    import sys

    if len(sys.argv) < 2:
        print
        'Usage: xyzviewer.py itemfile'
        sys.exit()
    pointCloud = VtkPointCloud()
    pointCloud = load_data(sys.argv[1], pointCloud)

    # Renderer
    renderer = vtk.vtkRenderer()
    # render= vtk.vtkPolyDataMapper()
    renderer.AddActor(pointCloud.vtkActor)
    # renderer.SetBackground(.2, .3, .4)
    renderer.SetBackground(0.0, 0.0, 0.0)
    renderer.ResetCamera()

    # Render Window
    renderWindow = vtk.vtkRenderWindow()
    renderWindow.AddRenderer(renderer)

    # Interactor
    renderWindowInteractor = vtk.vtkRenderWindowInteractor()
    renderWindowInteractor.SetRenderWindow(renderWindow)

    # Begin Interaction
    renderWindow.Render()
    renderWindow.SetWindowName("XYZ Data Viewer:   " + sys.argv[1])

    render_window = vtk.vtkRenderWindow()

    render_window.AddRenderer(renderer)

    render_window_interactor = vtk.vtkRenderWindowInteractor()
    render_window_interactor.SetInteractorStyle(vtk.vtkInteractorStyleTrackballCamera())
    render_window_interactor.SetRenderWindow(render_window)

    '''Add camera coordinates'''
    axes = vtk.vtkAxesActor()
    widget = vtk.vtkOrientationMarkerWidget()
    widget.SetOutlineColor(0.9300, 0.5700, 0.1300)
    widget.SetOrientationMarker(axes)
    widget.SetInteractor(render_window_interactor)
    widget.SetViewport(0.0, 0.0, 0.4, 0.4)
    widget.SetEnabled(1)
    widget.InteractiveOn()
    render_window.Render()

    renderWindowInteractor.Start()

    pointCloud.clearPoints()
    pointCloud = load_data(sys.argv[2], pointCloud)
    renderer.AddActor(pointCloud.vtkActor)
    render_window.Render()
