//+------------------------------------------------------------------+
//|  From "Mesa Stochastic" by John F. Ehlers
//|  Technical Analysis of Stocks and Commodities
//|  JANUARY 2014 TRADERS’ TIPS CODE
//| In his article in this issue, “Predictive And Successful 
//| Indicatorsauthor John Ehlers presents two new indicators: the 
//| SuperSmoother filter, which is superior to moving averages for
//| removing aliasing noise, and the MESA Stochastic oscillator, a 
//| stochastic successor that removes the effect of spectral dilation
//| through the use of a roofing filter.
//+------------------------------------------------------------------+
//|                                           SuperSmoother.mq5      |
//| SuperSmoother                             Copyright 2016, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.00"
#property indicator_chart_window
const double PI=3.14159265359;
#property indicator_buffers 1
#property indicator_plots 1
#property indicator_type1         DRAW_LINE
#property indicator_color1        clrRed
#property indicator_width1 2
input int InpSmoothing=10; //  Smoothing
                           //'Highpass filter cyclic components whose periods are shorter than 48 bars
double SQ2=sqrt(2);
double FILT[];
int min_rates_total=10;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- 
   SetIndexBuffer(0,FILT,INDICATOR_DATA);
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---
   int i,first;
   if(rates_total<=min_rates_total) return(0);
//---
   int begin_pos=min_rates_total;

   first=begin_pos;
   if(first+1<prev_calculated) first=prev_calculated-2;

//---
   for(i=first; i<rates_total && !IsStopped(); i++)
     {

      double a1,b1,c2,c3,c1;

      // SuperSmoother Filter

      a1 = MathExp( -SQ2  * PI / InpSmoothing );
      b1 = 2 * a1 * MathCos( SQ2 *PI / InpSmoothing );
      c2 = b1;
      c3 = -a1 * a1;
      c1 = 1 - c2 - c3;
      FILT[i]=c1 *(close[i]+close[i-1])/2+c2*FILT[i-1]+c3*FILT[i-2];

     }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
