//+------------------------------------------------------------------+
//|                        EMA Scalping Bot for MT5                 |
//|                      Combines EMA Crossover + SL/TP             |
//+------------------------------------------------------------------+
input int      FastEMAPeriod     = 7;
input int      SlowEMAPeriod     = 14;
input double   TakeProfitPercent = 2.0;   // TP in %
input double   StopLossPercent   = 1.0;   // SL in %
input double   TrailingStopPercent = 0.5; // Trailing Stop in %
input double   LotSize           = 0.01;

int fastEMABuffer, slowEMABuffer;
double prevFastEMA, prevSlowEMA;
bool  inTrade = false;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("EMA Scalping Bot Initialized");
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   double fastEMA = iMA(NULL, 0, FastEMAPeriod, 0, MODE_EMA, PRICE_CLOSE, 0);
   double slowEMA = iMA(NULL, 0, SlowEMAPeriod, 0, MODE_EMA, PRICE_CLOSE, 0);
   prevFastEMA = iMA(NULL, 0, FastEMAPeriod, 0, MODE_EMA, PRICE_CLOSE, 1);
   prevSlowEMA = iMA(NULL, 0, SlowEMAPeriod, 0, MODE_EMA, PRICE_CLOSE, 1);

   double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   // Buy Signal: Fast EMA crosses above Slow EMA
   if (prevFastEMA < prevSlowEMA && fastEMA > slowEMA && !PositionSelect(_Symbol))
   {
      OpenTrade(ORDER_TYPE_BUY, price);
   }

   // Sell Signal: Fast EMA crosses below Slow EMA
   if (prevFastEMA > prevSlowEMA && fastEMA < slowEMA && !PositionSelect(_Symbol))
   {
      OpenTrade(ORDER_TYPE_SELL, price);
   }
}

//+------------------------------------------------------------------+
//| Open Trade with SL/TP/Trailing                                  |
//+------------------------------------------------------------------+
void OpenTrade(int direction, double price)
{
   double tpLevel = 0;
   double slLevel = 0;
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double pipMultiplier = SymbolInfoInteger(_Symbol, SYMBOL_DIGITS) == 3 || SymbolInfoInteger(_Symbol, SYMBOL_DIGITS) == 5 ? 10 : 1;

   double slPoints = (price * StopLossPercent / 100.0) / point;
   double tpPoints = (price * TakeProfitPercent / 100.0) / point;
   double tsPoints = (price * TrailingStopPercent / 100.0) / point;

   if (direction == ORDER_TYPE_BUY)
   {
      tpLevel = price + tpPoints * point;
      slLevel = price - slPoints * point;
   }
   else
   {
      tpLevel = price - tpPoints * point;
      slLevel = price + slPoints * point;
   }

   trade.PositionOpen(_Symbol, direction, LotSize, price, slLevel, tpLevel);
   if (TrailingStopPercent > 0)
   {
      trade.TrailingStop(_Symbol, tsPoints);
   }
}

//+------------------------------------------------------------------+
//| Global CTrade instance                                           |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
CTrade trade;
