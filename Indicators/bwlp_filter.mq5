//+------------------------------------------------------------------+
//|                                             bwlp_filter.mq5      |
//| bwlp_filter                               Copyright 2016, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.00"
#property indicator_chart_window
#define PId	3.1415926535897932384626433832795


#property indicator_buffers 1
#property indicator_plots 1
#property indicator_type1         DRAW_LINE
#property indicator_color1        clrRed
#property indicator_width1 2



unsigned int NumChann=1;            // channels number 

double InpCutoff     = 1.0;          // cutoff frequency, in Hz 
input double InpFs         = 14.0;        // cutoff frequency in pediord
input unsigned int InpNum_pole=2;      // filter order 

int InpHighpass=0;            // 0:lowpass, 1:highpass

double Fc=InpCutoff/InpFs;  /* normalized cut-off frequency, Hz */

double DEN[];
double NUM[];
double FILT[];
int min_rates_total=10;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
 if(InpNum_pole>12)
     {
      Alert("error initializing expert!");
      return(INIT_FAILED);
     }

//--- 
//--- 
   SetIndexBuffer(0,FILT,INDICATOR_DATA);
//--- 

   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);

   main(NUM,DEN);
   min_rates_total=ArraySize(NUM)*2;
//--- digits
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

      filter(FILT,close,DEN,NUM,i);
     }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
