//=============================================
//	Plugin Writed by Visual Studio Code.
//=============================================
// Supported BIOHAZARD.
// #define BIOHAZARD_SUPPORT
// #define ZP_SUPPORT

//=====================================
//  INCLUDE AREA
//=====================================
#include <amxmodx>
#include <amxmisc>
#include <amxconst>
#include <cstrike>
#include <csx>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <xs>
#include <json>
#include <fun>

#define AMXMODX_NOAUTOLOAD
#include <reapi>

//=====================================
//  VERSION CHECK
//=====================================
#if AMXX_VERSION_NUM < 190
	#assert "AMX Mod X v1.9.0 or greater library required!"
#endif

#include <lasermine_util>
#include <lasermine_resources>

#pragma semicolon 1
#pragma tabsize 4

#if !defined BIOHAZARD_SUPPORT && !defined ZP_SUPPORT
	#define PLUGIN 					"Laser/Tripmine Entity"
	#define CHAT_TAG 				"[Lasermine]"
	#define CVAR_TAG				"amx_ltm"
	#define CVAR_CFG				"lasermine/ltm_cvars"
#endif

//=====================================
//  MACRO AREA
//=====================================
// AUTHOR NAME +ARUKARI- => SandStriker => Aoi.Kagase
#define AUTHOR 						"Aoi.Kagase"
#define VERSION 					"3.41"

//====================================================
//  GLOBAL VARIABLES
//====================================================
new gMsgBarTime;
new gMsgWeaponList;
new gCvar				[E_CVAR_SETTING];
new gCvarPointer		[E_CVAR_SETTING_LIST];
new gEntMine;
new gWeaponId;
new gDeployingMines		[MAX_PLAYERS];

#if AMXX_VERSION_NUM > 183
new Stack:gRecycleMine	[MAX_PLAYERS];
#endif

#if defined BIOHAZARD_SUPPORT || defined ZP_SUPPORT
#pragma semicolon 0
	#include <lasermine_zombie>
#pragma semicolon 1
#endif
#define RELOAD_TIME						0.6
enum E_FORWARD
{
	E_FWD_ONBUY_PRE,
	E_FWD_ONBUY_POST,
	E_FWD_ONPLANT,
	E_FWD_ONPLANTED,
	E_FWD_ONHIT_PRE,
	E_FWD_ONHIT_POST,
	E_FWD_ONPICKUP_PRE,
	E_FWD_ONPICKUP_POST,
}

new g_forward[E_FORWARD];

new g_library;
new g_players[MAX_PLAYERS + 1];

//====================================================
// Forward declarations
//====================================================
public plugin_forward();
public module_filter(const module[]);
public native_filter(const name[], index, trap);
public plugin_init();
public register_cvars();
#if AMXX_VERSION_NUM < 190
public plugin_cfg();
#endif
#if AMXX_VERSION_NUM > 183
public plugin_end();
public cvar_change_callback(pcvar, const old_value[], const new_value[]);
#endif
public plugin_precache();
public NewRound(id);
public KeepMaxSpeed(id);
public DeathEvent();
public lm_progress_deploy(id);
public lm_progress_remove(id);
public lm_progress_stop(id);
public SpawnMine(id);
public RemoveMine(id);
public LaserThink(iEnt);
public lm_step_powerup(iEnt, Float:fCurrTime);
public lm_step_beamup(iEnt, Float:vEnd[3], Float:fCurrTime);
public lm_step_beambreak(iEnt, Float:vEnd[3], Float:fCurrTime);
public lm_step_explosion(iEnt, iOwner);
public draw_laserline(iEnt, const Float:vEndOrigin[3]);
public create_laser_damage(iEnt, iTarget, hitGroup, Float:hitPoint[]);
public PlayerKilling(iVictim, inflictor, iAttacker, Float:damage, bits);
#if !defined ZP_SUPPORT
public lm_buy_lasermine(id);
#endif
public show_ammo(id);
public lm_say_lasermine(id);
public PlayerCmdStart(id, handle, random_seed);
public lm_deploy_status(id);
public Reload(taskid);
public client_putinserver(id);
public client_disconnected(id);
#if defined BIOHAZARD_SUPPORT
public event_infect2(id);
#endif
public CheckSpectator();
public CheckPlayer(id);
public Message_TextMsg(iMsgId, iMsgDest, id);
public OnAddToPlayerC4(const item, const player);
public SelectLasermine(const client);
public OnItemSlotC4(const item);
public OnSetDeployModels(const item);
public OnC4Drop(const iEntity);
public weapon_change(id);
public OnPrimaryAttackPre(Weapon);
public OnPrimaryAttackPost(Weapon);
public OnUpdateClientDataPost(Player, SendWeapons, CD_Handle);
public plugin_natives();
public _native_lm_give(iPlugin, iParams);
public _native_lm_set(iPlugin, iParams);
public _native_lm_sub(iPlugin, iParams);
public _native_lm_get_have(iPlugin, iParams);
public _native_lm_remove_all(iPlugin, iParams);
public _native_lm_is_lasermine(iPlugin, iParams);
public _native_lm_get_owner(iPlugin, iParams);
public _native_lm_get_laser(iPlugin, iParams);

