//+------------------------------------------------------------------+
//|                                                  Son_Project.mq5 |
//|                                  Copyright 2023, Son.Nguyen-Cong |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#include "zone.mqh"
#include "candle.mqh"
#include "candleLib.mqh"
#include <Trade\Trade.mqh>

CTrade trade;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   findResistanceZones(50, 20); // duyệt 50 nến, gom vùng cách nhau trong 20 pip

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+


void OnTick()
{
   detect_and_draw_zone(); // chỉ cần gọi 1 dòng!
}

