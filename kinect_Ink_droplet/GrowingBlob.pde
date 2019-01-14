import toxi.processing.*; // toxiclibs display
import toxi.geom.*; // toxiclibs shapes and vectors

class GrowingBlob {  

  float scale = 1; 
  float maxSize;
  float acceleration = 0;
  float velocity = 1;  
  float velocityMin = 0.005; 
  float velocityMax = 0.01;
  float randomVel = 0;
  boolean deleteBlob = false;
  color thisColor;
  PolygonBlob polyBlob;

  GrowingBlob() {        
    polyBlob = poly; // saves the polygon created by the blob detetection at this moment
    //acceleration = random(1, 1.1);
    randomVel = random(velocityMin, velocityMax);
    randomVel = logVal(randomVel, velocityMin, velocityMax, false);
    //println(randomVel);
    //velocity = randomVel;
    thisColor = getRandomColor();
    updateAndDrawBox2DBlob(scale, thisColor);
    //println("blob");
  }

  void grow() {
    //velocity += acceleration;
    //scale += random(0.001, 0.02);
    scale += randomVel;
    //scale += random(0, 0.3);
  }

  void update() {
    updateAndDrawBox2DBlob(scale, thisColor);
  }

  boolean isDead() {

    maxSize = 6;
    if (scale > maxSize) {
      return true;
    } else {
      return false;
    }
  }

  void updateAndDrawBox2DBlob(float _scale, color _blobColor) {
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
    gfx.polygon2D(polyBlob);
    popMatrix();
  }

  // makes a log curve
  float logVal (float val, float minVal, float maxVal, boolean invert) {

    val = map(val, velocityMin, velocityMax, 0, 1);
    if (invert == false) {
      val = (val*val); //
    } else {
      val = 1-(val*val); // make it log and invert the curve
    }

    val = map(val, 0, 1, minVal, maxVal); // creates a probablity of values close to min
    return val;
  }
}