//====================================================
// Initialize forwards
//====================================================
public plugin_forward()
{
	g_forward[E_FWD_ONBUY_PRE]		= CreateMultiForward("LM_OnBuy_Pre",  		ET_STOP, 	FP_CELL, FP_VAL_BYREF, FP_VAL_BYREF);
	g_forward[E_FWD_ONBUY_POST]		= CreateMultiForward("LM_OnBuy_Post", 		ET_IGNORE, 	FP_CELL, FP_CELL, FP_CELL);
	g_forward[E_FWD_ONPLANT]		= CreateMultiForward("LM_OnPlant", 			ET_STOP, 	FP_CELL, FP_VAL_BYREF);
	g_forward[E_FWD_ONPLANTED]		= CreateMultiForward("LM_OnPlanted", 		ET_IGNORE, 	FP_CELL, FP_CELL);
	g_forward[E_FWD_ONHIT_PRE]		= CreateMultiForward("LM_OnHit_Pre", 		ET_STOP, 	FP_CELL, FP_VAL_BYREF, FP_VAL_BYREF, FP_VAL_BYREF);
	g_forward[E_FWD_ONHIT_POST]		= CreateMultiForward("LM_OnHit_Post", 		ET_IGNORE, 	FP_CELL, FP_CELL, FP_CELL, FP_CELL);
	g_forward[E_FWD_ONPICKUP_PRE]	= CreateMultiForward("LM_OnPickup_Pre", 	ET_STOP, 	FP_CELL, FP_CELL);
	g_forward[E_FWD_ONPICKUP_POST]	= CreateMultiForward("LM_OnPickup_Post", 	ET_IGNORE, 	FP_CELL);
}

//====================================================
// Check Module. Section 2.
//====================================================
public module_filter(const module[])
{
	if (equali(module, "reapi"))
		return PLUGIN_HANDLED;

	return PLUGIN_CONTINUE;
}
//====================================================
// Check Module. Section 3.
//====================================================
public native_filter(const name[], index, trap)
{
	if (!trap)
		return PLUGIN_HANDLED;

	return PLUGIN_CONTINUE;
}
//====================================================
//  PLUGIN INITIALIZE
//====================================================
public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	// Add your code here...
	register_concmd("lm_remove", 	"admin_remove_laser",ADMIN_ACCESSLEVEL, " - <num>"); 
	register_concmd("lm_give", 		"admin_give_laser",  ADMIN_ACCESSLEVEL, " - <num>"); 

	register_clcmd("say", 			"lm_say_lasermine");

#if !defined ZP_SUPPORT	
	register_clcmd("buy_lasermine", "lm_buy_lasermine");
#endif
	register_cvars();

	gMsgBarTime	= get_user_msgid("BarTime");
	gMsgWeaponList = get_user_msgid("WeaponList");
	register_message(get_user_msgid("TextMsg"), 	"Message_TextMsg") ;

	// Register Hamsandwich
	RegisterHamPlayer	(Ham_Spawn, 		"NewRound",			1);
	RegisterHamPlayer	(Ham_Item_PreFrame,	"KeepMaxSpeed", 	1);
	RegisterHamPlayer	(Ham_TakeDamage, 	"PlayerKilling",	0);

	RegisterHam			(Ham_Think,			ENT_CLASS_BREAKABLE, "LaserThink",		0);
	RegisterHam			(Ham_TakeDamage,	ENT_CLASS_BREAKABLE, "MinesTakeDamage",	0);
	RegisterHam			(Ham_TakeDamage,	ENT_CLASS_BREAKABLE, "MinesTakeDamaged",1);

	// Register Event
	register_event_ex	("DeathMsg", 		"DeathEvent",		RegisterEvent_Global);
	register_event_ex	("TeamInfo", 		"CheckSpectator",	RegisterEvent_Global);

	// Register Forward.
	register_forward	(FM_CmdStart,		"PlayerCmdStart");
	register_forward	(FM_TraceLine,		"MinesShowInfo", 1);

	// Multi Language Dictionary.
	register_dictionary	("lasermine.txt");

