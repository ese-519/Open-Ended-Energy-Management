function [ result_matrix ] = mylagmatrix( X, Lags )
%MYLAGMATRIX Summary of this function goes here
%   Detailed explanation goes here

result_matrix = zeros(size(X,1), size(Lags, 2));

for n = Lags
   vector_NaN = NaN([n, 1], 'like', X);
   vector_X = X(1:end-n);
   result_matrix(:,n) = cat(1, vector_NaN, vector_X);
end

end

