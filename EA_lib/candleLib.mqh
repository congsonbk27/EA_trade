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
enum CANDLE_TYPE {
   CANDLE_TYPE_PINBAR = 0,
   CANDLE_TYPE_MARUBOZU = 1,
   
};

string CheckCandleColor(int index){
   if ( iOpen(Symbol(), Period(), index) <= iClose(Symbol(), Period(), index) ) 
      return "BLUE";
   else 
      return "RED";
}

double shadowLower(int index){
   double shadowLower = 0;
   
   if(CheckCandleColor(index) == "RED"){
      shadowLower = iClose(Symbol(), Period(), index) - iLow(Symbol(), Period(), index);
   }

   if(CheckCandleColor(index) == "BLUE"){
      shadowLower = iOpen(Symbol(), Period(), index) - iLow(Symbol(), Period(), index);
   }
   return shadowLower;
}


double shadowUpper(int index){
   double shadowUpper = 0;
   
   if(CheckCandleColor(index) == "RED"){
      shadowUpper = iHigh(Symbol(), Period(), index) - iOpen(Symbol(), Period(), index);
   }

   if(CheckCandleColor(index) == "BLUE"){
      shadowUpper = iHigh(Symbol(), Period(), index) - iClose(Symbol(), Period(), index);
   }
   return shadowUpper;
}

void getTime(int index){
   
   // Get the time of the open and close of the specified candle
   datetime openTime = iTime(Symbol(), Period(), index);
   datetime closeTime = iTime(Symbol(), Period(), index + 1); // To get the close time
   
   // Convert the times to a readable format (optional)
   string openTimeStr = TimeToString(openTime, TIME_DATE | TIME_MINUTES);
   string closeTimeStr = TimeToString(closeTime, TIME_DATE | TIME_MINUTES);
   
   // Print the times
   //Print("Open Time: ", openTimeStr);
   //Print("Close Time: ", closeTimeStr);

}



void print_candle_info(int index){
   double openPrice = iOpen(Symbol(),Period(),index);
   double closePrice = iClose(Symbol(),Period(),index);
   double highPrice = iHigh(Symbol(),Period(),index);
   double lowPrice = iLow(Symbol(),Period(),index);
   double shadowLower = shadowLower(index);
   double shadowUpper = shadowUpper(index);
   double bodySize = MathAbs(iOpen(Symbol(),Period(),index) - iClose(Symbol(),Period(),index));
   double totalSize = MathAbs(iHigh(Symbol(),Period(),index) - iLow(Symbol(),Period(),index));
 
   string CheckCandleColor = CheckCandleColor(index);
   
   Print("print_candle_info=============== Start =====================");
   //Print("CheckCandleColor = ", CheckCandleColor);
   //Print("openPrice = ", openPrice);
   //Print("closePrice = ", closePrice);
   //Print("highPrice = ", highPrice);
   //Print("lowPrice = ", lowPrice);
   //Print("shadowLower = ", shadowLower);
   //Print("shadowUpper = ", shadowUpper);
   //Print("bodySize = ", bodySize); 
   Print("totalSize = ", totalSize); 
   Print("print_candle_info=============== End =======================");
}

bool isMarubozu(int index){
   double bodySize = MathAbs(iOpen(Symbol(),Period(),index) - iClose(Symbol(),Period(),index));
   double shadowLower = shadowLower(index);
   double shadowUpper = shadowUpper(index);
   if(
      bodySize >= 3 && 
      shadowLower/bodySize <= 0.2 &&
      shadowUpper/bodySize <= 0.2
      )
      return true;
   else return false;
}

bool isPinbar(int index){
   double bodySize = MathAbs(iOpen(Symbol(),Period(),index) - iClose(Symbol(),Period(),index));
   double shadowLower = shadowLower(index);
   double shadowUpper = shadowUpper(index);
   
   if(
      ///bodySize <=1 &&
      bodySize > 0 &&
      shadowUpper <= 0.5 &&
      shadowLower / bodySize >= 3
   )
   return true;
   else return false;
}

bool isDoublePinbar(int index)
{
   if(
      isPinbar(index) &&
      isPinbar(index+1)
   )
   return true;
   else return false;
}


