//+------------------------------------------------------------------+
//|                                                    candleLib.mqh |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+
// ==== Struct lưu thông tin vùng ====
struct Zone
{
   string name;
   datetime time1;
   datetime time2;
   double high;
   double low;
   int candleCount;
};

Zone zones[];                 // Mảng lưu các vùng
int zoneCounter = 0;          // Đếm vùng
datetime lastCheckedTime = 0; // Đảm bảo mỗi nến chỉ xử lý 1 lần


bool detect_zone(int barIndex, int lookback, double maxRange, datetime &zoneStartTime, datetime &zoneEndTime, double &high, double &low)
{
   high = iHigh(_Symbol, _Period, barIndex);
   low  = iLow(_Symbol, _Period, barIndex);

   for (int j = 1; j < lookback; j++)
   {
      double h = iHigh(_Symbol, _Period, barIndex + j);
      double l = iLow(_Symbol, _Period, barIndex + j);
      high = MathMax(high, h);
      low = MathMin(low, l);
   }

   double range = high - low;
   if (range <= maxRange)
   {
      zoneStartTime = iTime(_Symbol, _Period, barIndex + lookback);
      zoneEndTime   = iTime(_Symbol, _Period, barIndex);
      return true;
   }

   return false;
}

int countCandlesInsideZone(datetime time1, datetime time2, double zoneHigh, double zoneLow)
{
   int count = 0;
   int totalBars = Bars(_Symbol, _Period);

   for (int i = 0; i < totalBars; i++)
   {
      datetime t = iTime(_Symbol, _Period, i);
      if (t < time1) break;
      if (t > time2) continue;

      double high = iHigh(_Symbol, _Period, i);
      double low  = iLow(_Symbol, _Period, i);

      if (high <= zoneHigh && low >= zoneLow)
         count++;
   }

   return count;
}


// ==== Hàm kiểm tra xem có vùng nào chồng lặp không ====
int find_overlapping_zone(double high, double low, datetime t1, datetime t2, double priceTolerance)
{
   for (int i = 0; i < ArraySize(zones); i++)
   {
      bool priceOverlap =
         MathAbs(zones[i].high - high) <= priceTolerance &&
         MathAbs(zones[i].low - low) <= priceTolerance;

      bool timeOverlap =
         (t1 <= zones[i].time2 && t2 >= zones[i].time1);

      if (priceOverlap && timeOverlap)
         return i;
   }
   return -1;
}

// ==== Hàm vẽ vùng (vẽ lại hoặc tạo mới) ====
void draw_zone(string name, datetime time1, datetime time2, double high, double low)
{
   if (time1 > time2)
   {
      datetime tmp = time1;
      time1 = time2;
      time2 = tmp;
   }

   if (ObjectFind(0, name) >= 0)
      ObjectDelete(0, name);

   if (!ObjectCreate(0, name, OBJ_RECTANGLE, 0, time1, high, time2, low))
   {
      Print("ObjectCreate failed: ", GetLastError());
      return;
   }

   ObjectSetInteger(0, name, OBJPROP_COLOR, clrGold);
   ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_DASH);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, name, OBJPROP_BACK, true);
}

// ==== Hàm kiểm tra cây nến có nằm trong vùng không ====
bool isCandleInsideZone(int barIndex, double zoneHigh, double zoneLow)
{
   double high = iHigh(_Symbol, _Period, barIndex);
   double low = iLow(_Symbol, _Period, barIndex);
   return (high <= zoneHigh && low >= zoneLow);
}

void createNewZone(string name, datetime t1, datetime t2, double hi, double lo)
{
   draw_zone(name, t1, t2, hi, lo);

   Zone z;
   z.name = name;
   z.time1 = t1;
   z.time2 = t2;
   z.high = hi;
   z.low = lo;
   z.candleCount = countCandlesInsideZone(t1, t2, hi, lo);

   ArrayResize(zones, ArraySize(zones) + 1);
   zones[ArraySize(zones) - 1] = z;

   Print("Zone created: ", name);
   Print("Zone candleCount: ", z.candleCount);
}

void updateExistingZone(int idx, double hi, double lo)
{
   zones[idx].high = hi;
   zones[idx].low = lo;
   zones[idx].candleCount = countCandlesInsideZone(zones[idx].time1, zones[idx].time2, hi, lo);

   draw_zone(zones[idx].name, zones[idx].time1, zones[idx].time2, hi, lo);

   Print("Zone updated: ", zones[idx].name);
   Print("Zone candleCount: ", zones[idx].candleCount);
}

void expandZoneWithCandle(int idx)
{
   datetime candleTime = iTime(_Symbol, _Period, 1);
   double candleHigh = iHigh(_Symbol, _Period, 1);
   double candleLow  = iLow(_Symbol, _Period, 1);

   double newHigh = MathMax(zones[idx].high, candleHigh);
   double newLow  = MathMin(zones[idx].low, candleLow);

   if (candleTime < zones[idx].time1)
      zones[idx].time1 = candleTime;
   if (candleTime > zones[idx].time2)
      zones[idx].time2 = candleTime;

   zones[idx].high = newHigh;
   zones[idx].low = newLow;
   zones[idx].candleCount = countCandlesInsideZone(zones[idx].time1, zones[idx].time2, newHigh, newLow);

   draw_zone(zones[idx].name, zones[idx].time1, zones[idx].time2, newHigh, newLow);

   Print("Zone expanded to include candle at ", TimeToString(candleTime));
   Print("Zone candleCount: ", zones[idx].candleCount);
}

void processZoneDetection()
{
   int lookback = 20;
   double maxRangePip = 30;
   int scanBar = 2;

   double pointSize;
   SymbolInfoDouble(_Symbol, SYMBOL_POINT, pointSize);
   double maxRange = maxRangePip * pointSize;

   if (Bars(_Symbol, _Period) < scanBar + lookback)
      return;

   datetime t1, t2;
   double hi, lo;

   if (detect_zone(scanBar, lookback, maxRange, t1, t2, hi, lo))
   {
      int idx = find_overlapping_zone(hi, lo, t1, t2, 5 * pointSize);

      if (idx >= 0)
         updateExistingZone(idx, hi, lo);
      else
      {
         string name = "accum_zone_" + IntegerToString(zoneCounter++);
         createNewZone(name, t1, t2, hi, lo);
      }

      if (isCandleInsideZone(1, hi, lo))
      {
         Print("Candle is inside the zone: ", TimeToString(iTime(_Symbol, _Period, 1)));
         if (idx >= 0)
            expandZoneWithCandle(idx);
      }
      else
         Print("Candle is outside the zone: ", TimeToString(iTime(_Symbol, _Period, 1)));
   }
}

void detect_and_draw_zone()
{
   datetime candleTime = iTime(_Symbol, _Period, 1);
   if (candleTime == lastCheckedTime)
      return;

   lastCheckedTime = candleTime;
   processZoneDetection();
}



