//+------------------------------------------------------------------+
//|                                                       candle.mqh |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
class Candle
{
public:
    int index;
    double openPrice;
    double closePrice;
    double highPrice;
    double lowPrice; 
    string colorCandle;
    double shadowLower;
    double shadowUpper;
    double bodySize;
    double totalSize;
    string typeCandle;
    // method      
    Candle(int i){  
      this.index = i;
      this.openPrice = iOpen(Symbol(),Period(),this.index);
      this.closePrice = iClose(Symbol(),Period(),this.index);
      this.highPrice = iHigh(Symbol(),Period(),this.index);
      this.lowPrice = iLow(Symbol(),Period(),this.index);
      
      if ( this.openPrice <= this.closePrice ) 
         this.colorCandle = "BLUE";
      else 
         this.colorCandle =  "RED";
      
      if(this.colorCandle == "RED"){
         this.shadowLower = this.closePrice - this.lowPrice;
      } else {
         this.shadowLower = this.openPrice - this.lowPrice;
      }
      
      if(this.colorCandle == "RED"){
      this.shadowUpper = this.highPrice - this.openPrice;
      } else {
      this.shadowUpper = this.highPrice - this.closePrice;
      }
      
      this.bodySize = MathAbs(this.openPrice - this.closePrice);
      this.totalSize = MathAbs(this.highPrice - this.lowPrice);
    }
};


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

void GetCandleInfo(const Candle& candle)
{
   Print("GetCandleInfo=============== Start =====================");
   Print("index = ", candle.index);
   Print("openPrice = ", candle.openPrice);
   Print("closePrice = ", candle.closePrice);
   Print("highPrice = ", candle.highPrice);
   Print("lowPrice = ", candle.lowPrice);
   Print("colorCandle = ", candle.colorCandle);
   Print("shadowLower = ", candle.shadowLower);
   Print("shadowUpper = ", candle.shadowUpper);
   Print("bodySize = ", candle.bodySize); 
   Print("totalSize = ", candle.totalSize);
   Print("GetCandleInfo=============== End =======================");
}

double averageSize(int numCandle) {
   if(numCandle <=0 ) numCandle = 1;
   
   double sum = 0;
   for(int i = 0;i<numCandle;i++) {
      double highPrice = iHigh(Symbol(),Period(),i);
      double lowPrice = iLow(Symbol(),Period(),i);
      double size = highPrice - lowPrice;
      sum += size;
   }
   
   return sum/numCandle;
}

bool isMarubozu(double _averageSize){
   Print("_averageSize = ", _averageSize);
   double bodySize = MathAbs(iOpen(Symbol(),Period(),0) - iClose(Symbol(),Period(),0)); 
   Print("bodySize = ", bodySize);
   
   if ( (iOpen(Symbol(),Period(),0) <= iClose(Symbol(),Period(),0)) ) 
   {

   }
   
   if(
      bodySize >= _averageSize //&& 
      //shadowLower <= _averageSize/3 &&
      //shadowUpper <= _averageSize/3
      )
      return true;
   else return false;
}
