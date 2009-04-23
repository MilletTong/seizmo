function [m,covm]=wlsi_wvary_lin1(x,y,vary,wp)
% PERFORMS WEIGHTED LEAST-SQUARES INVERSION TO FIND A LINEAR FIT TO X VS Y
%
% CASE:
% - PREDICTORS X ARE ASSUMED KNOWN
% - OBSERVATIONS Y ARE ESTIMATED WITH VARIANCES ASSUMED KNOWN
% - VARIANCES OF OBSERVATIONS Y ARE ASSUMED TO BE NORMAL
% - VARIANCES OF OBSERVATIONS Y ARE NOT CONSTANT
% - OBSERVATIONS Y ARE ASSUMED TO HAVE NO COVARIANCE
% - Y IS ASSUMED TO BE A LINEAR FUNCTION OF X OF ORDER 1
% - HIGHLY VARIANT OBSERVATIONS Y ARE NOT TRUSTED
%
% NOTES:
% - WP = 0 IS UNWEIGHTED CASE

% MAKE COLUMN VECTORS
x=x(:);
y=y(:);
vary=vary(:);

% NUMBER OF OBSERVATIONS
len=length(x);

% MAKE WEIGHTING MATRIX (WEIGHTS ARE INVERSE OF VARIANCE TO THE WP POWER)
W=sparse(1:len,1:len,1/vary.^wp,len,len);

% KERNEL MATRIX (SOLVE FOR THE SLOPE AND INTERCEPT)
G=[x ones(len,1)];

% WEIGHTED LEAST SQUARES INVERSION (SAVING GENERALIZED INVERSE)
Gg=inv(G.'*W*G)*G.'*W;
m=Gg*y;

% SET UP DATA COVARIANCE MATRIX (ASSUME NO COVARIANCE)
covd=diag(vary.^2);

% FIND MODEL COVARIANCE MATRIX
covm=Gg*covd*Gg.';

end