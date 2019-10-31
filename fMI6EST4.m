% This code is for application to images that contain Poisson noise.
% The image's hisograms must also be 'smooth', i.e. can not contain interleaved empty bins, or the deconvolution won't work

function [ami, disppmis] = fMI6EST4(img1, img2, ch1gain, ch2gain) 

% Int to photon conversion... Intensity is == photons when intscale = 1
intscale1 = ch1gain; % units of photons per intensity - USER INPUT
intscale2 = ch2gain; % USER INPUT

image1 = img1;
image2 = img2;

% Removes saturated pixels (255,y) or (x,255)
image1(image1 == 255) = 0;
image2(image2 == 255) = 0;

% Scales intensities into photons...
phimg1 = intscale1*image1;
phimg2 = intscale2*image2;

% Takes the intersection of the images (keeps only pairs where both values are > 0)
phimg1(phimg2 == 0) = 0;	
phimg2(phimg1 == 0) = 0;

% The zero value locations need to stay zero value, so this logical mask is needed after some calculations
zmask = phimg1;
zmask(zmask > 0) = 1; % Zeros stay as zeros, >0 values set to 1

% -------------- Anscombe transform of photon values ---------------
% Converts discrete photon values into a continuous range to avoid binning artifacts after the AnscTrans
	% Some values will get split across multiple bins, but that is OK because...
	% A. There will be a deconvolution step
	% B. There will be final, coarse, re-binning
% Note zeros are converted to a small pos value - this must be undone later with the mask
crphimg1 = phimg1 + (intscale1*rand(size(phimg1))); % rand() is 0-1
crphimg2 = phimg2 + (intscale2*rand(size(phimg2)));

% Anscombe Transform images to stabilize variance...
	% Note that AnscTrans of 0 is 1.22 - introduction of these spurious positive values must be undone later with a mask
anscimg1 = anscombe(crphimg1);
anscimg2 = anscombe(crphimg2);

% Brings back the zero value positions...
anscimg1 = zmask.*anscimg1; % Elementwise array multiplication!
anscimg2 = zmask.*anscimg2;

% Scatter plot of Anscombe transformed images... 

% Sets up the Ansc histogram bins.  Axes must extend from #ph=0 to #ph=max(phimg)
bw = 0.10; % FIXED - Do not change
% Sets X bin limits...
xbinmin = 1.20; % Fixed LHS edge; Note Ansc(0)=1.20
% Finds an RHS edge that is greater than the data and a multiple of bw...
anscimg1max = max(anscimg1(:));
xbinmax = ceil((anscimg1max*10))/10; % rounds up to nearest tenth ansc unit (bw)
% Sets Y bin limits...
ybinmin = 1.20; % Fixed LHS edge; Catches the Ansc(0) value
% Finds an RHS edge that is greater than the data and a multiple of bw...
anscimg2max = max(anscimg2(:));
ybinmax = ceil((anscimg2max*10))/10; 

% *Edgs and BinLimits are RELATIVE TO HOW THE HISTOGRAM IS DISPLAYED (rotated 90d ccw), e.g. X-axis/Xedgs correspond to ROWs of anschist; The first vector is displayed along the x-axis
	% The origin of anschist is still the upper left as for all matrices
[anschist,anscXedgs,anscYedgs] = histcounts2(anscimg1,anscimg2,'BinWidth',[bw bw],'XBinLimits',[xbinmin xbinmax],'YBinLimits',[ybinmin ybinmax]);
anschist(1,1) = 0; % Gets rid of counts corresponding to zero photons.

% 'Decompresses' the Ansc scatterplot based on the slope of the AnscTrans to estimate the photon data compression...
	% Could also develop a specific decompression function for strong linear correlations
xedg = invanscombe(anscXedgs); 
yedg = invanscombe(anscYedgs);
manscx = anscslope(xedg);
manscy = anscslope(yedg);
decomp = transpose(manscx)*manscy; % A 2D matrix of decompression factors
% There are 1 more bin edges than there are bins.  Decomp dim's must be reduced by 1 before it can be applied to bins.
	% Dropping the first column and last row best aligns the remaining results with the other histogram bins
decomp(:,1) = [];
decomp(size(decomp,1),:) = [];

