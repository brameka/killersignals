//+------------------------------------------------------------------+
//|                                             KillerCalculator.mq4 |
//|                                    Copyright 2016, Killersignals |
//|                                    https://www.killersignals.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, Killersignals"
#property link      "https://www.killersignals.com"
#property version   "1.00"
#property strict

string orderId = "order";
string limitId = "limit";
string stopId = "stop";

string cancelId = "cancel";
string cancelLimitId = "cancelLimit";
string cancelStopId = "cancelStop";

string tradeId = "trade";
string tradeLimitId = "tradeLimit";
string tradeStopId = "tradeLimit";

string labelID="Info";
int broadcastEventID=5000;
int click = 0;

extern double EntryLevel = 0;
extern double StopLossLevel = 0;
extern double TakeProfitLevel = 0; // Optional
extern double Risk = 1; // Risk tolerance in percentage points
extern double MoneyRisk = 0; // Risk tolerance in account currency
extern bool UseMoneyInsteadOfPercentage = false;
extern bool UseEquityInsteadOfBalance = false;
extern bool DeleteLines = false; // If true, will delete lines on deinitialization. Otherwise will leave lines, so levels can be restored.
extern bool UseAskBidForEntry = false; // If true, Entry level will be updated to current Ask/Bid price automatically.

extern color white_color = clrWhite;
extern color green_color = clrLimeGreen;
extern color red_color = clrRed;
extern color blue_color = clrBlue;

extern color entry_font_color = clrBlue;
extern color sl_font_color = clrRed;
extern color tp_font_color = clrYellow;
extern color ps_font_color = clrLimeGreen;
extern color rp_font_color = clrLightBlue;
extern color balance_font_color = clrLightBlue;
extern color rmm_font_color = clrLightBlue;
extern color pp_font_color = clrLightBlue;
extern color rr_font_color = clrYellow;
extern int font_size = 9;
extern string font_face = "Courier";
extern int corner = 0; //0 - for top-left corner, 1 - top-right, 2 - bottom-left, 3 - bottom-right
extern int distance_x = 10;
extern int distance_y = 40;
extern color entry_line_color = clrBlue;
extern color stoploss_line_color = clrRed;
extern color takeprofit_line_color = clrYellow;
extern ENUM_LINE_STYLE entry_line_style = STYLE_SOLID;
extern ENUM_LINE_STYLE stoploss_line_style = STYLE_SOLID;
extern ENUM_LINE_STYLE takeprofit_line_style = STYLE_SOLID;
extern int entry_line_width = 1;
extern int stoploss_line_width = 1;
extern int takeprofit_line_width = 1;

string title = "Killer Calculator | Powered by Killersignals";
string orderTitle = "Market Order Calculater";
string stopTitle = "Stop Order Calculater";
string limitTitle = "Limit Order Calculater";

// Global Variables
int hwnd = 0;
// GUI Object Handles
int Button1,Button2,Button3,Button4,Button5;
int Label1,Label2,Label3,List1,List2,Edit1,Edit2,Label4;
int CB1,CB2,R1,R2,R3,R4,L1,L2,L3,L4,Label5;

// Settings
int GUIX = 50;
int GUIY = 100;
int ButtonWidth = 150;
int ButtonHeight = 30;

string SizeText;
double Size, RiskMoney;
double PositionSize;
double StopLoss;

double entry, stoploss, takeprofit;

double initStoploss = 100;
double initEntry = 100;
double multiplier = 1;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   if(Digits == 2 || Digits == 4) multiplier = 1;
   if(Digits == 3 || Digits == 5) multiplier = 10;
   if(Digits == 6) multiplier = 100; 
   
   initStoploss = initStoploss * multiplier;
   initEntry = initEntry * multiplier;
   
   
   ShowHeaderUI();
   ShowInitUI();
   
   return(INIT_SUCCEEDED);
}
  
void AddButton(int y_shift, int x_shift, string id, string label, color colour){
   ObjectCreate(0,id,OBJ_BUTTON,0,30,20);
   ObjectSetInteger(0,id,OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0,id,OBJPROP_BGCOLOR, colour);
   ObjectSetInteger(0,id,OBJPROP_BORDER_COLOR, colour);
   ObjectSetInteger(0,id,OBJPROP_XDISTANCE,x_shift);
   ObjectSetInteger(0,id,OBJPROP_YDISTANCE,distance_y + y_shift);
   ObjectSetInteger(0,id,OBJPROP_XSIZE,80);
   ObjectSetInteger(0,id,OBJPROP_YSIZE,25);
   ObjectSetString(0,id,OBJPROP_FONT,"Arial");
   ObjectSetString(0,id,OBJPROP_TEXT,label);
   ObjectSetInteger(0,id,OBJPROP_FONTSIZE,9);
   ObjectSetInteger(0,id,OBJPROP_SELECTABLE,0);
} 

void ShowErrorMessage(string message){
   ObjectCreate("ErrorMessage", OBJ_LABEL, 0, 0, 0);
   ObjectSet("ErrorMessage", OBJPROP_CORNER, corner);
   ObjectSet("ErrorMessage", OBJPROP_XDISTANCE, distance_x+5);
   ObjectSet("ErrorMessage", OBJPROP_YDISTANCE, distance_y+180);
   ObjectSetText("ErrorMessage", message, 9, NULL, red_color);
}

void DeleteErrorMessage(){
   ObjectDelete("ErrorHeader");
   ObjectDelete("ErrorMessage");
   ObjectDelete("ErrorFooter");
}

