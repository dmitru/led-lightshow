import ddf.minim.analysis.*;
import ddf.minim.*;
import processing.serial.*;
import cc.arduino.*;
 
Arduino arduino;
 
Minim minim;
AudioInput in;
FFT fft;
String windowName;

final int SPECTRUM_SIZE = 256;

final float SCALER_LOW = 0.7;
final float SCALER_MED = 1.0;
final float SCALER_HIGH = 3.8;

final float LOW_START = 40;
final float LOW_END = 1800;
final float MED_START = 1000;
final float MED_END = 5000;
final float HIGH_START = 5000;
final float HIGH_END = 13000;


float currentSmoothLevel = 1.0; 
float smoothCoefficient = 0.998;
float decayRate = 0.92;

float[] hPrev = new float[SPECTRUM_SIZE + 1];
float[] brightness = new float[3]; 

 
void setup()
{
  size(1024, 600, P3D);
  
  println(Arduino.list());
  arduino = new Arduino(this, Arduino.list()[2], 57600);
 
  minim = new Minim(this); 
 
  in = minim.getLineIn(Minim.STEREO, SPECTRUM_SIZE * 2);
 
  fft = new FFT(in.bufferSize(), in.sampleRate());
  
  for (int i = 0; i <= SPECTRUM_SIZE; ++i)
    hPrev[i] = 0.0;
 
  textFont(createFont("Arial", 16));
  rectMode(CORNERS);
}

float calcAverage(float scalerLow, float scalerMed, float scalerHigh) {
  float densityLow = 0.0;
  int cntLow = 0;

  for(int i = fft.freqToIndex(LOW_START); i <= fft.freqToIndex(LOW_END); ++i) {
    densityLow += fft.getBand(i);
    cntLow++;
  } 

 float densityMed = 0.0; 
 int cntMed = 0;
 for(int i = fft.freqToIndex(MED_START); i <= fft.freqToIndex(MED_END); ++i) {
    densityMed += fft.getBand(i);
    cntMed++;
  }

  float densityHigh = 0.0;
  int cntHigh = 0;
  for(int i = fft.freqToIndex(HIGH_START); i <= fft.freqToIndex(HIGH_END); ++i) {
    densityHigh += fft.getBand(i);
    cntHigh++;
  }     
  
  return (densityLow * scalerLow + densityMed * scalerMed + densityHigh * scalerHigh) / 
         (cntLow * scalerLow + cntMed * scalerMed + cntHigh * scalerHigh);
}
 
void draw()
{
  background(0);
  
  fft.forward(in.mix);
  float averageLevel = calcAverage(1.0, 1.0, 1.0);
  
  
  // draw three color rectangles, for low, medium and high frequencies  
  //println(brightness[0]);
  fill(255, 0, 0, (int) 255 * brightness[0]);
  stroke(255, 0, 0, (int) 255 * brightness[0]);
  rect(0, height, width/3, 0);
  
  fill(0, 255, 0, (int) 255 * brightness[1]);
  stroke(0, 255, 0, (int) 255 * brightness[1]);
  rect(width/3, height, 2*width/3, 0);
  
  fill(0, 0, 255, (int) 255 * brightness[2]);
  stroke(0, 0, 255, (int) 255 * brightness[2]);
  rect(2*width/3, height, width, 0);
  
  // draw spectrum
  fill(255, 255, 255, 128);
  stroke(255, 255, 255, 128);
  
  for(int i = 1; i < fft.specSize(); i++)
  {
    int x1 = i * (1024 / SPECTRUM_SIZE);
    int x2 = x1 + (1024 / SPECTRUM_SIZE); 
    float band = fft.getBand(i);
        
    if (i < fft.freqToIndex(LOW_END)) 
      band *= SCALER_LOW;
    else if (i < fft.freqToIndex(MED_END)) 
      band *= SCALER_MED;
    else
      band *= SCALER_HIGH;
    
    float h = (averageLevel > 0.04)? 1.0 - (averageLevel) / band : 0.0;
    
    if (h < 0) 
      h = 0;
    if (hPrev[i] > h) 
      h = decayRate * hPrev[i] + (1 - decayRate) * h;
      
    if (h > 1.0) 
      h = 1.0;
    
    hPrev[i] = h;
    
    rect(x1, height, x2, height - 600 * h);
  }
  
  line(fft.freqToIndex(LOW_START) * (1024 / SPECTRUM_SIZE), 0, fft.freqToIndex(LOW_START)* (1024 / SPECTRUM_SIZE), height);
  line(fft.freqToIndex(LOW_END) * (1024 / SPECTRUM_SIZE), 0, fft.freqToIndex(LOW_END)* (1024 / SPECTRUM_SIZE), height);
  line(fft.freqToIndex(MED_END) * (1024 / SPECTRUM_SIZE), 0, fft.freqToIndex(MED_END)* (1024 / SPECTRUM_SIZE), height);
  line(fft.freqToIndex(HIGH_END) * (1024 / SPECTRUM_SIZE), 0, fft.freqToIndex(HIGH_END)* (1024 / SPECTRUM_SIZE), height);
  
  float hh = 0.0;
  int cnt = 0;
  for(int i = fft.freqToIndex(LOW_START); i <= fft.freqToIndex(LOW_END); ++i) {
    hh += hPrev[i];
    cnt++;
  }  
  hh /= cnt;
  
  if (brightness[0] > hh) 
    brightness[0] = (1 - decayRate) * brightness[0] + decayRate * hh;
  else
    brightness[0] = hh;
    
  hh = 0.0;
  cnt = 0;
  float b = (fft.freqToIndex(MED_END) - fft.freqToIndex(MED_START) + 1) / 2;
  float middle = (fft.freqToIndex(MED_END) + fft.freqToIndex(MED_START)) / 2;
  for(int i = fft.freqToIndex(MED_START) + 1; i <= fft.freqToIndex(MED_END); ++i) {
    hh += hPrev[i] * 2 * (1 - abs(( i - middle) / b));
    cnt++;
  }  
  hh /= cnt;
  
  if (brightness[1] > hh) 
    brightness[1] = (1 - decayRate) * brightness[1] + decayRate * hh;
  else
    brightness[1] = hh;
    
  hh = 0.0;
  cnt = 0;
  for(int i = fft.freqToIndex(HIGH_START) + 1; i <= fft.freqToIndex(HIGH_END); ++i) {
    hh += hPrev[i];
    cnt++;
  }  
  hh /= cnt;
  
  if (brightness[2] > hh) 
    brightness[2] = (1 - decayRate) * brightness[2] + decayRate * hh;
  else
    brightness[2] = hh;
    
  sendSignals();
  
  fill(255);
}

