import "std.zh"
//BALL NEEDS TO HAVE A 6PX BY 6PX HITBOX, AND THUS A HIT OFFSET OF -1,-1, so that ->HitBy[] returns when the ball hits a block, and
//the ball is still not yet inside that object
//Note: We also need to store the UID of each ball, as HitBy[] works from the UID, not the pointer. 

//# QUEST ISSUE: Bricks Break playing the wrong sound, despite being set. Might be a 2.54 bug? -Z

/* ZC issues: I forgot to expand ->Misc[] in sprite.cpp, which should be fixed int he source for Alpha 32. 
	This meant that r/w to ptr->Misc[>15] would use invalid data, or overwrite other data. bad, bad, bad. 
	
	Continue script does not run when Init script runs. It NEEDS to do that! Otherwise, settings that affect things such as Link's tile
	don't happen before the opening wipe. 
	
	HitBy[] Doesn't yet use UIDs. :/ I forgot that it uses the screen index. This is a case for adding HitBy[UID] to 2.54...
	In fact, the only reason that using HitBy[UID] worked, was because my object 9the ball_ was *both* UID1 and LW1. :D
	
*/

//Arkanoid script
//v0.11
//15th August, 2018

const int FFC_VAUS = 1;
const int CMB_VAUS_EXTENDED = 1528;
const int CMB_VAUS = 1524;
const int CMB_VAUS_DEAD = 1520;

const int MID_STAGE_START = 4;
const int NPCM_AWARDED_POINTS = 3; //brick->Misc[], flag to mark if points were awarded to the player. 
const int NPC_ATTRIB_POINTS = 0; //brick->Attributes[], value for score. 

int quit;
int caught;
int frame;
bool newstage = true;
bool revive_vaus = false; 

int ball_x;
int ball_y;
int ball_dir;
int ball_angle;
int ball_speed;
int ball_vx;
int ball_vy;
int paddle_x;
int paddle_y;
int paddle_width = 16;
int paddle_speed = 2;
int extended;

int ball_uid;

//animation
int death_frame;

int templayer[4];

int input_accel; //pressing left and right for multiple frames increases this
int frames_pressed[18]; 

//ffc paddle;

int hit_zones[5]; //angle offsets for where the ball strikes the paddle

const int WALL_LEFT = 24;
const int WALL_TOP = 8; //Mix Ball Y
const int WALL_RIGHT = 232;

const int BALL_MIN_Y = 9; //ceiling +1
const int BALL_MAX_Y = 145; //one pixel under paddle top
const int BALL_MIN_X = 25; //left wall +1
const int BALL_MAX_X = 229; //right wall -1



const int START_PADDLE_X = 62;
const int START_PADDLE_Y = 160;
const int START_PADDLE_WIDTH = 32;
const int START_PADDLE_HEIGHT = 8;
const int BALL_WIDTH = 4;
const int BALL_HEIGHT = 4;
const int START_BALL_X = 98; //(START_PADDLE_X + 36);
const int START_BALL_Y = 156; //START_PADDLE_Y - 4;
const int START_BALL_DIR = 5; //DIR_UPRIGHT;
const int START_BALL_RADS = 220; //angle in radians
const int START_BALL_SPEED = 45;
const int START_BALL_VX = 0;
const int START_BALL_VY = 0;

const int PADDLE_MIN_X = 25;
const int PADDLE_MAX_X = 200; //WALL_RIGHT -32; //This one varies as the paddle width may change.
const int PADDLE_MAX_X_EXTENDED = 184; //WALL_RIGHT - 48; //This one varies as the paddle width may change.
const int PADDLE_MIN_X_EXTENDED = 25;

const int _MOUSE_X = 0;
const int _MOUSE_Y = 1;
const int _MOUSE_LCLICK = 2;

//const float ACCEL_FACTOR = 0.25;

const int FRAMES_PER_MOVEMENT = 10; 
int USE_ACCEL = 0; //Do we accelerate KB/JP input?
int USE_MOUSE = 0; //Are we using the mouse?


/*
const int CB_UP		= 0;
const int CB_DOWN	= 1;
const int CB_LEFT	= 2;
const int CB_RIGHT	= 3;
const int CB_A		= 4;
const int CB_B		= 5;
const int CB_L		= 7;
const int CB_R		= 8;
const int CB_START	= 6;
const int CB_MAP	= 9;
const int CB_EX1	= 10;
const int CB_EX2	= 11;
const int CB_EX3	= 12;
const int CB_EX4	= 13;
const int CB_AXIS_UP	= 14;
const int CB_AXIS_DOWN	= 15;
const int CB_AXIS_LEFT	= 16;
const int CB_AXIS_RIGHT	= 17;

*/