#if AMXX_VERSION_NUM > 183
	for(new i = 0; i < MAX_PLAYERS; i++)
		gRecycleMine[i] = CreateStack(1);
#endif

#if defined ZP_SUPPORT || defined BIOHAZARD_SUPPORT
	register_zombie();
#else
#if AMXX_VERSION_NUM > 183
	AutoExecConfig(true, CVAR_CFG);
#endif
#endif

	create_cvar			("ltm_version", 	VERSION, FCVAR_SERVER|FCVAR_SPONLY);

	// Add Custom weapon id to CSX.
	gWeaponId = custom_weapon_add("Laser Mine", 0, ENT_CLASS_LASER);

	// registered func_breakable
	gEntMine = engfunc(EngFunc_AllocString, ENT_CLASS_BREAKABLE);

	g_library = LibraryExists("reapi", LibType_Library);

/// =======================================================================================
/// START Custom Weapon
/// =======================================================================================
    register_clcmd		("weapons/ltm/weapon_lasermine", 	"SelectLasermine");
    RegisterHam			(Ham_Item_AddToPlayer, 				"weapon_c4", 	"OnAddToPlayerC4",		.Post = true);
	RegisterHam			(Ham_Item_ItemSlot, 				"weapon_c4", 	"OnItemSlotC4");
	RegisterHam			(Ham_Item_Deploy, 					"weapon_c4", 	"OnSetDeployModels",	.Post = true);
	RegisterHam			(Ham_Weapon_PrimaryAttack, 			"weapon_c4", 	"OnPrimaryAttackPre");
	RegisterHam			(Ham_Weapon_PrimaryAttack, 			"weapon_c4", 	"OnPrimaryAttackPost",	.Post = true);
	RegisterHam			(Ham_CS_Item_CanDrop, 				"weapon_c4", 	"OnC4Drop");

	register_event		("CurWeapon", 						"weapon_change", "be", "1=1");
	register_forward	(FM_UpdateClientData, 				"OnUpdateClientDataPost", 				._post = true);
/// =======================================================================================
/// END Custom Weapon
/// =======================================================================================

	LoadDecals();
	plugin_forward();
	return PLUGIN_CONTINUE;
}

public register_cvars()
{
	new E_CVAR_SETTING:key;
	// CVar settings.
	for(new E_CVAR_SETTING_LIST:i = CL_ENABLE; i < E_CVAR_SETTING_LIST; i++)
	{
		key = get_cvar_key(i);
		if (i == CL_FRIENDLY_FIRE || i == CL_VIOLENCE_HBLOOD)
			gCvarPointer[i] = get_cvar_pointer(CVAR_CONFIGRATION[i][0]);
		else
			gCvarPointer[i] = create_cvar(fmt("%s%s", CVAR_TAG, CVAR_CONFIGRATION[i][0]), CVAR_CONFIGRATION[i][2], FCVAR_NONE, CVAR_CONFIGRATION[i][1]);
		if (equali(CVAR_CONFIGRATION[i][3], "num")) {
			bind_pcvar_num(gCvarPointer[i], gCvar[key]);
		}
		else if(equali(CVAR_CONFIGRATION[i][3], "float")) {
			bind_pcvar_float(gCvarPointer[i], Float:gCvar[key]);
		}
		else if(equali(CVAR_CONFIGRATION[i][3], "string")) {
			switch(i)
			{
				case CL_CBT: 			bind_pcvar_string(gCvarPointer[CL_CBT], gCvar[CVAR_CBT], charsmax(gCvar[CVAR_CBT]));
				case CL_LASER_COLOR_TR: bind_pcvar_string(gCvarPointer[CL_LASER_COLOR_TR], gCvar[CVAR_LASER_COLOR_TR], charsmax(gCvar[CVAR_LASER_COLOR_TR]));
				case CL_LASER_COLOR_CT: bind_pcvar_string(gCvarPointer[CL_LASER_COLOR_CT], gCvar[CVAR_LASER_COLOR_CT], charsmax(gCvar[CVAR_LASER_COLOR_CT]));
				case CL_MINE_GLOW_TR: 	bind_pcvar_string(gCvarPointer[CL_MINE_GLOW_TR], gCvar[CVAR_MINE_GLOW_TR], charsmax(gCvar[CVAR_MINE_GLOW_TR]));
				case CL_MINE_GLOW_CT: 	bind_pcvar_string(gCvarPointer[CL_MINE_GLOW_CT], gCvar[CVAR_MINE_GLOW_CT], charsmax(gCvar[CVAR_MINE_GLOW_CT]));				
			}
		}
		
		hook_cvar_change(gCvarPointer[i], "cvar_change_callback");
	}	
}