int[] brightnessTable = new int[] { 
  0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01,
  0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02,
  0x02, 0x02, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x04, 0x04, 0x04, 0x04, 0x04, 0x05, 0x05, 0x05,
  0x05, 0x06, 0x06, 0x06, 0x07, 0x07, 0x07, 0x08, 0x08, 0x08, 0x09, 0x09, 0x0A, 0x0A, 0x0B, 0x0B,
  0x0C, 0x0C, 0x0D, 0x0D, 0x0E, 0x0F, 0x0F, 0x10, 0x11, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17,
  0x18, 0x19, 0x1A, 0x1B, 0x1C, 0x1D, 0x1F, 0x20, 0x21, 0x23, 0x24, 0x26, 0x27, 0x29, 0x2B, 0x2C,
  0x2E, 0x30, 0x32, 0x34, 0x36, 0x38, 0x3A, 0x3C, 0x3E, 0x40, 0x43, 0x45, 0x47, 0x4A, 0x4C, 0x4F,
  0x51, 0x54, 0x57, 0x59, 0x5C, 0x5F, 0x62, 0x64, 0x67, 0x6A, 0x6D, 0x70, 0x73, 0x76, 0x79, 0x7C,
  0x7F, 0x82, 0x85, 0x88, 0x8B, 0x8E, 0x91, 0x94, 0x97, 0x9A, 0x9C, 0x9F, 0xA2, 0xA5, 0xA7, 0xAA,
  0xAD, 0xAF, 0xB2, 0xB4, 0xB7, 0xB9, 0xBB, 0xBE, 0xC0, 0xC2, 0xC4, 0xC6, 0xC8, 0xCA, 0xCC, 0xCE,
  0xD0, 0xD2, 0xD3, 0xD5, 0xD7, 0xD8, 0xDA, 0xDB, 0xDD, 0xDE, 0xDF, 0xE1, 0xE2, 0xE3, 0xE4, 0xE5,
  0xE6, 0xE7, 0xE8, 0xE9, 0xEA, 0xEB, 0xEC, 0xED, 0xED, 0xEE, 0xEF, 0xEF, 0xF0, 0xF1, 0xF1, 0xF2,
  0xF2, 0xF3, 0xF3, 0xF4, 0xF4, 0xF5, 0xF5, 0xF6, 0xF6, 0xF6, 0xF7, 0xF7, 0xF7, 0xF8, 0xF8, 0xF8,
  0xF9, 0xF9, 0xF9, 0xF9, 0xFA, 0xFA, 0xFA, 0xFA, 0xFA, 0xFB, 0xFB, 0xFB, 0xFB, 0xFB, 0xFB, 0xFC,
  0xFC, 0xFC, 0xFC, 0xFC, 0xFC, 0xFC, 0xFC, 0xFC, 0xFD, 0xFD, 0xFD, 0xFD, 0xFD, 0xFD, 0xFD, 0xFD,
  0xFD, 0xFD, 0xFD, 0xFD, 0xFD, 0xFD, 0xFD, 0xFE, 0xFE, 0xFE, 0xFE, 0xFE, 0xFE, 0xFE, 0xFF, 0xFF
};

void sendSignals() 
{  
  arduino.analogWrite(9, brightnessTable[(int) (brightness[0] * 255) > 255? 255 : (int) (brightness[0] * 255)]);
  arduino.analogWrite(10, brightnessTable[(int) (brightness[1] * 255) > 255? 255 : (int) (brightness[1] * 255)]);
  arduino.analogWrite(11, brightnessTable[(int) (brightness[2] * 255) > 255? 255 : (int) (brightness[2] * 255)]);
}
 
void keyReleased()
{
  if ( key == 'u' ) 
  {
    // a Hamming window can be used to shape the sample buffer that is passed to the FFT
    // this can reduce the amount of noise in the spectrum
    smoothCoefficient *= 1.1;
  }
 
  if ( key == 'd' ) 
  {
    smoothCoefficient /= 1.1;
  }
}
 
void stop()
{
  // always close Minim audio classes when you finish with them
  in.close();
  minim.stop();
 
  super.stop();
}