ffc script paddle
{
	void run(){}
	
	bool move(bool mouse, bool accel, ffc p)
	{
		int dir; int dist;
		if ( mouse ) 
		{
			//get the mouse movement this frame and apply a relative amount to the paddle
			//set the dir here
			//set the dist here
			//if moving left
			//if ( p->X > PADDLE_MIN_X ) 
			//{
			//	p->X = Input->Mouse[_MOUSE_X];
				//apply change -- ZC has no special mouse tracking. 
			//}
			//if moving right
			if ( !extended )
			{
				if ( Input->Mouse[_MOUSE_X] <= PADDLE_MAX_X )
				{
					if ( Input->Mouse[_MOUSE_X] >= PADDLE_MIN_X )
					{
						//apply change
						p->X = Input->Mouse[_MOUSE_X];
					}
				}
			}
			else
			{
				if ( Input->Mouse[_MOUSE_X] <= PADDLE_MAX_X_EXTENDED )
				{
					if ( Input->Mouse[_MOUSE_X] >= PADDLE_MIN_X_EXTENDED )
					{
						//apply change
						p->X = Input->Mouse[_MOUSE_X];
					}
				}
			}
		}
		else //using a KB or joypad
		{
			//check how long the dir button is held
			if ( accel ) //if we allow acceleratiopn, move N pixeld * accel factor * frames held
			{
				
				if ( !extended )
				{
					if (  Input->Button[CB_LEFT] ) 
					{
						for ( int q = frames_pressed[CB_LEFT]; q > 0 ; --q ) 
						{
							if ( p->X > PADDLE_MIN_X )
							{
								--p->X;
								--p->X;
							}
						}
					}
					if (  Input->Button[CB_RIGHT] ) 
					{
						for ( int q = frames_pressed[CB_RIGHT]; q > 0; --q ) 
						{
							if ( p->X < PADDLE_MAX_X )
							{
								++p->X;
							}
						}
					}
				}
				
			}
			
			else //no accel offered, move a static number of pixels
			{
				
				if ( !extended )
				{
					if (  Input->Button[CB_LEFT] ) 
					{
						for ( int q = 0; q < paddle_speed; ++q ) 
						{
							if ( p->X > PADDLE_MIN_X )
							{
								--p->X;
							}
						}
					}
					if (  Input->Button[CB_RIGHT] ) 
					{
						for ( int q = 0; q < paddle_speed; ++q ) 
						{
							if ( p->X < PADDLE_MAX_X )
							{
								++p->X;
							}
						}
					}
				}
				else
				{
					if (  Input->Button[CB_LEFT] ) 
					{
						if ( p->X > PADDLE_MIN_X_EXTENDED )
						{
							--p->X;
						}
					}
					if (  Input->Button[CB_RIGHT] ) {
						if ( p->X < PADDLE_MAX_X_EXTENDED )
						{
							++p->X;
						}
					}
					
				}
			}
		}
		
	}

	void check_input()
	{
		if ( Input->Button[CB_LEFT] ) ++frames_pressed[CB_LEFT];
		else frames_pressed[CB_LEFT] = 0;
		if ( Input->Button[CB_RIGHT] ) ++frames_pressed[CB_RIGHT];
		else frames_pressed[CB_RIGHT] = 0;
		
	}
	
	void extend(ffc p)
	{
		if ( extended ) 
		{
			if ( p->TileWidth < 3 ) 
			{
				p->Data = CMB_VAUS_EXTENDED;
				p->TileWidth = 3;
			}
		}
		else
		{
			if ( p->TileWidth > 2 ) 
			{
				p->Data = CMB_VAUS;
				p->TileWidth = 2;
			}
		}
	}
	void setup(ffc p)
	{
		p->Y = START_PADDLE_Y;
		p->X = START_PADDLE_X;
		p->Data = CMB_VAUS;
		p->TileWidth = 2;
		
	}
	void dead(ffc p)
	{
		p->Data = CMB_VAUS_DEAD;
		p->TileWidth = 2;
		death_frame = frame;
	}
	

}

