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
extern int LongOpenRsiLength = 30;
extern double LongOpenRsiLevel = 39;

extern int LongCloseRsiLength = 27;
extern double LongCloseRsiLevel = 59;

extern int ShortOpenRsiLength = 12;
extern double ShortOpenRsiLevel = 75;

extern int ShortCloseRsiLength = 22;
extern double ShortCloseRsiLevel = 28;

extern double StopLossPips = 100;
extern int MagicNumber = 1369462;
extern double RiskPercent = 1;

extern int ExpiryBars = 50;

double longRsi[5];
double shortRsi[5];
double candleValues[5];

int LotDigits;
double Multiplier;

int slippage = 3;

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
      slippage *= 10;
   }
   //Print("Multiplier: " + DoubleToStr(Multiplier), " Point: ", Point, " Point(): ", Point());
   
   double step = MarketInfo(Symbol(), MODE_LOTSTEP);
   if (step >= 1) LotDigits = 0;
   else if (step >= 0.1) LotDigits = 1;
   else if (step >= 0.01) LotDigits = 2;
   else LotDigits = 3;
   
   InitialiseArray(longRsi);
   InitialiseArray(shortRsi);
   InitialiseArray(candleValues);
   
   return(INIT_SUCCEEDED);
}

void InitialiseArray(double &array[]){
    for(int i = 0;i<5; i++){
        array[i] = 0;
    }
}