int CountOrders(string type)
{
    int count = 0;
    uint total=PositionsTotal();
    for(uint i=0; i < total; i++)
	 { 	
	   string position_symbol=PositionGetSymbol(i);
	   ENUM_POSITION_TYPE PositionType = ENUM_POSITION_TYPE(PositionGetInteger(POSITION_TYPE));
	   {
	      if(position_symbol == _Symbol)
	      {
	         if(type=="OP_BUY" && PositionType ==0)
	            count ++;
	         if(type=="OP_SELL" && PositionType==1)
	            count ++;
	         if(type=="OP_SELL_OP_BUY" && PositionType>-1 &&PositionType<2)
	            count ++;
	      }
	   }	
	}
   return count;

}

bool price_touch_MA(int index, int ma_period){

   double getMAValue = get_MA_Value(ma_period, index, MODE_EMA);
   
   double openPrice = iOpen(Symbol(),Period(),index);
   double closePrice = iClose(Symbol(),Period(),index);
   double highPrice = iHigh(Symbol(),Period(),index);
   double lowPrice = iLow(Symbol(),Period(),index);
   
   if(
      CheckCandleColor(index) == "BLUE" &&
      openPrice > getMAValue &&
      lowPrice < getMAValue
      
   ){
      return true;
   }
   
   return false;
   
}


struct ma_properties_t {
   double MAValue;
   double MAAngle;
};

ma_properties_t ma_properties(int ma_period){
   
   ma_properties_t ma_1;
   
   int getMA = iMA(_Symbol,_Period, ma_period, 1, MODE_EMA, PRICE_CLOSE);
   
   double         arrayMa[];
   
   ArraySetAsSeries(arrayMa,true);

   CopyBuffer(getMA,0,0,10,arrayMa);
   
   double ValueMACurrent = NormalizeDouble(arrayMa[1],_Digits);
   
   double ValueMAPast    = NormalizeDouble(arrayMa[8],_Digits);
   
   double MA_slope = ValueMACurrent - ValueMAPast;
   
   ma_1.MAAngle = MathArctan(MA_slope) * 180 / 3.14;

   ma_1.MAValue = ValueMACurrent;
   
   //Comment("MAValue = ", ma_1.MAValue, " MAAngle = ", ma_1.MAAngle);
   
   return ma_1;

}

// trend:
// tang = 0
// giam = 1
// siteway = 2
enum ENUM_TREND {
   ENUM_TREND_INCREASE = 0,
   ENUM_TREND_DECREASE = 1,
   ENUM_TREND_SITEWAY = 2,
};

int trendByMA(int ma_period){
   double site_angle = 15;
   ma_properties_t ma_1 = ma_properties(ma_period);
   if(ma_1.MAAngle >= site_angle){
      Comment("Trend is Increase");
      return ENUM_TREND_INCREASE;
   }
   else if(ma_1.MAAngle <= -site_angle){
      Comment("Trend is decrease");
      return ENUM_TREND_DECREASE;
   } 
    else {
      Comment("Trend is siteway");
      return ENUM_TREND_SITEWAY;
   }
   return ENUM_TREND_SITEWAY;
}

bool chien_luoc_04_buy(){

   int ma_period = 500;
   double site_angle = 10;
   double ma_zone = 2;
   
   ma_properties_t ma_1 = ma_properties(ma_period);
   
   double priceLow = iLow(_Symbol, _Period, 1);
   
   //Print("ma_1.MAAngle = ", ma_1.MAAngle);
   //Print("ma_1.MAValue + ma_zone = ", ma_1.MAValue + ma_zone);
   //Print("ma_1.MAValue - ma_zone = ", ma_1.MAValue - ma_zone);
   //Print("priceLow = ", priceLow);
   
   if(
      (ma_1.MAAngle >= site_angle) &&
      (priceLow <=  ma_1.MAValue + ma_zone) && 
      (priceLow >= ma_1.MAValue - ma_zone)
   )
   {
      //Print("chien_luoc_04_buy");
      return true;
   }
   else{
      return false;
   }  
}

