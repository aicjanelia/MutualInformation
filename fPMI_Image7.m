% Takes two 8-bit images and a scattervals matrix and codes the image pixels according to the scattervals levels
% This is a total re-write based how Jess did it.  MUCH FASTER.
% The axes of Scattervals are assumed to span 0-255 (256 values), although the actual # rows and columns can be different.  ORGIN MUST  BE IN UPPER LEFT CORNER
	% The 256 span is required since the image intensities to map are 8-bit
	% Image1 values are represented along the scattervals x-axis
% The images must be 8-bit so that scatterplot axes correspond to image intensity levels

function [pmiimg] = fPMI_Image7(image1, image2, scattervals) 

% Keeps only the intersection of the images (intensity combos where both values are > 0)
	% PMIs can only exist over the intersection and the scatterplot of these images must reflect that
image1(image2 == 0) = 0;	
image2(image1 == 0) = 0;
% At this point image pixel combinations are either (0,0) or (>0,>0).

% Scattervals is typically the ESTNPMIfd plot but could be any matrix of any dimensions and values
	% It would be modestly (~4x) faster to process the raw ESTNPMI first and then scale it up last here
	% The below code scales the 8-bit image intensities onto the axes of the scattervals matrix

% The x and y bins of scattervals - typically 256x256 but not necessarily
svxmax = size(scattervals,2);
svymax = size(scattervals,1);
xbinscat = 1:1:svxmax;
ybinscat = 1:1:svymax;

% Scales the image intensities to fall within the corresponding axes of scattervals
	% Image1 corrsponds to the x-axis of scattervals
xscale = svxmax / 256; % images have a possible int range of 0-255
yscale = svymax / 256;
scimage1 = image1.*xscale;
scimage2 = image2.*yscale;

% An estNPMI plot contains values that are positive, zero, and NaN
% Interp2 and other functions can not work with NaNs, so they are handled separately (to distinguish from genuine 0)
nansarray = isnan(scattervals);
nanval = -0.00001; % change as desired

% Smoothing of scattervals (NaNs treated as zero for speed)
% A non-smooth NPMI plot is the main problem to solve because that affect 100% of pixels in the coded image
scattervals(nansarray) = 0;
smscattervals = imgaussfilt(scattervals,2); % Filter size depends on scattervals size...change as needed

% Transforms NPMI values to make the final NPMI coded image histogram more uniform
	% This is analogous to the sqrt applied during the AMI calculation
smtscattervals = sqrt(smscattervals); % all input >= 0
% Adds back nans
smtscattervals(nansarray) = nanval;

% Corresponding elements of xmesh and ymesh form the 2D grid of order pairs
[ymesh,xmesh] = meshgrid(xbinscat,ybinscat);
% ymesh, xmesh, and scattervals are all the same size. Image1 corrsponds to the x-axis of scattervals
	% Extrapolated regions return -1 to be consistent with above definition of NaN
pmiimg1 = interp2(ymesh,xmesh,smtscattervals,scimage2(:),scimage1(:),'nearest',nanval);

% The returned PMI Image
% The initially sampled points are along column vectors
pmiimg = reshape(pmiimg1,size(image1,1),size(image1,2));


end