void ShowSuccessMessage(string message){
   //ObjectCreate("SuccessHeader", OBJ_LABEL, 0, 0, 0);
   //ObjectSet("SuccessHeader", OBJPROP_CORNER, corner);
   //ObjectSet("SuccessHeader", OBJPROP_XDISTANCE, distance_x);
   //ObjectSet("SuccessHeader", OBJPROP_YDISTANCE, distance_y+80);
   //ObjectSetText("SuccessHeader", "****************************************************", 7, NULL, green_color);
   
   
   ObjectCreate("SuccessMessage", OBJ_LABEL, 0, 0, 0);
   ObjectSet("SuccessMessage", OBJPROP_CORNER, corner);
   ObjectSet("SuccessMessage", OBJPROP_XDISTANCE, distance_x+5);
   ObjectSet("SuccessMessage", OBJPROP_YDISTANCE, distance_y+70);
   ObjectSetText("SuccessMessage", message, 8, NULL, green_color);
   
   
   //ObjectCreate("SuccessFooter", OBJ_LABEL, 0, 0, 0);
   //ObjectSet("SuccessFooter", OBJPROP_CORNER, corner);
   //ObjectSet("SuccessFooter", OBJPROP_XDISTANCE, distance_x);
   //ObjectSet("SuccessFooter", OBJPROP_YDISTANCE, distance_y+103);
   //ObjectSetText("SuccessFooter", "****************************************************", 7, NULL, green_color);
   Sleep(3000);
   DeleteSuccessMessage();
}

void DeleteSuccessMessage(){
   //ObjectDelete("SuccessHeader");
   ObjectDelete("SuccessMessage");
   //ObjectDelete("SuccessFooter");
}

void ShowHeaderUI(){
   ObjectCreate("Header1", OBJ_LABEL, 0, 0, 0);
   ObjectSet("Header1", OBJPROP_CORNER, corner);
   ObjectSet("Header1", OBJPROP_XDISTANCE, distance_x);
   ObjectSet("Header1", OBJPROP_YDISTANCE, distance_y);
   ObjectSetText("Header1", "****************************************************", 7, NULL, white_color);
   
   
   ObjectCreate("Header2", OBJ_LABEL, 0, 0, 0);
   ObjectSet("Header2", OBJPROP_CORNER, corner);
   ObjectSet("Header2", OBJPROP_XDISTANCE, distance_x+5);
   ObjectSet("Header2", OBJPROP_YDISTANCE, distance_y+8);
   ObjectSetText("Header2", title, 8, NULL, white_color);
   
   ObjectCreate("Header3", OBJ_LABEL, 0, 0, 0);
   ObjectSet("Header3", OBJPROP_CORNER, corner);
   ObjectSet("Header3", OBJPROP_XDISTANCE, distance_x);
   ObjectSet("Header3", OBJPROP_YDISTANCE, distance_y+23);
   ObjectSetText("Header3", "****************************************************", 7, NULL, white_color);
} 

void ShowOrderHeaderUI(string headerTitle, color clr){
   ObjectCreate("Header1", OBJ_LABEL, 0, 0, 0);
   ObjectSet("Header1", OBJPROP_CORNER, corner);
   ObjectSet("Header1", OBJPROP_XDISTANCE, distance_x);
   ObjectSet("Header1", OBJPROP_YDISTANCE, distance_y);
   ObjectSetText("Header1", "*****************************************", 7, NULL, clr);
   
   
   ObjectCreate("Header2", OBJ_LABEL, 0, 0, 0);
   ObjectSet("Header2", OBJPROP_CORNER, corner);
   ObjectSet("Header2", OBJPROP_XDISTANCE, distance_x+5);
   ObjectSet("Header2", OBJPROP_YDISTANCE, distance_y+8);
   ObjectSetText("Header2", headerTitle, 8, NULL, clr);
   
   ObjectCreate("Header3", OBJ_LABEL, 0, 0, 0);
   ObjectSet("Header3", OBJPROP_CORNER, corner);
   ObjectSet("Header3", OBJPROP_XDISTANCE, distance_x);
   ObjectSet("Header3", OBJPROP_YDISTANCE, distance_y+23);
   ObjectSetText("Header3", "*****************************************", 7, NULL, clr);
} 

void DeleteHeaderUI(){
   ObjectDelete("Header1");
   ObjectDelete("Header2");
   ObjectDelete("Header3");
}

void ShowInitUI(){
   AddButton(40, 10, orderId, "Order", clrBlue);
   AddButton(40, 100, limitId, "Limits", clrBlue);
   AddButton(40, 190, stopId, "Stop", clrBlue);
}

void DeleteUI(){
   ObjectDelete(orderId);
   ObjectDelete(stopId);
   ObjectDelete(limitId);
}



//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
  DeleteUI();
  DeleteOrderUI();
  DeleteLimitUI();
  DeleteHeaderUI();
  DeleteErrorMessage();
  DeleteSuccessMessage();
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
}

void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam){
   
   if(id==CHARTEVENT_OBJECT_CLICK)
   {
      string clickedChartObject=sparam;
      
      if(clickedChartObject==orderId){
         DeleteUI();
         ShowOrderUI();
         DeleteHeaderUI();
         ShowOrderHeaderUI(orderTitle, white_color);
      }

      if(clickedChartObject==limitId){
         DeleteUI();
         ShowLimitUI();
         DeleteHeaderUI();
         ShowOrderHeaderUI(limitTitle, white_color);
      }
      
      if(clickedChartObject==stopId){
         DeleteUI();
         ShowStopUI();
         DeleteHeaderUI();
         ShowOrderHeaderUI(stopTitle, white_color);
      }
      
      if(clickedChartObject==cancelId){
         DeleteOrderUI();
         ShowInitUI();
         DeleteHeaderUI();
         ShowHeaderUI();
         DeleteErrorMessage();
      }
      
      if(clickedChartObject==cancelLimitId){
         DeleteLimitUI();
         ShowInitUI();
         DeleteHeaderUI();
         ShowHeaderUI();
         DeleteErrorMessage();
      }
      
      if(clickedChartObject==cancelStopId){
         DeleteStopUI();
         ShowInitUI();
         DeleteHeaderUI();
         ShowHeaderUI();
         DeleteErrorMessage();
      }
      
      //ShowErrorMessage
      if(clickedChartObject==tradeId){
         ShowErrorMessage("Invalid Trade Parameters");
      }
      
      if(clickedChartObject==tradeStopId){
         ShowErrorMessage("Invalid Order Parameters");
      }
      
      if(clickedChartObject==tradeLimitId){
         ShowErrorMessage("Invalid Limit Parameters");
      }
      
      //StopLossLine
      if(clickedChartObject=="StopLossLine"){
         Print("StopLossLine");
         DeleteErrorMessage();
      }
      
      if(clickedChartObject=="EntryLine"){
         Print("EntryLine");
         DeleteErrorMessage();
      }
      
      ChartRedraw();
   }
   UpdateLevels();
 }
  
