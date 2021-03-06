/*

Created by: Zethax
Document created on: Wednesday, January 9th, 2019
Last edit made on: Tuesday, January 29th, 2019
Current version: v1.1

Credits:
-Pikachu on LSD
	If you see anything involving DHooks or external files it's his

Attributes in this pack:
	- "dispenser minigun main"
		1) Radius of the dispenser
		2) Maximum healing required to charge Dispensing Fury
		3) How long Dispensing Fury lasts
				
		The main attribute for the dispenser minigun attributes.
		This attribute is required for the others to work, and must be added first.
		Don't want Dispensing Fury? Set the values associated with it to 0 to disable.

	- "dispenser minigun heal"
		1) Healing per second
				
		Restores health to allies within the radius at a rate of X% of max health per second
		Requires "dispenser minigun main" to work.
				
	- "dispenser minigun ammo"
		1) Ammo to dispense per tick
				
		Replenishes ammo to allies within the radius at a rate of X% max ammo per second
		Requires "dispenser minigun main" to work.
	
	I might remake that attribute that reduces healing from all sources, to make it compatible with this
	Future note: I did
	
	- "reduced healing while spun up"
		1) Amount to reduce healing by while spun up
		
		Reduces healing while spun up. Only including this here so it affects other Provisioners as well.
*/

#pragma semicolon 1
#include <sourcemod>
#include <cw3-attributes>
#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>
#include <dhooks>
#include <sdktools>
#include <zethax>
#include <tf2attributes>

#define PLUGIN_NAME "Dispenser Minigun"
#define PLUGIN_DESC "Creates the attributes associated with the dispenser minigun"
#define PLUGIN_AUTH "Zethax"
#define PLUGIN_VERS "v1.1"

//apparently because the sound was "too annoying"
//#define SOUND_DISPENSER_HEAL "weapons/dispenser_heal.wav"

#define TF_ECON_INDEX_PERSIAN_PERSUADER 404
#define TF_ECON_INDEX_BACKSCRATCHER 326
new Handle:g_DHookPlayerTakeHealth;
new HealBeams[MAXPLAYERS + 1][MAXPLAYERS + 1];

public Plugin:my_info = {
	
	name	    = PLUGIN_NAME,
	description = PLUGIN_DESC,
	author	    = PLUGIN_AUTH,
	version	    = PLUGIN_VERS,
	url	    	= ""
};

//These attributes were seen before, but were terribly made
//They put a heavy load on the server when in use
//So I'm just remaking them completely

public OnPluginStart() 
{
	new Handle:hGameConf = LoadGameConfigFile("tf2.weapon_overhaul"); 
	
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("player_spawn", OnPlayerSpawn);
	HookEvent("player_disconnect", OnPlayerDisconnect);
	HookEvent("post_inventory_application", OnInventoryApplication);
	
	for(new i = 1; i < MaxClients; i++)
	{
		if(!IsValidClient(i))
			continue;
		
		OnClientPutInServer(i);
	}
	
	new iOffset = GameConfGetOffset(hGameConf, "CTFPlayer::TakeHealth()");
	if (iOffset == -1) {
		SetFailState("Missing offset for CTFPlayer::TakeHealth()"); 
	}
	
	g_DHookPlayerTakeHealth = DHookCreate(iOffset, HookType_Entity, ReturnType_Bool,
			ThisPointer_CBaseEntity, OnPlayerTakeHealth);
	DHookAddParam(g_DHookPlayerTakeHealth, HookParamType_Float); // flHealth
	DHookAddParam(g_DHookPlayerTakeHealth, HookParamType_Int); // bitsDamageType
	
	delete hGameConf;
	
	for (new i = 0; i < sizeof(HealBeams[]); i++)
	{
		HealBeams[i][i] = -1;
	}
}

public OnMapStart()
{
	//apparently because the sound was "too annoying"
	//PrecacheSound(SOUND_DISPENSER_HEAL, true);
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_PostThink, OnClientPostThink);
	
	DHookEntity(g_DHookPlayerTakeHealth, false, client);
}

new bool:DispenserMinigun[2049];
new Float:DispenserMinigun_Radius[2049];
new Float:DispenserMinigun_Charge[2049];
new Float:DispenserMinigun_MaxCharge[2049];
new Float:DispenserMinigun_FuryDur[2049];
new bool:DispenserMinigun_InFury[2049];
new bool:DispenserMinigun_InRadius[MAXPLAYERS + 1];
new Float:DispenserMinigun_Dur[2049];

