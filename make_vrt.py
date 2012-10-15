#make_vrt.py - read a raw filename of the form filename_widthXheight.raw and write out a 
#              matching vrt file to be used with gdal.
# This is brittle, no error checking...sorry.

import sys
import re

filename = sys.argv[1]
print "filename: %s" % filename
m = re.search("(\d+)x(\d+)\.raw",filename)
width  = m.group(1)
height =  m.group(2)
line_offset = int(width)*3
m = re.search("(.+)\.raw",filename)
vrtfilename = "%s.vrt" % m.group(1)

st = """<VRTDataset rasterXSize="%s" rasterYSize="%s">
  <VRTRasterBand dataType="Byte" band="1" subClass="VRTRawRasterBand">
    <ColorInterp>Red</ColorInterp>
    <SourceFilename relativetoVRT="1">%s</SourceFilename>
    <ImageOffset>0</ImageOffset>
    <PixelOffset>3</PixelOffset>
    <LineOffset>%s</LineOffset>
  </VRTRasterBand>
  <VRTRasterBand dataType="Byte" band="2" subClass="VRTRawRasterBand">
    <ColorInterp>Green</ColorInterp>
    <SourceFilename relativetoVRT="1">%s</SourceFilename>
    <ImageOffset>1</ImageOffset>
    <PixelOffset>3</PixelOffset>
    <LineOffset>%s</LineOffset>
  </VRTRasterBand>
  <VRTRasterBand dataType="Byte" band="3" subClass="VRTRawRasterBand">
    <ColorInterp>Blue</ColorInterp>
    <SourceFilename relativetoVRT="1">%s</SourceFilename>
    <ImageOffset>2</ImageOffset>
    <PixelOffset>3</PixelOffset>
    <LineOffset>%s</LineOffset>
  </VRTRasterBand>
</VRTDataset>
""" % (width, height, filename, line_offset, filename, line_offset, filename, line_offset)

f = open(vrtfilename, 'w')
f.write(st)
f.close