//+------------------------------------------------------------------+
//| sends broadcast event to all open charts                         |
//+------------------------------------------------------------------+
void BroadcastEvent(long lparam,double dparam,string sparam)
{
   
   int eventID=broadcastEventID-CHARTEVENT_CUSTOM;
   long currChart=ChartFirst();
   int i=0;
   while(i<CHARTS_MAX)
   {
      currChart=ChartNext(currChart); // We have received a new chart from the previous
      if(currChart==-1) break;        // Reached the end of the charts list
      i++; // Do not forget to increase the counter
   }
}
  
  
  
void UpdateLevels()
{
   double tEntryLevel, tStopLossLevel, tTakeProfitLevel;
   tEntryLevel = 0;
      
   // Update Entry to Ask/Bid if needed.
   if (UseAskBidForEntry)
   {
      RefreshRates();
      if ((Ask > 0) && (Bid > 0))
      {
         tStopLossLevel = ObjectGet("StopLossLine", OBJPROP_PRICE1);
         // Long entry
         if (tStopLossLevel < Bid) tEntryLevel = Ask;
         // Short entry
         else if (tStopLossLevel > Ask) tEntryLevel = Bid;
         ObjectSet("EntryLine", OBJPROP_PRICE1, tEntryLevel);
      }
   }
   
   if (EntryLevel - StopLossLevel == 0) return;

   if (AccountCurrency() == "") return;

   tEntryLevel = ObjectGet("EntryLine", OBJPROP_PRICE1);
   tStopLossLevel = ObjectGet("StopLossLine", OBJPROP_PRICE1);
   tTakeProfitLevel = ObjectGet("TakeProfitLine", OBJPROP_PRICE1);
   
   stoploss = tStopLossLevel;
   entry = tEntryLevel;
   
   ObjectSetText("EntryLevel", "Entry Line:   " + DoubleToStr(tEntryLevel, Digits), font_size, font_face, entry_font_color);
   ObjectSetText("StopLoss", "Stop-Loss:    " + DoubleToStr(tStopLossLevel, Digits), font_size, font_face, sl_font_color);
   if (tTakeProfitLevel > 0) ObjectSetText("TakeProfit", "Take-Profit:  " + DoubleToStr(tTakeProfitLevel, Digits), font_size, font_face, tp_font_color);

   StopLoss = MathAbs(tEntryLevel - tStopLossLevel);

   if (tTakeProfitLevel > 0)
   {
      string RR;
      // Have valid take-profit level that is above entry for SL below entry, or below entry for SL above entry.
      if (((tTakeProfitLevel > tEntryLevel) && (tEntryLevel > tStopLossLevel)) || ((tTakeProfitLevel < tEntryLevel) && (tEntryLevel < tStopLossLevel)))
         RR = DoubleToStr(MathAbs((tTakeProfitLevel - tEntryLevel) / StopLoss), 1);
      else RR = "Invalid TP.";
      ObjectSetText("RR", "Reward/Risk:  " + RR, font_size, font_face, takeprofit_line_color);
      ObjectSetText("PotentialProfit", "Reward:       " + DoubleToStr(RiskMoney * MathAbs((tTakeProfitLevel - tEntryLevel) / StopLoss), 2), font_size, font_face, pp_font_color);
   }
   
   if (UseEquityInsteadOfBalance) Size = AccountEquity();
   else Size = AccountBalance();
   ObjectSetText("AccountSize", "Acc. " + SizeText + ": " + DoubleToStr(Size, 2), font_size, font_face, balance_font_color);

   CalculateRiskAndPositionSize();
}

void CalculateRiskAndPositionSize()
{
   if (!UseMoneyInsteadOfPercentage) RiskMoney = Size * Risk / 100;
   else RiskMoney = MoneyRisk;
   ObjectSetText("RiskMoney", "Risk, money:  " + DoubleToStr(RiskMoney, 2), font_size, font_face, rmm_font_color);
   double UnitCost = MarketInfo(Symbol(), MODE_TICKVALUE);
   double TickSize = MarketInfo(Symbol(), MODE_TICKSIZE);
   if ((StopLoss != 0) && (UnitCost != 0) && (TickSize != 0)) PositionSize = RiskMoney / (StopLoss * UnitCost / TickSize);
   ObjectSetText("PositionSize", "Pos. Size:    " + DoubleToStr(PositionSize, 2), font_size + 1, font_face, ps_font_color);
}

