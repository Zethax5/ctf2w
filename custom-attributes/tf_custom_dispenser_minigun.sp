/*

Created by: Zethax
Document created on: Wednesday, January 9th, 2019
Last edit made on: Tuesday, January 29th, 2019
Current version: v1.1

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
				
		Replenishes ammo to allies within the radius at a rate of X ammo per second
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
#include <sdktools>
#include <zethax>
#include <tf2attributes>

#define PLUGIN_NAME "Dispenser Minigun"
#define PLUGIN_DESC "Creates the attributes associated with the dispenser minigun"
#define PLUGIN_AUTH "Zethax"
#define PLUGIN_VERS "v1.1"

#define SOUND_DISPENSE "weapons/dispenser_heal.wav"

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
	
	for(new i = 1; i < MaxClients; i++)
	{
		if(!IsValidClient(i))
			continue;
		
		OnClientPutInServer(i);
	}
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_PostThink, OnClientPostThink);
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

//Tracks last time a player performed a healing tick
//Used to reduce the load on the server heavily
new Float:LastTick[MAXPLAYERS + 1];

//Tracks maximum ammo on a weapon
//Used for ammo restoration
new MaxAmmo[2049];

//Used for tracking whether or not a Heavy healed a player last tick
new LastHealer[MAXPLAYERS + 1];

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
	
	if(!DispenserMinigun[weapon])
		return;
		
	new Float:rage = (DispenserMinigun_Charge[weapon] / DispenserMinigun_MaxCharge[weapon]) * 100.0;
	SetEntPropFloat(client, Prop_Send, "m_flRageMeter", rage);
	
	if(GetEngineTime() > LastTick[client] + 1.0 && !DispenserMinigun_InFury[weapon])
		DispenserMinigun_PostThink(client, weapon);
	else if(GetEngineTime() > LastTick[client] + 0.5 && DispenserMinigun_InFury[weapon])
		DispenserMinigun_PostThink(client, weapon);
}

static void DispenserMinigun_PostThink(client, weapon)
{
	new Float:radmult = 1.0;
	if(DispenserMinigun_InFury[weapon])
		radmult++;
	new AmountHealed;
	
	//new buttons = GetClientButtons(client);
	if(TF2_IsPlayerInCondition(client, TFCond:0))
	{
		if(ReduceHealingSpinning[weapon])
		{
			TF2Attrib_SetByName(weapon, "reduced_healing_from_medics", 1.0 - ReduceHealingSpinning_Amount[weapon]); //reduce healing from medics
			TF2Attrib_SetByName(weapon, "health from packs decreased", 1.0 - ReduceHealingSpinning_Amount[weapon]); //reduce healing from medkits
		}
		
		TF2_AddCondition(client, TFCond:20, 1.0);
		new Float:Pos1[3];
		GetClientAbsOrigin(client, Pos1);
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
				//Used for sounds
				if(distance > DispenserMinigun_Radius[weapon] * radmult &&
				    LastHealer[i] == client && DispenserMinigun_InRadius[i])
				{
					DispenserMinigun_InRadius[i] = false;
				}
				
				if(distance <= DispenserMinigun_Radius[weapon] * radmult)
				{
					
					//Gotta check to see if the healing target is under max health first
					if(GetClientHealth(i) < GetClientMaxHealth(i) && i != client)
					{
						AmountHealed += RoundFloat(GetClientMaxHealth(i) * DispenserMinigun_HealRate[weapon]);
						new Float:position[3];
						position[2] += 75;
						if(TF2_GetClientTeam(i) == TFTeam_Blue)
							SpawnParticle(i, "healthgained_blu", position);
						if(TF2_GetClientTeam(i) == TFTeam_Red)
							SpawnParticle(i, "healthgained_red", position);
					}
					
					if(DispenserMinigun_Heal[weapon])
					{
						if(TF2_GetPlayerClass(i) != TFClass_Heavy)
							HealPlayer(client, i, RoundFloat(GetClientMaxHealth(i) * DispenserMinigun_HealRate[weapon]), _);
						else if(TF2_GetPlayerClass(i) == TFClass_Heavy)
						{
							new wep = GetActiveWeapon(i);
							//Should the player have reduced healing while spun up
							if(i != client && ReduceHealingSpinning[wep] && TF2_IsPlayerInCondition(i, TFCond:0))
								HealPlayer(client, i, RoundToFloor((GetClientMaxHealth(i) * DispenserMinigun_HealRate[weapon]) * (1.0 - ReduceHealingSpinning_Amount[wep])), _); //reduced healing
							else
								HealPlayer(client, i, RoundToFloor(GetClientMaxHealth(i) * DispenserMinigun_HealRate[weapon]), _); //defaults to regular healing amount
						}
					}
					//Emits healing sound to players that step into the radius
					if(!DispenserMinigun_InRadius[i])
					{
						DispenserMinigun_InRadius[i] = true;
						if(i == client)
							EmitSoundToAll(SOUND_DISPENSE, client);
					}
					if(DispenserMinigun_InFury[weapon])
						TF2_AddCondition(i, TFCond:20, 0.6, client);
					
					//If the weapon is also set to dispense ammo, this executes
					if(DispenserMinigun_Ammo[weapon])
					{
						for(new j = 0; j <= 3 ; j++)
						{
							new wep = GetPlayerWeaponSlot(i, j);
							if(wep == -1) continue;
							new ammo = RoundToFloor(MaxAmmo[wep] * DispenserMinigun_DispenseRate[weapon]);
							new ammotype = GetEntProp(wep, Prop_Data, "m_iPrimaryAmmoType");
							
							//PrintToChat(client, "ammo count stored as %i", MaxAmmo[wep]);
							
							GivePlayerAmmo(i, ammo, ammotype);
							//PrintToChat(client, "ammo dispensed");
						}
					}
					
					//Helps the system track who did the healing
					LastHealer[i] = client;
				}
			}
		}
	}
	else if(!TF2_IsPlayerInCondition(client, TFCond:0))
	{
		if(DispenserMinigun_InRadius[client])
		{
			DispenserMinigun_InRadius[client] = false;
			StopSound(client, SNDCHAN_AUTO, SOUND_DISPENSE);
		}
		
		if(ReduceHealingSpinning[weapon])
		{
			TF2Attrib_RemoveByName(weapon, "health from packs decreased"); //reduce healing from packs
			//TF2Attrib_RemoveByName(weapon, "health from healers reduced"); //reduce healing from dispensers
			TF2Attrib_RemoveByName(weapon, "reduced_healing_from_medics"); //reduce healing from medics
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
			
			StopSound(client, SNDCHAN_AUTO, SOUND_DISPENSE);
			DispenserMinigun_InRadius[client] = false;
		}
	}
	
	//Deals with pulling the player out of mad dispensing when they're done
	if(DispenserMinigun_InFury[weapon] && GetEngineTime() > DispenserMinigun_Dur[weapon] + DispenserMinigun_FuryDur[weapon])
	{
		DispenserMinigun_InFury[weapon] = false; //Signals that the Heavy is no longer furious
							//Allows him to gain rage again
		StopSound(client, SNDCHAN_AUTO, SOUND_DISPENSE);
		DispenserMinigun_InRadius[client] = false;
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
