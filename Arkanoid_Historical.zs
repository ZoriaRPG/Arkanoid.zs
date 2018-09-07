import "std.zh"


//Arkanoid script
//v0.16
//17th August, 2018

//////////////////////
/// Script issues: ///
//////////////////////

// We need to either re-arrange the living/dead/death logic, or add another animation phase. 
// May as well set up the Vaus explosion and add it with a SPARKLE LWeapon.



//# QUEST ISSUE: Bricks Break playing the wrong sound, despite being set. Might be a 2.54 bug? -Z

/* ZC issues: 
	Continue script does not run when Init script runs. It NEEDS to do that! Otherwise, settings that affect things such as Link's tile
	don't happen before the opening wipe. 
	
*/

/// Changes, Revision History
///
///
/// Alpha 0.16: Reverted Alpha 0.15 changes back to before adding any angular physics.
///		Then, re-implemented ONLY the Vaus midpoint physics.
///		Fixed the hack for UID in brick.take_hit(). This means that ZC 2.54 Alpha **32** is now the minimum ZC version.

//Radians for special directions. 
const float DIR_UUL = 4.3197;
const float DIR_LUU = 4.3197;
const float DIR_LLU = 3.5343;
const float DIR_ULL = 3.5343;
const float DIR_LLD = 2.7489;
const float DIR_DLL = 2.7489;
const float DIR_DDL = 1.9635;
const float DIR_LDD = 1.9635;
const float DIR_DDR = 1.1781;
const float DIR_RDD = 1.1781;
const float DIR_RRD = 0.3927; 
const float DIR_DRR = 0.3927; 
const float DIR_RRU = 5.1051;
const float DIR_URR = 5.1051;
const float DIR_RUU = 5.1141;
const float DIR_UUR = 5.1141;



const int MIN_ZC_ALPHA_BUILD = 32; //Alphas are negatives, so we neex to check maximum, not minimum.


const float ARKANOID_VERSION = 0.16;

int GAME[256];
const int GAME_MISC_FLAGS = 0;
const int GMFS_PLAYED_GAME_OVER_MUSIC = 0x01;

const int FFC_VAUS = 1;
const int CMB_VAUS_EXTENDED = 1528;
const int CMB_VAUS = 1524;
const int CMB_VAUS_DEAD = 1520;

const int MID_STAGE_START = 4;
const int NPCM_AWARDED_POINTS = 3; //brick->Misc[], flag to mark if points were awarded to the player. 
const int NPC_ATTRIB_POINTS = 0; //brick->Attributes[], value for score. 

//Counters
const int CR_SCORE = 7; //script 1
const int CR_LIVES = 8; 

int quit;

const int QUIT_TITLE = -1;
const int QUIT_GAME_RUNNING = 0; //i.e., !quit
const int QUIT_GAMEOVER = 1;

const int MAX_BALL_SPEED = 300;

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

int death_anim[DEATH_ANIM_MAX]; 
const int DEATH_ANIM_TIMER = 0;
const int DEATH_ANIM_1 = 1; //1-7 Unused 
const int DEATH_ANIM_2 = 2;
const int DEATH_ANIM_3 = 3;
const int DEATH_ANIM_4 = 4;
const int DEATH_ANIM_5 = 5;
const int DEATH_ANIM_6 = 6;
const int DEATH_ANIM_COUNTDOWN_TO_QUIT = 7;

const int DEATH_ANIM_MAX = 8;

const int COUNTDOWN_TO_QUIT_FRAMES = 289; //36*8+1;

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

ffc script holdlink
{
	void run()
	{
		while(1)
		{
			Link->Y = START_PADDLE_Y - 4;
			Waitframe();
		}
	}
}
		