const int MISC_BALLID = 0; //Misc index of Vaud->Misc[]
const int MISC_DEAD = 1; //Misc index of Vaud->Misc[]
const int MISC_LAUNCHED = 0; //Misc index of ball->Misc[]

const int BALL_MINIMUM_Y = 24; //Invisible line at which point, ball is lost. 
global script arkanoid
{
	
	void run()
	{
		quit = -1;
		frame = -1;
		ffc vaus = Screen->LoadFFC(FFC_VAUS);
		lweapon movingball;
		bool ext;
		Link->CollDetection = false;
		Link->DrawYOffset = -32768;
		Trace(quit);
		ball.setup_sprite(SPR_BALL);
		while(true)
		{
			//TraceS("Starting Arkanoid");
			++frame;
			hold_Link();
			if ( newstage ) 
			{
				Game->PlayMIDI(MID_STAGE_START);
				brick.setup();
				Waitframes(6);
				
				brick.clear_combos();
				
				newstage = false;
				paddle.setup(vaus);
				ball.create(vaus);
				movingball = vaus->Misc[MISC_BALLID];
			}
			if ( revive_vaus ) //when this is called, the ball breaks through all bricks. Something isn't being set. 
			{
				Game->PlayMIDI(MID_STAGE_START);
				vaus->Misc[MISC_DEAD] = 0; 
				revive_vaus = false;
				paddle.setup(vaus);
				ball.create(vaus);
				movingball = vaus->Misc[MISC_BALLID];
			}
			
			if ( !vaus->Misc[MISC_DEAD] )
			{
				if ( Input->Key[KEY_P] ) Trace(movingball->UID); //Frick, I'm an idiot. HIT_BY_LWEAPON is the SCREEN INDEX< not the UID!!
					//2.54 Absolutely needs HitBy_UID!
				change_setting(); //check for a setting change_setting
				paddle.extend(vaus);
				paddle.check_input();
				paddle.move(USE_MOUSE, USE_ACCEL, vaus);
				
				ball.launch(movingball);
				if ( !ball.launched(movingball) )
				{
					ball.move_with_vaus(movingball, vaus);
				}
				
				ball.check_ceiling(movingball);
				ball.check_leftwall(movingball);
				ball.check_rightwall(movingball);
				ball.check_hitvaus(movingball, vaus);
				/*
				
				I moved this to after Waitdraw, because I wanted the post-draw timing for ball bounce, and to ensure that
				the movingball lweapon stayed alive. -Z (Alpha 0.10)
				//Bounce ball on bricks. 
				for ( int q = Screen->NumNPCs(); q > 0; --q )
				{ 
					npc b = Screen->LoadNPC(q);
					if ( b->Type != NPCT_OTHERFLOAT ) continue;
					TraceNL(); TraceS("movingball->X = "); Trace(movingball->X);
					TraceNL(); TraceS("movingball->Y = "); Trace(movingball->Y);
					brick.take_hit(b, movingball);
				}
				*/
				movingball->DeadState = WDS_ALIVE; //Force it alive at all times if the vaus is alive. 
					//We'll need another solition once we do the 3-way split ball. Bleah. 
			}
			
			//It's probably unwise to run this block twice! Where do I want it, before or after Waitdraw() ? -Z
			else
			{
				paddle.dead(vaus);
				while ( (frame - 100) < death_frame ) 
				{
					//we should hide the vaus, and restart the stage here. 
					++frame;
					Waitdraw(); //Something is preventing the vaus from changing into the explosion style. S
					Waitframe();
				}
				lweapon deadball = movingball; 
				deadball->DeadState = WDS_DEAD; 
				movingball = vaus->Misc[10];
				revive_vaus = true; 
				
			}
			
			Waitdraw();
			
			
			if ( !vaus->Misc[MISC_DEAD] )
			{
				movingball->DeadState = WDS_ALIVE;
				
				//Bounce ball on bricks. 
				for ( int q = Screen->NumNPCs(); q > 0; --q )
				{ 
					npc b = Screen->LoadNPC(q);
					if ( b->Type != NPCT_OTHERFLOAT ) continue;
					//TraceNL(); TraceS("movingball->X = "); Trace(movingball->X);
					//TraceNL(); TraceS("movingball->Y = "); Trace(movingball->Y);
					movingball->DeadState = WDS_ALIVE;
					brick.take_hit(b, movingball);
				}
				
			}
			else
			{
				paddle.dead(vaus);
				while ( (frame - 100) < death_frame ) 
				{
					//we should hide the vaus, and restart the stage here. 
					++frame;
					Waitdraw();
					Waitframe();
				}
				lweapon deadball = movingball; 
				deadball->DeadState = WDS_DEAD; 
				movingball = vaus->Misc[10]; //Because = NULL() requires alpha 32. :D
				revive_vaus = true; 
				
			}
			
			Waitframe();
		}
	}
	void change_setting()
	{
		if ( Input->Key[KEY_M] ) USE_MOUSE = 1;
		if ( Input->Key[KEY_N] ) USE_MOUSE = 0;
		if ( Input->Key[KEY_F] ) USE_ACCEL = 1;
		if ( Input->Key[KEY_G] ) USE_ACCEL = 0;
		if ( Input->Key[KEY_T] ) --paddle_speed; // paddle_speed = vbound(paddle_speed
		if ( Input->Key[KEY_Y] ) ++paddle_speed; // paddle_speed = vbound(paddle_speed
	}
	void hold_Link()
	{
		Link->X = 60; Link->Y = 60;
	}
	
}

