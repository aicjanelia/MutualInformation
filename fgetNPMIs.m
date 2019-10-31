% Calculates the *normalized* PMI values given a scatter plot
% pmis usually contains positive reals, negative reals, and NaNs

function [npmis] = fgetNPMIs(scatterplot) 

%Converts counts to observed probabilities
obsjpdf = scatterplot/sum(sum(scatterplot));

% Gets the marginal distributions
xpdf = sum(obsjpdf,1); % a row vector
ypdf = sum(obsjpdf,2); %  a column vector
	
% Joint PDF when outcomes independent
indjpdf = ypdf*xpdf; % a matrix

% pmis contains NaN where the ratio is undefined
pmis = obsjpdf.*(log2(obsjpdf./indjpdf)); % raw pmis

% ----- Normalization ----
% Drops zeros from the pdfs since the log of 'non-outcomes' is undefined
xpdf(xpdf == 0) = '';
ypdf(ypdf == 0) = '';

% Marginal informations	
xH = -sum(xpdf.*log2(xpdf));
yH = -sum(ypdf.*log2(ypdf));

minH = min([xH,yH]); % a single value

npmis = pmis./minH;

end