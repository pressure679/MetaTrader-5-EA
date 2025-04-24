//+------------------------------------------------------------------+
//|                                               EMA Crossover EA   |
//|                             Auto-closes opposite trades on signal |
//+------------------------------------------------------------------+
#property strict

input int    fastEMAPeriod = 7;
input int    slowEMAPeriod = 14;
input double lotSize       = 0.01;
input string symbol        = "XAUUSD"; // or _Symbol for current chart
input ENUM_TIMEFRAMES timeframe = PERIOD_M1;

int ticket;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   Print("EMA Crossover EA Initialized");
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   double fastEMA = iMA(symbol, timeframe, fastEMAPeriod, 0, MODE_EMA, PRICE_CLOSE, 0);
   double slowEMA = iMA(symbol, timeframe, slowEMAPeriod, 0, MODE_EMA, PRICE_CLOSE, 0);

   // Get current position info
   int total = PositionsTotal();
   bool hasBuy = false;
   bool hasSell = false;

   for (int i = 0; i < total; i++)
     {
      if (PositionGetSymbol(i) == symbol)
        {
         if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
            hasBuy = true;
         if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
            hasSell = true;
        }
     }

   // === Check and manage trade ===
   if (fastEMA > slowEMA)
     {
      if (hasSell)
         ClosePosition(POSITION_TYPE_SELL);
      if (!hasBuy)
         OpenOrder(ORDER_TYPE_BUY);
     }
   else if (fastEMA < slowEMA)
     {
      if (hasBuy)
         ClosePosition(POSITION_TYPE_BUY);
      if (!hasSell)
         OpenOrder(ORDER_TYPE_SELL);
     }
  }

//+------------------------------------------------------------------+
//| Open Buy/Sell Order                                              |
//+------------------------------------------------------------------+
void OpenOrder(ENUM_ORDER_TYPE orderType)
  {
   MqlTradeRequest request;
   MqlTradeResult result;

   ZeroMemory(request);
   request.action = TRADE_ACTION_DEAL;
   request.symbol = symbol;
   request.volume = lotSize;
   request.type = orderType;
   request.price = (orderType == ORDER_TYPE_BUY) ? SymbolInfoDouble(symbol, SYMBOL_ASK) : SymbolInfoDouble(symbol, SYMBOL_BID);
   request.deviation = 5;
   request.magic = 123456;

   OrderSend(request, result);

   if (result.retcode != TRADE_RETCODE_DONE)
      Print("Order send failed: ", result.comment);
   else
      Print("Opened ", (orderType == ORDER_TYPE_BUY ? "BUY" : "SELL"), " at ", request.price);
  }

//+------------------------------------------------------------------+
//| Close open position by type                                      |
//+------------------------------------------------------------------+
void ClosePosition(int positionType)
  {
   for (int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if (PositionGetSymbol(i) == symbol && PositionGetInteger(POSITION_TYPE) == positionType)
        {
         ulong ticket = PositionGetInteger(POSITION_TICKET);
         double volume = PositionGetDouble(POSITION_VOLUME);

         MqlTradeRequest request;
         MqlTradeResult result;
         ZeroMemory(request);

         request.action = TRADE_ACTION_DEAL;
         request.position = ticket;
         request.symbol = symbol;
         request.volume = volume;
         request.magic = 123456;
         request.deviation = 5;
         request.type = (positionType == POSITION_TYPE_BUY) ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
         request.price = (positionType == POSITION_TYPE_BUY) ? SymbolInfoDouble(symbol, SYMBOL_BID) : SymbolInfoDouble(symbol, SYMBOL_ASK);

         OrderSend(request, result);

         if (result.retcode != TRADE_RETCODE_DONE)
            Print("Close failed: ", result.comment);
         else
            Print("Closed ", (positionType == POSITION_TYPE_BUY ? "BUY" : "SELL"), " position");
        }
     }
  }