int ShowOrderUI(){
   
   if (ObjectFind("StopLossLine") > -1)
   {
      StopLossLevel = ObjectGet("StopLossLine", OBJPROP_PRICE1);
      ObjectSet("StopLossLine", OBJPROP_STYLE, stoploss_line_style);
      ObjectSet("StopLossLine", OBJPROP_COLOR, stoploss_line_color);
      ObjectSet("StopLossLine", OBJPROP_WIDTH, stoploss_line_width);
   }
   
   if ((EntryLevel == 0) && (StopLossLevel == 0))
   {
      Print(Symbol() + ": Entry and Stop-Loss levels not given. Using local values.");
      EntryLevel = High[0];
      StopLossLevel = Low[0];
      if (EntryLevel == StopLossLevel) StopLossLevel -= Point;
   }
   
   if (EntryLevel - StopLossLevel == 0)
   {
      Alert("Entry and Stop-Loss levels should be different and non-zero.");
      return(-1);
   }

   if (UseAskBidForEntry)
   {
      RefreshRates();
      if ((Ask > 0) && (Bid > 0))
      {
         // Long entry
         if (StopLossLevel < Bid) EntryLevel = Ask;
         // Short entry
         else if (StopLossLevel > Ask) EntryLevel = Bid;
      }
   }

   ObjectCreate("StopLoss", OBJ_LABEL, 0, 0, 0);
   ObjectSet("StopLoss", OBJPROP_CORNER, corner);
   ObjectSet("StopLoss", OBJPROP_XDISTANCE, distance_x);
   ObjectSet("StopLoss", OBJPROP_YDISTANCE, distance_y + 37);
   ObjectSetText("StopLoss", "Stop-Loss:    " + DoubleToStr(StopLossLevel, Digits), font_size, font_face, sl_font_color);
      
   if (ObjectFind("StopLossLine") == -1)
   {
      ObjectCreate("StopLossLine", OBJ_HLINE, 0, Time[0], StopLossLevel-(initStoploss*Point));
      ObjectSet("StopLossLine", OBJPROP_STYLE, stoploss_line_style);
      ObjectSet("StopLossLine", OBJPROP_COLOR, stoploss_line_color);
      ObjectSet("StopLossLine", OBJPROP_WIDTH, stoploss_line_width);
      ObjectSet("StopLossLine", OBJPROP_WIDTH, 1);
   }
   StopLoss = MathAbs(EntryLevel - StopLossLevel);
   
   int y_shift = 55;
   
   if (UseEquityInsteadOfBalance)
   {
      SizeText = "Equity";
      Size = AccountEquity();
   }
   else
   {
      SizeText = "Balance";
      Size = AccountBalance();
   }
   ObjectCreate("AccountSize", OBJ_LABEL, 0, 0, 0);
   ObjectSet("AccountSize", OBJPROP_CORNER, corner);
   ObjectSet("AccountSize", OBJPROP_XDISTANCE, distance_x);
   ObjectSet("AccountSize", OBJPROP_YDISTANCE, distance_y + y_shift);
   ObjectSetText("AccountSize", "Acc. " + SizeText + ": " + DoubleToStr(Size, 2), font_size, font_face, balance_font_color);
   y_shift += 15;
   
   if (!UseMoneyInsteadOfPercentage)
   {
      ObjectCreate("Risk", OBJ_LABEL, 0, 0, 0);
      ObjectSet("Risk", OBJPROP_CORNER, corner);
      ObjectSet("Risk", OBJPROP_XDISTANCE, distance_x);
      ObjectSet("Risk", OBJPROP_YDISTANCE, distance_y + y_shift);
      ObjectSetText("Risk", "Risk:         " + DoubleToStr(Risk, 2) + "%", font_size, font_face, rp_font_color);
      y_shift += 15;
   }
   
   ObjectCreate("RiskMoney", OBJ_LABEL, 0, 0, 0);
   ObjectSet("RiskMoney", OBJPROP_CORNER, corner);
   ObjectSet("RiskMoney", OBJPROP_XDISTANCE, distance_x);
   ObjectSet("RiskMoney", OBJPROP_YDISTANCE, distance_y + y_shift);
   y_shift += 15;

   if (TakeProfitLevel > 0)
   {
      ObjectCreate("PotentialProfit", OBJ_LABEL, 0, 0, 0);
      ObjectSet("PotentialProfit", OBJPROP_CORNER, corner);
      ObjectSet("PotentialProfit", OBJPROP_XDISTANCE, distance_x);
      ObjectSet("PotentialProfit", OBJPROP_YDISTANCE, distance_y + y_shift);
      y_shift += 15;

      ObjectCreate("RR", OBJ_LABEL, 0, 0, 0);
      ObjectSet("RR", OBJPROP_CORNER, corner);
      ObjectSet("RR", OBJPROP_XDISTANCE, distance_x);
      ObjectSet("RR", OBJPROP_YDISTANCE, distance_y + y_shift);
      ObjectSetText("RR", "Reward/Risk:  " + DoubleToStr(MathAbs((TakeProfitLevel - EntryLevel) / (EntryLevel - TakeProfitLevel)), 1), font_size, font_face, rr_font_color);
      y_shift += 15;
   }

   ObjectCreate("PositionSize", OBJ_LABEL, 0, 0, 0);
   ObjectSet("PositionSize", OBJPROP_CORNER, corner);
   ObjectSet("PositionSize", OBJPROP_XDISTANCE, distance_x);
   ObjectSet("PositionSize", OBJPROP_YDISTANCE, distance_y + y_shift);

   CalculateRiskAndPositionSize();
   y_shift+=30;
   createBackButton(y_shift, cancelId);
   createTradeButton(y_shift, tradeId);
   return(1);
}

void DeleteOrderUI(){
   Print("Delete Order UI");
   ObjectDelete("StopLoss");
   if (DeleteLines) ObjectDelete("StopLossLine");
   if (!UseMoneyInsteadOfPercentage) ObjectDelete("Risk");
   ObjectDelete("AccountSize");
   ObjectDelete("RiskMoney");
   ObjectDelete("PositionSize");
   ObjectDelete(0,tradeId);
   ObjectDelete(0,cancelId);
   ObjectDelete("EntryLine");
   ObjectDelete("StopLossLine");
}