#if AMXX_VERSION_NUM < 190
//====================================================
//  PLUGIN CONFIG (for 1.8.2)
//====================================================
public plugin_cfg()
{
	new file[64];
	new len = charsmax(file);
	get_localinfo("amxx_configsdir", file, len);
	format(file, len, "%s/plugins/%s.cfg", file, CVAR_CFG);

	if(file_exists(file)) 
	{
		server_cmd("exec %s", file);
		server_exec();
	}
}
#endif

//====================================================
//  PLUGIN END
//====================================================
#if AMXX_VERSION_NUM > 183
public plugin_end()
{
	for(new i = 0; i < MAX_PLAYERS; i++)
		DestroyStack(gRecycleMine[i]);

	lm_resources_release();
}

// ====================================================
//  Callback cvar change.
// ====================================================
public cvar_change_callback(pcvar, const old_value[], const new_value[])
{
	new E_CVAR_SETTING:key;
	for(new E_CVAR_SETTING_LIST:i = CL_ENABLE; i < E_CVAR_SETTING_LIST; i++)
	{
		key = get_cvar_key(i);
		if (gCvarPointer[i] == pcvar)
		{
			if (equali(CVAR_CONFIGRATION[i][3], "num"))
				gCvar[key] = str_to_num(new_value);
			else if (equali(CVAR_CONFIGRATION[i][3], "float"))
				gCvar[key] = _:str_to_float(new_value);
			else if (equali(CVAR_CONFIGRATION[i][3], "string"))
			{
				switch(i)
				{
					case CL_CBT: 			copy(gCvar[CVAR_CBT], charsmax(gCvar[CVAR_CBT]), new_value);
					case CL_LASER_COLOR_TR: copy(gCvar[CVAR_LASER_COLOR_TR], charsmax(gCvar[CVAR_LASER_COLOR_TR]), new_value);
					case CL_LASER_COLOR_CT: copy(gCvar[CVAR_LASER_COLOR_CT], charsmax(gCvar[CVAR_LASER_COLOR_CT]), new_value);
					case CL_MINE_GLOW_TR: 	copy(gCvar[CVAR_MINE_GLOW_TR], charsmax(gCvar[CVAR_MINE_GLOW_TR]), new_value);
					case CL_MINE_GLOW_CT: 	copy(gCvar[CVAR_MINE_GLOW_CT], charsmax(gCvar[CVAR_MINE_GLOW_CT]), new_value);				
				}
			}
			console_print(0,"[LM Debug]: Changed Cvar '%s' => '%s' to '%s'", fmt("%s%s", CVAR_TAG, CVAR_CONFIGRATION[i][0]), old_value, new_value);
		}
	}
}
#endif

//====================================================
//  PLUGIN PRECACHE
//====================================================
public plugin_precache() 
{
	check_plugin();

	// Load Custom Resources.
	lm_resources_load();
	lm_resources_precache();

	// WEAPON SLOT ENVIRONMENT.
	precache_model("sprites/weapons/ltm/2560/weapon_tripmine_weapon.spr"),
	precache_model("sprites/weapons/ltm/2560/weapon_tripmine_weapon_s.spr"),
	precache_model("sprites/weapons/ltm/2560/weapon_tripmine_ammo.spr"),
	precache_model("sprites/weapons/ltm/1280/weapon_tripmine_weapon.spr"),
	precache_model("sprites/weapons/ltm/1280/weapon_tripmine_weapon_s.spr"),	
	precache_model("sprites/weapons/ltm/1280/weapon_tripmine_weapon.spr"),
	precache_model("sprites/weapons/ltm/640hud3.spr"),
	precache_model("sprites/weapons/ltm/640hud6.spr"),
	precache_model("sprites/weapons/ltm/640hud7.spr"),
	precache_model("sprites/weapons/ltm/320hud1.spr"),
	precache_model("sprites/weapons/ltm/320hud2.spr"),
	precache_generic("sprites/weapons/ltm/weapon_lasermine.txt");
	
	return PLUGIN_CONTINUE;
}