bool chien_luoc_04_sell(){

   int ma_period = 500;
   double site_angle = -10;
   double ma_zone = 2;
   
   ma_properties_t ma_1 = ma_properties(ma_period);
   
   double priceLow = iHigh(_Symbol, _Period, 1);
   
   //Print("ma_1.MAAngle = ", ma_1.MAAngle);
   //Print("ma_1.MAValue + ma_zone = ", ma_1.MAValue + ma_zone);
   //Print("ma_1.MAValue - ma_zone = ", ma_1.MAValue - ma_zone);
   //Print("priceLow = ", priceLow);
   
   if(
      (ma_1.MAAngle <= site_angle) &&
      (priceLow <=  ma_1.MAValue + ma_zone) && 
      (priceLow >= ma_1.MAValue - ma_zone)
   )
   {
      //Print("chien_luoc_04_sell");
      return true;
   }
   else{
      return false;
   }  
}


double get_MA_Value(int ma_period,  
   int                  ma_shift,  
   ENUM_MA_METHOD       ma_method)
{
   int getMA = iMA(_Symbol,_Period,ma_period, ma_shift, ma_method, PRICE_CLOSE);
   
   double         arrayMa[];
   
   ArraySetAsSeries(arrayMa,true);

   CopyBuffer(getMA,0,0,10,arrayMa);

   double ValueMACurrent = NormalizeDouble(arrayMa[1],_Digits);
   double ValueMAPast    = NormalizeDouble(arrayMa[8],_Digits);

   double getMAValue = NormalizeDouble(arrayMa[ma_shift],_Digits);
   
   return getMAValue;
}

// Hàm tính góc nghiêng MA
double CalculateMAAngle(int ma_period, int index)
{	
      
   int getMA = iMA(_Symbol,_Period,ma_period, 1, MODE_SMA, PRICE_CLOSE);
   
   double arrayMa[];
   
   ArraySetAsSeries(arrayMa,true);

   CopyBuffer(getMA,0,0,10,arrayMa);

   double ValueMACurrent = NormalizeDouble(arrayMa[1],_Digits);
   double ValueMAPast    = NormalizeDouble(arrayMa[8],_Digits);
    

    if (getMA != INVALID_HANDLE)
    {
        double MA_slope = ValueMACurrent - ValueMAPast;
        double MA_angle_degrees = MathArctan(MA_slope*2) * 180 / 3.14;
        return MA_angle_degrees;
    }
    else
    {
        //Print("Không thể tìm thấy MA.");
        return 0.0; // Trả về giá trị mặc định nếu không tìm thấy MA
    }
}




int ma_trend(int ma_period, int ma_shift, ENUM_MA_METHOD ma_method)
{
   int getMA = iMA(_Symbol,_Period,ma_period, ma_shift, ma_method,PRICE_CLOSE);
   
   double arrayMa[];
   
   ArraySetAsSeries(arrayMa,true);

   CopyBuffer(getMA,0,0,10,arrayMa);

   double ValueMACurrent = NormalizeDouble(arrayMa[1],_Digits);
   double ValueMAPast    = NormalizeDouble(arrayMa[8],_Digits);
   //Print("ValueMACurrent = ", ValueMACurrent);
   //Print("ValueMAPast = ", ValueMAPast);
   
   if(ValueMACurrent > ValueMAPast) 
   {  
      //Print("Trend is Tang");
      return ENUM_TREND_INCREASE;
   }
   
   if(ValueMACurrent < ValueMAPast) 
   {  
      //Print("Trend is Giam");
      return ENUM_TREND_DECREASE;
   }
   
   if(ValueMACurrent == ValueMAPast)    
   {  
      //Print("Trend is Siteway");
      return ENUM_TREND_SITEWAY;
   }
   return ENUM_TREND_INCREASE;
}

// trend on MA 200: tang
// trend on MA 100: Tang
// MA100 > price 
// price > MA200
// MA100 - MA200 <= 5
bool chien_luoc_01(){

   int ma_period_short = 100;
   int ma_period_long = 200;
   int index = 1;
   if(
      ma_trend(ma_period_long, index, MODE_EMA) == 0 &&
      ma_trend(ma_period_short, index, MODE_EMA) == 0 &&
      get_MA_Value(ma_period_short, index, MODE_EMA) > iClose(_Symbol, _Period, index) &&
      iClose(_Symbol, _Period, index) > get_MA_Value(ma_period_long, index, MODE_EMA) &&
      get_MA_Value(ma_period_short, index, MODE_EMA) - get_MA_Value(ma_period_long, index, MODE_EMA) <= 5
   )
   return true;
   else
   return false;
} 

