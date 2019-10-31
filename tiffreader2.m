function img = tiffreader2(filename,pathname)
%imports .tif file into matlab var space using the Tiff object library
%(faster than imread)

imginfo = imfinfo([pathname filename]);
w = imginfo(1).Width; h = imginfo(1).Height;
frames = length(imginfo);
img = zeros(h,w,frames);

tifobj = Tiff([pathname filename],'r');
for a = 1:frames
    tifobj.setDirectory(a)
    img(:,:,a) = tifobj.read();
    %warning('off','last');
end

tifobj.close();
