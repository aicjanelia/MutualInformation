
% Anscscat bins span the PRE-DECONVOLUTION data (ansc photons detected) on each axis and in general the anscscat is rectangular
	% After deconvolution, the data generally occupies as smaller range; only a portion of anscscat, because the noise has been removed
	% Thus, at least some of the large value bins in 64x64 intscat remain empty (zeros)
		% This property is convenient for display (because the inscat axes remain proportional to the initial scatter plot axes)
		% For PMI/MI calculations, the span of the (deconned) data itself should be 64x64 binned.
function [phintscat, phintscatXedgs, phintscatYedgs] = fAnscScatToIntScat3(anscscat, anscXedgs, anscYedgs) 

% Note that anscXedgs corresponds to ROW indices and anscYedgs to COL indices because these were produced by histscounts2
% bin# = edg#-1; k falls into a bin if upper_bin_edg > k >= lower_bin_edg EXCEPT for the last bin where the upper bin edge is included

% Flips the axis conventions to avoid confusion e.g. makes 'y' represent a row index and 'x' col index per usual
xx = anscXedgs;
yy = anscYedgs;	
anscXedgs = yy;
anscYedgs = xx;

% --------- Preparations for inverse transform----------
% Finds the (round) max number of photons (ints) along each axis that fall within anscscat
maxintX = floor(invanscombe(anscXedgs(end))); % round down so ints don't fall beyond Ansc vals
maxintY = floor(invanscombe(anscYedgs(end)));

% The Anscombe edges/bins were designed to always hold at least one photon
intbin = 1;
% A set of integers (photons) that cover the ranges in the Ansc plot
intXedgs = [1:intbin:maxintX];
intYedgs = [1:intbin:maxintY];
% The Ansc values that correspond to these integers (and so can be immediately located along the Ansc plot axes)
anscintXedgs = anscombe(intXedgs);
anscintYedgs = anscombe(intYedgs);
% Vectors that hold the Ansc plot indices (bins #) where the anscintedgs fall
xAnsScatIndices = zeros(1,maxintX);
yAnsScatIndices = zeros(1,maxintY);

% ---------- Inverse transformation of anscscat --------------
% Finds the ansc index (bin #) that holds each anscintedgs
for i = 1:intbin:maxintX
	xAnsScatIndices(i) = find(anscXedgs < anscintXedgs(i),1,'last');
end
for j = 1:intbin:maxintY
	yAnsScatIndices(j) = find(anscYedgs < anscintYedgs(j),1,'last');
end

% Assigns values from anscscat to appropriate locations (indexes) in intscat
intscat = zeros(maxintY,maxintX); % initialization
for x = 1:intbin:maxintX % column index
	for y = 1:intbin:maxintY % row index
	
		intscat(y,x) = anscscat(yAnsScatIndices(y),xAnsScatIndices(x));
		
	end
end

% At this point the photon inscat is generally rectangular and has arbitrary dimensions
% Some of the ints also correspond to Ansc values where the transform is inaccurate

% --------- Rebinning of Int scatterplot to ~64x64 plot -------------
% Calculation of blksizes
% 64x64 binning OF DATA geared to represent the underlying inverse transform Ansc data, which is inherently blocky

% Locates empty rows/cols in intscat so the data itself will be split into exactly 64x64
	% MAXDATA are the largest number of INT PHOTONS along each axis
[maxdataX, maxdataY] = dataextent(intscat);

% Since MAXDATA is generally only a bit bigger than 64, blocking intscat up into integer bins directly led to huge rounding errors (e.g. blksize 1 vs 2, or 2 vs 3).
% To avoid these rounding problems, inscat is resized by imgscale (10x) and then blocked up accordingly so that rounding errors change blksize by <10%.
imgscale = 10;
bigintscat = imresize(intscat,imgscale,'nearest');

% Set blksizes = 10 to avoid rebinning completely
% Change 10*maxdataX/Y to 10*maxintX/Y to block the entire extent of the axes into 64x64
% If maxdata < 64, there is not enough data for further calcuations!
	% If blksizes differ by more than 2x or the rebinning looks very stretched, but that is just what the data requires
xblksize = round(imgscale*maxdataX/64);
yblksize = round(imgscale*maxdataY/64);

% Final cintscat will generally be > 64x64 since regions that do not contain data are also included
% Partial blocks are processed 'as-is'
blktot = @(block_struct) sum(sum(block_struct.data,'native'),'native'); % sum of all values in a block. block_struct is a required data handle.
cintscat = blockproc(bigintscat,[yblksize xblksize], blktot);

% The edge labels for cintscat
cxblksz = xblksize/imgscale;
cyblksz = yblksize/imgscale;
cintXedgs = cxblksz:cxblksz:maxintX;
cintYedgs = cyblksz:cyblksz:maxintY;

% ----- Removal of inaccurately transformed values -----
% Sets to zero those bins that correspond to an outcome of < 10 photons = 6 Ansc units
cintXcut = find(cintXedgs < 10,1,'last');
cintYcut = find(cintYedgs < 10,1,'last'); 
cintscat(1:cintYcut,:) = 0; % x axis is a column number
cintscat(:,1:cintXcut) = 0;

% --- Final returned matrix ---
% NOTE THESE INT CORRESPOND TO A NUMBER OF PHOTONS
phintscat = cintscat;
phintscatXedgs = cintXedgs;
phintscatYedgs = cintYedgs;


% ------------ Internal Functions ------------------

function [anscvals] = anscombe(vals)

	anscvals = 2*((vals+0.375).^(0.5));

end

function [vals] = invanscombe(anscvals)

	vals = ((anscvals/2).^(2))-0.375;
	
end

function [maxdataX, maxdataY] = dataextent(anscscat) 

% Identifies 'high index' rows/columns in anscscat that are empty
	% This is done so that exactly the range of the 'main' data itself will be split into 64x64 and a sparse outlying point will be excluded
	maxrow = size(anscscat,1);
	maxcol = size(anscscat,2);
	
	for a = 1:1:maxrow
		aind = (maxrow+1)-a;
		atot = sum(anscscat(aind,:),'omitnan');
		if (atot > 0.02) % Did not use zero because otherwise single, 'noise' pixels can through it off
			% Record the first index where the row is not 'empty'
			maxdataY = aind;
			break % breaks out of loop
		end
	end	
	for b = 1:1:maxcol
		% Searches until at least one of the rows/cols contains data
		bind = (maxcol+1)-b;
		btot = sum(anscscat(:,bind),'omitnan');
		if (btot > 0.02)
			% Record the first index where the column is not empty
			maxdataX = bind;
			break % breaks out of loop
		end
	end
	
	
end


end