new bool:DispenserMinigun_Heal[2049];
new Float:DispenserMinigun_HealRate[2049];

new bool:DispenserMinigun_Ammo[2049];
new Float:DispenserMinigun_DispenseRate[2049];

new bool:ReduceHealingSpinning[2049];
new Float:ReduceHealingSpinning_Amount[2049];

new Float:LastTick[MAXPLAYERS + 1];
new Float:LastAmmoTick[MAXPLAYERS + 1];
new Float:LastHealTick[MAXPLAYERS + 1];
new MaxAmmo[2049];
new LastHealer[MAXPLAYERS + 1];

new Float:SpinupDelay[MAXPLAYERS + 1];

new g_iParticleEntityStart[MAXPLAYERS+1][MAXPLAYERS+1];
new g_iParticleEntityEnd[MAXPLAYERS+1][MAXPLAYERS+1];

//all of this resets sounds and particles
public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	KillAllDualParticles(client);
	//StopSound(client, SNDCHAN_ITEM, SOUND_DISPENSER_HEAL);
}
public Action:OnPlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	KillAllDualParticles(client);
	//StopSound(client, SNDCHAN_ITEM, SOUND_DISPENSER_HEAL);
}
public Action:OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	KillAllDualParticles(client);
	//StopSound(client, SNDCHAN_ITEM, SOUND_DISPENSER_HEAL);
}
public Action:OnInventoryApplication(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	KillAllDualParticles(client);
	//StopSound(client, SNDCHAN_ITEM, SOUND_DISPENSER_HEAL);
}

public Action:CW3_OnAddAttribute(slot, client, const String:attrib[], const String:plugin[], const String:value[], bool:whileActive)
{
	new Action:action;
	
	if(!StrEqual(plugin, "tf_custom_dispenser_minigun"))
		return action;
	
	new weapon = GetPlayerWeaponSlot(client, slot);
	if(weapon < 0 || weapon > 2048)
		return action;
	
	if(StrEqual(attrib, "dispenser minigun main"))
	{
		new String:values[3][10];
		ExplodeString(value, " ", values, sizeof(values), sizeof(values[]));
		
		DispenserMinigun_Radius[weapon] = StringToFloat(values[0]);
		DispenserMinigun_MaxCharge[weapon] = StringToFloat(values[1]);
		DispenserMinigun_FuryDur[weapon] = StringToFloat(values[2]);
		
		if(DispenserMinigun_FuryDur[weapon] > 0.0 && DispenserMinigun_MaxCharge[weapon] > 0)
		{
			TF2Attrib_SetByName(weapon, "generate rage on damage", 1.0);
		}
		
		DispenserMinigun[weapon] = true;
		action = Plugin_Handled;
	}
	
	//The following attributes require "dispenser minigun main" to be set on the weapon first
	//and a defined radius value, or else they simply won't work.
	else if(StrEqual(attrib, "dispenser minigun heal") && DispenserMinigun[weapon])
	{
		DispenserMinigun_HealRate[weapon] = StringToFloat(value);
		
		DispenserMinigun_Heal[weapon] = true;
		action = Plugin_Handled;
	}
	else if(StrEqual(attrib, "dispenser minigun ammo") && DispenserMinigun[weapon])
	{
		DispenserMinigun_DispenseRate[weapon] = StringToFloat(value);
		
		DispenserMinigun_Ammo[weapon] = true;
		action = Plugin_Handled;
	}
	
	//this one is just to reduce healing while spun up
	//it's only in here so other Provisioners are affected
	else if(StrEqual(attrib, "reduced healing while spun up"))
	{
		ReduceHealingSpinning_Amount[weapon] = StringToFloat(value);
		
		ReduceHealingSpinning[weapon] = true;
		action = Plugin_Handled;
	}
	return action;
}