void compute_cheby_iir(double  &num[],double   &den[],unsigned int num_pole,
                       int highpass,double ripple,double cutoff_freq)
  {
   double a[],b[],ta[],tb[];
   double ap[3],bp[3];
   double sa,sb,gain;
   unsigned int i,p;
   int retval=1;

// Allocate temporary arrays
   ArrayResize(a,(num_pole+3));
   ArrayResize(b,(num_pole+3));
   ArrayResize(ta,(num_pole+3));
   ArrayResize(tb,(num_pole+3));
   ArrayFill(a,0,num_pole+3,0);
   ArrayFill(b,0,num_pole+3,0);

   a[2] = 1.0;
   b[2] = 1.0;

   for(p=1; p<=uint(num_pole/2); p++) 
     {
      // Compute the coefficients for this pole
      get_pole_coefs(p,num_pole,cutoff_freq,ripple,highpass,ap,bp);

      // Add coefficients to the cascade
      ArrayCopy(ta,a);
      ArrayCopy(tb,b);
      for(i=2; i<=num_pole+2; i++) 
        {
         a[i] = ap[0]*ta[i] + ap[1]*ta[i-1] + ap[2]*ta[i-2];
         b[i] = tb[i] - bp[1]*tb[i-1] - bp[2]*tb[i-2];
        }
     }

// Finish combining coefficients
   b[2]=0.0;
   for(i=0; i<=num_pole; i++) 
     {
      a[i] = a[i + 2];
      b[i] = -b[i + 2];
     }

// Normalize the gain
   sa=sb=0.0;
   for(i=0; i<=num_pole; i++) 
     {
      sa += a[i] * ((highpass!=0 && (i % 2 !=0)) ? -1.0 : 1.0);
      sb += b[i] * ((highpass!=0 && (i % 2 !=0)) ? -1.0 : 1.0);
     }
   gain=sa/(1.0-sb);
   for(i=0; i<=num_pole; i++)
      a[i]/=gain;

// Copy the results to the num and den
   for(i=0; i<=num_pole; i++) 
     {
      num[i] = a[i];
      den[i] = -b[i];
     }
// den[0] must be 1.0
   den[0]=1.0;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void get_pole_coefs(double p,double np,double fc,double r,int highpass,double  &a[],double  &b[])
  {
   double rp,ip,es,vx,kx,t,w,m,d,x0,x1,x2,y1,y2,k;

// calculate pole locate on the unit circle
   rp = -cos(PId / (np * 2.0) + (p - 1.0) * PId / np);
   ip = sin(PId / (np * 2.0) + (p - 1.0) * PId / np);

// Warp from a circle to an ellipse
   if(r!=0.0) 
     {
      es = sqrt(pow(1.0 / (1.0 - r), 2) - 1.0);
      vx = asinh(1.0/es) / np;
      kx = acosh(1.0/es) / np;
      kx = cosh( kx );
      rp *= sinh(vx) / kx;
      ip *= cosh(vx) / kx;

     }

// s to z domains conversion
   t = 2.0*tan(0.5);
   w = 2.0*PId*fc;
   m = rp*rp + ip*ip;
   d = 4.0 - 4.0*rp*t + m*t*t;
   x0 = t*t/d;
   x1 = 2.0*t*t/d;
   x2 = t*t/d;
   y1 = (8.0 - 2.0*m*t*t)/d;
   y2 = (-4.0 - 4.0*rp*t - m*t*t)/d;

// LP(s) to LP(z) or LP(s) to HP(z)
   if(highpass)
      k=-cos(w/2.0+0.5)/cos(w/2.0-0.5);
   else
      k=sin(0.5-w/2.0)/sin(0.5+w/2.0);
   d=1.0+y1*k-y2*k*k;
   a[0] = (x0 - x1*k + x2*k*k)/d;
   a[1] = (-2.0*x0*k + x1 + x1*k*k - 2.0*x2*k)/d;
   a[2] = (x0*k*k - x1*k + x2)/d;
   b[1] = (2.0*k + y1 + y1*k*k - 2.0*y2*k)/d;
   b[2] = (-k*k - y1*k + y2)/d;
   if(highpass) 
     {
      a[1] *= -1.0;
      b[1] *= -1.0;
     }
  }
//+------------------------------------------------------------------+
//| Hyperbolic sine                                                  |
//+------------------------------------------------------------------+
double sinh(const double x)
  {
//--- return result
   return((MathPow(M_E,x)-MathPow(M_E,-x))/2);
  }
//+------------------------------------------------------------------+
//| Hyperbolic cosine                                                |
//+------------------------------------------------------------------+
double cosh(const double x)
  {
//--- return result
   return((MathPow(M_E,x)+MathPow(M_E,-x))/2);
  }
//+------------------------------------------------------------------+
//| Hyperbolic tangent                                               |
//+------------------------------------------------------------------+
double tanh(const double x)
  {
//--- return result
   return(sinh(x)/cosh(x));
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double asinh(const double v)
  {
   if(v<0)return (-log(-v+sqrt(v*v+1)));
   else return (log(v+sqrt(v*v+1)));
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double acosh(const double v)
  {
   return(log(MathAbs(v)+sqrt(v*v-1)));//

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double atanh(const double v)
  {
   return (0.5*log((1+v)/(1-v)));
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int calc_coeff(unsigned int nchann,double fc,
               int num_pole,int highpass,
               double &num[],double &den[])
  {
   double ripple=0.0;


   ArrayResize(num,num_pole+1);
   ArrayResize(den,num_pole+1);

/* Prepare the z-transform of the filter */
   compute_cheby_iir(num,den,num_pole,highpass,ripple,fc);
   return 0;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int main(double &num[],double &den[])
  {

   int res;
   unsigned int i;

/* Calculate coefficients */
   res=calc_coeff(NumChann,Fc,InpNum_pole,InpHighpass,num,den);
   if(res!=0) 
     {
      Print("Error: unable to calculate coefficients: %d\n",res);
      return -1;
     }

/* TODO: Work with calculated coefficients here (coeff.num, coeff.den) */
   string s="";
   for(i=0; i<InpNum_pole+1;++i)
      s+= DoubleToString(num[i])+", ";
   Print("num: "+s);
   s="";
   for(i=0; i<InpNum_pole+1;++i)
      s+=DoubleToString(den[i])+", ";
   Print("den: "+s);

   return 0;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void filter(double &out[],const double &in[],const double &a[],const double &b[],const int i)
  {

   int Q = ArraySize(a) - 1;
   int P = ArraySize(b) - 1;
   double o=0;
   for(int j=0;j<=P;j++) o += b[j] * in[i - j];
   for(int j=1;j<=Q;j++)
     {

      if(out[i-j]==EMPTY_VALUE) o-=a[j] *in[i-j];
      else o-=a[j] *out[i-j];
     }
   out[i]=o;
  }
//+------------------------------------------------------------------+