//+------------------------------------------------------------------+
//| Expert tick function |
//+------------------------------------------------------------------+
void OnTick()
{
  TrailingStop(OP_BUY, 12 * Multiplier);
  TrailingStop(OP_SELL, 12 * Multiplier);

  if(LongCloseSignal(LongCloseRsiLength, LongCloseRsiLevel)){
    CloseOrder(OP_BUY);
  }

  if(ShortCloseSignal(ShortCloseRsiLength, ShortCloseRsiLevel)){
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
  return(IsTradeAllowed());
}

bool LongOpenSignal (int length, double level) {
  if (!OpenForSignals()) {
      return(false);
  }
  bool signal = LongSignal(length, level) && Macdsignal(OP_BUY);
  return(signal);
}

bool LongCloseSignal (int length, double level) {
  double rsiPrevious = iRSI(NULL, PERIOD_CURRENT, length, PRICE_CLOSE, 2);
  double rsiCurrent = iRSI(NULL, PERIOD_CURRENT, length, PRICE_CLOSE, 1);
  if (longRsi[1] == rsiCurrent && longRsi[2] == rsiPrevious) return(false);
  bool signal = LongSignal(length, level);
  if (signal) {
      longRsi[1] = rsiCurrent;
      longRsi[2] = rsiPrevious;
  }
  return(signal);
}

bool LongSignal (int length, double level) {
  double rsiPrevious = iRSI(NULL, PERIOD_CURRENT, length, PRICE_CLOSE, 2);
  double rsiCurrent = iRSI(NULL, PERIOD_CURRENT, length, PRICE_CLOSE, 1);
  if(rsiPrevious <= level && rsiCurrent > level){
    return(true);
  }
  return(false);
}

bool ShortOpenSignal(int length, double level){
  if (!OpenForSignals()) {
      return(false);
  }
  bool signal = ShortSignal(length, level) && Macdsignal(OP_SELL);
  return(signal);
}

bool ShortCloseSignal (int length, double level) {
  double rsiPrevious = iRSI(NULL, PERIOD_CURRENT, length, PRICE_CLOSE, 2);
  double rsiCurrent = iRSI(NULL, PERIOD_CURRENT, length, PRICE_CLOSE, 1);
  if (shortRsi[1] == rsiCurrent && shortRsi[2] == rsiPrevious) return(false);
  bool signal = ShortSignal(length, level);
  if (signal) {
      shortRsi[1] = rsiCurrent;
      shortRsi[2] = rsiPrevious;
  }
  return(signal);
}

bool ShortSignal (int length, double level) {
  double rsiPrevious = iRSI(NULL, PERIOD_CURRENT, length, PRICE_CLOSE, 2);
  double rsiCurrent = iRSI(NULL, PERIOD_CURRENT, length, PRICE_CLOSE, 1);
  if(rsiPrevious >= level && rsiCurrent < level){
    return(true);
  }
  return(false);
}

bool Macdsignal (int type){
   double macd1 = iMACD(Symbol(), PERIOD_CURRENT, 5, 34, 9, PRICE_CLOSE, MODE_SIGNAL, 1);
   double macd2 = iMACD(Symbol(), PERIOD_CURRENT, 5, 34, 9, PRICE_CLOSE, MODE_SIGNAL, 2);
   double macd3 = iMACD(Symbol(), PERIOD_CURRENT, 5, 34, 9, PRICE_CLOSE, MODE_SIGNAL, 3);
   bool macdSignal = false;
   if (type == OP_SELL && macd1 < macd2 < macd3) {
      macdSignal = true;
   }
   
   if (type == OP_BUY && macd1 > macd2 > macd3) {
      macdSignal = true;
   }
   return(macdSignal);
}
//+------------------------------------------------------------------+
//| Order functions |
//+------------------------------------------------------------------+

bool IsMaxTradesExceeded(int type, int longTrades, int shortTrades) {
   if ((type == OP_BUY && longTrades >= MaxLongTrades) 
   || (type == OP_SELL && shortTrades >= MaxShortTrades))
   {
      return(true);
   }
   return(false);
}

void StopAndReverse(int type, int longTrades, int shortTrades) {
   if(type == OP_BUY && shortTrades > 0) {
      CloseOrder(OP_SELL);
   }
   
   if(type == OP_SELL && longTrades > 0) {
      CloseOrder(OP_BUY);
   }
}

bool SameTypeOrderExists(int type, int longTrades, int shortTrades) {
   return((type == OP_BUY && longTrades > 0) || (type == OP_SELL && shortTrades > 0));
}


int OpenOrder(int type)
{
   int longTrades = TradesCount(OP_BUY);
   int shortTrades = TradesCount(OP_SELL);
   if (!IsTradeAllowed()) return(-1);
   if (IsMaxTradesExceeded(type, longTrades, shortTrades)) return (-1);
   if (SameTypeOrderExists(type, longTrades, shortTrades)) return (-1);
   StopAndReverse(type, longTrades, shortTrades);
   
   
   int ticket = -1;
   int retries = 0;
   int error = 0;
   int colour = (type == OP_SELL) ? clrRed : clrBlue;
   string name = (type == OP_SELL) ? "Thor Sell Order" : "Thor Buy Order";
   //while(IsTradeContextBusy()) Sleep(100);
   
   RefreshRates();
   
   //while(ticket < 0 && retries < OrderRetry + 1)
   //{
      double price = (type == OP_SELL) ? Bid : Ask;
      price = NormalizeDouble(price, Digits());
      double spread = MarketInfo(Symbol(), MODE_SPREAD);
      double pips = StopLossPips* Multiplier;
      double stoploss = (type == OP_SELL) ? price+pips : price-pips;
      double takeprofit = (type == OP_SELL) ? price-pips-(spread*Point) : price+pips+(spread*Point);
      double volume = NormalizeDouble(Size(pips), LotDigits);
      
      Print("type: ", type, " volume: ", volume, " price: ", price, " slippage: ", slippage);
      Print("SL: ", stoploss, " TP: ", takeprofit, " name: ", name, " colour: ", colour);
      
      ticket = OrderSend(Symbol(), type, volume, price, slippage, stoploss, takeprofit, name, MagicNumber, 0, colour);
      
      if(ticket < 0)
      {
         error = GetLastError();
         Sleep(OrderWait*1000);
      }
      retries++;
   //}
   return(ticket);
}

void CloseOrder(int type)
{
  bool success = false;
  int total = OrdersTotal();
  int error;
  
  for(int i = total-1; i >= 0; i--)
  {
    
    //while(IsTradeContextBusy()) Sleep(100);

    if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
    if(OrderMagicNumber() != MagicNumber || OrderSymbol() != Symbol() || OrderType() != type) continue;

    //while(IsTradeContextBusy()) Sleep(100);

    RefreshRates();

    double price = (type == OP_SELL) ? Ask : Bid;
    price = NormalizeDouble(price, Digits());
    
    success = OrderClose(OrderTicket(), OrderLots(), price, slippage, clrWhite);
    if(!success)
    {
      error = GetLastError();
      ShowAlert("error", "OrderClose failed; error #" + IntegerToString(error) + " "+ErrorDescription(error));
    }
  }
}

int Modify(int ticket, double stoploss, double takeprofit)
{
   if(!IsTradeAllowed()) return(-1);
   bool success = false;
   int retries = 0;
   int error = 0;
   stoploss = NormalizeDouble(stoploss, Digits());
   takeprofit = NormalizeDouble(takeprofit, Digits());

   if (stoploss < 0) stoploss = 0;
   if (takeprofit < 0) takeprofit = 0;

   while(IsTradeContextBusy()) Sleep(100);
   
   if(!OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
   {
      error = GetLastError();
      ShowAlert("error", "OrderSelect failed; error #"+IntegerToString(error)+" "+ErrorDescription(error));
      return(-1);
   }

   while(IsTradeContextBusy()) Sleep(100);
   
   RefreshRates();
   
   if (CompareDoubles(stoploss, 0)) stoploss = OrderStopLoss();
   if (CompareDoubles(takeprofit, 0)) takeprofit = OrderTakeProfit();

   if (CompareDoubles(stoploss, OrderStopLoss()) && CompareDoubles(takeprofit, OrderTakeProfit())) return(0);

   while(!success && retries < OrderRetry+1)
   {
      success = OrderModify(ticket, NormalizeDouble(OrderOpenPrice(), Digits()), NormalizeDouble(stoploss, Digits()), NormalizeDouble(takeprofit, Digits()), OrderExpiration(), CLR_NONE);
      if(!success)
      {
        error = GetLastError();
        ShowAlert("print", "OrderModify error #"+IntegerToString(error)+" "+ErrorDescription(error));
        Sleep(OrderWait*1000);
      }
      retries++;
   }

   if(!success)
   {
      ShowAlert("error", "OrderModify failed "+(IntegerToString(OrderRetry+1))+" times; error #"+IntegerToString(error)+" "+ErrorDescription(error));
      return(-1);
   }

   string message = "Order modified: ticket=" + IntegerToString(ticket);
   if(!CompareDoubles(stoploss, 0)) message = message+" SL="+ DoubleToString(stoploss);
   if(!CompareDoubles(takeprofit, 0)) message = message+" TP="+ DoubleToString(takeprofit);
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
   double lots = RiskPercent * 1.0 / 100 * AccountBalance() / (stoploss / ticksize * tickvalue);
   if(lots > maxLot) lots = maxLot;
   if(lots < minLot) lots = minLot;
   return(lots);
}

double SizeBinaryOptions() //Risk % per trade for Binary Options
{
   double MaxLot = MarketInfo(Symbol(), MODE_MAXLOT);
   double MinLot = MarketInfo(Symbol(), MODE_MINLOT);
   double tickvalue = MarketInfo(Symbol(), MODE_TICKVALUE);
   double ticksize = MarketInfo(Symbol(), MODE_TICKSIZE);
   return(RiskPercent * 1.0 / 100 * AccountBalance());
}

void ShowAlert(string type, string message)
{
   if(type == "print"){
      Print(message);
   }
   else if(type == "error"){
      Print(type+" | MA-Scalp @ "+Symbol()+","+DoubleToString(Period())+" | "+message);
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
      
      if (IsOrderExpired()){
         double price = (type == OP_SELL) ? Ask : Bid;
         price = NormalizeDouble(price, Digits());
         bool success = OrderClose(OrderTicket(), OrderLots(), price, slippage, clrWhite);
      }
      
   }
}

bool IsOrderExpired() {
  datetime orderTime = OrderOpenTime();
  int shift = iBarShift(Symbol(), PERIOD_CURRENT, orderTime);
  return(shift >= ExpiryBars);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
}