public void OnClientPostThink(client)
{
	if(!IsValidClient(client))
		return;
	
	new weapon = GetActiveWeapon(client);
	if(weapon < 0 || weapon > 2048)
		return;
	
	if(DispenserMinigun_InRadius[client])
	{
		new healer = LastHealer[client];
		if(healer == -1)
			return;
		
		new wep = GetActiveWeapon(healer);
		if(DispenserMinigun_Heal[wep])
		{
			//used throughout for reducing heal rate
			new Float:fiftypercentModifier = 0.5;
			//base delay
			new Float:delay = 1.0 / (GetClientMaxHealth(client) * DispenserMinigun_HealRate[wep]);
			
			if(TF2_GetPlayerClass(client) == TFClass_Heavy && TF2_IsPlayerInCondition(client, TFCond:0) && client != healer)
			{
				//increase delay if they have reduced healing while spun up
				if(ReduceHealingSpinning[weapon])
					delay /= 1.0 - ReduceHealingSpinning_Amount[weapon];
			}
			//iincrease delay if they have the persian persuader or back scratcher equipped
			if(GetWeaponIndex(GetPlayerWeaponSlot(client, 2)) == TF_ECON_INDEX_PERSIAN_PERSUADER || 
				GetWeaponIndex(GetActiveWeapon(client)) == TF_ECON_INDEX_BACKSCRATCHER)
				delay /= fiftypercentModifier;
			
			//decrease delay if the Heavy is using dispensing fury
			if(DispenserMinigun_InFury[wep])
				delay *= fiftypercentModifier;
			
			if(GetClientHealth(client) < GetClientMaxHealth(client) && GetEngineTime() >= LastHealTick[client] + delay)
			{
				HealPlayer(healer, client, 1, 1.0);
				
				if(!DispenserMinigun_InFury[wep] && client != healer)
					DispenserMinigun_Charge[wep] += 1;
				
				LastHealTick[client] = GetEngineTime();
			}
		}
		if(DispenserMinigun_Ammo[wep])
		{
			new Float:delay = 1.0;
			if(DispenserMinigun_InFury[wep])
				delay *= 0.5;
			if(GetEngineTime() >= LastAmmoTick[client] + delay)
			{
				for(new j = 0; j <= 3 ; j++)
				{
					new target = GetPlayerWeaponSlot(client, j);
					if(target == -1) continue;
					new ammo = RoundToFloor(MaxAmmo[target] * DispenserMinigun_DispenseRate[wep]);
					new ammotype = GetEntProp(target, Prop_Data, "m_iPrimaryAmmoType");
					
					GivePlayerAmmo(client, ammo, ammotype);
				}
				LastAmmoTick[client] = GetEngineTime();
			}
		}
		if(DispenserMinigun_InRadius[client] && !TF2_IsPlayerInCondition(healer, TFCond:0))
		{
			DispenserMinigun_InRadius[client] = false;
			LastHealer[client] = -1;
		}
	}
	
	if(!DispenserMinigun[weapon])
		return;
		
	new Float:rage = (DispenserMinigun_Charge[weapon] / DispenserMinigun_MaxCharge[weapon]) * 100.0;
	SetEntPropFloat(client, Prop_Send, "m_flRageMeter", rage);
	
	if(GetEngineTime() > LastTick[client] + 0.1)
		DispenserMinigun_PostThink(client, weapon);
}

