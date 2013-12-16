import ddf.minim.analysis.*;
import ddf.minim.*;
import processing.serial.*;
import cc.arduino.*;
import controlP5.*;

Minim minim;
 
LedsDevice leds;
final int LEDS_PIN_LOW = 9;
final int LEDS_PIN_MED = 10;
final int LEDS_PIN_HIGH = 11;

Spectrum spectrum;
final int SPECTRUM_SIZE = 256;

final float DEFAULT_NOISE_LEVEL = 0.02;
final float DEFAULT_DECAY_RATE = 0.95;

final float DEFAULT_SCALER_LOW = 0.5;
final float DEFAULT_SCALER_MED = 1.25;
final float DEFAULT_SCALER_HIGH = 4.0;
final float DEFAULT_SCALER_MASTER = 1.0;

final float DEFAULT_LOW_START = 40;
final float DEFAULT_LOW_END = 1800;
final float DEFAULT_MED_START = 1500;
final float DEFAULT_MED_END = 6200;
final float DEFAULT_HIGH_START = 6200;
final float DEFAULT_HIGH_END = 19000;

// Windows parameters
final int SPECTRUM_WIDTH = 800;
final int CONTROLS_WIDTH = 300;
final int HEIGHT = 600;
final int WIDTH = SPECTRUM_WIDTH + CONTROLS_WIDTH;

float[] brightness = new float[3]; 
 
void setup()
{
  size(SPECTRUM_WIDTH + CONTROLS_WIDTH, HEIGHT, P3D);
  rectMode(CORNERS);
  setUpGui();
  
  // You'll want to change this to choose the right device on your system
  // usually it will be Arduino.list[0]
  Arduino arduino = new Arduino(this, Arduino.list()[2], 57600);
  leds = new LedsDevice(arduino, LEDS_PIN_LOW, LEDS_PIN_MED, LEDS_PIN_HIGH);
 
  minim = new Minim(this);  
  spectrum = new Spectrum(minim.getLineIn(Minim.STEREO, SPECTRUM_SIZE * 2));
}

ControlP5 cp5;

void setUpGui() 
{
  cp5 = new ControlP5(this);
  
  final int vspace = 5;
  final int vspaceLarge = 20;
  final int vsize = 20;
  
  int vbase = 20; 
  
  cp5.addTextlabel("Sensitivity")
     .setText("Sensitivity:")
     .setPosition(SPECTRUM_WIDTH + 20, vbase);
     
  vbase += vsize + vspace;
  
  cp5.addSlider("Master")
     .setPosition(SPECTRUM_WIDTH + 20, vbase)
     .setSize(CONTROLS_WIDTH - 100, vsize)
     .setValue(DEFAULT_SCALER_MASTER)
     .setRange(0.0, 5.0)
     ;
  vbase += vspace + vsize;
  
  vbase += vspaceLarge ;
  cp5.addSlider("Low")
     .setPosition(SPECTRUM_WIDTH + 20, vbase)
     .setSize(CONTROLS_WIDTH - 100, vsize)
     .setValue(DEFAULT_SCALER_LOW)
     .setRange(0.0, 5.0)
     ;
  vbase += vspace + vsize;
  cp5.addSlider("Med")
     .setPosition(SPECTRUM_WIDTH + 20, vbase)
     .setSize(CONTROLS_WIDTH - 100, vsize)
     .setValue(DEFAULT_SCALER_MED)
     .setRange(0.0, 5.0)
     ;
  vbase += vspace + vsize;
  cp5.addSlider("High")
     .setPosition(SPECTRUM_WIDTH + 20, vbase)
     .setSize(CONTROLS_WIDTH - 100, vsize)
     .setValue(DEFAULT_SCALER_HIGH)
     .setRange(0.0, 5.0)
     ;
  vbase += vspace + vsize;
     
  vbase += vspaceLarge;
  cp5.addTextlabel("Band frequencies")
     .setText("Band frequencies:")
     .setPosition(SPECTRUM_WIDTH + 20, vbase);
  vbase += vspace + vsize;   
  cp5.addSlider("Low start")
     .setPosition(SPECTRUM_WIDTH + 20, vbase)
     .setSize(CONTROLS_WIDTH - 100, vsize)
     .setRange(20, 800)
     .setValue(DEFAULT_LOW_START)
     ;
  vbase += vspace + vsize;
  cp5.addSlider("Low end")
     .setPosition(SPECTRUM_WIDTH + 20, vbase)
     .setSize(CONTROLS_WIDTH - 100, vsize)
     .setRange(100, 3000)
     .setValue(DEFAULT_LOW_END)
     ;
  vbase += vspace + vsize;
     
  vbase += vspaceLarge;
  cp5.addSlider("Med start")
     .setPosition(SPECTRUM_WIDTH + 20, vbase)
     .setSize(CONTROLS_WIDTH - 100, vsize)
     .setRange(500, 4000)
     .setValue(DEFAULT_MED_START)
     ;
  vbase += vspace + vsize;
  cp5.addSlider("Med end")
     .setPosition(SPECTRUM_WIDTH + 20, vbase)
     .setSize(CONTROLS_WIDTH - 100, vsize)
     .setRange(3000, 8000)
     .setValue(DEFAULT_MED_END)
     ;
  vbase += vspace + vsize;
     
  vbase += vspaceLarge;
  cp5.addSlider("High start")
     .setPosition(SPECTRUM_WIDTH + 20, vbase)
     .setSize(CONTROLS_WIDTH - 100, vsize)
     .setRange(4000, 8000)
     .setValue(DEFAULT_HIGH_START)
     ;
  vbase += vspace + vsize;
  cp5.addSlider("High end")
     .setPosition(SPECTRUM_WIDTH + 20, vbase)
     .setSize(CONTROLS_WIDTH - 100, vsize)
     .setRange(6000, 20000)
     .setValue(DEFAULT_HIGH_END)
     ;
  vbase += vspace + vsize;
     
  vbase += vspaceLarge;
  cp5.addTextlabel("Other")
     .setText("Other:")
     .setPosition(SPECTRUM_WIDTH + 20, vbase);
     
  vbase += vsize + vspace;
  cp5.addSlider("Decay rate")
     .setPosition(SPECTRUM_WIDTH + 20, vbase)
     .setSize(CONTROLS_WIDTH - 100, vsize)
     .setRange(0.85, 0.999)
     .setValue(DEFAULT_DECAY_RATE)
     ;
  vbase += vspace + vsize;
  cp5.addSlider("Noise level")
     .setPosition(SPECTRUM_WIDTH + 20, vbase)
     .setSize(CONTROLS_WIDTH - 100, vsize)
     .setRange(0.001, 0.05)
     .setValue(DEFAULT_NOISE_LEVEL)
     ;
}