% This could also be used to produce a warning when there is insufficient data for PMI...
% Calculates SNR in the Ansc hist as a basis for determining the number of deconvolution iterations...
danschist = double(anschist);
meananschist = imboxfilt(danschist); % 3x3 mean filter
stdevanschist = stdfilt(danschist); % Often these are NaN BUT CAN BE ZERO
stdevanschist(stdevanschist == 0) = NaN;  % Sets zero stdevs to nan
snrgraph = meananschist./stdevanschist;
fsnrgraph = snrgraph.*(double(~isnan(snrgraph))); % Keeps only values that are NOT NaNs 
snrmask = fsnrgraph > 0; % Mask of positive snr values
totsnr = sum(sum(snrgraph(snrmask)));
numsnr = sum(sum(snrmask));
avgsnr = totsnr/numsnr; % avg snr where mean is > 0

% -------R-L Deconvolution--------
	% Note that if the images do not contain Poisson noise, deconvolution will take out real spread in the data
% Number of iterations is set based on a linear function of the above SNR estimate. Seems to work great - Theoretically kosher?
itnum = ceil(3*avgsnr); % This function will need some calibration to ground truths for sure
kernsig = 1/bw; 
kernsize = floor(8*kernsig); % Diameter of the kernel should be roughly 8 NSF stdevs
kernel = fspecial('gaussian', kernsize, kernsig);
deconanschist = deconvlucy(anschist, kernel, itnum);

% Applies decompression factors to the deconed scatterplot...
% The decompression is merely a convenience that makes it easy to take the Ansc scatter back into intensity space
	% An alternative would be to instead divide out each Ansc value when making the final intensity histogram
decompanschist = decomp.*deconanschist; % Elementwise

%Coverts the decomp Ansc Scatter into an an Int Scatter
	% **Currently the corresponding int edges are not returned, but eventually they need to be
	% NOTE THESE INTS CORRESPOND TO A NUMBER OF PHOTONS - They need to be scaled back into intensities before PMI coding can work
[phintscat, phintscatXedgs, phintscatYedgs] = fAnscScatToIntScat3(decompanschist, anscXedgs, anscYedgs);

%Calculates estimated PMIs from the inverse transformed int PHOTON scatter plot
epmis = fgetNPMIs(phintscat);

% Adjusted MI
% The 2x is motivated by the MI that is measured (0.47) on the smallest stdev gaussian that can be accurately represented on the 64x64 grid
% The sqrt is motivated by wanting the meausurement to reflect magnitude of linear displacement rather than mag of areal increase
rawmi = sum(epmis(:),'omitnan');
% RETURNED
ami = sqrt(2*rawmi);

% Keeps only POSITIVE PMI values
posepmis = epmis.*(epmis > 0);

% Scales photons back into arbitrary integers for display and NPMI coding purposes
	% These are the axis labels on posepmis
	% In general the intscatXedges will be fractional
	% The axis labels must be passed to the NPMI coding....
intscatXedgs = phintscatXedgs./intscale1;
intscatYedgs = phintscatYedgs./intscale2;

% ---------- Adds padding as needed so the final plot covers an intensity range of 256x256 for NPMI Coding-------
	% The size() of the plot will NOT be 256x256, but some multiple of that (based on bin sizes)
inscatXbw = intscatXedgs(2)-intscatXedgs(1);
inscatYbw = intscatYedgs(2)-intscatYedgs(1);	
intscatXmax = intscatXedgs(end);
intscatYmax = intscatYedgs(end);
% The amount of padding to add
padx = round((255-intscatXmax)/inscatXbw);
pady = round((255-intscatYmax)/inscatYbw);
% Does the padding with NaN
padposepmis = padarray(posepmis,[pady padx],NaN,'post');

% disppmi is ~256x256 based on edge labels but bin widths are generally anisotropic so pixel dimensions are not square

% -------- Generate a square, 256x256 NPMI for display ------------
% RETURNED
disppmis = imresize(padposepmis,[256 256],'nearest');  

end



% ------ FUNCTIONS----------

function [anscvals] = anscombe(vals)

	anscvals = 2*((vals+0.375).^(0.5));

end

function [vals] = invanscombe(anscvals)

	vals = ((anscvals/2).^(2))-0.375;
	
end


function [slopes] = anscslope(vals)

	slopes = ((vals + 0.375).^(-0.5));
	
end

