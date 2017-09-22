//+------------------------------------------------------------------+
//|                                                      Goliath.mq4 |
//|                                    Copyright 2016, Killersignals |
//|                                    https://www.killersignals.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, Killersignals"
#property link      "https://www.killersignals.com"
#property version   "1.00"
#property description ""
#property strict
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

#include <stdlib.mqh>
#include <stderror.mqh>

extern double LongOpenRsiLength = 6;
extern double LongOpenRsiLevel = 42;

extern double LongCloseRsiLength = 0;
extern double LongCloseRsiLevel = 0;

extern double ShortOpenRsiLength = 17;
extern double ShortOpenRsiLevel = 60;

extern double ShortCloseRsiLength = 0;
extern double ShortCloseRsiLevel = 0;


int LotDigits;
int MagicNumber = 1369462;
double MM_Percent = 1;
int MaxSlippage = 3; //adjusted in OnInit
double MaxSL = 10;
bool crossed[4]; //initialized to true, used in function Cross
int MaxOpenTrades = 1;
int MaxLongTrades = 1000;
int MaxShortTrades = 1000;
int MaxPendingOrders = 1000;
bool Hedging = false;
int OrderRetry = 5; //# of retries if sending order returns error
int OrderWait = 5; //# of seconds to wait if sending order returns error
double myPoint; //initialized in OnInit

double MM_Size(double SL) //Risk % per trade, SL = relative Stop Loss to calculate risk
{
   double MaxLot = MarketInfo(Symbol(), MODE_MAXLOT);
   double MinLot = MarketInfo(Symbol(), MODE_MINLOT);
   double tickvalue = MarketInfo(Symbol(), MODE_TICKVALUE);
   double ticksize = MarketInfo(Symbol(), MODE_TICKSIZE);
   double lots = MM_Percent * 1.0 / 100 * AccountBalance() / (SL / ticksize * tickvalue);
   if(lots > MaxLot) lots = MaxLot;
   if(lots < MinLot) lots = MinLot;
   return(lots);
}

double MM_Size_BO() //Risk % per trade for Binary Options
{
   double MaxLot = MarketInfo(Symbol(), MODE_MAXLOT);
   double MinLot = MarketInfo(Symbol(), MODE_MINLOT);
   double tickvalue = MarketInfo(Symbol(), MODE_TICKVALUE);
   double ticksize = MarketInfo(Symbol(), MODE_TICKSIZE);
   return(MM_Percent * 1.0 / 100 * AccountBalance());
}

bool Cross(int i, bool condition) //returns true if "condition" is true and was false in the previous call
{
   bool ret = condition && !crossed[i];
   crossed[i] = condition;
   return(ret);
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
   for(int i = 0; i < total; i++)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == false) continue;
      if(OrderMagicNumber() != MagicNumber || OrderSymbol() != Symbol() || OrderType() != type) continue;
      result++;
   }
   return(result);
}

int OrderSend(int type, double volume, string ordername) //send order, return ticket ("price" is irrelevant for market orders)
{
   if(!IsTradeAllowed()) return(-1);
   int ticket = -1;
   int retries = 0;
   int err;
   
   int long_trades = TradesCount(OP_BUY);
   int short_trades = TradesCount(OP_SELL);
   int long_pending = TradesCount(OP_BUYLIMIT) + TradesCount(OP_BUYSTOP);
   int short_pending = TradesCount(OP_SELLLIMIT) + TradesCount(OP_SELLSTOP);
   
   //test Hedging
   if(!Hedging && ((type % 2 == 0 && short_trades + short_pending > 0) || (type % 2 == 1 && long_trades + long_pending > 0)))
   {
      return(-1);
   }

   //test maximum trades
   if((type % 2 == 0 && long_trades >= MaxLongTrades)
   || (type % 2 == 1 && short_trades >= MaxShortTrades)
   || (long_trades + short_trades >= MaxOpenTrades)
   || (type > 1 && long_pending + short_pending >= MaxPendingOrders))
   {
      return(-1);
   }

   while(IsTradeContextBusy()) Sleep(100);

   RefreshRates();
   
   double price;
   if(type == OP_BUY)
      price = Ask;
   else if(type == OP_SELL)
      price = Bid;
   else if(price < 0)
   {
      return(-1);
   }

   int clr = (type % 2 == 1) ? clrRed : clrBlue;
   while(ticket < 0 && retries < OrderRetry + 1)
   {
      ticket = OrderSend(Symbol(), type, NormalizeDouble(volume, LotDigits), NormalizeDouble(price, Digits()), MaxSlippage, 0, 0, ordername, MagicNumber, 0, clr);
      
      if(ticket < 0)
      {
         err = GetLastError();
         Sleep(OrderWait*1000);
      }
      retries++;
   }
   return(ticket);
}