void controlEvent(ControlEvent theEvent) {
  if (theEvent.isController()) {
    String name = theEvent.controller().name();
    float value = theEvent.controller().value();
   
    if (spectrum == null) 
      return;
   
    if (name == "Master") {
      spectrum.setScalerMaster(value);
    } else if (name == "Low") {
      spectrum.setScalerLow(value);
    } else if (name == "Med") {
      spectrum.setScalerMed(value);
    } else if (name == "High") {
      spectrum.setScalerHigh(value);
    } else if (name == "Low start") {
      spectrum.setLowFreqStart(value);
    } else if (name == "Low end") {
      spectrum.setLowFreqEnd(value);
    } else if (name == "Med start") {
      spectrum.setMedFreqStart(value);
    } else if (name == "Med end") {
      spectrum.setMedFreqEnd(value);
    } else if (name == "High start") {
      spectrum.setHighFreqStart(value);
    } else if (name == "High end") {
      spectrum.setHighFreqEnd(value);
    } else if (name == "Decay rate") {
      spectrum.setDecayRate(value); 
    } else if (name == "Noise level") {
      spectrum.setNoiseLevel(value); 
    }
  }  
}
 
void draw()
{ 
  spectrum.update();
  leds.updateBrightness(spectrum);
  
  spectrum.draw();
	
  // draw three color rectangles, for low, medium and high frequencies
  float brightness[] = leds.getBrightness();

  fill(255, 0, 0, (int) 255 * brightness[0]);
  stroke(255, 0, 0, (int) 255 * brightness[0]);
  rect(0, HEIGHT, SPECTRUM_WIDTH / 3, 0);
  
  fill(0, 255, 0, (int) 255 * brightness[1]);
  stroke(0, 255, 0, (int) 255 * brightness[1]);
  rect(SPECTRUM_WIDTH / 3, HEIGHT, 2 * SPECTRUM_WIDTH / 3, 0);
  
  fill(0, 0, 255, (int) 255 * brightness[2]);
  stroke(0, 0, 255, (int) 255 * brightness[2]);
  rect(2 * SPECTRUM_WIDTH / 3, HEIGHT, SPECTRUM_WIDTH, 0);
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
    this.fft = new FFT(this.in.bufferSize(), this.in.sampleRate()); 
    this.bands = new float[this.fft.specSize() + 1];
    this.prevBands = new float[this.fft.specSize() + 1];
    this.noiseLevel = DEFAULT_NOISE_LEVEL;
    this.decayRate = DEFAULT_DECAY_RATE;
    
    this.scalerMaster = DEFAULT_SCALER_MASTER;
    this.scalerLow = DEFAULT_SCALER_LOW;
    this.scalerMed = DEFAULT_SCALER_MED;
    this.scalerHigh = DEFAULT_SCALER_HIGH;
    
    this.lowFreqStart = DEFAULT_LOW_START;
    this.lowFreqEnd = DEFAULT_LOW_END;
    this.medFreqStart = DEFAULT_MED_START;
    this.medFreqEnd = DEFAULT_MED_END;
    this.highFreqStart = DEFAULT_HIGH_START;
    this.highFreqEnd = DEFAULT_HIGH_END;
  }
  
  public void setDecayRate(float value) {
    this.decayRate = value;
  }
  
  public float getDecayRate() {
    return this.decayRate;
  }
  
  public void setScalerMaster(float value) {
    this.scalerMaster = value;
  }
  
  public float getScalerMaster() {
    return this.scalerMaster;
  }
  
  public void setScalerLow(float value) {
    this.scalerLow = value;
  }
  
  public float getScalerLow() {
    return this.scalerLow;
  }
  
  public void setScalerMed(float value) {
    this.scalerMed = value;
  }
  
  public float getScalerMed() {
    return this.scalerMed;
  }
  
  public void setScalerHigh(float value) {
    this.scalerHigh = value;
  }
  
  public float getScalerHigh() {
    return this.scalerHigh;
  }
  
  public void setLowFreqStart(float value) {
    this.lowFreqStart = value; 
  }
  
  public float getLowFreqStart() {
    return this.lowFreqStart; 
  }
  
  public void setMedFreqStart(float value) {
    this.medFreqStart = value; 
  }
  
  public float getMedFreqStart() {
    return this.medFreqStart; 
  }
  
  public void setHighFreqStart(float value) {
    this.highFreqStart = value; 
  }
  
  public float getHighFreqStart() {
    return this.highFreqStart; 
  }
  
    public void setLowFreqEnd(float value) {
    this.lowFreqEnd = value; 
  }
  
  public float getLowFreqEnd() {
    return this.lowFreqEnd; 
  }
  
  public void setMedFreqEnd(float value) {
    this.medFreqEnd = value; 
  }
  
  public float getMedFreqEnd() {
    return this.medFreqEnd; 
  }
  
  public void setHighFreqEnd(float value) {
    this.highFreqEnd = value; 
  }
  
  public float getHighFreqEnd() {
    return this.highFreqEnd; 
  }
  
  public void setNoiseLevel(float value) {
    this.noiseLevel = value;
  }
  
  public float getNoiseLevel() {
    return this.noiseLevel;
  }
  
  public void update() {
    fft.forward(in.mix); 
	
    float averageLevel = calculateAverage();
    for(int i = 1; i < spectrum.fft.specSize(); i++) {
      float band = this.fft.getBand(i);
      		
      band *= this.scalerMaster;
      if (i < this.fft.freqToIndex(this.lowFreqEnd)) 
        band *= this.scalerLow;
      else if (i < spectrum.fft.freqToIndex(this.medFreqEnd)) 
        band *= this.scalerMed;
      else
        band *= this.scalerHigh;	     		
      
      float h = (averageLevel > this.noiseLevel)? 1.0 - (averageLevel) / band : 0.0;
           		
      if (h < 0) h = 0;
      if (h > 1.0) h = 1.0;
      		  
      if (bands[i] > h) 
        h = this.decayRate * bands[i] + (1 - this.decayRate) * h;
      bands[i] = h;
    }
  }
  
  public void draw() {
    background(0);
    fill(255, 255, 255, 128);
    stroke(255, 255, 255, 128);
    for(int i = 1; i < spectrum.fft.specSize(); i++) {
      int x1 = i * (SPECTRUM_WIDTH / SPECTRUM_SIZE);
      int x2 = x1 + (SPECTRUM_WIDTH / SPECTRUM_SIZE); 
      float band = this.bands[i];
      rect(x1, HEIGHT, x2, HEIGHT - HEIGHT * band);
    }
    
    stroke(255, 0, 0, 255);
    line(this.fft.freqToIndex(this.lowFreqStart) * (SPECTRUM_WIDTH / SPECTRUM_SIZE), 0, 
      this.fft.freqToIndex(this.lowFreqStart) * (SPECTRUM_WIDTH / SPECTRUM_SIZE), HEIGHT);
    line(this.fft.freqToIndex(this.lowFreqEnd) * (SPECTRUM_WIDTH / SPECTRUM_SIZE), 0, 
      this.fft.freqToIndex(this.lowFreqEnd) * (SPECTRUM_WIDTH / SPECTRUM_SIZE), HEIGHT);
    stroke(0, 255, 0, 255);
    line(this.fft.freqToIndex(this.medFreqStart) * (SPECTRUM_WIDTH / SPECTRUM_SIZE), 0, 
      this.fft.freqToIndex(this.medFreqStart) * (SPECTRUM_WIDTH / SPECTRUM_SIZE), HEIGHT);
    line(this.fft.freqToIndex(this.medFreqEnd) * (SPECTRUM_WIDTH / SPECTRUM_SIZE), 0, 
      this.fft.freqToIndex(this.medFreqEnd) * (SPECTRUM_WIDTH / SPECTRUM_SIZE), HEIGHT);
    stroke(0, 0, 255, 255);
    line(this.fft.freqToIndex(this.highFreqStart) * (SPECTRUM_WIDTH / SPECTRUM_SIZE), 0, 
      this.fft.freqToIndex(this.highFreqStart) * (SPECTRUM_WIDTH / SPECTRUM_SIZE), HEIGHT);
    line(this.fft.freqToIndex(this.highFreqEnd) * (SPECTRUM_WIDTH / SPECTRUM_SIZE), 0, 
      this.fft.freqToIndex(this.highFreqEnd) * (SPECTRUM_WIDTH / SPECTRUM_SIZE), HEIGHT);
  }
  
  public void stop() {
    in.close();
  }
  
  float calculateAverageOnInterval(float freqStart, float freqEnd) {
    float density = 0.0;
    int cnt = 0;
    for(int i = fft.freqToIndex(freqStart); i <= fft.freqToIndex(freqEnd); ++i) {
      density += this.bands[i];
      cnt++;
    } 
    return density / cnt;
  }
  
  float calculateAverage(float freqStart, float freqEnd) {
    float density = 0.0;
    int cnt = 0;
    for(int i = fft.freqToIndex(freqStart); i <= fft.freqToIndex(freqEnd); ++i) {
      density += fft.getBand(i);
      cnt++;
    } 
    return density / cnt;
  }
  
  private float calculateAverage() {
    float densityLow = 0.0;
    int cntLow = 0;
    for(int i = fft.freqToIndex(this.lowFreqStart); i <= fft.freqToIndex(this.lowFreqEnd); ++i) {
      densityLow += fft.getBand(i);
      cntLow++;
    }
   
    float densityMed = 0.0;
    int cntMed = 0;
    for(int i = fft.freqToIndex(this.medFreqStart); i <= fft.freqToIndex(this.medFreqEnd); ++i) {
      densityMed += fft.getBand(i);
      cntMed++;
    } 
   
    float densityHigh = 0.0;
    int cntHigh = 0;
    for(int i = fft.freqToIndex(this.highFreqStart); i <= fft.freqToIndex(this.highFreqEnd); ++i) {
      densityHigh += this.bands[i];
      cntHigh++;
    }  
    
    return (densityLow * this.scalerLow + densityMed * this.scalerMed + densityHigh * this.scalerHigh) / 
      (cntLow * this.scalerLow + cntMed * this.scalerMed + cntHigh * this.scalerHigh); 
  }
  
  private AudioInput in;
  public FFT fft;
  public float[] bands;
  private float[] prevBands;
  private float noiseLevel;
  private float decayRate;
  
  private float scalerMaster;
  private float scalerLow;
  private float scalerMed;
  private float scalerHigh;
  
  private float lowFreqStart;
  private float medFreqStart;
  private float highFreqStart;
  private float lowFreqEnd;
  private float medFreqEnd;
  private float highFreqEnd;
}

class LedsDevice {
  public LedsDevice(Arduino arduino, int pinLow, int pinMed, int pinHigh) {
    this.arduino = arduino;
    this.brightness = new float[3];
    this.pinLow = pinLow;
    this.pinMed = pinMed;
    this.pinHigh = pinHigh;
  } 
  
  public void updateBrightness(Spectrum spectrum) {
    brightness[0] = spectrum.calculateAverageOnInterval(spectrum.getLowFreqStart(), spectrum.getLowFreqEnd());
    brightness[1] = spectrum.calculateAverageOnInterval(spectrum.getMedFreqStart(), spectrum.getMedFreqEnd());
    brightness[2] = spectrum.calculateAverageOnInterval(spectrum.getHighFreqStart(), spectrum.getHighFreqEnd());
    
    arduino.analogWrite(pinLow, brightnessTable[(int) (brightness[0] * 255)]);
    arduino.analogWrite(pinMed, brightnessTable[(int) (brightness[1] * 255)]);
    arduino.analogWrite(pinHigh, brightnessTable[(int) (brightness[2] * 255)]);
  }
  
  public float[] getBrightness() {
    return this.brightness;
  }
 
  private Arduino arduino;

  private float brightness[];
  
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