int ShowLimitUI(){
   if (ObjectFind("EntryLine") > -1)
   {
      EntryLevel = ObjectGet("EntryLine", OBJPROP_PRICE1);
      ObjectSet("EntryLine", OBJPROP_STYLE, entry_line_style);
      ObjectSet("EntryLine", OBJPROP_COLOR, entry_line_color);
      ObjectSet("EntryLine", OBJPROP_WIDTH, entry_line_width);
   }
   if (ObjectFind("StopLossLine") > -1)
   {
      StopLossLevel = ObjectGet("StopLossLine", OBJPROP_PRICE1);
      ObjectSet("StopLossLine", OBJPROP_STYLE, stoploss_line_style);
      ObjectSet("StopLossLine", OBJPROP_COLOR, stoploss_line_color);
      ObjectSet("StopLossLine", OBJPROP_WIDTH, stoploss_line_width);
   }
   if (ObjectFind("TakeProfitLine") > -1)
   {
      TakeProfitLevel = ObjectGet("TakeProfitLine", OBJPROP_PRICE1);
      ObjectSet("TakeProfitLine", OBJPROP_STYLE, takeprofit_line_style);
      ObjectSet("TakeProfitLine", OBJPROP_COLOR, takeprofit_line_color);
      ObjectSet("TakeProfitLine", OBJPROP_WIDTH, takeprofit_line_width);
   }
   
   if ((EntryLevel == 0) && (StopLossLevel == 0))
   {
      Print(Symbol() + ": Entry and Stop-Loss levels not given. Using local values.");
      EntryLevel = High[0];
      StopLossLevel = Low[0];
      if (EntryLevel == StopLossLevel) StopLossLevel -= Point;
   }
   if (EntryLevel - StopLossLevel == 0)
   {
      Alert("Entry and Stop-Loss levels should be different and non-zero.");
      return(-1);
   }

   if (UseAskBidForEntry)
   {
      RefreshRates();
      if ((Ask > 0) && (Bid > 0))
      {
         // Long entry
         if (StopLossLevel < Bid) EntryLevel = Ask;
         // Short entry
         else if (StopLossLevel > Ask) EntryLevel = Bid;
      }
   }
   
   ObjectCreate("EntryLevel", OBJ_LABEL, 0, 0, 0);
   ObjectSet("EntryLevel", OBJPROP_CORNER, corner);
   ObjectSet("EntryLevel", OBJPROP_XDISTANCE, distance_x);
   ObjectSet("EntryLevel", OBJPROP_YDISTANCE, distance_y + 37);
   ObjectSetText("EntryLevel", "Entry Line:   " + DoubleToStr(EntryLevel, Digits), font_size, font_face, entry_font_color);

   if (ObjectFind("EntryLine") == -1) 
   {
      ObjectCreate("EntryLine", OBJ_HLINE, 0, Time[0], EntryLevel+(initEntry*Point));
      ObjectSet("EntryLine", OBJPROP_STYLE, entry_line_style);
      ObjectSet("EntryLine", OBJPROP_COLOR, entry_line_color);
      ObjectSet("EntryLine", OBJPROP_WIDTH, entry_line_width);
      ObjectSet("EntryLine", OBJPROP_WIDTH, 1);
   }

   ObjectCreate("StopLoss", OBJ_LABEL, 0, 0, 0);
   ObjectSet("StopLoss", OBJPROP_CORNER, corner);
   ObjectSet("StopLoss", OBJPROP_XDISTANCE, distance_x);
   ObjectSet("StopLoss", OBJPROP_YDISTANCE, distance_y + 52);
   ObjectSetText("StopLoss", "Stop-Loss:    " + DoubleToStr(StopLossLevel, Digits), font_size, font_face, sl_font_color);
      
   if (ObjectFind("StopLossLine") == -1)
   {
      ObjectCreate("StopLossLine", OBJ_HLINE, 0, Time[0], StopLossLevel-(initStoploss*Point));
      ObjectSet("StopLossLine", OBJPROP_STYLE, stoploss_line_style);
      ObjectSet("StopLossLine", OBJPROP_COLOR, stoploss_line_color);
      ObjectSet("StopLossLine", OBJPROP_WIDTH, stoploss_line_width);
      ObjectSet("StopLossLine", OBJPROP_WIDTH, 1);
   }
   StopLoss = MathAbs(EntryLevel - StopLossLevel);
   
   int y_shift = 67;
   
   if (TakeProfitLevel > 0) // Show TP line and RR ratio only if TakeProfitLevel input parameter is set by user or found via chart object.
   {
      ObjectCreate("TakeProfit", OBJ_LABEL, 0, 0, 0);
      ObjectSet("TakeProfit", OBJPROP_CORNER, corner);
      ObjectSet("TakeProfit", OBJPROP_XDISTANCE, distance_x);
      ObjectSet("TakeProfit", OBJPROP_YDISTANCE, distance_y + y_shift);
      ObjectSetText("TakeProfit", "Take-Profit:  " + DoubleToStr(TakeProfitLevel, Digits), font_size, font_face, tp_font_color);
      y_shift += 15;

      if (ObjectFind("TakeProfitLine") == -1) 
      {
         ObjectCreate("TakeProfitLine", OBJ_HLINE, 0, Time[0], TakeProfitLevel);
         ObjectSet("TakeProfitLine", OBJPROP_STYLE, takeprofit_line_style);
         ObjectSet("TakeProfitLine", OBJPROP_COLOR, takeprofit_line_color);
         ObjectSet("TakeProfitLine", OBJPROP_WIDTH, takeprofit_line_width);
         ObjectSet("TakeProfitLine", OBJPROP_WIDTH, 1);
      }
   }
   
   if (UseEquityInsteadOfBalance)
   {
      SizeText = "Equity";
      Size = AccountEquity();
   }
   else
   {
      SizeText = "Balance";
      Size = AccountBalance();
   }
   ObjectCreate("AccountSize", OBJ_LABEL, 0, 0, 0);
   ObjectSet("AccountSize", OBJPROP_CORNER, corner);
   ObjectSet("AccountSize", OBJPROP_XDISTANCE, distance_x);
   ObjectSet("AccountSize", OBJPROP_YDISTANCE, distance_y + y_shift);
   ObjectSetText("AccountSize", "Acc. " + SizeText + ": " + DoubleToStr(Size, 2), font_size, font_face, balance_font_color);
   y_shift += 15;
   
   if (!UseMoneyInsteadOfPercentage)
   {
      ObjectCreate("Risk", OBJ_LABEL, 0, 0, 0);
      ObjectSet("Risk", OBJPROP_CORNER, corner);
      ObjectSet("Risk", OBJPROP_XDISTANCE, distance_x);
      ObjectSet("Risk", OBJPROP_YDISTANCE, distance_y + y_shift);
      ObjectSetText("Risk", "Risk:         " + DoubleToStr(Risk, 2) + "%", font_size, font_face, rp_font_color);
      y_shift += 15;
   }
   
   ObjectCreate("RiskMoney", OBJ_LABEL, 0, 0, 0);
   ObjectSet("RiskMoney", OBJPROP_CORNER, corner);
   ObjectSet("RiskMoney", OBJPROP_XDISTANCE, distance_x);
   ObjectSet("RiskMoney", OBJPROP_YDISTANCE, distance_y + y_shift);
   y_shift += 15;

   if (TakeProfitLevel > 0)
   {
      ObjectCreate("PotentialProfit", OBJ_LABEL, 0, 0, 0);
      ObjectSet("PotentialProfit", OBJPROP_CORNER, corner);
      ObjectSet("PotentialProfit", OBJPROP_XDISTANCE, distance_x);
      ObjectSet("PotentialProfit", OBJPROP_YDISTANCE, distance_y + y_shift);
      y_shift += 15;

      ObjectCreate("RR", OBJ_LABEL, 0, 0, 0);
      ObjectSet("RR", OBJPROP_CORNER, corner);
      ObjectSet("RR", OBJPROP_XDISTANCE, distance_x);
      ObjectSet("RR", OBJPROP_YDISTANCE, distance_y + y_shift);
      ObjectSetText("RR", "Reward/Risk:  " + DoubleToStr(MathAbs((TakeProfitLevel - EntryLevel) / (EntryLevel - TakeProfitLevel)), 1), font_size, font_face, rr_font_color);
      y_shift += 15;
   }

   ObjectCreate("PositionSize", OBJ_LABEL, 0, 0, 0);
   ObjectSet("PositionSize", OBJPROP_CORNER, corner);
   ObjectSet("PositionSize", OBJPROP_XDISTANCE, distance_x);
   ObjectSet("PositionSize", OBJPROP_YDISTANCE, distance_y + y_shift);

   CalculateRiskAndPositionSize();
   y_shift+=30;
   createBackButton(y_shift, cancelLimitId);
   createTradeButton(y_shift, tradeLimitId);
   return(1);
}

