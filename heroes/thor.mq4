//+------------------------------------------------------------------+
//|                                                      Goliath.mq4 |
//|                                    Copyright 2016, Killersignals |
//|                                    https://www.killersignals.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, Killersignals"
#property link      "https://www.killersignals.com"
#property version   "1.00"
#property description "Thor - Hammer Throw EA"
#property strict
#include <stdlib.mqh>
#include <stderror.mqh>


//+------------------------------------------------------------------+
//| Externals                                   |
//+------------------------------------------------------------------+
extern double LongOpenRsiLength = 6;
extern double LongOpenRsiLevel = 42;

extern double LongCloseRsiLength = 0;
extern double LongCloseRsiLevel = 0;

extern double ShortOpenRsiLength = 17;
extern double ShortOpenRsiLevel = 60;

extern double ShortCloseRsiLength = 0;
extern double ShortCloseRsiLevel = 0;

extern double StopLossPips = 100;

extern int MagicNumber = 1369462;

int LotDigits;
double Multiplier;
double Percent = 1;
int MaxSlippage = 3; //adjusted in OnInit

int MaxOpenTrades = 1;
int MaxLongTrades = 1000;
int MaxShortTrades = 1000;
int MaxPendingOrders = 1000;

int OrderRetry = 5; //# of retries if sending order returns error
int OrderWait = 5; //# of seconds to wait if sending order returns error