static void DispenserMinigun_PostThink(client, weapon)
{
	new Float:radmult = 1.0;
	if(DispenserMinigun_InFury[weapon])
		radmult++;
	new AmountHealed;
	
	if(TF2_IsPlayerInCondition(client, TFCond:0))
	{
		SpinupDelay[client] += 0.1;
		
		new Float:Pos1[3];
		GetClientAbsOrigin(client, Pos1);
		if(SpinupDelay[client] >= 1.0)
		{
			for(new i = 1; i < MaxClients; i++)
			{
				if(IsValidClient(i) && GetClientTeam(i) == GetClientTeam(client))
				{
					//Gets the position of the valid player in question
					new Float:Pos2[3];
					GetClientAbsOrigin(i, Pos2);
					
					//Gets the distance between the Heavy and the client
					new Float:distance = GetVectorDistance(Pos1, Pos2);
					
					//A check to remove InRadius
					//Used to remove particles
					if(distance > DispenserMinigun_Radius[weapon] * radmult)
					{
						if(LastHealer[i] == client && DispenserMinigun_InRadius[i])
							DispenserMinigun_InRadius[i] = false;
						
						if(HealBeams[client][i] > -1)
						{
							KillDualParticle(client, i);
							HealBeams[client][i] = -1;
						}
					}
					
					if(distance <= DispenserMinigun_Radius[weapon] * radmult)
					{
						//Attaches heal beams to players who step in the radius
						if(!DispenserMinigun_InRadius[i])
						{
							DispenserMinigun_InRadius[i] = true;
							
							if(i != client && !TF2_IsPlayerInCondition(i, TFCond_Cloaked) && 
								((HealBeams[client][i] < 0) || (HealBeams[i][client] < 0)) && !DispenserMinigun[GetActiveWeapon(i)])
							{
								if(TF2_GetClientTeam(i) == TFTeam_Blue)
									HealBeams[client][i] = AttachDualParticle(client, i, "medicgun_beam_blue");
								if(TF2_GetClientTeam(i) == TFTeam_Red)
									HealBeams[client][i] = AttachDualParticle(client, i, "medicgun_beam_red");
								
							}
						}
						if(DispenserMinigun_InFury[weapon])
							TF2_AddCondition(i, TFCond:20, 0.2, client);
						
						//Helps the system track who did the healing
						LastHealer[i] = client;
					}
				}
			}
		}
	}
	else if(!TF2_IsPlayerInCondition(client, TFCond:0))
	{
		if(SpinupDelay[client] > 0.0)
		{
			DispenserMinigun_InRadius[client] = false;
			KillAllDualParticles(client);
			for (new i = 0; i < sizeof(HealBeams[]); i++)
				HealBeams[client][i] = -1;
			
			SpinupDelay[client] = 0.0;
		}
	}
	
	//Adds the amount the Heavy healed to the rage meter
	if(!DispenserMinigun_InFury[weapon])
		DispenserMinigun_Charge[weapon] += AmountHealed;
	if(DispenserMinigun_Charge[weapon] > DispenserMinigun_MaxCharge[weapon])
		DispenserMinigun_Charge[weapon] = DispenserMinigun_MaxCharge[weapon];
	
	//For dealing with the Dispensing Fury triggers and actually displaying rage with the in-game Rage meter
	if(DispenserMinigun_MaxCharge[weapon] > 0.0)
	{
		if(GetEntProp(client, Prop_Send, "m_bRageDraining") && !DispenserMinigun_InFury[weapon])
		{
			//PrintToChat(client, "this guy dispensing");
			DispenserMinigun_Charge[weapon] = 0.0;
			DispenserMinigun_InFury[weapon] = true; //Tells the system this guy is dispensing like mad
			DispenserMinigun_Dur[weapon] = GetEngineTime(); //For timing
			
			DispenserMinigun_InRadius[client] = false;
		}
	}
	
	//Deals with pulling the player out of mad dispensing when they're done
	if(DispenserMinigun_InFury[weapon] && GetEngineTime() > DispenserMinigun_Dur[weapon] + DispenserMinigun_FuryDur[weapon])
	{
		DispenserMinigun_InFury[weapon] = false; //Signals that the Heavy is no longer furious
							//Allows him to gain rage again
		
		DispenserMinigun_InRadius[client] = false;
		TF2_RemoveCondition(client, TFCond:20);
	}
	
	//Finally, resets the delay on this mf
	LastTick[client] = GetEngineTime();
}

public OnEntityCreated(ent, const String:name[])
{
	if(ent < 0 || ent > 2048)
		return;

	if (!StrContains(name, "tf_weapon_")) 
		CreateTimer(0.3, OnWeaponSpawned, EntIndexToEntRef(ent));
}

public Action:OnWeaponSpawned(Handle:timer, any:ref)
{
	new ent = EntRefToEntIndex(ref);
	if(!IsValidEntity(ent) || ent == -1)
		return;
		
	new owner = ReturnOwner(ent);
	MaxAmmo[ent] = GetAmmo_Weapon(owner, ent);
}

public OnEntityDestroyed(ent)
{
	if(ent < 0 || ent > 2048)
		return;
		
	DispenserMinigun[ent] = false;
	DispenserMinigun_Radius[ent] = 0.0;
	DispenserMinigun_MaxCharge[ent] = 0.0;
	DispenserMinigun_Charge[ent] = 0.0;
	DispenserMinigun_FuryDur[ent] = 0.0;
	DispenserMinigun_InFury[ent] = false;
	
	DispenserMinigun_Heal[ent] = false;
	DispenserMinigun_HealRate[ent] = 0.0;
	
	DispenserMinigun_Ammo[ent] = false;
	DispenserMinigun_DispenseRate[ent] = 0.0;
	
	ReduceHealingSpinning[ent] = false;
	ReduceHealingSpinning_Amount[ent] = 0.0;
	
	MaxAmmo[ent] = 0;
}