void DeleteLimitUI(){
   Print("Delete Order UI");
   ObjectDelete("EntryLevel");
   if (DeleteLines) ObjectDelete("EntryLine");
   ObjectDelete("StopLoss");
   if (DeleteLines) ObjectDelete("StopLossLine");
   if (!UseMoneyInsteadOfPercentage) ObjectDelete("Risk");
   ObjectDelete("AccountSize");
   ObjectDelete("RiskMoney");
   ObjectDelete("PositionSize");
   
   if (TakeProfitLevel > 0)
   {
      ObjectDelete("TakeProfit");
      if (DeleteLines) ObjectDelete("TakeProfitLine");
      ObjectDelete("RR");
      ObjectDelete("PotentialProfit");
   }
   
   ObjectDelete(0,tradeLimitId);
   ObjectDelete(0,cancelLimitId);
   ObjectDelete("EntryLine");
   ObjectDelete("StopLossLine");
}


/*************************************************************/

int ShowStopUI(){
   if (ObjectFind("EntryLine") > -1)
   {
      EntryLevel = ObjectGet("EntryLine", OBJPROP_PRICE1);
      ObjectSet("EntryLine", OBJPROP_STYLE, entry_line_style);
      ObjectSet("EntryLine", OBJPROP_COLOR, entry_line_color);
      ObjectSet("EntryLine", OBJPROP_WIDTH, entry_line_width);
   }
   if (ObjectFind("StopLossLine") > -1)
   {
      StopLossLevel = ObjectGet("StopLossLine", OBJPROP_PRICE1);
      ObjectSet("StopLossLine", OBJPROP_STYLE, stoploss_line_style);
      ObjectSet("StopLossLine", OBJPROP_COLOR, stoploss_line_color);
      ObjectSet("StopLossLine", OBJPROP_WIDTH, stoploss_line_width);
   }
   if (ObjectFind("TakeProfitLine") > -1)
   {
      TakeProfitLevel = ObjectGet("TakeProfitLine", OBJPROP_PRICE1);
      ObjectSet("TakeProfitLine", OBJPROP_STYLE, takeprofit_line_style);
      ObjectSet("TakeProfitLine", OBJPROP_COLOR, takeprofit_line_color);
      ObjectSet("TakeProfitLine", OBJPROP_WIDTH, takeprofit_line_width);
   }
   
   if ((EntryLevel == 0) && (StopLossLevel == 0))
   {
      Print(Symbol() + ": Entry and Stop-Loss levels not given. Using local values.");
      EntryLevel = High[0];
      StopLossLevel = Low[0];
      if (EntryLevel == StopLossLevel) StopLossLevel -= Point;
   }
   if (EntryLevel - StopLossLevel == 0)
   {
      Alert("Entry and Stop-Loss levels should be different and non-zero.");
      return(-1);
   }

   if (UseAskBidForEntry)
   {
      RefreshRates();
      if ((Ask > 0) && (Bid > 0))
      {
         // Long entry
         if (StopLossLevel < Bid) EntryLevel = Ask;
         // Short entry
         else if (StopLossLevel > Ask) EntryLevel = Bid;
      }
   }
   
   ObjectCreate("EntryLevel", OBJ_LABEL, 0, 0, 0);
   ObjectSet("EntryLevel", OBJPROP_CORNER, corner);
   ObjectSet("EntryLevel", OBJPROP_XDISTANCE, distance_x);
   ObjectSet("EntryLevel", OBJPROP_YDISTANCE, distance_y + 37);
   ObjectSetText("EntryLevel", "Entry Line:   " + DoubleToStr(EntryLevel, Digits), font_size, font_face, entry_font_color);

   if (ObjectFind("EntryLine") == -1) 
   {
      ObjectCreate("EntryLine", OBJ_HLINE, 0, Time[0], EntryLevel+(initEntry*Point));
      ObjectSet("EntryLine", OBJPROP_STYLE, entry_line_style);
      ObjectSet("EntryLine", OBJPROP_COLOR, entry_line_color);
      ObjectSet("EntryLine", OBJPROP_WIDTH, entry_line_width);
      ObjectSet("EntryLine", OBJPROP_WIDTH, 1);
   }

   ObjectCreate("StopLoss", OBJ_LABEL, 0, 0, 0);
   ObjectSet("StopLoss", OBJPROP_CORNER, corner);
   ObjectSet("StopLoss", OBJPROP_XDISTANCE, distance_x);
   ObjectSet("StopLoss", OBJPROP_YDISTANCE, distance_y + 52);
   ObjectSetText("StopLoss", "Stop-Loss:    " + DoubleToStr(StopLossLevel, Digits), font_size, font_face, sl_font_color);
      
   if (ObjectFind("StopLossLine") == -1)
   {
      ObjectCreate("StopLossLine", OBJ_HLINE, 0, Time[0], StopLossLevel-(initStoploss*Point));
      ObjectSet("StopLossLine", OBJPROP_STYLE, stoploss_line_style);
      ObjectSet("StopLossLine", OBJPROP_COLOR, stoploss_line_color);
      ObjectSet("StopLossLine", OBJPROP_WIDTH, stoploss_line_width);
      ObjectSet("StopLossLine", OBJPROP_WIDTH, 1);
   }
   StopLoss = MathAbs(EntryLevel - StopLossLevel);
   
   int y_shift = 67;
   
   if (TakeProfitLevel > 0) // Show TP line and RR ratio only if TakeProfitLevel input parameter is set by user or found via chart object.
   {
      ObjectCreate("TakeProfit", OBJ_LABEL, 0, 0, 0);
      ObjectSet("TakeProfit", OBJPROP_CORNER, corner);
      ObjectSet("TakeProfit", OBJPROP_XDISTANCE, distance_x);
      ObjectSet("TakeProfit", OBJPROP_YDISTANCE, distance_y + y_shift);
      ObjectSetText("TakeProfit", "Take-Profit:  " + DoubleToStr(TakeProfitLevel, Digits), font_size, font_face, tp_font_color);
      y_shift += 15;

      if (ObjectFind("TakeProfitLine") == -1) 
      {
         ObjectCreate("TakeProfitLine", OBJ_HLINE, 0, Time[0], TakeProfitLevel);
         ObjectSet("TakeProfitLine", OBJPROP_STYLE, takeprofit_line_style);
         ObjectSet("TakeProfitLine", OBJPROP_COLOR, takeprofit_line_color);
         ObjectSet("TakeProfitLine", OBJPROP_WIDTH, takeprofit_line_width);
         ObjectSet("TakeProfitLine", OBJPROP_WIDTH, 1);
      }
   }
   
   if (UseEquityInsteadOfBalance)
   {
      SizeText = "Equity";
      Size = AccountEquity();
   }
   else
   {
      SizeText = "Balance";
      Size = AccountBalance();
   }
   ObjectCreate("AccountSize", OBJ_LABEL, 0, 0, 0);
   ObjectSet("AccountSize", OBJPROP_CORNER, corner);
   ObjectSet("AccountSize", OBJPROP_XDISTANCE, distance_x);
   ObjectSet("AccountSize", OBJPROP_YDISTANCE, distance_y + y_shift);
   ObjectSetText("AccountSize", "Acc. " + SizeText + ": " + DoubleToStr(Size, 2), font_size, font_face, balance_font_color);
   y_shift += 15;
   
   if (!UseMoneyInsteadOfPercentage)
   {
      ObjectCreate("Risk", OBJ_LABEL, 0, 0, 0);
      ObjectSet("Risk", OBJPROP_CORNER, corner);
      ObjectSet("Risk", OBJPROP_XDISTANCE, distance_x);
      ObjectSet("Risk", OBJPROP_YDISTANCE, distance_y + y_shift);
      ObjectSetText("Risk", "Risk:         " + DoubleToStr(Risk, 2) + "%", font_size, font_face, rp_font_color);
      y_shift += 15;
   }
   
   ObjectCreate("RiskMoney", OBJ_LABEL, 0, 0, 0);
   ObjectSet("RiskMoney", OBJPROP_CORNER, corner);
   ObjectSet("RiskMoney", OBJPROP_XDISTANCE, distance_x);
   ObjectSet("RiskMoney", OBJPROP_YDISTANCE, distance_y + y_shift);
   y_shift += 15;

   if (TakeProfitLevel > 0)
   {
      ObjectCreate("PotentialProfit", OBJ_LABEL, 0, 0, 0);
      ObjectSet("PotentialProfit", OBJPROP_CORNER, corner);
      ObjectSet("PotentialProfit", OBJPROP_XDISTANCE, distance_x);
      ObjectSet("PotentialProfit", OBJPROP_YDISTANCE, distance_y + y_shift);
      y_shift += 15;

      ObjectCreate("RR", OBJ_LABEL, 0, 0, 0);
      ObjectSet("RR", OBJPROP_CORNER, corner);
      ObjectSet("RR", OBJPROP_XDISTANCE, distance_x);
      ObjectSet("RR", OBJPROP_YDISTANCE, distance_y + y_shift);
      ObjectSetText("RR", "Reward/Risk:  " + DoubleToStr(MathAbs((TakeProfitLevel - EntryLevel) / (EntryLevel - TakeProfitLevel)), 1), font_size, font_face, rr_font_color);
      y_shift += 15;
   }

   ObjectCreate("PositionSize", OBJ_LABEL, 0, 0, 0);
   ObjectSet("PositionSize", OBJPROP_CORNER, corner);
   ObjectSet("PositionSize", OBJPROP_XDISTANCE, distance_x);
   ObjectSet("PositionSize", OBJPROP_YDISTANCE, distance_y + y_shift);

   CalculateRiskAndPositionSize();
   y_shift+=30;
   createBackButton(y_shift, cancelStopId);
   createTradeButton(y_shift, tradeStopId);
   return(1);
}

