package com.legionrun.game;
import android.app.Activity;
import android.os.Bundle;
import android.view.Window;
import android.view.WindowManager;
public class MainActivity extends Activity {
 @Override public void onCreate(Bundle b) {
  super.onCreate(b); requestWindowFeature(Window.FEATURE_NO_TITLE);
  getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN,WindowManager.LayoutParams.FLAG_FULLSCREEN);
  getWindow().getDecorView().setSystemUiVisibility(5894|1024|512|4096);
  setContentView(new GameView(this));
 }
}
