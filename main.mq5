//+------------------------------------------------------------------+
//|                                             EMA_Crossover_EA.mq5|
//|                             Adapted by ChatGPT                  |
//+------------------------------------------------------------------+
#property copyright "ChatGPT"
#property version   "1.00"
#property strict

input int    fastEMALen     = 7;
input int    slowEMALen     = 14;
input double riskPercent    = 10.0;    // Risk % of balance per trade
input int    slippage       = 5;
input ulong  magicNumber    = 123456;

double emaFastPrev, emaSlowPrev;
string symbol;
ENUM_TIMEFRAMES tf;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   symbol = _Symbol;
   tf = PERIOD_CURRENT;
   return INIT_SUCCEEDED;
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   double emaFast = iMA(symbol, tf, fastEMALen, 0, MODE_EMA, PRICE_CLOSE, 0);
   double emaSlow = iMA(symbol, tf, slowEMALen, 0, MODE_EMA, PRICE_CLOSE, 0);

   bool buySignal  = (emaFast > emaSlow) && (emaFastPrev <= emaSlowPrev);
   bool sellSignal = (emaFast < emaSlow) && (emaFastPrev >= emaSlowPrev);

   if (buySignal)
     {
      CloseOpenOrders(); // Close opposite
      OpenOrder(ORDER_TYPE_BUY);
     }
   else if (sellSignal)
     {
      CloseOpenOrders(); // Close opposite
      OpenOrder(ORDER_TYPE_SELL);
     }

   emaFastPrev = emaFast;
   emaSlowPrev = emaSlow;
  }

//+------------------------------------------------------------------+
//| Open Market Order                                                |
//+------------------------------------------------------------------+
void OpenOrder(ENUM_ORDER_TYPE orderType)
  {
   MqlTradeRequest request;
   MqlTradeResult  result;

   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double lotStep = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
   double minLot  = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
   double maxLot  = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);

   // Dynamic Lot Size Calculation
   double calcLot = (balance * riskPercent / 100.0) / 100.0;
   double lotSize = MathMax(minLot, MathMin(maxLot, NormalizeDouble(calcLot, 2)));

   ZeroMemory(request);
   request.action   = TRADE_ACTION_DEAL;
   request.symbol   = symbol;
   request.volume   = lotSize;
   request.type     = orderType;
   request.price    = (orderType == ORDER_TYPE_BUY) ? SymbolInfoDouble(symbol, SYMBOL_ASK)
                                                    : SymbolInfoDouble(symbol, SYMBOL_BID);
   request.slippage = slippage;
   request.magic    = magicNumber;

   OrderSend(request, result);

   if (result.retcode != TRADE_RETCODE_DONE)
      Print("Order send failed: ", result.comment);
   else
      Print("Opened ", (orderType == ORDER_TYPE_BUY ? "BUY" : "SELL"), 
            " at ", request.price, " with lot: ", lotSize);
  }

//+------------------------------------------------------------------+
//| Close Existing Orders                                            |
//+------------------------------------------------------------------+
void CloseOpenOrders()
  {
   for (int i = OrdersTotal() - 1; i >= 0; i--)
     {
      if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;

      if (OrderGetInteger(ORDER_MAGIC) != magicNumber ||
          OrderGetString(ORDER_SYMBOL) != symbol) continue;

      ENUM_ORDER_TYPE orderType = (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
      double volume = OrderGetDouble(ORDER_VOLUME_CURRENT);
      ulong ticket  = OrderGetTicket();

      MqlTradeRequest request;
      MqlTradeResult  result;
      ZeroMemory(request);

      request.action = TRADE_ACTION_DEAL;
      request.position = ticket;
      request.symbol = symbol;
      request.volume = volume;
      request.type = (orderType == ORDER_TYPE_BUY) ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
      request.price = (request.type == ORDER_TYPE_BUY) ? SymbolInfoDouble(symbol, SYMBOL_ASK)
                                                       : SymbolInfoDouble(symbol, SYMBOL_BID);
      request.magic = magicNumber;
      request.slippage = slippage;

      OrderSend(request, result);
     }
  }