int myOrderModify(int ticket, double SL, double TP) //modify SL and TP (absolute price), zero targets do not modify
{
   if(!IsTradeAllowed()) return(-1);
   bool success = false;
   int retries = 0;
   int err;
   SL = NormalizeDouble(SL, Digits());
   TP = NormalizeDouble(TP, Digits());
   if(SL < 0) SL = 0;
   if(TP < 0) TP = 0;
   //prepare to select order
   while(IsTradeContextBusy()) Sleep(100);
   if(!OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
   {
   err = GetLastError();
   ShowAlert("error", "OrderSelect failed; error #"+err+" "+ErrorDescription(err));
   return(-1);
   }
   //prepare to modify order
   while(IsTradeContextBusy()) Sleep(100);
   RefreshRates();
   if(CompareDoubles(SL, 0)) SL = OrderStopLoss(); //not to modify
   if(CompareDoubles(TP, 0)) TP = OrderTakeProfit(); //not to modify
   if(CompareDoubles(SL, OrderStopLoss()) && CompareDoubles(TP, OrderTakeProfit())) return(0); //nothing to do
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
   string alertstr = "Order modified: ticket="+ticket;
   if(!CompareDoubles(SL, 0)) alertstr = alertstr+" SL="+ SL;
   if(!CompareDoubles(TP, 0)) alertstr = alertstr+" TP="+ TP;
   ShowAlert("modify", alertstr);
   return(0);
}

// close open orders for current symbol, magic number and "type" (OP_BUY or OP_SELL)
void CloseOrder(int type, int volumepercent, string ordername)
{
    if(!IsTradeAllowed()) return;
    if (type > 1)
    {
      ShowAlert("error", "Invalid type in myOrderClose");
      return;
    }
    bool success = false;
    int err;
    string ordername_ = ordername;
    if(ordername != "") ordername_ = "("+ordername+")";
    int total = OrdersTotal();

    for(int i = total-1; i >= 0; i--)
    {
      while(IsTradeContextBusy()) Sleep(100);

      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if(OrderMagicNumber() != MagicNumber || OrderSymbol() != Symbol() || OrderType() != type) continue;

      while(IsTradeContextBusy()) Sleep(100);

      RefreshRates();

      double price = (type == OP_SELL) ? Ask : Bid;
      double volume = NormalizeDouble(OrderLots()*volumepercent * 1.0 / 100, LotDigits);
      if (NormalizeDouble(volume, LotDigits) == 0) continue;
      success = OrderClose(OrderTicket(), volume, NormalizeDouble(price, Digits()), MaxSlippage, clrWhite);
      if(!success)
      {
        err = GetLastError();
        ShowAlert("error", "OrderClose"+ordername_+" failed; error #"+err+" "+ErrorDescription(err));
      }
    }

    string typestr[6] = {"Buy", "Sell", "Buy Limit", "Sell Limit", "Buy Stop", "Sell Stop"};

    if(success) ShowAlert("order", "Orders closed"+ordername_+": "+typestr[type]+" "+Symbol()+" Magic #"+MagicNumber);
}

void TrailingStopBE(int type, double profit) //set Stop Loss to open price if in profit
{
   int total = OrdersTotal();
   profit = NormalizeDouble(profit, Digits());
   for(int i = total-1; i >= 0; i--)
   {
      while(IsTradeContextBusy()) Sleep(100);
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if(OrderMagicNumber() != MagicNumber || OrderSymbol() != Symbol() || OrderType() != type) continue;
      RefreshRates();
      if((type == OP_BUY && Ask > OrderOpenPrice() + profit && OrderOpenPrice() > OrderStopLoss())
      || (type == OP_SELL && Bid < OrderOpenPrice() - profit && OrderOpenPrice() < OrderStopLoss()))
      myOrderModify(OrderTicket(), OrderOpenPrice(), 0);
   }
}

//+------------------------------------------------------------------+
//| Expert initialization function |
//+------------------------------------------------------------------+
int OnInit()
{
   //initialize myPoint
   myPoint = Point();
   if(Digits() == 5 || Digits() == 3)
   {
      myPoint *= 10;
      MaxSlippage *= 10;
   }

   //initialize LotDigits
   double LotStep = MarketInfo(Symbol(), MODE_LOTSTEP);
   if(LotStep >= 1) LotDigits = 0;
   else if(LotStep >= 0.1) LotDigits = 1;
   else if(LotStep >= 0.01) LotDigits = 2;
   else LotDigits = 3;
   MaxSL = MaxSL * myPoint;
   int i;

   //initialize crossed
   for (i = 0; i < ArraySize(crossed); i++)
   crossed[i] = true;
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
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
//| Expert tick function |
//+------------------------------------------------------------------+
void OnTick()
{
  double price;
  double tradeSize = 0.1;
  int ticket;
  
  // TrailingStopBE(OP_BUY, 12 * myPoint); //Trailing Stop = go break even
  // TrailingStopBE(OP_SELL, 12 * myPoint); //Trailing Stop = go break even

  // Close Signals
  if(LongSignal(LongCloseRsiLength, LongCloseRsiLevel)){
    Print("Short Close Signal");
    //CloseOrder(OP_BUY, 100, "");
  }

  if(ShortSignal(ShortCloseRsiLength, ShortCloseRsiLevel)){
    Print("Short Close Signal");
    //CloseOrder(OP_SELL, 100, "");
  }

  // Open Signals
  if(LongOpenSignal(LongOpenRsiLength, LongOpenRsiLevel)){
    Send(OP_BUY);
    //RefreshRates();
    //price = Ask;
    //ticket = OrderSend(OP_BUY, tradeSize, "");
  }

  if(ShortOpenSignal(ShortOpenRsiLength, ShortOpenRsiLevel)){
    Send(OP_SELL);
    //RefreshRates();
    //price = Bid;
    //ticket = OrderSend(OP_SELL, price, TradeSize, "");
  }

}

int Send(int type)
{
   int long_trades = TradesCount(OP_BUY);
   int short_trades = TradesCount(OP_SELL);
   int long_pending = TradesCount(OP_BUYLIMIT) + TradesCount(OP_BUYSTOP);
   int short_pending = TradesCount(OP_SELLLIMIT) + TradesCount(OP_SELLSTOP);
   
   //test Hedging
   if(!Hedging && ((type % 2 == 0 && short_trades + short_pending > 0) || (type % 2 == 1 && long_trades + long_pending > 0)))
   {
      return(-1);
   }

   //test maximum trades
   if((type % 2 == 0 && long_trades >= MaxLongTrades)
   || (type % 2 == 1 && short_trades >= MaxShortTrades)
   || (long_trades + short_trades >= MaxOpenTrades)
   || (type > 1 && long_pending + short_pending >= MaxPendingOrders))
   {
      return(-1);
   }
   double price = (type == OP_SELL) ? Ask : Bid;
   double spread = MarketInfo(Symbol(),MODE_SPREAD);
   double pips = 50*Point;
   double sl = (type == OP_SELL) ? price+pips : price-pips ;
   double tp = (type == OP_SELL) ? price-pips-(spread*Point) : price+pips+(spread*Point);
   
   
   //double volume = NormalizeDouble(OrderLots()*volumepercent * 1.0 / 100, LotDigits);
   
   int colour = (type == OP_SELL) ? clrRed : clrBlue;
   int ticket = OrderSend(Symbol(), type, NormalizeDouble(0.1, LotDigits), NormalizeDouble(price, Digits()), MaxSlippage, sl, tp, "Buy Order", MagicNumber, 0, colour);
   
   if(ticket < 0)
   {
      Print("OrderSend failed with error #",GetLastError());
   }
   
   return(ticket);
}

