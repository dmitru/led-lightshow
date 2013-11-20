import ddf.minim.analysis.*;
import ddf.minim.*;
import processing.serial.*;
import cc.arduino.*;
import controlP5.*;

Minim minim;
 
Leds leds;
final int LEDS_PIN_LOW = 9;
final int LEDS_PIN_MED = 10;
final int LEDS_PIN_HIGH = 11;

Spectrum spectrum;
final int SPECTRUM_SIZE = 256;

float SCALER_LOW = 0.5;
float SCALER_MED = 1.25;
float SCALER_HIGH = 4.0;

float SCALER_MASTER = 1.0;

final float LOW_START_DEFAULT = 40;
final float LOW_END_DEFAULT = 1800;
final float MED_START_DEFAULT = 1500;
final float MED_END_DEFAULT = 6200;
final float HIGH_START_DEFAULT = 6200;
final float HIGH_END_DEFAULT = 19000;

float LOW_START = LOW_START_DEFAULT;
float LOW_END = LOW_END_DEFAULT;
float MED_START = MED_START_DEFAULT;
float MED_END = MED_END_DEFAULT;
float HIGH_START = HIGH_START_DEFAULT;
float HIGH_END = HIGH_END_DEFAULT;

float decayRate = 0.92;

final int SPECTRUM_WIDTH = 800;
final int CONTROLS_WIDTH = 300;
final int HEIGHT = 600;
final int WIDTH = SPECTRUM_WIDTH + CONTROLS_WIDTH;

float[] hPrev = new float[SPECTRUM_SIZE + 1];
float[] brightness = new float[3]; 
 
void setup()
{
  size(SPECTRUM_WIDTH + CONTROLS_WIDTH, HEIGHT, P3D);
  
  // You'll want to change this to choose the right device on your system
  // usually it will be Arduino.list[0]
  Arduino arduino = new Arduino(this, Arduino.list()[2], 57600);
  leds = new LedsDevice(arduino, LEDS_PIN_LOW, LEDS_PIN_MED, LEDS_PIN_HIGH);
 
  minim = new Minim(this);  
  spectrum = new Spectrum(minim.getLineIn(Minim.STEREO, SPECTRUM_SIZE * 2));
  
  setUpGui();
 
  rectMode(CORNERS);
}

ControlP5 cp5;

void setUpGui() 
{
  cp5 = new ControlP5(this);
  
  final int vspace = 5;
  final int vspaceLarge = 20;
  final int vsize = 20;
  
  int vbase = 20; 
  
  cp5.addSlider("SCALER_MASTER")
     .setPosition(SPECTRUM_WIDTH + 20, vbase)
     .setSize(CONTROLS_WIDTH - 100, vsize)
     .setValue(SCALER_MASTER)
     .setRange(0.0, 5.0)
     ;
  vbase += vspace + vsize;
  
  vbase += vspaceLarge ;
  cp5.addSlider("SCALER_LOW")
     .setPosition(SPECTRUM_WIDTH + 20, vbase)
     .setSize(CONTROLS_WIDTH - 100, vsize)
     .setRange(0.0, 5.0)
     ;
  vbase += vspace + vsize;
  cp5.addSlider("SCALER_MED")
     .setPosition(SPECTRUM_WIDTH + 20, vbase)
     .setSize(CONTROLS_WIDTH - 100, vsize)
     .setRange(0.0, 5.0)
     ;
  vbase += vspace + vsize;
  cp5.addSlider("SCALER_HIGH")
     .setPosition(SPECTRUM_WIDTH + 20, vbase)
     .setSize(CONTROLS_WIDTH - 100, vsize)
     .setRange(0.0, 5.0)
     ;
  vbase += vspace + vsize;
     
  vbase += vspaceLarge;
  cp5.addSlider("LOW_START")
     .setPosition(SPECTRUM_WIDTH + 20, vbase)
     .setSize(CONTROLS_WIDTH - 100, vsize)
     .setRange(20, 800)
     .setValue(LOW_START_DEFAULT)
     ;
  vbase += vspace + vsize;
  cp5.addSlider("LOW_END")
     .setPosition(SPECTRUM_WIDTH + 20, vbase)
     .setSize(CONTROLS_WIDTH - 100, vsize)
     .setRange(100, 3000)
     .setValue(LOW_END_DEFAULT)
     ;
  vbase += vspace + vsize;
     
  vbase += vspaceLarge;
  cp5.addSlider("MED_START")
     .setPosition(SPECTRUM_WIDTH + 20, vbase)
     .setSize(CONTROLS_WIDTH - 100, vsize)
     .setRange(500, 4000)
     .setValue(MED_START_DEFAULT)
     ;
  vbase += vspace + vsize;
  cp5.addSlider("MED_END")
     .setPosition(SPECTRUM_WIDTH + 20, vbase)
     .setSize(CONTROLS_WIDTH - 100, vsize)
     .setRange(3000, 8000)
     .setValue(MED_END_DEFAULT)
     ;
  vbase += vspace + vsize;
     
  vbase += vspaceLarge;
  cp5.addSlider("HIGH_START")
     .setPosition(SPECTRUM_WIDTH + 20, vbase)
     .setSize(CONTROLS_WIDTH - 100, vsize)
     .setRange(4000,8000)
     .setValue(HIGH_START_DEFAULT)
     ;
  vbase += vspace + vsize;
  cp5.addSlider("HIGH_END")
     .setPosition(SPECTRUM_WIDTH + 20, vbase)
     .setSize(CONTROLS_WIDTH - 100, vsize)
     .setRange(6000,20000)
     .setValue(HIGH_END_DEFAULT)
     ;
}
 