void DeleteStopUI(){
   Print("Delete Order UI");
   ObjectDelete("EntryLevel");
   if (DeleteLines) ObjectDelete("EntryLine");
   ObjectDelete("StopLoss");
   if (DeleteLines) ObjectDelete("StopLossLine");
   if (!UseMoneyInsteadOfPercentage) ObjectDelete("Risk");
   ObjectDelete("AccountSize");
   ObjectDelete("RiskMoney");
   ObjectDelete("PositionSize");
   
   if (TakeProfitLevel > 0)
   {
      ObjectDelete("TakeProfit");
      if (DeleteLines) ObjectDelete("TakeProfitLine");
      ObjectDelete("RR");
      ObjectDelete("PotentialProfit");
   }
   
   ObjectDelete(0,tradeStopId);
   ObjectDelete(0,cancelStopId);
   ObjectDelete("EntryLine");
   ObjectDelete("StopLossLine");
}



















void createTradeButton(int y_shift, string id){
   ObjectCreate(0,id,OBJ_BUTTON,0,50,20);
   ObjectSetInteger(0,id,OBJPROP_COLOR,clrWhite);
   ObjectSetInteger(0,id,OBJPROP_BGCOLOR,clrBlue);
   ObjectSetInteger(0,id,OBJPROP_BORDER_COLOR,clrBlue);
   ObjectSetInteger(0,id,OBJPROP_XDISTANCE,120);
   ObjectSetInteger(0,id,OBJPROP_YDISTANCE,distance_y + y_shift);
   ObjectSetInteger(0,id,OBJPROP_XSIZE,100);
   ObjectSetInteger(0,id,OBJPROP_YSIZE,25);
   ObjectSetString(0,id,OBJPROP_FONT,"Arial");
   ObjectSetString(0,id,OBJPROP_TEXT,"Place");
   ObjectSetInteger(0,id,OBJPROP_FONTSIZE,9);
   ObjectSetInteger(0,id,OBJPROP_SELECTABLE,0);
   y_shift += 15;
}

