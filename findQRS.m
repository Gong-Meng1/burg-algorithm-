function [labelVals,labelLocs] = findQRS(x,t,parentLabelVal,parentLabelLoc,varargin)
% This is a template for creating a custom function for automated labeling
%
%  x is a matrix where each column contains data corresponding to a
%  channel. If the channels have different lengths, then x is a cell array
%  of column vectors.
%
%  t is a matrix where each column contains time corresponding to a
%  channel. If the channels have different lengths, then t is a cell array
%  of column vectors.
%
%  parentLabelVal is the parent label value associated with the output
%  sublabel or empty when output is not a sublabel.
%  parentLabelLoc contains an empty vector when the parent label is an
%  attribute, a vector of ROI limits when parent label is an ROI or a point
%  location when parent label is a point.
%
%  labelVals must be a column vector with numeric, logical or string output
%  values.
%  labelLocs must be an empty vector when output labels are attributes, a
%  two column matrix of ROI limits when output labels are ROIs, or a column
%  vector of point locations when output labels are points.

labelVals = cell(2,1);
labelLocs = cell(2,1);

if nargin<5
    Fs = 1.0/(t(2)-t(1));
else
    Fs = varargin{1};
end

df = 20;

load('trainedQTSegmentationNetwork','net')

for kj = 1:size(x,2)

    sig = x(:,kj);
      
    % Reshape input and compute Fourier synchrosqueezed transforms

    mitFSST = computeFSST(sig,Fs);
    
    % Use trained network to predict which points belong to QRS regions
    
    netPreds = classify(net,mitFSST,'MiniBatchSize',50);

    % Create a signal mask for QRS regions and specify minimum sequence length
    
    QRS = categorical([netPreds{1} netPreds{2}]',"QRS");
    msk = signalMask(QRS,"MinLength",df,"SampleRate",Fs);
    r = roimask(msk);
    
    % Label QRS complexes as regions of interest
    
    labelVals{kj} = r.Value;
    labelLocs{kj} = r.ROILimits;

end

labelVals = vertcat(labelVals{:});
labelLocs = cell2mat(labelLocs);

function signalsFsst = computeFSST(xd,Fs)
    
d = [normalize(xd);randn(2^nextpow2(length(xd))-length(xd),1)/100];
xd = reshape(d,length(d)/2,2);
signalsFsst = cell(1,2);    
    
for k = 1:2
    [ss,ff] = fsst(xd(:,k),Fs,kaiser(128));
    sp = ss(ff>0.5 & ff<=ff(21),:);
    signalsFsst{k} = normalize([real(sp);imag(sp)],2);
end

end
end