//+------------------------------------------------------------------+
//| Expert initialization function |
//+------------------------------------------------------------------+
int OnInit()
{
   Multiplier = Point();
   if(Digits() == 5 || Digits() == 3)
   {
      Multiplier *= 10;
      MaxSlippage *= 10;
   }

   double step = MarketInfo(Symbol(), MODE_LOTSTEP);
   if (step >= 1) LotDigits = 0;
   else if (step >= 0.1) LotDigits = 1;
   else if (step >= 0.01) LotDigits = 2;
   else LotDigits = 3;
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert tick function |
//+------------------------------------------------------------------+
void OnTick()
{
  // TrailingStop(OP_BUY, 12 * Multiplier);
  // TrailingStop(OP_SELL, 12 * Multiplier);

  if(LongSignal(LongCloseRsiLength, LongCloseRsiLevel)){
    CloseOrder(OP_BUY);
  }

  if(ShortSignal(ShortCloseRsiLength, ShortCloseRsiLevel)){
    CloseOrder(OP_SELL);
  }

  if(LongOpenSignal(LongOpenRsiLength, LongOpenRsiLevel)){
    int ticket = OpenOrder(OP_BUY);
  }

  if(ShortOpenSignal(ShortOpenRsiLength, ShortOpenRsiLevel)){
    int ticket = OpenOrder(OP_SELL);
  }

}

//+------------------------------------------------------------------+
//| Signals |
//+------------------------------------------------------------------+
bool OpenForSignals () {
  //todo: implement market signal
  return(IsTradeAllowed());
}

bool LongOpenSignal (int length, int level) {
  int long_trades = TradesCount(OP_BUY);
  if (long_trades >= MaxLongTrades && OpenForSignals()) {
      return(false);
  }
  return(LongSignal(length, level));
}

bool LongSignal (int length, int level) {
  double rsiPrevious = iRSI(NULL, PERIOD_CURRENT, length, PRICE_CLOSE, 2);
  double rsiCurrent = iRSI(NULL, PERIOD_CURRENT, length, PRICE_CLOSE, 1);
  if(rsiPrevious <= level && rsiCurrent > level){
    return(true);
  }
  return(false);
}

bool ShortOpenSignal(int length, int level){
  int short_trades = TradesCount(OP_SELL);
  if (short_trades >= MaxLongTrades && OpenForSignals()) {
      return(false);
  }
  return(ShortSignal(length, level));
}

bool ShortSignal (int length, int level) {
  double rsiPrevious = iRSI(NULL, PERIOD_CURRENT, length, PRICE_CLOSE, 2);
  double rsiCurrent = iRSI(NULL, PERIOD_CURRENT, length, PRICE_CLOSE, 1);
  if(rsiPrevious >= level && rsiCurrent < level){
    return(true);
  }
  return(false);
}

//+------------------------------------------------------------------+
//| Order functions |
//+------------------------------------------------------------------+

int OpenOrder(int type)
{
   if (!IsTradeAllowed()) return(-1);
   if ((type == OP_BUY && long_trades >= MaxLongTrades) || (type == OP_SELL && short_trades >= MaxShortTrades))
   {
      return(-1);
   }

   int ticket = -1;
   int retries = 0;
   int error = 0;
   int long_trades = TradesCount(OP_BUY);
   int short_trades = TradesCount(OP_SELL);
   int colour = (type == OP_SELL) ? clrRed : clrBlue;
   double price = (type == OP_SELL) ? Bid : Ask;
   double spread = MarketInfo(Symbol(), MODE_SPREAD);
   double pips = StopLossPips* Multiplier;
   double sl = (type == OP_SELL) ? price+pips : price-pips;
   double tp = (type == OP_SELL) ? price-pips-(spread*Point) : price+pips+(spread*Point);
   double volume = NormalizeDouble(OrderLots() * (1.0 / 100), LotDigits);
   string name = (type == OP_SELL) ? "Thor Sell Order" : "Thor Buy Order";
   
   while(IsTradeContextBusy()) Sleep(100);
   RefreshRates();
   
   while(ticket < 0 && retries < OrderRetry + 1)
   {
      ticket = OrderSend(Symbol(), type, NormalizeDouble(volume, LotDigits), NormalizeDouble(price, Digits()), MaxSlippage, sl, tp, name, MagicNumber, 0, colour);
      
      if(ticket < 0)
      {
         error = GetLastError();
         Sleep(OrderWait*1000);
      }
      retries++;
   }
   return(ticket);
}

void CloseOrder(int type)
{
  bool success = false;
  int total = OrdersTotal();

  for(int i = total-1; i >= 0; i--)
  {
    while(IsTradeContextBusy()) Sleep(100);

    if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
    if(OrderMagicNumber() != MagicNumber || OrderSymbol() != Symbol() || OrderType() != type) continue;

    while(IsTradeContextBusy()) Sleep(100);

    RefreshRates();

    double price = (type == OP_SELL) ? Ask : Bid;
    double volume = NormalizeDouble(OrderLots() * (1.0 / 100), LotDigits);
    if (NormalizeDouble(volume, LotDigits) == 0) continue;
    success = OrderClose(OrderTicket(), volume, NormalizeDouble(price, Digits()), MaxSlippage, clrWhite);
    if(!success)
    {
      err = GetLastError();
      ShowAlert("error", "OrderClose"+ordername_+" failed; error #"+err+" "+ErrorDescription(err));
    }
  }
}

int Modify(int ticket, double stoploss, double takeprofit)
{
   if(!IsTradeAllowed()) return(-1);
   bool success = false;
   int retries = 0;
   int err;
   stoploss = NormalizeDouble(stoploss, Digits());
   takeprofit = NormalizeDouble(takeprofit, Digits());

   if (stoploss < 0) stoploss = 0;
   if (takeprofit < 0) takeprofit = 0;

   while(IsTradeContextBusy()) Sleep(100);
   
   if(!OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
   {
      err = GetLastError();
      ShowAlert("error", "OrderSelect failed; error #"+err+" "+ErrorDescription(err));
      return(-1);
   }

   while(IsTradeContextBusy()) Sleep(100);
   
   RefreshRates();
   
   if (CompareDoubles(stoploss, 0)) stoploss = OrderStopLoss();
   if (CompareDoubles(takeprofit, 0)) takeprofit = OrderTakeProfit();

   if (CompareDoubles(SL, OrderStopLoss()) && CompareDoubles(TP, OrderTakeProfit())) return(0);

   while(!success && retries < OrderRetry+1)
   {
      success = OrderModify(ticket, NormalizeDouble(OrderOpenPrice(), Digits()), NormalizeDouble(SL, Digits()), NormalizeDouble(TP, Digits()), OrderExpiration(), CLR_NONE);
      if(!success)
      {
        err = GetLastError();
        ShowAlert("print", "OrderModify error #"+err+" "+ErrorDescription(err));
        Sleep(OrderWait*1000);
      }
      retries++;
   }

   if(!success)
   {
      ShowAlert("error", "OrderModify failed "+(OrderRetry+1)+" times; error #"+err+" "+ErrorDescription(err));
      return(-1);
   }

   string message = "Order modified: ticket=" + ticket;
   if(!CompareDoubles(SL, 0)) message = message+" SL="+ SL;
   if(!CompareDoubles(TP, 0)) message = message+" TP="+ TP;
   ShowAlert("modify", message);
   return(0);
}

//+------------------------------------------------------------------+
//| Utility functions |
//+------------------------------------------------------------------+
double Size(double stoploss) //Risk % per trade, SL = relative Stop Loss to calculate risk
{
   double maxLot = MarketInfo(Symbol(), MODE_MAXLOT);
   double minLot = MarketInfo(Symbol(), MODE_MINLOT);
   double tickvalue = MarketInfo(Symbol(), MODE_TICKVALUE);
   double ticksize = MarketInfo(Symbol(), MODE_TICKSIZE);
   double lots = Percent * 1.0 / 100 * AccountBalance() / (stoploss / ticksize * tickvalue);
   if(lots > maxLot) lots = maxLot;
   if(lots < maxLot) lots = maxLot;
   return(lots);
}

double SizeBinaryOptions() //Risk % per trade for Binary Options
{
   double MaxLot = MarketInfo(Symbol(), MODE_MAXLOT);
   double MinLot = MarketInfo(Symbol(), MODE_MINLOT);
   double tickvalue = MarketInfo(Symbol(), MODE_TICKVALUE);
   double ticksize = MarketInfo(Symbol(), MODE_TICKSIZE);
   return(Percent * 1.0 / 100 * AccountBalance());
}

void ShowAlert(string type, string message)
{
   if(type == "print")
      Print(message);
   else if(type == "error")
   {
      Print(type+" | MA-Scalp @ "+Symbol()+","+Period()+" | "+message);
   }
   else if(type == "order")
   {
   }
   else if(type == "modify")
   {
   }
}

int TradesCount(int type) //returns # of open trades for order type, current symbol and magic number
{
   int result = 0;
   int total = OrdersTotal();
   for (int i = 0; i < total; i++)
   {
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == false) continue;
      if (OrderMagicNumber() != MagicNumber || OrderSymbol() != Symbol() || OrderType() != type) continue;
      result++;
   }
   return(result);
}

void TrailingStop(int type, double profit) //set Stop Loss to open price if in profit
{
   int total = OrdersTotal();
   profit = NormalizeDouble(profit, Digits());
   for(int i = total-1; i >= 0; i--)
   {
      while(IsTradeContextBusy()) Sleep(100);
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if(OrderMagicNumber() != MagicNumber || OrderSymbol() != Symbol() || OrderType() != type) continue;

      RefreshRates();
      
      if (type == OP_BUY 
          && Ask > OrderOpenPrice() + profit 
          && OrderOpenPrice() > OrderStopLoss()) {
            Modify(OrderTicket(), OrderOpenPrice(), 0);
      }


      if (type == OP_SELL 
          && Bid < OrderOpenPrice() - profit 
          && OrderOpenPrice() < OrderStopLoss()) {
            Modify(OrderTicket(), OrderOpenPrice(), 0);
      }
   }
}

//+------------------------------------------------------------------+
//| Expert deinitialization function |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
}