void createBackButton(int y_shift, string id){
   ObjectCreate(0,id,OBJ_BUTTON,0,50,20);
   ObjectSetInteger(0,id,OBJPROP_COLOR,clrWhite);
   ObjectSetInteger(0,id,OBJPROP_BGCOLOR,clrRed);
   ObjectSetInteger(0,id,OBJPROP_BORDER_COLOR,clrRed);
   ObjectSetInteger(0,id,OBJPROP_XDISTANCE,10);
   ObjectSetInteger(0,id,OBJPROP_YDISTANCE,distance_y + y_shift);
   ObjectSetInteger(0,id,OBJPROP_XSIZE,100);
   ObjectSetInteger(0,id,OBJPROP_YSIZE,25);
   ObjectSetString(0,id,OBJPROP_FONT,"Arial");
   ObjectSetString(0,id,OBJPROP_TEXT,"Cancel");
   ObjectSetInteger(0,id,OBJPROP_FONTSIZE,9);
   ObjectSetInteger(0,id,OBJPROP_SELECTABLE,0);
   y_shift += 15;
}

void MarketOrder(){
   //todo where is the stoploss;
   MarketOrderBuy();
}

void LimitOrder(){

}

void StopOrder(){

}

void MarketOrderBuy()
{
    double lot = 0.1;
    int magic = 1982;
    int ticket=OrderSend(Symbol(),OP_BUY,lot,Ask,3,stoploss,entry,"Buy Order",magic,0,Green);
    if(ticket < 0)
    {
      Print("OrderSend failed with error #",GetLastError());
      //ShowErrorMessage("Error: Please move the stoploss #" + GetLastError());
    }else{
      if(OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES)){
         Print("Order 100%");
         //BroadcastSignal(ticket, "BUY");
         //PushValueOnArray(ticket);
      }
    }
}

/*void Sell()
{
    double range = GetPreviousRange();
    double high = High[1];
    double tp = Bid - range - (spread*Point);
    double pip = 1*multiplier*Point;
    double sl = high+pip;
   
   int ticket=OrderSend(Symbol(),OP_SELL,lot,Bid,3,sl,tp, "Sell Order",magic,0,Red);
  
   if(ticket < 0)
   {
      Print("OrderSend failed with error #",GetLastError());
   }else{
      if(OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES)){
         BroadcastSignal(ticket, "SELL");
         PushValueOnArray(ticket);
      }
   }
}*/