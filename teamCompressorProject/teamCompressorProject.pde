import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.signals.*;

Minim minim;
AudioPlayer song;
AudioPlayer fuelSound;
AudioPlayer jetSound;
AudioSnippet loseSound;
AudioSnippet winSound;
FFT fftLin;

SawWave saw;
AudioOutput out;

boolean blink=true;
boolean started=false;
PImage img;
PImage mainMenu;
PImage backgroundI;
PImage player;
PImage player2;
PImage fuel;
PImage deathScreen;//game over dude
PImage startEasy1;
PImage startEasy2;
PImage startMed1;
PImage startMed2;
PImage startHard1;
PImage startHard2;
PImage winScreen;
int groundLocation1=0;//two background images are used so that it can create a seamless scrolling background
int groundLocation2=1650;
boolean gameOver=false;
boolean gameWon=false;
//String songName="Spor_Kingdom_Original Mix Short.wav"; 
//String songName="Parov Stelar - Catgroove Short.wav";
String songName="Chateau_2_Short.mp3";
int dificulty=1;

float startTime = 0;
int platformWidth = 100;
float pixelsPerSecond = 100.0f;
float progress = 0;
int playerY;
float dif=0; //Difference in time between last draw and this draw
float lastTime=0;
int G=5;//speed of gravity and jet
float fuelUse=.2;
Player hero;
Battery[] batteries;
int millisPerCell = 500;

float sawFreq = 15000;
boolean sawAnimating = false;

void setup()
{
  size(800, 450);
  minim = new Minim(this);
  loseSound = minim.loadSnippet("DeathLoseSound2.wav");
  winSound = minim.loadSnippet("WinSound.wav");
  song = minim.loadFile(songName, 2048);
  
  out = minim.getLineOut(Minim.STEREO, 2048);
  saw = new SawWave(sawFreq, 0.1, out.sampleRate());
  out.addSignal(saw);
  saw.setAmp(0.00001f);
  
  String[] lines = loadStrings(songName+".txt");
  int[] cellHeights = int(split(lines[0], ',' ));
  
  batteries = new Battery[cellHeights.length];
  
  for(int i = 0; i < batteries.length; i++)
  {
    batteries[i] = new Battery();
    batteries[i].height = cellHeights[i];
  }
  
  processBatteries();
  
  int samplesPerPlatform = (int)((((float)platformWidth)/pixelsPerSecond) * song.sampleRate());
  hero= new Player();
  startEasy1= loadImage("StartScreenEasy1.png");
  startEasy2= loadImage("StartScreenEasy2.png");
  startMed1= loadImage("StartScreenMed1.png");
  startMed2=loadImage("StartScreenMedium2.png");
  startHard1=loadImage("StartScreenHard1.png");
  startHard2=loadImage("StartScreenHard2.png");
  mainMenu = loadImage("MainMenu.png");
  backgroundI= loadImage("background.png");
  player= loadImage("robot.png");
  player2= loadImage("robotJet.png");
  deathScreen=loadImage("GameOver.png");
  fuel=loadImage("Fuel.png");
  winScreen = loadImage("winScreen.png");
  jetSound = minim.loadFile("JetpackSound2.wav", 1024);
  int curX = 0;
  
  
}