global script arkanoid
{
	
	void run()
	{
		check_min_zc_build();
		
		TraceNL(); TraceS("Starting Arkanoid"); TraceNL(); TraceS("Game 'quit' state: "); Trace(quit);
		TraceNL(); TraceS("Game version, Alpha "); Trace(ARKANOID_VERSION); 
		
		//frame = -1;
		ffc vaus = Screen->LoadFFC(FFC_VAUS);
		lweapon movingball;
		npc vaus_guard; 
		bool ext;
		Link->CollDetection = false;
		Link->DrawYOffset = -32768;
		
		ball.setup_sprite(SPR_BALL);
		while(true)
		{
			while(!quit)
			{
				++frame;
				if ( Input->Key[KEY_L] ) ++Game->Counter[CR_LIVES]; 
				hold_Link_y(); //Don't allow Link to leave the screen, bt
					//keep his X and Y matched to the Vaus!
				hold_Link_x(vaus); //Link is used to cause floating enemies to home in on the vaus. 
				if ( newstage ) 
				{
					//vaus_guard = Screen->CreateNPC(NPC_VAUSGUARD);
					Game->PlayMIDI(MID_STAGE_START);
					brick.setup();
					Waitframes(6);
					
					brick.clear_combos();
					
					newstage = false;
					paddle.setup(vaus);
					ball.create(vaus);
					movingball = vaus->Misc[MISC_BALLID];
					/*
					TraceS("Checking lwpn->Misc[16-32] for junk data: ");
					for ( int q = 16; q < 32; ++q )
					{
						TraceNL(); TraceS("index: "); Trace(q); TraceS(" value: "); Trace(movingball->Misc[q]);
					}
					
					TraceS("Setting valid data to lwpn->Misc[16-32] to validate data: ");
					for ( int q = 16; q < 32; ++q )
					{
						movingball->Misc[q] = q*2;
						TraceNL(); TraceS("index: "); Trace(q); TraceS(" value: "); Trace(movingball->Misc[q]);
					}
					//Huzzah, another 2.54 bug bites the dust as of 254a32!!
					*/
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
					//if ( Input->Key[KEY_P] ) Trace(movingball->UID); //Frick, I'm an idiot. HIT_BY_LWEAPON is the SCREEN INDEX< not the UID!!
						//2.54 Absolutely needs HitBy_UID!
					if ( Input->Key[KEY_1] ) Trace(frame);
					//if ( frame%60 == 0 ) { Trace(movingball->Step); }
					//Trace(movingball->Step);
					change_setting(); //check for a setting change_setting
					paddle.extend(vaus);
					paddle.check_input();
					paddle.move(USE_MOUSE, USE_ACCEL, vaus);
					
					ball.launch(movingball);
					if ( !ball.launched(movingball) )
					{
						ball.move_with_vaus(movingball, vaus);
					}
					
					
					//clamp within bounds - MANDATORY because very fast Step speeds can cause the ball
					//to *phase* through pseudo-solid objects, such as walls and the Vaus. 
					ball.clamp_rightwall(movingball);
					ball.clamp_ceiling(movingball);
					ball.clamp_leftwall(movingball);
					ball.clamp_bottom(movingball, vaus); 
					
					
					//ball wall bounce checks
					ball.check_ceiling(movingball);
					ball.check_leftwall(movingball);
					ball.check_rightwall(movingball);
					ball.check_hitvaus(movingball, vaus);
					//ball.set_speed(movingball);
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
					paddle.dead(vaus); //Set the death animation here. 
					
					/*
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
					if ( Game->Counter[CR_LIVES] ) 
					{
						--Game->Counter[CR_LIVES];
						revive_vaus = true; 
					}
					*/
					
				}
				
				
				Waitdraw();
				
				hold_Link_y();
				
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
						//TraceNL(); TraceS("movingball ptr: "); Trace(movingball); 
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
					if ( Game->Counter[CR_LIVES] ) 
					{
						--Game->Counter[CR_LIVES];
						revive_vaus = true; 
					}
					else //Ugh, this is a mess. I might want to rewrite the gane over portion, as it feels as if it'll be a biugger kludge than just calling break.
					{
						if ( !death_anim[DEATH_ANIM_COUNTDOWN_TO_QUIT] ) 
						{
							death_anim[DEATH_ANIM_COUNTDOWN_TO_QUIT] = COUNTDOWN_TO_QUIT_FRAMES;
							continue;
						}
						else
						{
							--death_anim[DEATH_ANIM_COUNTDOWN_TO_QUIT];
							if ( death_anim[DEATH_ANIM_COUNTDOWN_TO_QUIT] == 1 ) 
							{
								quit = QUIT_GAMEOVER; //Game over state. 
								TraceNL(); TraceS("Game 'quit' state is now: "); Trace(quit);
							}
						}
					}
						
				}
				
				Waitframe();
			}
			
			while (quit == QUIT_GAMEOVER) //Game Over
			{
				if ( !(GAME[GAME_MISC_FLAGS]&GMFS_PLAYED_GAME_OVER_MUSIC) )
				{
					GAME[GAME_MISC_FLAGS]|=GMFS_PLAYED_GAME_OVER_MUSIC;
					//Play Game over MIDI
					Game->PlayMIDI(1);
				}
					
				Screen->DrawString(6, 96, 80, 1, 0x51, 0x00, 0, "GAME OVER", 128);
				
				Waitdraw(); 
				Waitframe();
			}
			//We should never reach here. 
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
	void hold_Link_x(ffc v)
	{
		Link->X = v->X+(v->TileWidth*8);
	}
	void hold_Link_y()
	{
		Link->Y = START_PADDLE_Y - 4;
	}
	bool quit() { return ( quit ); }
	
	void check_min_zc_build()
	{
		if ( Game->Beta < MIN_ZC_ALPHA_BUILD )
		{
			Game->PlayMIDI(9);
			int v_too_early = 600; int req_vers[3]; itoa(req_vers, MIN_ZC_ALPHA_BUILD);
			TraceNL(); int vers[3]; itoa(vers,Game->Beta);
			TraceS("This version of Arkanoid.qst requires Zelda Classic v2.54, Alpha (");
			TraceS(req_vers);
			TraceS("), or later.");
			TraceNL();
			TraceS("I'm detecting Zelda Classic v2.54, Alpha (");
			TraceS(vers);
			TraceS(") and therefore, I must refuse to run. :) ");
			TraceNL();
			
			while(v_too_early--)
			{
				//Screen->DrawString(7, 4, 40, 1, 0x04, 0x5F, 0, 
				//"This version of Arkanoid.qst requires Zelda Classic 2.54, Alpha 32", 
				//128);
				Screen->DrawString(7, 15, 40, 1, 0x04, 0x5F, 0, 
				"You are not using a version of ZC adequate to run         ", 
				128);
				
				Screen->DrawString(7, 15, 55, 1, 0x04, 0x5F, 0, 
				"this quest. Please see allegro.log for details.                   ", 
				128);
			
				Waitdraw();
				WaitNoAction();
			}
			Game->End();
			
		}
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
	void set_speed(lweapon b, int speed)
	{
		//Trace(bounces);
		b->Step = speed; // bound(bounces,0,MAX_BOUNCES);
		//Trace(b->Step);
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
	float bound(int val, int min, int max)
	{
		if ( val < min ) return min;
		if ( val > max ) return max;
		return val;
	}
	//Not launched yet.
	void move_with_vaus(lweapon b, ffc v)
	{
		b->X = v->X+18;
	}
	//ball.clamp*() are needed for when the step speed is so great that the ball skips past the equality checks.
	void clamp_ceiling(lweapon b)
	{
		if ( b->Y < BALL_MIN_Y )			
		{
			b->Y = BALL_MIN_Y;
		}
	}
	void clamp_leftwall(lweapon b)
	{
		if ( caught ) return; //don't do anything while the vaus is holding the ball
		if ( b->X < BALL_MIN_X ) b ->X = BALL_MIN_X;
	}
	void clamp_rightwall(lweapon b)
	{
		if ( caught ) return; //don't do anything while the vaus is holding the ball
		if ( b->X > BALL_MAX_X ) b->X = BALL_MAX_X;
	}
	/*
	void clamp_bottom(lweapon b, ffc v)
	{
		if ( caught ) return; //don't do anything while the vaus is holding the ball
		if ( b->Y+4 > v->Y+8 ) dead(b,v);
	}
	*/
	//A function to check of the bounding will prevent the ball from falling out of field.
	void clamp_bottom(lweapon b, ffc v)
	{
		if ( caught ) return; //don't do anything while the vaus is holding the ball
		if ( b->Y+4 > v->Y ) b->Y = v->Y-4;
	}
	void check_ceiling(lweapon b)
	{
		if ( b->Y == BALL_MIN_Y )			
		{
			Game->PlaySound(7);
			if ( b->Angular )
			{
				switch(b->Angle)
				{
					case DIR_LLU:
					{
						b->Angular = false;
						b->Dir = DIR_LEFTDOWN;
						b->Step = bound(b->Step+1, 0, MAX_BALL_SPEED); 
						break;
					}
					case DIR_LUU:
					{
						b->Angular = false;
						b->Dir = DIR_LEFTDOWN;
						b->Step = bound(b->Step+1, 0, MAX_BALL_SPEED); 
						break;
					}
					case DIR_RRU:
					{
						b->Angular = false;
						b->Dir = DIR_RIGHTDOWN;
						b->Step = bound(b->Step+1, 0, MAX_BALL_SPEED); 
						break;
					}
					case DIR_RUU:
					{
						b->Angular = false;
						b->Dir = DIR_RIGHTDOWN;
						b->Step = bound(b->Step+1, 0, MAX_BALL_SPEED); 
						break;
					}
					
				}
			}
			else
			{
				switch(b->Dir)
				{
					case DIR_RIGHTUP: { b->Dir = DIR_RIGHTDOWN; b->Step = bound(b->Step+1, 0, MAX_BALL_SPEED); break; }
					case DIR_LEFTUP: { b->Dir = DIR_LEFTDOWN; b->Step = bound(b->Step+1, 0, MAX_BALL_SPEED); break; }
					default: { 
						TraceNL(); TraceS("Ball direction invalid for ball.check_ceiling()."); 
							TraceNL(); TraceS("Ball Dir is: "); Trace(b->Dir); TraceNL();
						b->Dir = DIR_DOWN; b->Step = bound(b->Step+1, 0, MAX_BALL_SPEED); break; }
				}
			}
		}
	}
	void check_leftwall(lweapon b)
	{
		if ( caught ) return; //don't do anything while the vaus is holding the ball
		if ( b->X == BALL_MIN_X ) 
		{
			Game->PlaySound(7);
			if ( b->Angular )
			{
				switch(b->Angle)
				{
					case DIR_LLU:
					{
						b->Angular = false;
						b->Dir = DIR_RIGHTUP;
						b->Step = bound(b->Step+1, 0, MAX_BALL_SPEED); 
						break;
					}
					case DIR_LUU:
					{
						b->Angular = false;
						b->Dir = DIR_RIGHTUP;
						b->Step = bound(b->Step+1, 0, MAX_BALL_SPEED); 
						break;
					}
					case DIR_LLD:
					{
						b->Angular = false;
						b->Dir = DIR_RIGHTDOWN;
						b->Step = bound(b->Step+1, 0, MAX_BALL_SPEED); 
						break;
					}
					case DIR_LDD:
					{
						b->Angular = false;
						b->Dir = DIR_RIGHTDOWN;
						b->Step = bound(b->Step+1, 0, MAX_BALL_SPEED); 
						break;
					}
					
				}
			}
			else
			{
				switch(b->Dir)
				{
					case DIR_LEFTDOWN: { b->Dir = DIR_RIGHTDOWN; b->Step = bound(b->Step+1, 0, MAX_BALL_SPEED); break; }
					case DIR_LEFTUP: { b->Dir = DIR_RIGHTUP; b->Step = bound(b->Step+1, 0, MAX_BALL_SPEED); break; }
					default: { 
						TraceNL(); TraceS("Ball direction invalid for ball.check_leftwall()."); 
							TraceNL(); TraceS("Ball Dir is: "); Trace(b->Dir); TraceNL();
						b->Dir = DIR_DOWN; b->Step = bound(b->Step+1, 0, MAX_BALL_SPEED); break; }
				}
			}
		}
	}
	void check_rightwall(lweapon b)
	{
		if ( caught ) return; //don't do anything while the vaus is holding the ball
		if ( b->X == BALL_MAX_X ) 
		{
			Game->PlaySound(7);
			if ( b->Angular )
			{
				switch(b->Angle)
				{
					case DIR_RRD:
					{
						b->Angular = false;
						b->Dir = DIR_LEFTDOWN;
						b->Step = bound(b->Step+1, 0, MAX_BALL_SPEED); 
						break;
					}
					case DIR_RDD:
					{
						b->Angular = false;
						b->Dir = DIR_LEFTDOWN;
						b->Step = bound(b->Step+1, 0, MAX_BALL_SPEED); 
						break;
					}
					case DIR_RRU:
					{
						b->Angular = false;
						b->Dir = DIR_RIGHTUP;
						b->Step = bound(b->Step+1, 0, MAX_BALL_SPEED); 
						break;
					}
					case DIR_RUU:
					{
						b->Angular = false;
						b->Dir = DIR_RIGHTUP;
						b->Step = bound(b->Step+1, 0, MAX_BALL_SPEED); 
						break;
					}
					
				}
			}
			else
			{
				switch(b->Dir)
				{
					case DIR_RIGHTDOWN: { b->Dir = DIR_LEFTDOWN; b->Step = bound(b->Step+1, 0, MAX_BALL_SPEED); break; }
					case DIR_RIGHTUP: { b->Dir = DIR_LEFTUP; b->Step = bound(b->Step+1, 0, MAX_BALL_SPEED); break; }
					default: { 
						TraceNL(); TraceS("Ball direction invalid for ball.check_rightwall()."); 
							TraceNL(); TraceS("Ball Dir is: "); Trace(b->Dir); TraceNL();
						b->Dir = DIR_DOWN; b->Step = bound(b->Step+1, 0, MAX_BALL_SPEED); break; }
				}
			}
		}
	}
	void check_hitvaus(lweapon b, ffc v)
	{
		if ( launched(b) )
		{
			
			if ( b->Angular )
			{
				if ( b->Angle == DIR_UUR ){ return; }
				if ( b->Angle == DIR_UUL ) { return; }
				if ( b->Angle == DIR_ULL ) { return; }
				if ( b->Angle == DIR_URR ) { return; }
			}
			else
			{
				if ( b->Dir == DIR_RIGHTUP ) { return; }
				if ( b->Dir == DIR_LEFTUP ) { return; }
			}
			//if ( Collision(b,v) ) //We'll refine this, later. 
			
			//else
			//{
				int hit_position; int vaus_midpoint =  v->X+(((v->TileWidth*16)/2)-1);
				int midpoint_segment = v->X+(((v->TileWidth*16)/6));
				int ball_midpoint = b->X+3;
				
				if ( b->Y+4 == v->Y )
					//Now we need to check here, if the paddle is under the ball:
				{
					if ( b->X >= v->X-3 ) //-3, because the ball is 4px wide, so we cover the last pixel of the ball against the furst pixel of the Vaus
					{
						if ( b->X <= v->X+((v->TileWidth*16)+4) ) //no +3 here, because it's the actual X, so the first pixel of the ball is covered by the last pixel of the vaus.
						{
							Game->PlaySound(6);
							//b->Y = v->Y-1;
							
							if ( ball_midpoint <= vaus_midpoint ) //hit left side of vaus
							{
								//more left than up, hit end of Vaus
								if ( b->X <= (v->X-1) )
								//if ( Abs(ball_midpoint-vaus_midpoint) <= 2 )
								{
									//angular up
									TraceNL(); TraceS("Setting ball dir to ANGULAR Left-left-Up");
									
									b->Angular = true;
									b->Angle = DIR_LLU;
									TraceNL(); TraceS("Checking if set angle evals true when compared against: "); TraceB(b->Angle == DIR_LUU);
									return;
								}
								
								//more up than left, hit close to centre
								//else if ( (Abs(b->X+2)-vaus_midpoint) <= 3 )
								//if ( Abs(ball_midpoint-vaus_midpoint) <= 2 )
								if ( (Abs(vaus_midpoint - b->X+2)) <= 3 )
								{
									//angular up
									TraceNL(); TraceS("Setting ball dir to ANGULAR Left-Up-Up");
									
									b->Angular = true;
									b->Angle = DIR_LUU;
									b->Step = bound(b->Step+1, 0, MAX_BALL_SPEED);
									TraceNL(); TraceS("Checking if set angle evals true when compared against: "); TraceB(b->Angle == DIR_LUU);
									return;
								}
								//hit between the zones, normal left-up
								else
								{
								
									//hit the centre midpoint
									//set angular = false
									//set DIR_UL
									TraceNL(); TraceS("Setting ball dir to DIGITAL Left-Up");
									//b->Y = v->Y-1;
									b->Angular = false;
									b->Dir = DIR_UPLEFT;
									b->Step = bound(b->Step+1, 0, MAX_BALL_SPEED);
									return;
								}
								
							}
							else if ( ball_midpoint > vaus_midpoint ) //hit right side of vaus
							{
								/*
								if ( Abs(ball_midpoint-vaus_midpoint) <= 2 )
								{
									//angular up
									TraceNL(); TraceS("Setting ball dir to ANGULAR RIGHT-Up-Up");
									--b->Y;
									b->Angular = true;
									b->Angle = DIR_RUU;
									TraceNL(); TraceS("Checking if set angle evals true when compared against: "); TraceB(b->Angle == DIR_RUU);
						
								}
								if ( b->X >= (v->X+(v->TileWidth*16)-2) )
								{
									//angular, sideways
									TraceNL(); TraceS("Setting ball dir to ANGULAR right-right-Up");
									--b->Y;
									b->Angular = true;
									b->Angle = DIR_RRU;
									TraceNL(); TraceS("Checking if set angle evals true when compared against: "); TraceB(b->Angle == DIR_RRU);
						
								}
								*/
								//more up then right, hit vaus close to centre
								if ( (Abs(vaus_midpoint - b->X)) <= 3 )
								{
									//angular up
									TraceNL(); TraceS("Setting ball dir to ANGULAR RIGHT-Up-Up");
									
									b->Angular = true;
									b->Angle = DIR_RUU;
									b->Step = bound(b->Step+1, 0, MAX_BALL_SPEED);
									TraceNL(); TraceS("Checking if set angle evals true when compared against: "); TraceB(b->Angle == DIR_RUU);
									return;
								}
								//more right than up, hit end of vaus
								else if ( b->X > ( vaus_midpoint + ((v->TileWidth*16)/2)-4) )
								//else if ( (Abs(vaus_midpoint - b->X)) >= v->X+((v->TileWidth*16)/2)-1 )
								{
									//angular up
									TraceNL(); TraceS("Setting ball dir to ANGULAR RIGHT-right-Up");
									
									b->Angular = true;
									b->Angle = DIR_RRU;
									b->Step = bound(b->Step+1, 0, MAX_BALL_SPEED);
									TraceNL(); TraceS("Checking if set angle evals true when compared against: "); TraceB(b->Angle == DIR_RUU);
									return;
								}
								else
								{
									//hit the centre midpoint
									//set angular = false
									//set DIR_UR
									TraceNL(); TraceS("Setting ball dir to DIGITAL Right-Up");
									//b->Y = v->Y-6;
									b->Angular = false;
									b->Dir = DIR_UPRIGHT;
									//b->Dir = DIR_UPRIGHT;
									b->Step = bound(b->Step+1, 0, MAX_BALL_SPEED);
									return;
								}
								
							}
								
							else //catchall
							{
								switch(b->Dir)
								{
									case DIR_LEFTDOWN: { b->Dir = DIR_LEFTUP; b->Step = bound(b->Step+1, 0, MAX_BALL_SPEED); break; }
									case DIR_RIGHTDOWN: { b->Dir = DIR_RIGHTUP; b->Step = bound(b->Step+1, 0, MAX_BALL_SPEED); break; }
									default: { b->Dir = DIR_DOWN; b->Step = bound(b->Step+1, 0, MAX_BALL_SPEED); break; }
								}
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
			//}
			
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
const int HIT_BY_LWEAPON_UID = 6; 

ffc script brick
{
	void run()
	{
	}
	float bound(int val, int min, int max)
	{
		if ( val < min ) return min;
		if ( val > max ) return max;
		return val;
	}
	bool hit(npc a, lweapon v)
	{
		/*
		if ( a->HitBy[HIT_BY_LWEAPON] < 1 ) return false; 
		a->Misc[12] = Screen->LoadLWeapon(a->HitBy[HIT_BY_LWEAPON]);
		lweapon hitwpn = a->Misc[12];
		return ( hitwpn->UID == v->UID );
		*/
		return ( a->HitBy[HIT_BY_LWEAPON_UID] == v->UID );
		//int indx; //Until we have UIDs working for HitBy[], we need to do it this way. 
		//for ( int q = Screen->NumLWeapons(); q > 0; --q ) 
		//{
		//	lweapon temp = Screen->LoadLWeapon(q);
		//	if ( temp->UID == v->UID ) 
		//	{ 
		//		indx = q; break;
		//	}
		//}
		//Link->Misc[0] = v; //We'll use this as scratch untyped space for the moment. -Z
		//TraceS("brick.hit() Link->Misc[] is: "); Trace(Link->Misc[0]);
		//TraceS("brick.hit() v is: "); Trace(v);
		//int temp_UID = v->UID * 10000; //this is a bug in HITBY[]. The HitBy value being stored is being multiplied by 10000, and it should not be.
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
		//	TraceS("Our Link->Misc scratch value `is: "); Trace((Link->Misc[0]+1));
		//}
		
		//! We'll use this method again when we add UIDs to HitBy[] ! -Z
		//return ( a->HitBy[HIT_BY_LWEAPON] == temp_UID ); 
		//return ( a->HitBy[HIT_BY_LWEAPON] == indx ); //(Link->Misc[0]+1) ); 
		
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
	
	void take_hit(npc a, lweapon b)
	{
		if ( hit(a,b) )
		{
			//TraceNL(); TraceS("Brick hit!"); 
			b->DeadState = WDS_ALIVE; 
			//TraceNL(); TraceS("brick->X = "); Trace(a->X);
			//TraceNL(); TraceS("brick->Y = "); Trace(a->Y);
			//TraceNL(); TraceS("ball->X = "); Trace(v->X);
			//TraceNL(); TraceS("ball->Y = "); Trace(v->Y);
			if ( hit_below(a,b) )
			{
				//check the corners:
				if ( hit_left(a,b) )
					//lower-left corner
				{
					
					if ( b->Angular )
					{
						switch(b->Angle)
						{
							case DIR_RRU:
							{
								b->Angular = false;
								b->Dir = DIR_RIGHTDOWN;
								b->Step = bound(b->Step+1, 0, MAX_BALL_SPEED); 
								break;
							}
							case DIR_RRD:
							{
								b->Angular = false;
								b->Dir = DIR_RIGHTUP;
								b->Step = bound(b->Step+1, 0, MAX_BALL_SPEED); 
								break;
							}
							case DIR_RUU:
							{
								b->Angular = false;
								b->Dir = DIR_RIGHTDOWN;
								b->Step = bound(b->Step+1, 0, MAX_BALL_SPEED); 
								break;
							}
							case DIR_RDD:
							{
								b->Angular = false;
								b->Dir = DIR_RIGHTUP;
								b->Step = bound(b->Step+1, 0, MAX_BALL_SPEED); 
								break;
							}
							case DIR_LLU:
							{
								b->Angular = false;
								b->Dir = DIR_RIGHTDOWN;
								b->Step = bound(b->Step+1, 0, MAX_BALL_SPEED); 
								break;
							}
							case DIR_LUU:
							{
								b->Angular = false;
								b->Dir = DIR_RIGHTDOWN;
								b->Step = bound(b->Step+1, 0, MAX_BALL_SPEED); 
								break;
							}
							case DIR_LLD:
							{
								b->Angular = false;
								b->Dir = DIR_RIGHTUP;
								b->Step = bound(b->Step+1, 0, MAX_BALL_SPEED); 
								break;
							}
							case DIR_LDD:
							{
								b->Angular = false;
								b->Dir = DIR_RIGHTUP;
								b->Step = bound(b->Step+1, 0, MAX_BALL_SPEED); 
								break;
							}
							
						}
						else
						{
							switch(b->Dir)
							{
								case DIR_RIGHTUP:
								{
									b->Angular = false;
									b->Dir = DIR_LEFTDOWN;
									b->Step = bound(b->Step+1, 0, MAX_BALL_SPEED); 
									break;
								}	
									
								case DIR_RIGHTDOWN:
								{
									b->Angular = false;
									b->Dir = DIR_LEFTUP;
									b->Step = bound(b->Step+1, 0, MAX_BALL_SPEED); 
									break;
								}	
								
							}
						}
					}
					
				}//end lower-left corner
				
				if ( hit_right(a,b) )
					//lower-right corner
				{
					
					if ( b->Angular )
					{
						switch(b->Angle)
						{
							case DIR_LLU:
							{
								b->Angular = false;
								b->Dir = DIR_RIGHTDOWN;
								b->Step = bound(b->Step+1, 0, MAX_BALL_SPEED); 
								break;
							}
							case DIR_LLD:
							{
								b->Angular = false;
								b->Dir = DIR_RIGHTDOWN;
								b->Step = bound(b->Step+1, 0, MAX_BALL_SPEED); 
								break;
							}
							case DIR_RUU:
							{
								b->Angular = false;
								b->Dir = DIR_RIGHTDOWN;
								b->Step = bound(b->Step+1, 0, MAX_BALL_SPEED); 
								break;
							}
							case DIR_RDD:
							{
								b->Angular = false;
								b->Dir = DIR_LEFTUP;
								b->Step = bound(b->Step+1, 0, MAX_BALL_SPEED); 
								break;
							}
							case DIR_LLU:
							{
								b->Angular = false;
								b->Dir = DIR_RIGHTDOWN;
								b->Step = bound(b->Step+1, 0, MAX_BALL_SPEED); 
								break;
							}
							case DIR_LUU:
							{
								b->Angular = false;
								b->Dir = DIR_RIGHTDOWN;
								b->Step = bound(b->Step+1, 0, MAX_BALL_SPEED); 
								break;
							}
							case DIR_LLD:
							{
								b->Angular = false;
								b->Dir = DIR_LEFTUP;
								b->Step = bound(b->Step+1, 0, MAX_BALL_SPEED); 
								break;
							}
							case DIR_LDD:
							{
								b->Angular = false;
								b->Dir = DIR_LEFTUP;
								b->Step = bound(b->Step+1, 0, MAX_BALL_SPEED); 
								break;
							}
							
						}
						else
						{
							switch(b->Dir)
							{
								case DIR_LEFTUP:
								{
									b->Angular = false;
									b->Dir = DIR_RIGHTDOWN;
									b->Step = bound(b->Step+1, 0, MAX_BALL_SPEED); 
									break;
								}	
									
								case DIR_LEFTDOWN:
								{
									b->Angular = false;
									b->Dir = DIR_RIGHTUP;
									b->Step = bound(b->Step+1, 0, MAX_BALL_SPEED); 
									break;
								}	
								
							}
						}
					}
					
				}//end lower-right corner
				
				
				else
				{
				
					if ( b->Angular )
					{
						switch(b->Angle)
						{
							case DIR_LLU:
							{
								b->Angular = false;
								b->Dir = DIR_LEFTDOWN;
								b->Step = bound(b->Step+1, 0, MAX_BALL_SPEED); 
								break;
							}
							case DIR_LUU:
							{
								b->Angular = false;
								b->Dir = DIR_LEFTDOWN;
								b->Step = bound(b->Step+1, 0, MAX_BALL_SPEED); 
								break;
							}
							case DIR_RRU:
							{
								b->Angular = false;
								b->Dir = DIR_RIGHTDOWN;
								b->Step = bound(b->Step+1, 0, MAX_BALL_SPEED); 
								break;
							}
							case DIR_RUU:
							{
								b->Angular = false;
								b->Dir = DIR_RIGHTDOWN;
								b->Step = bound(b->Step+1, 0, MAX_BALL_SPEED); 
								break;
							}
							
						}
					}
					else
					{
						switch(b->Dir)
						{
							case DIR_RIGHTUP: { b->Dir = DIR_RIGHTDOWN; b->Step = bound(b->Step+1, 0, MAX_BALL_SPEED); break; }
							case DIR_LEFTUP: { b->Dir = DIR_LEFTDOWN; b->Step = bound(b->Step+1, 0, MAX_BALL_SPEED); break; }
							default: { TraceNL(); TraceS("Ball direction invalid for brick.take_hit(hit_below())."); 
								TraceNL(); TraceS("Ball Dir is: "); Trace(b->Dir); TraceNL();
								b->Dir = DIR_DOWN; b->Step = bound(b->Step+1, 0, MAX_BALL_SPEED); break; }
						}
					}
				}
				/*
				switch ( v->Dir ) 
				{
					case DIR_UPRIGHT: { v->Dir = DIR_DOWNRIGHT; v->Step = bound(v->Step+2, 0, MAX_BALL_SPEED); break; }
					case DIR_UPLEFT: { v->Dir = DIR_DOWNLEFT; v->Step = bound(v->Step+2, 0, MAX_BALL_SPEED); break; }
					default: { TraceS("hit_below() found an illegal ball direction"); break; }
				}
				*/
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
			
			else if ( hit_above(a,b) )
			{
				if ( b->Angular )
				{
					switch(b->Angle)
					{
						case DIR_LLD:
						{
							b->Angular = false;
							b->Dir = DIR_LEFTUP;
							b->Step = bound(b->Step+1, 0, MAX_BALL_SPEED); 
							break;
						}
						case DIR_LDD:
						{
							b->Angular = false;
							b->Dir = DIR_LEFTUP;
							b->Step = bound(b->Step+1, 0, MAX_BALL_SPEED); 
							break;
						}
						case DIR_RRD:
						{
							b->Angular = false;
							b->Dir = DIR_RIGHTUP;
							b->Step = bound(b->Step+1, 0, MAX_BALL_SPEED); 
							break;
						}
						case DIR_RDD:
						{
							b->Angular = false;
							b->Dir = DIR_RIGHTUP;
							b->Step = bound(b->Step+1, 0, MAX_BALL_SPEED); 
							break;
						}
						
					}
				}
				else
				{
					switch(b->Dir)
					{
						case DIR_DOWNLEFT: { b->Dir = DIR_UPLEFT; b->Step = bound(b->Step+2, 0, MAX_BALL_SPEED); break; }
						case DIR_DOWNRIGHT: { b	->Dir = DIR_UPRIGHT; b->Step = bound(b->Step+2, 0, MAX_BALL_SPEED); break; } 
						default: { 
							TraceNL(); TraceS("Ball direction invalid for brick.take_hit(hit_above())."); 
							TraceNL(); TraceS("Ball Dir is: "); Trace(b->Dir); TraceNL();
							
							b->Dir = DIR_DOWN; b->Step = bound(b->Step+1, 0, MAX_BALL_SPEED); break; }
					}
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
			
			else if ( hit_left(a,b) )
			{
				if ( b->Angular )
				{
					switch(b->Angle)
					{
						case DIR_LLU:
						{
							b->Angular = false;
							b->Dir = DIR_RIGHTUP;
							b->Step = bound(b->Step+1, 0, MAX_BALL_SPEED); 
							break;
						}
						case DIR_LUU:
						{
							b->Angular = false;
							b->Dir = DIR_RIGHTUP;
							b->Step = bound(b->Step+1, 0, MAX_BALL_SPEED); 
							break;
						}
						case DIR_LLD:
						{
							b->Angular = false;
							b->Dir = DIR_RIGHTDOWN;
							b->Step = bound(b->Step+1, 0, MAX_BALL_SPEED); 
							break;
						}
						case DIR_LDD:
						{
							b->Angular = false;
							b->Dir = DIR_RIGHTDOWN;
							b->Step = bound(b->Step+1, 0, MAX_BALL_SPEED); 
							break;
						}
						
					}
				}
				else
				{
					switch(b->Dir)
					{
						case DIR_RIGHTDOWN: { b->Dir = DIR_LEFTDOWN; b->Step = bound(b->Step+1, 0, MAX_BALL_SPEED); break; }
						case DIR_RIGHTUP: { b->Dir = DIR_LEFTUP; b->Step = bound(b->Step+1, 0, MAX_BALL_SPEED); break; }
						default: { 
							TraceNL(); TraceS("Ball direction invalid for brick.take_hit(hit(left))."); 
							TraceNL(); TraceS("Ball Dir is: "); Trace(b->Dir); TraceNL();
							b->Dir = DIR_DOWN; b->Step = bound(b->Step+1, 0, MAX_BALL_SPEED); break; }
					}
				}
				/*
				switch ( v->Dir ) 
				{
					case DIR_UPRIGHT: { v->Dir = DIR_UPLEFT; v->Step = bound(v->Step+2, 0, MAX_BALL_SPEED); break; }
					case DIR_DOWNRIGHT: { v->Dir = DIR_DOWNLEFT; v->Step = bound(v->Step+2, 0, MAX_BALL_SPEED);  break; }
					default: { TraceS("hit_left() found an illegal ball direction"); break; }
				}
				*/
				if ( a->HP <= 0 ) 
				{ 
					if ( !a->Misc[NPCM_AWARDED_POINTS] )
					{
						a->Misc[NPCM_AWARDED_POINTS] = 1;
						Game->Counter[CR_SCRIPT1] += a->Attributes[NPC_ATTRIB_POINTS];
					}
				}
			}
			else if ( hit_right(a,b) )
			{
				if ( b->Angular )
				{
					switch(b->Angle)
					{
						case DIR_RRD:
						{
							b->Angular = false;
							b->Dir = DIR_LEFTDOWN;
							b->Step = bound(b->Step+1, 0, MAX_BALL_SPEED); 
							break;
						}
						case DIR_RDD:
						{
							b->Angular = false;
							b->Dir = DIR_LEFTDOWN;
							b->Step = bound(b->Step+1, 0, MAX_BALL_SPEED); 
							break;
						}
						case DIR_RRU:
						{
							b->Angular = false;
							b->Dir = DIR_LEFTUP;
							b->Step = bound(b->Step+1, 0, MAX_BALL_SPEED); 
							break;
						}
						case DIR_RUU:
						{
							b->Angular = false;
							b->Dir = DIR_LEFTUP;
							b->Step = bound(b->Step+1, 0, MAX_BALL_SPEED); 
							break;
						}
						
					}
				}
				else
				{
					switch(b->Dir)
					{
						case DIR_LEFTDOWN: { b->Dir = DIR_RIGHTDOWN; b->Step = bound(b->Step+1, 0, MAX_BALL_SPEED); break; }
						case DIR_LEFTUP: { b->Dir = DIR_RIGHTUP; b->Step = bound(b->Step+1, 0, MAX_BALL_SPEED); break; }
						default: { 
							TraceNL(); TraceS("Ball direction invalid for brick.take_hit(hit_right())."); 
							TraceNL(); TraceS("Ball Dir is: "); Trace(b->Dir); TraceNL();
							b->Dir = DIR_DOWN; b->Step = bound(b->Step+1, 0, MAX_BALL_SPEED); break; }
					}
				}
				/*
				switch ( v->Dir ) 
				{
					case DIR_UPLEFT: { v->Dir = DIR_UPRIGHT; v->Step = bound(v->Step+2, 0, MAX_BALL_SPEED); break; }
					case DIR_DOWNLEFT: { v->Dir = DIR_DOWNRIGHT; v->Step = bound(v->Step+2, 0, MAX_BALL_SPEED); break; }
					default: { TraceS("hit_below() found an illegal ball direction"); break; }
				}
				*/
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
		quit = 0;
		frame = -1;
		Game->Counter[CR_LIVES] = 5;
		Link->CollDetection = false;
		Link->DrawYOffset = -32768;
	}
}

global script Init
{
	void run()
	{
		quit = 0;
		frame = -1;
		Game->Counter[CR_LIVES] = 5;
		Link->CollDetection = false;
		Link->DrawYOffset = -32768;
	}
}

global script onContinue
{
	void run()
	{
		quit = 0;
		frame = -1;
		Game->Counter[CR_LIVES] = 5;
		Link->Invisible = true; 
		Link->CollDetection = false;
		Link->DrawYOffset = -32768;
	}
}

/////////////////////////
/// DEAD Script Bugs: ///
/////////////////////////

/*
//FIXED with ball.clamp(). 
//There's a step speed at which the ball phases *through* the vaus! 
					//Perhaps we should make the vaus an enemy, too? An invisible enemy to act as a failsafe?
					//if the ball hits the vaus, it bounces.
					//Or just scrap the vaus ffc, and use an npc for it in general?

//BALL NEEDS TO HAVE A 6PX BY 6PX HITBOX, AND THUS A HIT OFFSET OF -1,-1, so that ->HitBy[] returns when the ball hits a block, and
//the ball is still not yet inside that object
*/

//////////////////////
/// DEAD ZC Issues //////////////////////////////////////////////////////////////////////////////
/// I fixed these issues, in specific Alphas of ZC 2.54, noted below for historical purposes: ///
/////////////////////////////////////////////////////////////////////////////////////////////////


/*
FIXED in Alpha 32
I forgot to expand ->Misc[] in sprite.cpp, which should be fixed int he source for Alpha 32. 
	This meant that r/w to ptr->Misc[>15] would use invalid data, or overwrite other data. bad, bad, bad. 
	
	FIXED in Alpha 32
	//Note: We also need to store the UID of each ball, as HitBy[] works from the UID, not the pointer. 
	
*/