const int TILE_BALL = 50512;
const int SPR_BALL = 100;



//preliminary ball
ffc script ball
{
	void run(){}
	void setup_sprite(int sprite_id)
	{
		spritedata sd = Game->LoadSpriteData(sprite_id);
		sd->Tile = TILE_BALL;
	}
	void create(ffc vaus_id) //send the ball lweapon pointer back to the vaus
	{
		lweapon ball = Screen->CreateLWeapon(LW_SCRIPT1);
		TraceNL(); TraceS("Creating ball with Script UID: "); Trace(ball->UID);
		ball->HitWidth = 6; //Not 4, so that the ball bounces when its edges touch a brick. 
		ball->HitHeight = 6; //Not 4, so that the ball bounces when its edges touch a brick. 
		ball->UseSprite(SPR_BALL);
		ball->X = vaus_id->X+18;
		ball->Y = vaus_id->Y-2;
		ball->Damage = 1;
		ball_uid = ball->UID;
		ball->HitXOffset = -1; //so that the ball bounces when its edges touch a brick. 
		ball->HitYOffset = -1; //so that the ball bounces when its edges touch a brick. 
		vaus_id->Misc[MISC_BALLID] = ball;
	}
	void launch(lweapon b)
	{
		if ( b->Misc[MISC_LAUNCHED] ) return;
		bool launched;
		for ( int q = CB_A; q < CB_R; ++q ) 
		{
			if ( Input->Press[q] ) { launched = true; break; }
		}
		if ( launched ) 
		{
			//b->Angular = true;
			Game->PlaySound(6);
			b->Dir = DIR_RIGHTUP;	
			b->Step = 90;
			b->Misc[MISC_LAUNCHED] = 1;
		}
	}
	bool launched(lweapon b) 
	{
		return (b->Misc[MISC_LAUNCHED]);
	}
	void move(lweapon b)
	{
		
	}
	//Not launched yet.
	void move_with_vaus(lweapon b, ffc v)
	{
		b->X = v->X+18;
	}
	void check_ceiling(lweapon b)
	{
		if ( b->Y <= BALL_MIN_Y )			
		{
			Game->PlaySound(7);
			switch(b->Dir)
			{
				case DIR_RIGHTUP: { b->Dir = DIR_RIGHTDOWN; break; }
				case DIR_LEFTUP: { b->Dir = DIR_LEFTDOWN; break; }
				default: { b->Dir = DIR_DOWN; break; }
			}
		}
	}
	void check_leftwall(lweapon b)
	{
		if ( caught ) return; //don't do anything while the vaus is holding the ball
		if ( b->X == BALL_MIN_X ) 
		{
			Game->PlaySound(7);
			switch(b->Dir)
			{
				case DIR_LEFTDOWN: { b->Dir = DIR_RIGHTDOWN; break; }
				case DIR_LEFTUP: { b->Dir = DIR_RIGHTUP; break; }
				default: { b->Dir = DIR_DOWN; break; }
			}
		}
	}
	void check_rightwall(lweapon b)
	{
		if ( caught ) return; //don't do anything while the vaus is holding the ball
		if ( b->X == BALL_MAX_X ) 
		{
			Game->PlaySound(7);
			switch(b->Dir)
			{
				case DIR_RIGHTDOWN: { b->Dir = DIR_LEFTDOWN; break; }
				case DIR_RIGHTUP: { b->Dir = DIR_LEFTUP; break; }
				default: { b->Dir = DIR_DOWN; break; }
			}
		}
	}
	void check_hitvaus(lweapon b, ffc v)
	{
		if ( launched(b) )
		{
			if ( b->Dir == DIR_RIGHTUP ) return;
			if ( b->Dir == DIR_LEFTUP ) return;
			//if ( Collision(b,v) ) //We'll refine this, later. 
			
			if ( b->Y+4 == v->Y )
				//Now we need to check here, if the paddle is under the ball:
			{
				if ( b->X >= v->X-3 ) //-3, because the ball is 4px wide, so we cover the last pixel of the ball against the furst pixel of the Vaus
				{
					if ( b->X <= v->X+(v->TileWidth*16) ) //no +3 here, because it's the actual X, so the first pixel of the ball is covered by the last pixel of the vaus.
					{
						Game->PlaySound(6);
						b->Y = v->Y-1;
						switch(b->Dir)
						{
							case DIR_LEFTDOWN: { b->Dir = DIR_LEFTUP; break; }
							case DIR_RIGHTDOWN: { b->Dir = DIR_RIGHTUP; break; }
							default: { b->Dir = DIR_DOWN; break; }
						}
					}
					else 
					{
						dead(b,v);
					}
				}
				else 
				{
					dead(b,v);
				}
			}
			
		}
	}
	void dead(lweapon b, ffc v)
	{
		
		Game->PlayMIDI(5);
		//remove the ball
		b->Y = -32768; b->Step = 0;
		v->Misc[MISC_DEAD] = 1;
		//if there are more balls in play, switch movingball to one of those
		//otherwise,
		//check next life
		//if more lives, reset playfield
		//otherwise game over
		
	}
	
	
	
}