void draw()
{ 
  spectrum.update();
  float averageLevel = spectrum.calcAverage();
  
  background(0);
  
  // draw three color rectangles, for low, medium and high frequencies  
  fill(255, 0, 0, (int) 255 * brightness[0]);
  stroke(255, 0, 0, (int) 255 * brightness[0]);
  rect(0, HEIGHT, SPECTRUM_WIDTH/3, 0);
  
  fill(0, 255, 0, (int) 255 * brightness[1]);
  stroke(0, 255, 0, (int) 255 * brightness[1]);
  rect(SPECTRUM_WIDTH/3, HEIGHT, 2*SPECTRUM_WIDTH/3, 0);
  
  fill(0, 0, 255, (int) 255 * brightness[2]);
  stroke(0, 0, 255, (int) 255 * brightness[2]);
  rect(2*SPECTRUM_WIDTH/3, HEIGHT, SPECTRUM_WIDTH, 0);
  
  // draw spectrum
  fill(255, 255, 255, 128);
  stroke(255, 255, 255, 128);
  
  for(int i = 1; i < spectrum.fft.specSize(); i++)
  {
    int x1 = i * (SPECTRUM_WIDTH / SPECTRUM_SIZE);
    int x2 = x1 + (SPECTRUM_WIDTH / SPECTRUM_SIZE); 
    float band = spectrum.fft.getBand(i);
        
    if (i < spectrum.fft.freqToIndex(LOW_END)) 
      band *= SCALER_LOW;
    else if (i < spectrum.fft.freqToIndex(MED_END)) 
      band *= SCALER_MED;
    else
      band *= SCALER_HIGH;
     
    band *= SCALER_MASTER; 
    
    float h = (averageLevel > 0.04)? 1.0 - (averageLevel) / band : 0.0;
    
    if (h < 0) 
      h = 0;
    else if (h > 1.0) 
      h = 1.0;
      
    if (hPrev[i] > h) 
      h = decayRate * hPrev[i] + (1 - decayRate) * h;
    hPrev[i] = h;
    
    rect(x1, HEIGHT, x2, HEIGHT - HEIGHT * h);
  }
  
  stroke(255, 0, 0, 255);
  line(spectrum.fft.freqToIndex(LOW_START) * (SPECTRUM_WIDTH / SPECTRUM_SIZE), 0, spectrum.fft.freqToIndex(LOW_START) * (SPECTRUM_WIDTH / SPECTRUM_SIZE), HEIGHT);
  line(spectrum.fft.freqToIndex(LOW_END) * (SPECTRUM_WIDTH / SPECTRUM_SIZE), 0, spectrum.fft.freqToIndex(LOW_END) * (SPECTRUM_WIDTH / SPECTRUM_SIZE), HEIGHT);
  stroke(0, 255, 0, 255);
  line(spectrum.fft.freqToIndex(MED_START) * (SPECTRUM_WIDTH / SPECTRUM_SIZE), 0, spectrum.fft.freqToIndex(MED_START) * (SPECTRUM_WIDTH / SPECTRUM_SIZE), HEIGHT);
  line(spectrum.fft.freqToIndex(MED_END) * (SPECTRUM_WIDTH / SPECTRUM_SIZE), 0, spectrum.fft.freqToIndex(MED_END) * (SPECTRUM_WIDTH / SPECTRUM_SIZE), HEIGHT);
  stroke(0, 0, 255, 255);
  line(spectrum.fft.freqToIndex(HIGH_START) * (SPECTRUM_WIDTH / SPECTRUM_SIZE), 0, spectrum.fft.freqToIndex(HIGH_START) * (SPECTRUM_WIDTH / SPECTRUM_SIZE), HEIGHT);
  line(spectrum.fft.freqToIndex(HIGH_END) * (SPECTRUM_WIDTH / SPECTRUM_SIZE), 0, spectrum.fft.freqToIndex(HIGH_END) * (SPECTRUM_WIDTH / SPECTRUM_SIZE), HEIGHT);
  
  float hh = 0.0;
  int cnt = 0;
  for(int i = spectrum.fft.freqToIndex(LOW_START); i <= spectrum.fft.freqToIndex(LOW_END); ++i) {
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
  float b = (spectrum.fft.freqToIndex(MED_END) - spectrum.fft.freqToIndex(MED_START) + 1) / 2;
  float middle = (spectrum.fft.freqToIndex(MED_END) + spectrum.fft.freqToIndex(MED_START)) / 2;
  for(int i = spectrum.fft.freqToIndex(MED_START) + 1; i <= spectrum.fft.freqToIndex(MED_END); ++i) {
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
  for(int i = spectrum.fft.freqToIndex(HIGH_START) + 1; i <= spectrum.fft.freqToIndex(HIGH_END); ++i) {
    hh += hPrev[i];
    cnt++;
  }  
  hh /= cnt;
  
  if (brightness[2] > hh) 
    brightness[2] = (1 - decayRate) * brightness[2] + decayRate * hh;
  else
    brightness[2] = hh;
    
  leds.setBrightness(brightness[0], brightness[1], brightness[2]);
  
  fill(255);
}
 
void stop()
{
  minim.stop();
  spectrum.stop(); 
  super.stop();
}


class Spectrum {
  public Spectrum(AudioInput in) {
    this.in = in;
    fft = new FFT(this.in.bufferSize(), this.in.sampleRate()); 
  }
  
  public void update() {
    fft.forward(in.mix); 
  }
  
  public void stop() {
    in.close();
  }
  
  public float calcAverage() {
     return calcAverage(1.0, 1.0, 1.0); 
  }
  
  public float calcAverage(float scalerLow, float scalerMed, float scalerHigh) {
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
  
  private AudioInput in;
  public FFT fft;
}


interface Leds {
  public void setBrightness(double low, double med, double high);
}

class LedsDevice implements Leds {
  public LedsDevice(Arduino arduino, int pinLow, int pinMed, int pinHigh) {
    this.arduino = arduino;
    this.pinLow = pinLow;
    this.pinMed = pinMed;
    this.pinHigh = pinHigh;
  } 
  
  public void setBrightness(double low, double med, double high) {
    if (low > 1.0) low = 1.0;
    if (low < 0.0) low = 0.0;
    
    if (med > 1.0) med = 1.0;
    if (med < 0.0) med = 0.0;
    
    if (high > 1.0) high = 1.0;
    if (high < 0.0) high = 0.0;
    
    arduino.analogWrite(pinLow, brightnessTable[(int) (low * 255)]);
    arduino.analogWrite(pinMed, brightnessTable[(int) (med * 255)]);
    arduino.analogWrite(pinHigh, brightnessTable[(int) (high * 255)]);
  }
 
  private Arduino arduino; 
  
  private int pinLow;
  private int pinMed;
  private int pinHigh;
  
  private int[] brightnessTable = new int[] { 
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
}