AttachDualParticle(iClient, iTarget, String:particleType[])
{
	g_iParticleEntityStart[iClient][iTarget] = CreateEntityByName("info_particle_system");
	g_iParticleEntityEnd[iClient][iTarget] = CreateEntityByName("info_particle_system");
	if (IsValidEdict(g_iParticleEntityStart[iClient][iTarget]))
	{ 
	new String:tName[128];
	Format(tName, sizeof(tName), "target%i", iClient);
	DispatchKeyValue(iClient, "targetname", tName);
	
	new String:cpName[128];
	Format(cpName, sizeof(cpName), "target%i", iTarget);
	DispatchKeyValue(iTarget, "targetname", cpName);
	
	//--------------------------------------
	new String:cp2Name[128];
	Format(cp2Name, sizeof(cp2Name), "tf2particle%i", iTarget);
	
	DispatchKeyValue(g_iParticleEntityEnd[iClient][iTarget], "targetname", cp2Name);
	DispatchKeyValue(g_iParticleEntityEnd[iClient][iTarget], "parentname", cpName);
	
	SetVariantString(cpName);
	AcceptEntityInput(g_iParticleEntityEnd[iClient][iTarget], "SetParent");
	
	SetVariantString("flag");
	AcceptEntityInput(g_iParticleEntityEnd[iClient][iTarget], "SetParentAttachment");
	//-----------------------------------------------
	
	
	DispatchKeyValue(g_iParticleEntityStart[iClient][iTarget], "targetname", "tf2particle");
	DispatchKeyValue(g_iParticleEntityStart[iClient][iTarget], "parentname", tName);
	DispatchKeyValue(g_iParticleEntityStart[iClient][iTarget], "effect_name", particleType);
	DispatchKeyValue(g_iParticleEntityStart[iClient][iTarget], "cpoint1", cp2Name);
	
	DispatchSpawn(g_iParticleEntityStart[iClient][iTarget]);
	
	SetVariantString(tName);
	AcceptEntityInput(g_iParticleEntityStart[iClient][iTarget], "SetParent");
	
	SetVariantString("flag");
	AcceptEntityInput(g_iParticleEntityStart[iClient][iTarget], "SetParentAttachment");
	
	//The particle is finally ready
	ActivateEntity(g_iParticleEntityStart[iClient][iTarget]);
	AcceptEntityInput(g_iParticleEntityStart[iClient][iTarget], "start");
	}
} 

public KillDualParticle(iClient, iTarget)
{
	if (g_iParticleEntityStart[iClient][iTarget] > 0)
		AcceptEntityInput(g_iParticleEntityStart[iClient][iTarget], "kill");
	if (g_iParticleEntityEnd[iClient][iTarget] > 0)
		AcceptEntityInput(g_iParticleEntityEnd[iClient][iTarget], "kill");
	
	g_iParticleEntityStart[iClient][iTarget] = 0;
	g_iParticleEntityEnd[iClient][iTarget] = 0;
}

KillAllDualParticles(iClient)
{
	for (new iTarget =0;iTarget < MaxClients;iTarget++)
	{
		KillDualParticle(iClient, iTarget);
		KillDualParticle(iTarget, iClient);
	}
}

new Float:HealFrac[MAXPLAYERS + 1];

public MRESReturn OnPlayerTakeHealth(client, Handle:hReturn, Handle:hParams)
{
	new weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	
	new Float:flHealth = DHookGetParam(hParams, 1);
	
	if(weapon < 0 || weapon > 2048)
		return MRES_Ignored;
	
	if(!ReduceHealingSpinning[weapon])
		return MRES_Ignored;
	
	if(!TF2_IsPlayerInCondition(client, TFCond:0))
		return MRES_Ignored;
	
	new Float:flHealMult = 1.0 - ReduceHealingSpinning_Amount[weapon];
	
	HealFrac[client] += flHealth * flHealMult;
	
	if (HealFrac[client] > 1.0) {
		new Float:flHealAmount = float(RoundToFloor(HealFrac[client]));
		HealFrac[client] -= flHealAmount;
		
		DHookSetParam(hParams, 1, flHealAmount);
	} else {
		DHookSetParam(hParams, 1, 0.0);
	}
	return MRES_ChangedHandled;
}
