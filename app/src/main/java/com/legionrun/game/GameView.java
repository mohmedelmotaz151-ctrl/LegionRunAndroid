package com.legionrun.game;

import android.content.Context;
import android.graphics.*;
import android.view.*;
import java.util.*;

public class GameView extends View {
 private final Paint p=new Paint(3); private final Random random=new Random(7);
 private float playerX=.5f, downX, lastX; private int crowd=12, level=1, score=0;
 private float progress=0; private boolean running=false, won=false, lost=false;
 private long last=0; private final ArrayList<Thing> things=new ArrayList<>();
 private static class Thing { float z,x; int type; Thing(float a,float b,int c){z=a;x=b;type=c;} }
 public GameView(Context c){super(c);setLayerType(View.LAYER_TYPE_SOFTWARE,null);reset();}
 private void reset(){crowd=12;progress=0;score=0;won=false;lost=false;running=true;things.clear();for(int i=0;i<18;i++)things.add(new Thing(i/18f,random.nextFloat(),i%3==0?1:0));invalidate();}
 private int color(String s){return Color.parseColor(s);}
 private void paint(Canvas c,int col){p.setColor(col);p.setStyle(Paint.Style.FILL);p.setShader(null);}
 @Override protected void onDraw(Canvas c){
  super.onDraw(c);float w=getWidth(),h=getHeight();
  c.drawColor(color("#101B31"));
  p.setShader(new LinearGradient(0,0,0,h*.62f,color("#182E4B"),color("#71859A"),Shader.TileMode.CLAMP));c.drawRect(0,0,w,h*.62f,p);p.setShader(null);
  paint(c,color("#26384B"));Path road=new Path();road.moveTo(w*.36f,h*.22f);road.lineTo(w*.64f,h*.22f);road.lineTo(w*1.08f,h);road.lineTo(-w*.08f,h);road.close();c.drawPath(road,p);
  paint(c,color("#D9E2EC"));p.setStrokeWidth(5);c.drawLine(w*.36f,h*.22f,w*.0f,h,p);c.drawLine(w*.64f,h*.22f,w,h,p);
  for(int i=0;i<7;i++){float z=((i/7f+progress*1.8f)%1);float y=h*(.24f+z*.72f);float x=w*(.5f);p.setColor(0x66FFFFFF);p.setStrokeWidth(2+z*5);c.drawLine(x,y,x,y+10+z*32,p);}
  for(Thing t:things){float z=(t.z+progress*1.5f)%1f;float y=h*(.25f+z*.7f);float x=w*(.36f+t.x*.28f+(.5f-t.x)*z*.35f);float size=8+z*30;
   if(t.type==1){paint(c,color("#21C77A"));c.drawRoundRect(x-size*1.3f,y-size*.6f,x+size*1.3f,y+size*.6f,size*.3f,size*.3f,p);p.setColor(Color.WHITE);p.setTextSize(size*.8f);c.drawText("x2",x-size*.5f,y+size*.25f,p);}
   else{paint(c,color("#E94B55"));c.drawRoundRect(x-size,y-size,x+size,y+size,size*.25f,size*.25f,p);}
  }
  // squad in perspective
  for(int i=0;i<Math.min(crowd,36);i++){float row=i/6, col=i%6;float x=w*(playerX-.12f+col*.048f+(row%2)*.018f);float y=h*.78f+row*7;float r=Math.max(4,10-row*.7f);paint(c,color("#F3C969"));c.drawCircle(x,y,r,p);paint(c,color("#2679C8"));c.drawRoundRect(x-r*.8f,y,x+r*.8f,y+r*1.7f,4,4,p);}
  paint(c,0xCC0B1425);c.drawRoundRect(24,28,w-24,116,28,28,p);
  p.setColor(Color.WHITE);p.setTextSize(22);p.setTypeface(Typeface.create("sans-serif",Typeface.BOLD));c.drawText("LEGION RUN",44,62,p);
  p.setTextSize(15);p.drawText("LEVEL "+level+"     SQUAD "+crowd,44,94,p);
  paint(c,color("#FFFFFF"));c.drawRoundRect(28,132,w-28,143,8,8,p);paint(c,color("#20C987"));c.drawRoundRect(28,132,28+(w-56)*Math.min(1,progress),143,8,8,p);
  if(!running){paint(c,0xD9000000);c.drawRect(0,0,w,h,p);p.setColor(Color.WHITE);p.setTextAlign(Paint.Align.CENTER);p.setTextSize(32);p.setTypeface(Typeface.DEFAULT_BOLD);c.drawText(won?"LEVEL COMPLETE!":lost?"TRY AGAIN":"LEGION RUN",w/2,h*.42f,p);p.setTextSize(18);c.drawText(won?"Your squad survived: "+crowd:"Tap to play",w/2,h*.49f,p);p.setTextAlign(Paint.Align.LEFT);}
  if(running){long now=System.currentTimeMillis();if(last!=0){float dt=Math.min(.05f,(now-last)/1000f);progress+=dt*.105f;if(progress>=1){running=false;won=crowd>=8;lost=!won;if(won)score+=crowd*10;}}last=now;postInvalidateDelayed(16);}
 }
 @Override public boolean onTouchEvent(android.view.MotionEvent e){
  float w=getWidth();
  if(e.getAction()==MotionEvent.ACTION_DOWN){downX=e.getX();lastX=downX;return true;}
  if(e.getAction()==MotionEvent.ACTION_MOVE&&running){playerX=Math.max(.12f,Math.min(.88f,playerX+(e.getX()-lastX)/w));lastX=e.getX();return true;}
  if(e.getAction()==MotionEvent.ACTION_UP){if(!running){level=won?level+1:level;reset();return true;}return true;}return true;
 }
}