void keyPressed() {
  if (keyCode==UP){
    if(!started){
      hero.setJet(true);
    }
    if(started& !gameOver){
      if(hero.fuelLevel>0){
        hero.setJet(true);
        if(!jetSound.isPlaying()){
          jetSound = minim.loadFile("JetpackSound2.wav", 1024);
          jetSound.setVolume(0.01);
          jetSound.play();
        }
      }
    }
  }
  if(keyCode==LEFT){
    if(!started){
      dificulty=dificulty-1;
      if(dificulty<1){
        dificulty=1;
      }
    }
  }
  if(keyCode==RIGHT){
    if(!started){
      dificulty=dificulty+1;
      if(dificulty>3){
        dificulty=3;
      }
    }
  }
  if(key==ENTER){//restart
    if(started & gameOver){
      hero.y=100;//reset starting height
      hero.speed=G;
      hero.fuelLevel=100;
      song = minim.loadFile(songName, 2048);//reload song
      loseSound = minim.loadSnippet("DeathLoseSound2.wav");
      gameWon=false;
      progress=0;
      String[] lines = loadStrings(songName+".txt");
      int[] cellHeights = int(split(lines[0], ',' ));
      batteries = new Battery[cellHeights.length];
  
      for(int i = 0; i < batteries.length; i++)
      {
        batteries[i] = new Battery();
        batteries[i].height = cellHeights[i];
      }
  
      processBatteries();
      
      song.play();
      gameOver=false;
      startTime = millis();
    }
    if(!started){
      started=true;
      song.play();
      startTime = millis();
    }
  }
  
} 
void keyReleased(){
  if(keyCode==UP){
    hero.setJet(false);
    if(started&!gameOver){
      
      jetSound.pause();
    }
  }
}
  
void draw()
{
  background(0);

  stroke(255);
    
  float curTime = millis();
  progress = curTime - startTime;
  dif=curTime-lastTime;
  if(dif>14){//helps framerate
 
  if(!gameOver & started){
    //image(mainMenu);
    if(groundLocation1<width)image(backgroundI, groundLocation1, 0);//draw if on screen
    if(groundLocation2<width)image(backgroundI, groundLocation2, 0);
    if(groundLocation1<groundLocation2){
      groundLocation2= groundLocation1+1650;
    }
    else{
      groundLocation1=groundLocation2+1650;
    }
    int change =int(dif*.12);
    groundLocation1=groundLocation1-change;//move the background images
    groundLocation2=groundLocation2-change;
    if(groundLocation1<(-1650)){//reset if the image is out of sight
      groundLocation1=1650;
    }
    if(groundLocation2<(-1650)){
      groundLocation2=1650;
    }
  }
  
  int gameOffset = (int) (progress * (pixelsPerSecond / 1000.0f));
  int startCell = floor(progress / (float)millisPerCell);
  int startOffset = (int) (startCell * (pixelsPerSecond / 2.0f));
  int endCell = (int) (startCell + (800.0f/(pixelsPerSecond/2.0f)));
  int cellXOffset = (int)(startOffset - gameOffset);
  
  if(endCell >= batteries.length)
  {
    endCell = batteries.length-1;
  }
  
  if(startCell >= (batteries.length-1))
  {
    gameWon = true;
    gameOver = true;
    winSound.play();
  }
  
 if(started)
 {
   for(int i = startCell; i < endCell; i++)
  { 
    if(i<batteries.length & batteries[i]!=null &batteries[i].active)
    {
      int actualX = (int) ((i-startCell)*(pixelsPerSecond/2.0f)+cellXOffset);
      int actualY = batteries[i].height+25;
      image(fuel, actualX, actualY);
      
      if( (actualX < (hero.x+player.width)) && ((actualX+20) > hero.x) && (actualY < (hero.y+player.height)) && ((actualY+40) > hero.y) )
      {
        //fuelSound = minim.loadFile("FuelPickUpSound.WAV", 1024);
        //fuelSound.play();
        batteries[i].active = false;
        hero.fuelLevel += fuelUse*10.0f*dificulty;
        if(hero.fuelLevel > 100) {hero.fuelLevel = 100;}
      }
      
      if((actualX < 10) && (batteries[i].active == true) && (!gameOver))
      {
        sawAnimating = true;
        sawFreq = 1000+(14000.0f*(1.0f-pow((float)hero.fuelLevel/100.0f, 0.5f)));
        print(sawFreq);
        saw.setFreq(15000);
        saw.setAmp(0.3f);
        batteries[i].active = false;
      }
    }
  }
  
  if(sawAnimating)
  {
    sawFreq -= pow(1.0f + sawFreq-100.0f, 0.5f)*10.0f;
    
    if(sawFreq > 440.0f)
    {
      saw.setFreq(sawFreq);
    }
    else
    {
      sawAnimating = false;
      saw.setAmp(0.0001f);
    }
  }
  
  fill(2.55*(100-hero.fuelLevel),2.55*hero.fuelLevel,0);
  stroke(2.55*(100-hero.fuelLevel),2.55*hero.fuelLevel,0);
  rect( 550,10, 2.25*hero.fuelLevel, 30);
  if(hero.fuelLevel>0){hero.fuelLevel=hero.fuelLevel-fuelUse*(dificulty*.32);}
  if(hero.fuelLevel<0){hero.fuelLevel=0;}
  hero.y= hero.y+hero.speed;//moves the hero with gravity or jets
  if(hero.y<0){hero.y=0;}// don't let you fly off
  if(hero.y>300){//ends the game if you hit lava
    hero.speed=0;
    gameOver=true;
    song.pause();
    if(fuelSound!=null){
     if(fuelSound.isPlaying()){
      fuelSound.pause();
     }
    }
    if(jetSound!=null){
      if(jetSound.isPlaying()){
        jetSound.pause();
      }
    }
    if(!gameWon){
      loseSound.play();
    }
  }
  if(hero.fuelLevel<=0){
    hero.speed=G;
    hero.setJet(false);
  }
  if(hero.jet){//use the image with fire if up is pressed
    image(player2, hero.x,hero.y);
  }
  else{//use the normal image if jets are off
    image(player,hero.x,hero.y); 
  }
  
  dif=0;
  }
  lastTime=curTime;
  if(gameOver){
    if(gameWon)
      image(winScreen, 0, 0);
    else
      image(deathScreen,0,0);
  }
  }
  
  if(!started){
   if(dificulty==1){
     image(startEasy1,0,0);
   }
   if(dificulty==2){
     image(startMed1,0,0);
   }
   if(dificulty==3){ 
     image(startHard1,0,0);
   }
   if(hero.jet){//use the image with fire if up is pressed
      image(player2, hero.x+620,hero.y-70);
    }
    else{//use the normal image if jets are off
      image(player,hero.x+620,hero.y-70); 
    }
  }
}

