/*

Created by: Zethax
Document created on: January 17th, 2019
Last edit made on: January 18th, 2019
Current version: v0.0

Attributes in this pack:
 None so far

*/

#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2>
#include <sdkhooks>
#include <sdktools>
#include <cw3_attributes>
#include <zethax>

#define PLUGIN_NAME "tf_custom_booster_uber"
#define PLUGIN_AUTH "Zethax"
#define PLUGIN_DESC "Adds in a custom ubercharge"
#define PLUGIN_VERS "v0.0"

#define PARTICLE_SHIELD ""
#define SOUND_BOOSTERUBER "weapons/fx/rics/arrow_impact_crossbow_heal.wav"

public Plugin:my_info = {
	
	name	    = PLUGIN_NAME,
	author	    = PLUGIN_AUTH,
	description = PLUGIN_DESC,
	version	    = PLUGIN_VERS,
	url	    = ""
};

public OnPluginStart() {
 
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("post_inventory_application", OnTouchResupply);
	
	for(new i = 1 ; i < MaxClients ; i++)
	{
		if(!IsValidClient(i))
			continue;

		OnClientPutInServer(i);
	}
}

public OnMapStart() {
	
	PrecacheSound(SOUND_BOOSTERUBER, true);
	PrecacheParticle(PARTICLE_SHIELD);
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_PreThink, OnClientPreThink);
	SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
}

new bool:BoosterUber[2049];
new Float:BoosterUber_Drain[2049];
new Float:BoosterUber_Overheal[2049];
new Float:BoosterUber_ShieldDur[2049];
new Float:BoosterUber_Dur[MAXPLAYERS + 1];
new Float:BoosterUber_Protection[2049];
new BoosterUber_Particle[MAXPLAYERS + 1];
new bool:Shielded[MAXPLAYERS + 1];

new Float:LastTick[MAXPLAYERS + 1];

public Action:CW3_OnAddAttribute(slot, client, const String:attrib[], const String:plugin[], const String:value[], bool:whileActive)
{
	new Action:action;
	if(!StrEqual(plugin, PLUGIN_NAME))
		return;
	
	new weapon = GetPlayerWeaponSlot(client, slot);
	if(weapon < 0 || weapon > 2048)
		return;
	
	if(StrEqual(attrib, "ubercharge is booster shot"))
	{
		new String:values[4][10];
		ExplodeString(value, " ", values, sizeof(values), sizeof(values[]));
		
		BoosterUber_Drain[weapon] = StringToFloat(values[0]);
		BoosterUber_Overheal[weapon] = StringToFloat(values[1]);
		BoosterUber_ShieldDur[weapon] = StringToFloat(values[2]);
		BoosterUber_Protection[weapon] = StringToFloat(values[3]);
		
		BoosterUber[weapon] = true;
		action = Plugin_Handled;
	}
	
	return action;
}

public OnClientPreThink(client)
{
	if(!IsValidClient(client))
		return;
		
	new weapon = GetActiveWeapon(client);
	if(weapon < 0 || weapon > 2048)
		return;
	
	if(GetEngineTime() > LastTick[client] + 0.1)
		BoosterUber_PreThink(client, weapon);
}

static void BoosterUber_PreThink(client, weapon);
{
	new buttons = GetClientButtons(client);
	new Float:ubercharge = GetEntPropFloat(weapon, Prop_Send, "m_flChargeLevel");
	
	if(GetEngineTime() > BoosterUber_Dur[client] + BoosterUber_ShieldDur[client] && Shielded[client])
	{
		CreateTimer(0.0, RemoveParticle, BoosterUber_Particle[client]);
		BoosterUber_Dur[client] = 0.0;
		BoosterUber_ShieldDur[client] = 0.0;
		BoosterUber_Protection[client] = 0.0;
		BoosterUber_Particle[client] = 0;
		Shielded[client] = false;
	}
	
	if(!BoosterUber[weapon])
		return;
	
	if((buttons & IN_ATTACK2) == IN_ATTACK2)
	{
		if(ubercharge >= BoosterUber_Drain[weapon] && IsValidClient(GetMediGunPatient(client)))
		{
			new patient = GetMediGunPatient(client);
			
			SetEntityHealth(patient, GetClientMaxHealth(patient) * BoosterUber_Overheal[weapon]);
			BoosterUber_Dur[patient] = GetEngineTime();
			BoosterUber_ShieldDur[patient] = BoosterUber_ShieldDur[weapon];
			BoosterUber_Protection[patient] = BoosterUber_Protection[weapon];
			BoosterUber_Particle[patient] = AttachParticle(patient, PARTICLE_SHIELD, BoosterUber_ShieldDur[weapon]);
			
			ubercharge -= BoosterUber_Drain[weapon];
			SetEntPropFloat(weapon, Prop_Send, "m_flChargeLevel", ubercharge);
		}
	}
	
	LastTick[client] = GetEngineTime();
}

public Action:OnTakeDamageAlive(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	if(attacker && victim)
	{
		if(Shielded[victim])
		{
			damage *= 1.0 - BoosterUber_Protection[victim];
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(attacker && victim)
	{
		if(Shielded[victim])
		{
			CreateTimer(0.0, RemoveParticle, BoosterUber_Particle[victim]);
			BoosterUber_Dur[victim] = 0.0;
			BoosterUber_ShieldDur[victim] = 0.0;
			BoosterUber_Protection[victim] = 0.0;
			BoosterUber_Particle[victim] = 0;
			Shielded[victim] = false;
		}
	}
	return Plugin_Continue;
}

public Action:OnTouchResupply(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsValidClient(client) && Shielded[client])
	{
		CreateTimer(0.0, RemoveParticle, BoosterUber_Particle[client]);
		BoosterUber_Dur[client] = 0.0;
		BoosterUber_ShieldDur[client] = 0.0;
		BoosterUber_Protection[client] = 0.0;
		BoosterUber_Particle[client] = 0;
		Shielded[client] = false;
	}
}

public OnEntityDestroyed(ent)
{
	if(ent < 0 || ent > 2048)
		return;
	
	BoosterUber[ent] = false;
	BoosterUber_Drain[ent] = 0.0;
	BoosterUber_Overheal[ent] = 0.0;
	BoosterUber_ShieldDur[ent] = 0.0;
	BoosterUber_Protection[ent] = 0.0;
}