// Buy khi:
// trend ma trend: tang
// ma short cat len ma long
bool chien_luoc_02_buy()
{
   int index = 1;
   int ma_period_short = 20;
   int ma_period_long = 50;
   int ma_period_trend = 500;
     
   int getMA_short = iMA(_Symbol,_Period,ma_period_short, index, MODE_EMA, PRICE_CLOSE); 
   double arrayMa_short[]; 
   ArraySetAsSeries(arrayMa_short,true);
   CopyBuffer(getMA_short,0,0,3,arrayMa_short);
   double getMAValue_short_1 = NormalizeDouble(arrayMa_short[index],_Digits);
   double getMAValue_short_3 = NormalizeDouble(arrayMa_short[2],_Digits);
   
   int getMA_long = iMA(_Symbol,_Period,ma_period_long, index, MODE_EMA, PRICE_CLOSE); 
   double arrayMa_long[]; 
   ArraySetAsSeries(arrayMa_long,true);
   CopyBuffer(getMA_long,0,0,3,arrayMa_long);
   double getMAValue_long_1 = NormalizeDouble(arrayMa_long[index],_Digits);
   double getMAValue_long_3 = NormalizeDouble(arrayMa_long[2],_Digits);
   
   
   if(
      ma_trend(ma_period_trend, index, MODE_EMA) == 0 &&
      getMAValue_short_3 < getMAValue_long_3 && 
      getMAValue_short_1 > getMAValue_long_1
   )
      return true;
   else
      return false;

}

// tp khi trend ko con la tang
// hoac RR = 3R
// hoac ma short cat xuong ma long
bool chien_luoc_02_tp(){

   int index = 1;
   int ma_period_short = 20;
   int ma_period_long = 50;
   int ma_period_trend = 500;
   
   int getMA_short = iMA(_Symbol,_Period,ma_period_short, index, MODE_EMA, PRICE_CLOSE); 
   double arrayMa_short[]; 
   ArraySetAsSeries(arrayMa_short,true);
   CopyBuffer(getMA_short,0,0,3,arrayMa_short);
   double getMAValue_short_1 = NormalizeDouble(arrayMa_short[index],_Digits);
   double getMAValue_short_3 = NormalizeDouble(arrayMa_short[2],_Digits);
   
   int getMA_long = iMA(_Symbol,_Period,ma_period_long, index, MODE_EMA, PRICE_CLOSE); 
   double arrayMa_long[]; 
   ArraySetAsSeries(arrayMa_long,true);
   CopyBuffer(getMA_long,0,0,3,arrayMa_long);
   double getMAValue_long_1 = NormalizeDouble(arrayMa_long[index],_Digits);
   double getMAValue_long_3 = NormalizeDouble(arrayMa_long[2],_Digits);
   
   if(
      //ma_trend(ma_period_trend, index, MODE_EMA) != 0 ||
      //(getMAValue_short_3 > getMAValue_long_3 && getMAValue_short_1 < getMAValue_long_1) ||
      //(ma_trend(ma_period_short, index, MODE_EMA) != 0 && ma_trend(ma_period_long, index, MODE_EMA) != 0)
      ma_trend(100, index, MODE_EMA) != 0
      
   )
      return true;
   else
      return false;
}

// sl khi gia giam xuong duoi duong MA sl
bool chien_luoc_02_sl(){

   int index = 1;
   int ma_period_trend = 500;
   if(
      iClose(_Symbol, _Period, index) > get_MA_Value(ma_period_trend, index, MODE_EMA)
   )
      return true;
   else
      return false;
}




int getTrend(){
   int index =1;
   int ma_period_long = 500;
   int trendLong = ma_trend(ma_period_long, index, MODE_EMA);
   double priceClose = iClose(_Symbol, _Period, index);
   double maValue = get_MA_Value(ma_period_long, index, MODE_EMA);
   double angleMA = CalculateMAAngle(ma_period_long, index);
   Comment("angleMA = ", angleMA);
   
   if(
      trendLong == ENUM_TREND_INCREASE &&
      priceClose > maValue && 
      angleMA >= 15
   ){
      Comment("Trend is: Tang"); 
   } else if (
      trendLong == ENUM_TREND_DECREASE &&
      priceClose < maValue &&
      angleMA <= -15
   ){
      Comment("Trend is: giam"); 
   } else {
      Comment("Trend is: siteway");
   }
   
   return 0; 

}