//====================================================
// Friendly Fire Method.
//====================================================
bool:is_valid_takedamage(iAttacker, iTarget)
{
	if (gCvar[CVAR_FRIENDLY_FIRE])
		return true;

	new name[MAX_NAME_LENGTH];
	pev(iTarget, pev_classname, name, charsmax(name));

	if (equali(name, ENT_CLASS_LASER))
	{
		if (cs_get_user_team(iAttacker) != lm_get_laser_team(iTarget))
			return true;
	}
	else
	{
		if (cs_get_user_team(iAttacker) != cs_get_user_team(iTarget))
			return true;
	}

	return false;
}

//====================================================
// Round Start Initialize
//====================================================
public NewRound(id)
{
	// Check Plugin Enabled
	if (!gCvar[CVAR_ENABLE])
		return PLUGIN_CONTINUE;

	if (!is_user_connected(id))
		return PLUGIN_CONTINUE;
	
	if (is_user_bot(id))
		return PLUGIN_CONTINUE;

	// alive?
	if (is_user_alive(id) && pev(id, pev_flags) & (FL_CLIENT)) 
	{
		// Delay time reset
		lm_set_user_delay_count(id, get_gametime());

#if AMXX_VERSION_NUM > 183
		// Init Recycle Health.
		ClearStack(gRecycleMine[id]);
#endif
		// Task Delete.
		delete_task(id);

		// Removing already put lasermine.
		lm_remove_all_entity(id, ENT_CLASS_LASER);

		// Round start set ammo.
		set_start_ammo(id);

		// Refresh show ammo.
		show_ammo(id);
	}
	return PLUGIN_CONTINUE;
}

//====================================================
// Keep Max Speed.
//====================================================
public KeepMaxSpeed(id)
{
	if (is_user_alive(id))
	{
		new Float:now_speed = lm_get_user_max_speed(id);
		if (now_speed > 1.0 && now_speed < 300.0)
			lm_save_user_max_speed(id, lm_get_user_max_speed(id));
	}

	return PLUGIN_CONTINUE;
}

//====================================================
// Round Start Set Ammo.
//====================================================
set_start_ammo(id)
{
	// Get CVAR setting.
	new int:stammo = int:gCvar[CVAR_START_HAVE];

	// Zero check.
	if(stammo <= int:0) 
		return;

	// Getting have ammo.
	new int:haveammo = lm_get_user_have_mine(id);

	// Set largest.
	lm_set_user_have_mine(id, (haveammo <= stammo ? stammo : haveammo));

	if (cs_get_user_bpammo(id, CSW_C4) <= 0)
		give_item(id, "weapon_c4");	

	cs_set_user_bpammo(id, CSW_C4, lm_get_user_have_mine(id));

	return;
}

//====================================================
// Death Event / Delete Task.
//====================================================
public DeathEvent()
{
	// new kID = read_data(1); // killer
	new vID = read_data(2); // victim
	// new isHS = read_data(3); // is headshot
	// new wpnName = read_data(4); // wpnName

	// Check Plugin Enabled
	if (!gCvar[CVAR_ENABLE])
		return PLUGIN_CONTINUE;

	// Is Connected?
	if (is_user_connected(vID)) 
		delete_task(vID);

	// Dead Player remove lasermine.
	if (gCvar[CVAR_DEATH_REMOVE])
		lm_remove_all_entity(vID, ENT_CLASS_LASER);

	return PLUGIN_CONTINUE;
}

