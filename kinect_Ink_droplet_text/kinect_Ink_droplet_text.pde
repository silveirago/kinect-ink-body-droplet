// Kinect Physics Example by Amnon Owed (15/09/12)
//edited by Arindam Sen
//updated for openProcessing library and Processing 3 by Erik Nauman 9/16
// import libraries
import org.openkinect.processing.*;
import blobDetection.*; // blobs
import toxi.geom.*; // toxiclibs shapes and vectors
import toxi.processing.*; // toxiclibs display
import shiffman.box2d.*; // shiffman's jbox2d helper library
import org.jbox2d.collision.shapes.*; // jbox2d
import org.jbox2d.dynamics.joints.*;
import org.jbox2d.common.*; // jbox2d
import org.jbox2d.dynamics.*; // jbox2d

Kinect kinect;
// declare BlobDetection object
BlobDetection theBlobDetection;
Blob findBlob;
// ToxiclibsSupport for displaying polygons
ToxiclibsSupport gfx;
// declare custom PolygonBlob object (see class for more info)
PolygonBlob poly;

// PImage to hold incoming imagery and smaller one for blob detection
PImage blobs;
// the kinect's dimensions to be used later on for calculations
int kinectWidth = 512;
int kinectHeight = 424;
PImage cam = createImage(640, 480, RGB);
int minThresh = 100;
int maxThresh = 920;
// to center and rescale from 640x480 to higher custom resolutions
float reScale;
PVector blobCenter;

// background and blob color
color bgColor, blobColor;
color bg = #ff8a5b;
color avatarColor = #b7c8ff;
// three color palettes (artifact from me storingmany interesting color palettes as strings in an external data file ;-)
color[] colorPalette;
int colorScheme = 0; // 0: Pinkish - 1: psy1

