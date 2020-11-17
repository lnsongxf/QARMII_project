function [W,S,L] = SSA_TF(P,R, n, EIG, M, SIGN, varargin)

%INPUT

    % P : Matrix of Price
    % R : Matrix of Return
    % n : length of Forecastatility of Risk Parity
    % D1: Short MA
    % D2: Long MA
    % PW: Scaling 1
    % SW. Scaling 2
    % VARARGIN : Varagin arguments come by pair.
           %'Target' -> A volatility Target such a 15% (0.15)
           %'Quantity' -> A % of the max value for the signal (i.e the
           %number of assets).
           %'Forecast' -> A method. for now only "Garch"
        
% Varargin : 
% TODO : 

% 1. Case if no input in varargin
% 2. Implemting garch etc..
% 3. In the case of "Quantity" do we target the Forecastatility ?


%% Parameters

[T, A] = size(P);


% Find for available data
f = zeros(1,A); %Vector having each first available return

    for i = 1:A
        f(i) = find (~ isnan(P(:,i)), 1);
    end

% Preallocating the memory
W = zeros(round((T - M)/21, 0), A); %Weights
L = ones(round((T - M)/21, 0), 1); %Leverage
S = zeros(round((T - M)/21, 0), A); %Signal
position = 1; %allow for monthly rebalancing


%% Performing Allocation

for time = M+2:21:T
 
%Displaying position of the allocation
if mod(position, 20) == 0
    fprintf('Allocation %d over %d has been performed !\n',position, round((T-(M+2))/21));
end
% Find index of available assets at time "time"
available = f <= time - M; 
Ind = available==1;

% Define returns and prices to compute weights and signals
R_T = R(time-n+1:time,Ind); 
P_T = P(time-M:time,Ind); 

% Compute Grosse Weights
W(position, Ind) = volparity(R_T);

% Compute Signal
S(position, Ind) = SSA_Signal(EIG, P_T, M, SIGN);

% Advanced method
if strcmp(varargin(1), 'Target')
    % We are taking leverage to get a constant running Volatility
    W_T = W(position, Ind).*S(position, Ind);
    L(position) = cell2mat(varargin(2)) / (sqrt(W_T*cov(R_T)*W_T.')*sqrt(252));
    
elseif strcmp(varargin(1), 'Forecast')
    %Garch ,....l
    
    parameters = tarch(y,1,1,1);
    
elseif strcmp(varargin(1), 'Quantity') %We compute the quantity of trend 
    
    % Compute parameters
    QT = sum(abs(S(position, :)));
    TH = sum(available)*cell2mat(varargin(2));
    
    if mod(position,20) == 0
        fprintf('The number of asset is %d, the threshold is %.4g and the quantity of trend is %.4g !\n',...
            sum(available), TH, QT);   
        
    end
    if QT <= TH %if trend is smaller than threshold
        
        % We don't take any signal if there is not enough trend (long only)
        S(position, :) = 1;

        
        %{
    elseif QT > sum(available) - TH %Here we have a lot of trend
        
        % We increase our investment (we take massive directional bets)
        S(position, :) = S(position, :)*2;
        %}
    end
    
    if length(varargin) > 2
       
        % We are taking leverage to get a constant running Volatility
        W_T = W(position, Ind).*S(position, Ind);
        L(position) = cell2mat(varargin(3)) / (sqrt(W_T*cov(R_T)*W_T.')*sqrt(252));
        
    end
    
elseif strcmp(varargin(1), 'IndQuantity') %Indivual Trend Quantity
    
    TH = cell2mat(varargin(2));
    OUT = abs(S(position, :)) > TH;
    S(position, OUT==0) = abs(S(position, OUT==0)); 
    
    if mod(position,20) == 0
        fprintf(...
 'The number of asset is %d, the threshold is %.4g and the number of asset over the threshold are %d !\n',...
         sum(available), TH, sum(OUT));  
    end
    
    
    if length(varargin) > 2

    % We are taking leverage to get a constant running Volatility
    W_T = W(position, Ind).*S(position, Ind);
    L(position) = cell2mat(varargin(3)) / (sqrt(W_T*cov(R_T)*W_T.')*sqrt(252));

    end
    
else %Just signal
    
    QT = sum(abs(S(position, :)));
    TH = sum(available)*cell2mat(varargin(2));
    
    if mod(position,20) == 0
        fprintf('The number of asset is %d, the threshold is %.4g and the quantity of trend is %.4g !\n',...
            sum(available), TH, QT);   
        
    end
    if QT <= TH %if trend is smaller than threshold
        
        % We don't take any signal if there is not enough trend (long only)
        S(position, :) = abs(S(position, :)); 
        
    end
    
    W = ones(round((T - M)/21, 0), A); %Weights
    
    if length(varargin) > 2

    % We are taking leverage to get a constant running Volatility
    W_T = W(position, Ind).*S(position, Ind);
    L(position) = cell2mat(varargin(3)) / (sqrt(W_T*cov(R_T)*W_T.')*sqrt(252));

    end
    
    
end

% Go for next rebalancing
position = position + 1;
end 


end

