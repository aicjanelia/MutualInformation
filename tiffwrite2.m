function tiffwrite2(img,pathsave,filesave,bits,normalize)

if nargin < 3
    normalize = 0;
end

if isa(img,'gpuArray')
    img = gather(img);
end

if normalize
    img = img/max(img(:))*(2^bits-1);
end

options.message = true; 
options.append = false;
options.comp = 'no';
options.color = false;
options.ask = false;



if bits == 8
     saveastiff(uint8(img), fullfile(pathsave,filesave), options);
elseif bits == 16
     saveastiff(uint16(img), fullfile(pathsave,filesave), options);
elseif bits == 32
     saveastiff(single(img), fullfile(pathsave,filesave), options);
end