// Chien luoc co chai
// trend on MA 200: tang
// MA100 > price 
// price > MA200
// MA100 - MA200 <= 5
bool chien_luoc_03(){

   int ma_period_short = 100;
   int ma_period_Average = 200;
   int ma_period_long = 500;
   int index = 1;
   double Bid = SymbolInfoDouble(Symbol(),SYMBOL_BID);
   
   
   double distance2MA = MathAbs( get_MA_Value(ma_period_short, index, MODE_EMA) - get_MA_Value(ma_period_long, index, MODE_EMA));
   double distancePriceMA = MathAbs( Bid - get_MA_Value(ma_period_long, index, MODE_EMA));
   int trendShort = ma_trend(ma_period_short, index, MODE_EMA);
   //int trendAverage = ma_trend(ma_period_Average, index, MODE_EMA);
   int trendLong = ma_trend(ma_period_long, index, MODE_EMA);
   
   
   if(
      //trendAverage == 0 &&
      trendLong == 0 &&
      distance2MA <= 5 &&
      distancePriceMA <= 5
   )
   return true;
   else
   return false;
} 


// Hàm để tìm đỉnh trong quá khứ
double FindPeak(int barsBack)
{
    double highestHigh = -DBL_MAX; // Khởi tạo giá trị cao nhất với giá trị rất nhỏ

    for (int i = 0; i < barsBack; i++)
    {
        double high = iHigh(Symbol(), 0, i); // Lấy giá cao của nến tại vị trí i

        if (high > highestHigh)
        {
            highestHigh = high; // Cập nhật giá trị cao nhất nếu tìm thấy một giá cao lớn hơn
        }
    }

    return highestHigh;
}

// Hàm để tìm vùng kháng cự trong quá khứ
double FindResistanceZone(int barsBack, double sensitivity)
{
    double highestHigh = -DBL_MAX; // Khởi tạo giá trị cao nhất với giá trị rất nhỏ

    for (int i = 0; i < barsBack; i++)
    {
        double high = iHigh(Symbol(), 0, i); // Lấy giá cao của nến tại vị trí i

        if (high > highestHigh)
        {
            highestHigh = high; // Cập nhật giá trị cao nhất nếu tìm thấy một giá cao lớn hơn
        }
    }

    double resistanceLevel = highestHigh * (1 - sensitivity);
   Comment("TresistanceLevel: ", resistanceLevel); 
    return resistanceLevel;
}



// Hàm để đánh dấu vùng kháng cự trên biểu đồ
void MarkResistanceZone(double priceLevel, double width)
{
    ENUM_TIMEFRAMES sub_window = _Period; // Đặt mặc định là khung thời gian của biểu đồ hiện tại
    int chart_id = 0; // ID của biểu đồ (0 cho biểu đồ hiện tại)
    color rectangleColor = clrRed; // Màu của vùng đánh dấu
    ENUM_TIMEFRAMES tf = sub_window; // Sử dụng khung thời gian của cửa sổ con
    datetime time1 = iTime(Symbol(), tf, 0); // Thời gian bắt đầu của cửa sổ con
    datetime time2 = TimeCurrent(); // Thời gian hiện tại
    //OBJPROP_WIDTH = width; // Độ dày của vùng đánh dấu

    // Tạo đối tượng vùng
    int obj = ObjectCreate(chart_id, "ResistanceZone", OBJ_RECTANGLE, 0, time1, priceLevel, time2, priceLevel);
    if (obj != -1)
    {
        // Đặt màu sắc của vùng đánh dấu
        ObjectSetInteger(chart_id, "ResistanceZone", OBJPROP_COLOR, rectangleColor);
    }
}



// Hàm để vẽ một đoạn thẳng màu đỏ theo phương ngang
void DrawHorizontalLine(double y)
{
    int chart_id = 0; // ID của biểu đồ (0 cho biểu đồ hiện tại)
    color lineColor = clrRed; // Màu của đoạn thẳng

    // Vẽ đoạn thẳng trên biểu đồ
    ObjectCreate(chart_id, "HorizontalLine", OBJ_HLINE, 0, 0, 0);
    ObjectSetInteger(chart_id, "HorizontalLine", OBJPROP_COLOR, lineColor);
    //ObjectSetDouble(chart_id, "HorizontalLine", OBJPROP_PRICE1, y);
}