//color[] hues = {228, 17, 226, 310, 348, 329, 269, 180, 339};
color[][] colors = {
  {#5678ff, #ff8a5b, #b7c8ff, #ff89eb, #ff7792, #ffa8d5, #8b1eff, #baffff, #ff327a, #5678ff}, //pinksish
  {#FF9500, #FF0000, #FF00F3, #AA00FF, #002EFF}
};

// the main PBox2D object in which all the physics-based stuff is happening
Box2DProcessing box2d;
// list to hold all the custom shapes (circles, polygons)
ArrayList<CustomShape> polygons = new ArrayList<CustomShape>();

// Growing Blobs
ArrayList<GrowingBlob> gBlobs; //growing blobs
int timer = 0;

void setup() {
  //println(colors[colorPalette.length]);
  println("SET UP");  
  // it's possible to customize this, for example 1920x1080
  //size(600, 400);
  fullScreen(P2D);    
  background(bg);

  //colorMode(HSB, 360, 100, 100);  
  kinect = new Kinect(this);
  // mirror the image to be more intuitive
  kinect.enableMirror(true);
  kinect.initDepth();
  // calculate the reScale value
  // currently it's rescaled to fill the complete width (cuts of top-bottom)
  // it's also possible to fill the complete height (leaves empty sides)
  reScale = (float) width / kinectWidth;
  // create a smaller blob image for speed and efficiency
  blobs = createImage(kinectWidth/3, kinectHeight/3, RGB);
  // initialize blob detection object to the blob image dimensions
  theBlobDetection = new BlobDetection(blobs.width, blobs.height);
  //findBlob = new Blob(width, height);
  theBlobDetection.setThreshold(0.3);
  // initialize ToxiclibsSupport object
  gfx = new ToxiclibsSupport(this);
  // setup box2d, create world, set gravity
  box2d = new Box2DProcessing(this);
  box2d.createWorld();
  box2d.setGravity(0, -40);
  //blob center
  blobCenter = new PVector(0, 0);
  // growing blobs
  gBlobs = new ArrayList<GrowingBlob>();
}

void draw() {

  generateBg();
  background(bg);
  // update the kinect object
  cam.loadPixels();

  // Get the raw depth as array of integers
  int[] depth = kinect.getRawDepth();
  for (int x = 0; x < kinect.width; x++) {
    for (int y = 0; y < kinect.height; y++) {
      int offset = x + y * kinect.width;
      int d = depth[offset];

      if (d > minThresh && d < maxThresh) {
        cam.pixels[offset] = color(255);
      } else {
        cam.pixels[offset] = color(0);
      }
    }
  }

  cam.updatePixels();
  //image(cam, 0, 0); skip displaying depth image
  // copy the image into the smaller blob image
  blobs.copy(cam, 0, 0, cam.width, cam.height, 0, 0, blobs.width, blobs.height);
  // blur the blob image, otherwise too many blog segments
  blobs.filter(BLUR, 1);
  // detect the blobs
  theBlobDetection.computeBlobs(blobs.pixels);
  // initialize a new polygon
  //find blocb center
  //findBlobCenter();
  poly = new PolygonBlob();
  // create the polygon from the blobs (custom functionality, see class)
  poly.createPolygon();
  // create the box2d body from the polygon
  poly.createBody();

  //growing blobs
  generateBlob();
  //for (int i = gBlobs.size() - 1; i >= 0; i--) {
  for (int i = 0; i < gBlobs.size(); i++) {
    GrowingBlob b = gBlobs.get(i);    
    b.grow();
    b.update();
    if (b.isDead()) {
      gBlobs.remove(i);
    }
  }

  // update and draw everything (see method)
  generateAvatarColor(); // generates random avatr colors
  updateAndDrawBox2D(1, avatarColor);
  // destroy the person's body (important!)
  poly.destroyBody();

  //println(frameRate);
  
  drawText();
}
// end of DRAW 
////////////////////////////////////////////

////////////////////////////////////////////
// Generates blog
void updateAndDrawBox2D(float _scale, color _blobColor) {
  // if frameRate is sufficient, add a polygon and a circle with a random radius
  // center and reScale from Kinect to custom dimensions

  float bScale = _scale;
  float scaleFactorY = (height - height/bScale)*bScale;
  float scaleFactorX = (width*bScale) - ((width*bScale)/2) - width/2;
  float newSize = (height-kinectHeight*reScale)/2;
  //float x = map(blobCenter.x, 0, 1, 0, width);
  //float y = map(blobCenter.y, 0, 1, 0, height);
  pushMatrix();
  //translate(0, (height-kinectHeight*reScale)/2);
  translate(0 - scaleFactorX, newSize - scaleFactorY);
  scale(reScale * bScale);     
  // display the person's polygon  
  noStroke();
  fill(_blobColor);
  gfx.polygon2D(poly);
  popMatrix();
}

////////////////////////////////////////////
// returns a random color from the palette (excluding first aka background color)
color getRandomColor() {
  //return colorPalette[int(random(1, colorPalette.length))];
  color tempColor = colors[colorScheme][int(random(0, colors[colorScheme].length))];
  ;
  //println("Color: ", color(tempColor));
  return tempColor;
}

////////////////////////////////////////////
// generate growing blobs
void generateBlob() {
  timer = millis() % int(random(50, 400));
  //println(timer);

  if (timer < 20) {
    gBlobs.add(new GrowingBlob()); //creates a new blob
    if (gBlobs.size() > 35) {
      gBlobs.remove(0);
    }
  }
}

////////////////////////////////////////////
// generate a new background
void generateBg() {
  timer = millis() % int(random(2000, 10000));
  //println(timer);

  if (timer < 20) {
    bg = getRandomColor();
  }
}
// generate a new avatar color
void generateAvatarColor() {
  timer = millis() % int(random(100, 2000));
  //println(timer);

  if (timer < 20) {
    avatarColor = getRandomColor();
  }
}

void drawText() {
  
  textSize(100);
  text("put your text here", 50, 100); // pos x y  
  //fill(#ffffff); //color RGB 0-255 - not working
}