void stop()
{
  song.close();
  fuelSound.close();
  jetSound.close();
  loseSound.close();
  minim.stop();
  super.stop();
}

void processBatteries()
{
  Battery[] nBat = new Battery[batteries.length];
  int smoothOrder = 5;
  float dropoffFactor = 2.0f;
  
  for(int i = 0; i < batteries.length; i++)
  {
    float total = 0;
    float weightTotal = 0;
    
    total += (float)batteries[i].height * 0.5f;
    weightTotal += 0.5f;
    
    for(int s = 1; s <= smoothOrder; s++)
    {
       if( (i+s) < batteries.length )
       {
         float weight = pow(1.0f/(2.0f + (float)s), dropoffFactor);
         total += (float)batteries[i+s].height * weight;
         weightTotal += weight;
       }
       
       if( (i-s) >= 0)
       {
         float weight = pow(1.0f/(2.0f+(float)s), dropoffFactor);
         total += (float)batteries[i-s].height * weight;
         weightTotal += weight;
       }
    }
    
    nBat[i] = new Battery();
    nBat[i].height = (int)(total / weightTotal) - 20;
  }
  
  batteries = nBat;
}

//The robot
class Player{
  float fuelLevel=100;
  int y = 100;//starting hieght
  int x=50;//distance from left side of the screen
  int speed=G;//gravity is dragging down
  boolean jet=false;
  void setJet(boolean bool){
    jet=bool;
    if(jet){//up if jet is on, down if not.
      speed=-G;
    }
    else{
      speed=G;
    }
  }
}

class Battery {
  boolean active = true;
  int height = 0;
}