ffc script ball_controller
{
	void run()
	{
		lweapon ball;
		lweapon active_ball; //will be used for when we have multiple balls. 
		lweapon balls[3]; //for divide
		ball = Screen->CreateLWeapon(LW_SCRIPT1);
		ball->X = START_BALL_X;
		ball->Y = START_BALL_Y;
		this->Vx = START_BALL_VX;
		this->Vy = START_BALL_VY;
		bool alive = true;
		int num_balls = 1;
		while(alive)
		{
			if ( ball->Y <= BALL_MIN_Y )
			{
				bounce();
			}
			if ( ball->X <= BALL_MIN_X )
			{
				bounce();
			}
			if ( ball->X >= BALL_MAX_X )
			{
				bounce();
			}
				
			if ( ball->Y >= BALL_MAX_Y )
			{
				if ( num_balls < 2 ) 
				{
					alive = false;
				}
				else 
				{
					kill_ball(ball); //removes this ball, and sets another ball to be the active one
					--num_balls;
				}
			}
			Waitframe();
		}
	}
	void bounce(){}
	void kill_ball(lweapon b){}
	
}

const int BRICK_MAX = 14;

//Layer 1
const int CMB_BRICK_RED		= 1488;
const int CMB_BRICK_WHITE	= 1490;
const int CMB_BRICK_BLUE	= 1492;
const int CMB_BRICK_ORANGE	= 1494;
const int CMB_BRICK_TEAL	= 1496;
const int CMB_BRICK_VIOLET	= 1498;
const int CMB_BRICK_GREEN	= 1500;
const int CMB_BRICK_YELLOW	= 1502;
const int CMB_BRICK_SILVER1	= 1504;
const int CMB_BRICK_SILVER2	= 1506;
const int CMB_BRICK_SILVER3	= 1508;
const int CMB_BRICK_SILVER4	= 1510;
const int CMB_BRICK_GOLD	= 1516;


//layer 2
const int CMB_BRICK_RED_LOW 	= 1489;
const int CMB_BRICK_WHITE_LOW	= 1491;
const int CMB_BRICK_BLUE_LOW 	= 1493;
const int CMB_BRICK_ORANGE_LOW	= 1495;
const int CMB_BRICK_TEAL_LOW	= 1497;
const int CMB_BRICK_VIOLET_LOW	= 1499;
const int CMB_BRICK_GREEN_LOW	= 1501;
const int CMB_BRICK_YELLOW_LOW	= 1503;
const int CMB_BRICK_SILVER1_LOW	= 1505;
const int CMB_BRICK_SILVER2_LOW	= 1507;
const int CMB_BRICK_SILVER3_LOW	= 1509;
const int CMB_BRICK_SILVER4_LOW	= 1511;
const int CMB_BRICK_GOLD_LOW	= 1517;