//====================================================
// Deploy LaserMine Start Progress
//====================================================
public lm_progress_deploy(id)
{
	// Deploying Check.
	if (!check_for_deploy(id))
		return PLUGIN_HANDLED;

	new wait = gCvar[CVAR_LASER_ACTIVATE];
	new iRet;
	ExecuteForward(g_forward[E_FWD_ONPLANT], iRet, id, wait);
	// Set Flag. start progress.
	lm_set_user_deploy_state(id, int:STATE_DEPLOYING);

	new iEnt = gDeployingMines[id] = engfunc(EngFunc_CreateNamedEntity, gEntMine);
	if (pev_valid(iEnt))
	{
		new szValue[MAX_RESOURCE_PATH_LENGTH];
		lm_get_models(W_WPN, cs_get_user_team(id), szValue, charsmax(szValue));
		// set models.
		engfunc(EngFunc_SetModel, iEnt, szValue);
		// set solid.
		set_pev(iEnt, pev_solid, 		SOLID_NOT);
		// set movetype.
		set_pev(iEnt, pev_movetype, 	MOVETYPE_FLY);

		set_pev(iEnt, pev_renderfx, 	kRenderFxHologram);
		set_pev(iEnt, pev_body, 		3);
		set_pev(iEnt, pev_sequence, 	TRIPMINE_WORLD);
		// set model animation.
		set_pev(iEnt, pev_frame,		0);
		set_pev(iEnt, pev_framerate,	0);
		set_pev(iEnt, pev_rendermode,	kRenderTransAdd);
		set_pev(iEnt, pev_renderfx,	 	kRenderFxHologram);
		set_pev(iEnt, pev_renderamt,	255.0);
		set_pev(iEnt, pev_rendercolor,	{255.0,255.0,255.0});

		if (cs_get_user_weapon(id) == CSW_C4)
			set_pdata_float(cs_get_user_weapon_entity(id), 35, 999.0);		
	}

	// Start Task. Put Lasermine.
	SpawnMine(TASK_PLANT + id);

	return PLUGIN_HANDLED;
}

//====================================================
// Removing target put lasermine.
//====================================================
public lm_progress_remove(id)
{
	// Removing Check.
	if (!check_for_remove(id))
		return PLUGIN_HANDLED;

	new wait = gCvar[CVAR_LASER_ACTIVATE];
	if (wait > 0)
		lm_show_progress(id, wait, gMsgBarTime);

	// Set Flag. start progress.
	lm_set_user_deploy_state(id, int:STATE_PICKING);

	// Start Task. Remove Lasermine.
	set_task(float(wait), "RemoveMine", (TASK_RELEASE + id));

	return PLUGIN_HANDLED;
}

//====================================================
// Stopping Progress.
//====================================================
public lm_progress_stop(id)
{
	if (pev_valid(gDeployingMines[id]))
		lm_remove_entity(gDeployingMines[id]);
	gDeployingMines[id] = 0;

	lm_hide_progress(id, gMsgBarTime);
	delete_task(id);

	return PLUGIN_HANDLED;
}

//====================================================
// Task: Spawn Lasermine.
//====================================================
public SpawnMine(id)
{
	// Task Number to uID.
	new uID = id - TASK_PLANT;
	new iRet;
	// is Valid?
	if(!gDeployingMines[uID])
	{
		cp_debug(uID);
		return PLUGIN_HANDLED_MAIN;
	}

	set_spawn_entity_setting(gDeployingMines[uID], uID, ENT_CLASS_LASER);
	ExecuteForward(g_forward[E_FWD_ONPLANTED], iRet, id, gDeployingMines[uID]);
	return 1;
}

//====================================================
// Lasermine Settings.
//====================================================
stock set_spawn_entity_setting(iEnt, uID, classname[])
{
	// Entity Setting.
	// set class name.
	set_pev(iEnt, pev_classname, 		classname);
	// set solid.
	set_pev(iEnt, pev_solid, 			SOLID_NOT);
	set_pev(iEnt, pev_rendermode,		kRenderNormal);
	set_pev(iEnt, pev_renderfx,	 		kRenderFxNone);
	// set take damage.
	set_pev(iEnt, pev_takedamage, 		DAMAGE_YES);
	set_pev(iEnt, pev_dmg, 				100.0);
	// set entity health.
	// if recycle health.
#if AMXX_VERSION_NUM > 183
	if (!IsStackEmpty(gRecycleMine[uID]))
	{
		new Float:health;
		PopStackCell(gRecycleMine[uID], health);
		lm_set_user_health(iEnt, 		health);
	}
	else
	{
		set_pev(iEnt, pev_health, gCvar[CVAR_MINE
