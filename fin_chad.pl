%ASSET LIST
 
asset(
     name(bitcoin),
     ticker('BTC'),
     purchase_price(10),
     units(100)
     ).
 
asset(
     name('Lehman Brothers Holdings Inc.'),
     ticker('LEH'),
     purchase_price(1),
     units(1000)
     ).
 
asset(
     name('Deutsche Bank AG'),
     ticker('DB'),
     purchase_price(5),
     units(200)
     ).
     
asset(
     name('Enron'),
     ticker('ENE'),
     purchase_price(1000000),
     units(200)
     ).
     
%CURRENT PRICE DATA
 
current_price_data([asset(ticker('DB'),  price(10)),
                    asset(ticker('LEH'), price(1)),
                    asset(ticker('BTC'), price(10)),
		    asset(ticker('ENE'), price(0.000001))]).
 
%RISK TOLERANCE PROFILES DATA
 
risk_tolerance_profile(
                      name('takeprofitnoliquidity'),
                      takeprofitpercent(150),
      				  liquiditydemand('LOW'),
                      maxportfolioshare(2)    
                      ).
 
risk_tolerance_profile(
                      name('takeprofitcapneeded'),
                      takeprofitpercent(150),
      				  liquiditydemand('URGENT'),
                      maxportfolioshare(51)    
                      ).
 
%active_rtp(takeprofitnoliquidity).
 
active_rtp(takeprofitcapneeded).
 
 
%HELPER RULES
 
portfolio_total(Total) :- 
    aggregate_all(sum((Price*Units)), 
                  (asset(_,ticker(Ticker),_,units(Units)),
                   current_price_data(LIST),
				   member(asset(ticker(Ticker), 
                   price(Price)), LIST)), 
                  Total).
 
 
%%SELL RULES
 
sell_rule(test,Arg):- [A1,A2]=Arg,
    	 nl,write('[sell_rule(test)]-> Arg1 is: '),write(A1),
         nl,write('[sell_rule(test)]-> Arg2 is: '),write(A2),
         nl,write('[sell_rule(test)]-> THE answer is: '),write('42').
 
sell_rule(takeprofit, Arg):- 
    [Purchse_price, Current_price, TakeprofitPercent, Gain] = Arg,
    Gain is (Current_price*100)/Purchse_price,Gain > TakeprofitPercent, 
    nl,write('[sell_rule(takeprofit)]-> Gain is: '),write(Gain),write('%').
 
sell_rule(diversify, Arg):- 
    	 [Maxportfolioshare,Current_price, Units, TotalPortfolio]=Arg,
         PortfolioShare is Current_price * Units,
         PortfolioSharePercent is (PortfolioShare*100/TotalPortfolio),
         PortfolioSharePercent > Maxportfolioshare, 
         nl,write('[sell_rule(diversify)]-> PortfolioShare is: '), write(PortfolioShare),
    	 nl,write('[sell_rule(diversify)]-> PortfolioSharePercent is: '), write(PortfolioSharePercent),write('%'),
         nl,write('[sell_rule(diversify)]-> Totalportfolio is: '), write(TotalPortfolio),
 		 nl,write('[sell_rule(diversify)]-> DIVIRSIFY!').
 
sell_rule(liquidity, Arg):- 
         [LiquidityDemand|_]=Arg,
    	 (LiquidityDemand = 'URGENT';
         LiquidityDemand = 'HIGH'),
    	 nl,write('[sell_rule(liquidity)]-> LiquidityDemand is: '), write(LiquidityDemand),
         nl,write('[sell_rule(liquidity)]-> Sell asset!').
 
 
%%SELL TACTICS
 
tactic(takeprofit, Asset_ticker) :- 
      %Assemble relative arguments 
      asset(_,ticker( Asset_ticker),purchase_price(Purchse_price),_),
      current_price_data(PRICELIST),
	  member(asset(ticker(Asset_ticker), price(Current_price)), 
             PRICELIST),
      %Retrive TakeprofitPercent from risk_tolerance_profile,
      active_rtp(RTPNAME),
      risk_tolerance_profile(
          name(RTPNAME),
          takeprofitpercent(TakeprofitPercent),_,_),
      %Evaluate tactic rules
      Rules= [test, takeprofit],
      Args = [[1,2],[Purchse_price,Current_price,TakeprofitPercent,_]],
      maplist(sell_rule(),Rules,Args).
 
tactic(takeprofitIFneeded, Asset_ticker) :- 
      %Assemble relative arguments 
      asset(_,ticker( Asset_ticker),purchase_price(Purchse_price),_),
      current_price_data(PRICELIST),
	  member(asset(ticker(Asset_ticker), price(Current_price)), 
             PRICELIST),
      %Retrive TakeprofitPercent from risk_tolerance_profile,
      %Retrive LiquidityDemand from risk_tolerance_profile,
      active_rtp(RTPNAME),
      risk_tolerance_profile(
          name(RTPNAME),
          takeprofitpercent(TakeprofitPercent),liquiditydemand(LiquidityDemand),_),
      %Evaluate tactic rules
      Rules= [liquidity, takeprofit],
      Args = [[LiquidityDemand],[Purchse_price,Current_price,TakeprofitPercent,_]],
      maplist(sell_rule(),Rules,Args).
 
tactic(diversify, Asset_ticker) :-
      
      active_rtp(RTPNAME),
      risk_tolerance_profile(name(RTPNAME),_,_,
                             maxportfolioshare(Maxportfolioshare)),
      asset(name(Name),ticker( Asset_ticker),_,units(Units)),
      current_price_data(PRICELIST),
	  member(asset(ticker(Asset_ticker), price(Current_price)), 
             PRICELIST),
      portfolio_total(TotalPortfolio),
      Arg=[Maxportfolioshare,Current_price, Units, TotalPortfolio],
      write('Asset name: '),write(Name),
      sell_rule(diversify, Arg).
            
%BUY TACTICS
 
 
%EXECUTE STRATEGY
 
 
sell_asset(Asset_ticker):- 
    tactic(takeprofit,Asset_ticker); 
    tactic(diversify, Asset_ticker).