//enemies
const int NPC_BRICK_RED 	= 181;
const int NPC_BRICK_WHITE 	= 182;
const int NPC_BRICK_BLUE 	= 183;
const int NPC_BRICK_ORANGE	= 184;
const int NPC_BRICK_TEAL 	= 185;
const int NPC_BRICK_VIOLET 	= 186;
const int NPC_BRICK_GREEN 	= 187;
const int NPC_BRICK_YELLOW 	= 188;
const int NPC_BRICK_SILVER1 	= 189;
const int NPC_BRICK_SILVER2 	= 190;
const int NPC_BRICK_SILVER3  	= 255; //not set up yet;
const int NPC_BRICK_SILVER4 	= 255; //not set up yet
const int NPC_BRICK_GOLD 	= 191;


const int HIT_BY_LWEAPON = 2;

ffc script brick
{
	void run()
	{
	}
	bool hit(npc a, lweapon v)
	{
		Link->Misc[0] = v; //We'll use this as scratch untyped space for the moment. -Z
		
		int temp_UID = v->UID * 10000; //this is a bug in HITBY[]. The HitBy value being stored is being multiplied by 10000, and it should not be.
			//as UID is not, and NEVER should be!!!
		//TraceNL(); TraceS("v->UID is: "); Trace(v->UID);
		/*
		To determine where a brick was hit, we first scan each brick and look to see which was
		hit at all, by our lweapon.
		
		The, we check if that ball is belove, above, right of, or left of the brick,
		and we read its direction.
		
		Using a logic chain from this data, we determine the direction that the ball should next 
		take, when it bounces.
		
		*/
		//HitBy[]
		
		//if ( a->HitBy[HIT_BY_LWEAPON] ) 
		//{ 
		//	TraceNL(); TraceS("a->HitBy[HIT_BY_LWEAPON] id: "); Trace(a->HitBy[HIT_BY_LWEAPON]); 
		//	TraceNL();
		//	TraceS("Our Link->Misc scratch value is: "); Trace((Link->Misc[0]+1));
		//}
		
		//! We'll use this method again when we add UIDs to HitBy[] ! -Z
		//return ( a->HitBy[HIT_BY_LWEAPON] == temp_UID ); 
		return ( a->HitBy[HIT_BY_LWEAPON] == (Link->Misc[0]+1) ); 
	}
	bool hit_below(npc a, lweapon v)
	{
		if ( v->Y == (a->Y + 8) ) return true; //we could do bounce here. 
	}
	bool hit_above(npc a, lweapon v)
	{
		if ( v->Y == (a->Y - 4) ) return true; //we could do bounce here. 
	}
	bool hit_left(npc a, lweapon v)
	{
		if ( v->X == (a->X - 4) ) return true; //we could do bounce here. 
	}
	bool hit_right(npc a, lweapon v)
	{
		if ( v->X == (a->X + 16 ) ) return true; //we could do bounce here. 
	}
	
	void take_hit(npc a, lweapon v)
	{
		if ( hit(a,v) )
		{
			//TraceNL(); TraceS("Brick hit!"); 
			v->DeadState = WDS_ALIVE; 
			//TraceNL(); TraceS("brick->X = "); Trace(a->X);
			//TraceNL(); TraceS("brick->Y = "); Trace(a->Y);
			//TraceNL(); TraceS("ball->X = "); Trace(v->X);
			//TraceNL(); TraceS("ball->Y = "); Trace(v->Y);
			if ( hit_below(a,v) )
			{
				switch ( v->Dir ) 
				{
					case DIR_UPRIGHT: { v->Dir = DIR_DOWNRIGHT; break; }
					case DIR_UPLEFT: { v->Dir = DIR_DOWNLEFT; break; }
					default: { TraceS("hit_below() found an illegal ball direction"); break; }
				}
				if ( a->HP <= 0 ) 
				{ 
					//TraceS("Brick is dead. "); TraceNL();
					//TraceS("a->Misc[NPCM_AWARDED_POINTS] is: "); Trace(a->Misc[NPCM_AWARDED_POINTS]); TraceNL();
					if ( !a->Misc[NPCM_AWARDED_POINTS] )
					{
						//TraceS("Can award points!"); TraceNL();
						a->Misc[18] = 1;
						//TraceS("The points for this brick are: "); Trace(a->Attributes[NPC_ATTRIB_POINTS]); TraceNL();
						Game->Counter[CR_SCRIPT1] += a->Attributes[NPC_ATTRIB_POINTS];
					}
				}
			}
			
			else if ( hit_above(a,v) )
			{
				switch ( v->Dir ) 
				{
					case DIR_DOWNLEFT: { v->Dir = DIR_UPLEFT; break; }
					case DIR_DOWNRIGHT: { v->Dir = DIR_UPRIGHT; break; }
					default: { TraceS("hit_above() found an illegal ball direction"); break; }
				}
				if ( a->HP <= 0 ) 
				{ 
					if ( !a->Misc[NPCM_AWARDED_POINTS] )
					{
						a->Misc[NPCM_AWARDED_POINTS] = 1;
						Game->Counter[CR_SCRIPT1] += a->Attributes[NPC_ATTRIB_POINTS];
					}
				}
			}
			
			else if ( hit_left(a,v) )
			{
				switch ( v->Dir ) 
				{
					case DIR_UPRIGHT: { v->Dir = DIR_UPLEFT; break; }
					case DIR_DOWNRIGHT: { v->Dir = DIR_DOWNLEFT; break; }
					default: { TraceS("hit_left() found an illegal ball direction"); break; }
				}
				if ( a->HP <= 0 ) 
				{ 
					if ( !a->Misc[NPCM_AWARDED_POINTS] )
					{
						a->Misc[NPCM_AWARDED_POINTS] = 1;
						Game->Counter[CR_SCRIPT1] += a->Attributes[NPC_ATTRIB_POINTS];
					}
				}
			}
			else if ( hit_right(a,v) )
			{
				switch ( v->Dir ) 
				{
					case DIR_UPLEFT: { v->Dir = DIR_UPRIGHT; break; }
					case DIR_DOWNLEFT: { v->Dir = DIR_DOWNRIGHT; break; }
					default: { TraceS("hit_below() found an illegal ball direction"); break; }
				}
				if ( a->HP <= 0 ) 
				{ 
					if ( !a->Misc[NPCM_AWARDED_POINTS] )
					{
						a->Misc[NPCM_AWARDED_POINTS] = 1;
						Game->Counter[CR_SCRIPT1] += a->Attributes[NPC_ATTRIB_POINTS];
					}
				}
			}
			
			else
			{
				TraceS("brick.hit() returned true, but couldn't determine a valid ball location!");
				return;
			}
		}
					
			
	}
	//turns layer objects into npc bricks. 
	void setup()
	{
		int tempenem; npc bricks[1024]; int temp;
		for ( int q = 0; q < 176; ++q )
		{
			//bricks on layer 1
			//Trace(GetLayerComboD(1,q));
			//while(!Input->Press[CB_A]) Waitframe();
			tempenem = brick_to_npc(GetLayerComboD(1,q),false);
			//TraceS("tempenem is: "); Trace(tempenem);
			//while(!Input->Press[CB_A]) Waitframe();
			if ( tempenem ) 
			{
				bricks[temp] = Screen->CreateNPC(tempenem); 
				//TraceS("Created npc: "); Trace(tempenem);
				bricks[temp]->X = ComboX(q); 
				bricks[temp]->Y = ComboY(q);
				TraceS("Brick defence is: "); Trace(bricks[temp]->Defense[20]);
				tempenem = 0; ++temp;
				
			}
			//bricks on layer 2, Y+8px
			tempenem = brick_to_npc(GetLayerComboD(2,q),true);
			//Trace(tempenem);
			if ( tempenem ) 
			{
				bricks[temp] = Screen->CreateNPC(tempenem); 
				//TraceS("Created npc: "); Trace(tempenem);
				bricks[temp]->X = ComboX(q); 
				bricks[temp]->Y = ComboY(q)+8;
				TraceS("Brick defence is: "); Trace(bricks[temp]->Defense[20]);
				tempenem = 0; ++temp;
			}
		}
		
	}
	void clear_combos()
	{
		templayer[0] = Screen->LayerOpacity[0];
		templayer[1] = Screen->LayerOpacity[1];
		templayer[2] = Screen->LayerMap[0];
		templayer[3] = Screen->LayerMap[1];
		Screen->LayerOpacity[0] = 0;
		Screen->LayerOpacity[1] = 0;
		Screen->LayerMap[0] = 0;
		Screen->LayerMap[1] = 0;
	}
	
	int brick_to_npc(int combo_id, bool layer2)
	{
		
		if ( !layer2 ) 
		{
			int brick_to_enemy[BRICK_MAX*2] =
			{ 	CMB_BRICK_RED, CMB_BRICK_WHITE, CMB_BRICK_BLUE, CMB_BRICK_ORANGE, CMB_BRICK_TEAL, 
				CMB_BRICK_VIOLET, CMB_BRICK_GREEN, CMB_BRICK_YELLOW, CMB_BRICK_SILVER1, CMB_BRICK_SILVER2,
				CMB_BRICK_SILVER3, CMB_BRICK_SILVER4, CMB_BRICK_GOLD, 

				NPC_BRICK_RED, NPC_BRICK_WHITE, NPC_BRICK_BLUE, NPC_BRICK_ORANGE, NPC_BRICK_TEAL,
				NPC_BRICK_VIOLET, NPC_BRICK_GREEN, NPC_BRICK_YELLOW, NPC_BRICK_SILVER1, NPC_BRICK_SILVER2,
				NPC_BRICK_SILVER3, NPC_BRICK_SILVER4, NPC_BRICK_GOLD 
			};
			for ( int q = 0; q < BRICK_MAX; ++q ) 
			{ 
				if ( brick_to_enemy[q] == combo_id ) 
				{
					//	TraceS("brick_to_npc : combo input: "); Trace(combo_id);
					//TraceS("brick_to_npc : enemy output: "); Trace(brick_to_enemy[BRICK_MAX+q]);
					
					return ( brick_to_enemy[BRICK_MAX+q-1] );
				}
			}
		}
		else
		{
			int brick_to_enemy2[BRICK_MAX*2] =
			{ 	CMB_BRICK_RED_LOW, CMB_BRICK_WHITE_LOW, CMB_BRICK_BLUE_LOW, CMB_BRICK_ORANGE_LOW, CMB_BRICK_TEAL_LOW, 
				CMB_BRICK_VIOLET_LOW, CMB_BRICK_GREEN_LOW, CMB_BRICK_YELLOW_LOW, CMB_BRICK_SILVER1_LOW, CMB_BRICK_SILVER2_LOW,
				CMB_BRICK_SILVER3_LOW, CMB_BRICK_SILVER4_LOW, CMB_BRICK_GOLD_LOW, 

				NPC_BRICK_RED, NPC_BRICK_WHITE, NPC_BRICK_BLUE, NPC_BRICK_ORANGE, NPC_BRICK_TEAL,
				NPC_BRICK_VIOLET, NPC_BRICK_GREEN, NPC_BRICK_YELLOW, NPC_BRICK_SILVER1, NPC_BRICK_SILVER2,
				NPC_BRICK_SILVER3, NPC_BRICK_SILVER4, NPC_BRICK_GOLD 
			};
			for ( int q = 0; q < BRICK_MAX; ++q ) 
			{ 
				if ( brick_to_enemy2[q] == combo_id ) 
				{
					//TraceS("brick_to_npc : combo input: "); Trace(combo_id);
					//TraceS("brick_to_npc : enemy output: "); Trace(brick_to_enemy2[BRICK_MAX+q-1]);
					return ( brick_to_enemy2[BRICK_MAX+q-1] );
				}
			}
		}
		return 0; //error
	}
}

global script onExit
{
	void run()
	{
		Screen->LayerOpacity[0] = templayer[0];
		Screen->LayerOpacity[1] = templayer[1];
		Screen->LayerMap[0] = templayer[2];
		Screen->LayerMap[1] = templayer[3];
		newstage = true;
		//vaus->Misc[MISC_DEAD] = 0;

	}
}	

global script init
{
	void run()
	{
		Link->CollDetection = false;
		Link->DrawYOffset = -32768;
	}
}

global script Init
{
	void run()
	{
		Link->CollDetection = false;
		Link->DrawYOffset = -32768;
	}
}

global script onContinue
{
	void run()
	{
		Link->Invisible = true; 
		Link->CollDetection = false;
		Link->DrawYOffset = -32768;
	}
}