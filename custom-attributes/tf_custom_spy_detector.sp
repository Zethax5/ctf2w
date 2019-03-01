/*

Created by: Zethax
Document created on: February 28th, 2019
Last edit made on: February 28th, 2019
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
#include <cw3-attributes>
#include <zethax>

#define PLUGIN_NAME "tf_custom_spy_detector"
#define PLUGIN_AUTH "Zethax"
#define PLUGIN_DESC "Adds an attribute that can debuff enemies while active"
#define PLUGIN_VERS "v0.0"

public Plugin:my_info = {
  
	name        = PLUGIN_NAME,
	author      = PLUGIN_AUTH,
	description = PLUGIN_DESC,
	version     = PLUGIN_VERS,
	url         = ""
};

public OnPluginStart() {
	
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("post_inventory_application", OnInventoryApplication);
 
	for(new i = 1 ; i < MaxClients ; i++)
	{
		if(!IsValidClient(i))
			continue;
  
		OnClientPutInServer(i);
	}
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_Think, OnClientThink);
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

new bool:Detector[2049];
new Float:Detector_Radius[2049];
new Float:Detector_DmgVuln[2049];
new Float:Detector_Duration[2049];

new bool:Detected[MAXPLAYERS + 1];
new Float:Detected_Dur[MAXPLAYERS + 1];
new Float:Detected_DmgVuln[MAXPLAYERS + 1];
new Float:Detected_MaxDur[MAXPLAYERS + 1];

new Float:LastTick[MAXPLAYERS + 1];

public Action:CW3_OnAddAttribute(slot, client, const String:attrib[], const String:plugin[], const String:value[], bool:whileActive)
{
	new Action:action;
	if(!StrEqual(plugin, PLUGIN_NAME))
  		return action;
	
	new weapon = GetPlayerWeaponSlot(client, slot);
	if(weapon < 0 || weapon > 2048)
		return action;
		
	if(StrEqual(attrib, "detection field while active"))
	{
		new String:values[3][10];
		ExplodeString(value, " ", values, sizeof(values), sizeof(values[]));
		
		Detector_Radius[weapon] = StringToFloat(values[0]);
		Detector_DmgVuln[weapon] = StringToFloat(values[1]);
		Detector_Duration[weapon] = StringToFloat(values[2]);
		
		Detector[weapon] = true;
		action = Plugin_Handled;
	}
	
	return action;
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damageCustom)
{
	if(victim)
	{
		if(Detected[victim])
		{
			damage *= 1.0 + Detected_DmgVuln[victim];
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

public OnClientThink(client)
{
	if(!IsValidClient(client))
		return;
	
	if(Detected[client] && GetEngineTime() >= Detected_Dur[client] + Detected_MaxDur[client])
		RemoveDetection(client);
	
	new weapon = GetActiveWeapon(client);
	if(weapon < 0 || weapon > 2048)
		return;
	
	if(Detector[weapon] && GetEngineTime() >= LastTick[client] + 0.1)
		Detector_Think(client, weapon);
}

public Action:OnInventoryApplication(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client < 0 || client > MAXPLAYERS)
		return Plugin_Continue;
	
	if(Detected[client])
		RemoveDetection(client);
	
	return Plugin_Continue;
}

public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iVictim = GetClientOfUserId(GetEventInt(event, "userid"));
	if(iVictim)
	{
		if(Detected[iVictim])
		{
			RemoveDetection(iVictim);
		}
	}
	
	return Plugin_Continue;
}

public OnEntityDestroyed(ent)
{
	if(ent < 0 || ent > 2048)
		return;
	
	Detector[ent] = false;
	Detector_Radius[ent] = 0.0;
	Detector_Duration[ent] = 0.0;
	Detector_DmgVuln[ent] = 0.0;
}

void RemoveDetection(client)
{
	Detected[client] = false;
	Detected_Dur[client] = 0.0;
	Detected_MaxDur[client] = 0.0;
	Detected_DmgVuln[client] = 0.0;
	SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0);
}

void Detector_Think(client, weapon)
{
	new metal = GetEntProp(client, Prop_Data, "m_iAmmo", 4, 3);
	if(metal > 0)
	{
		//now begins some intense shit
		//this indexes all players on the server and checks for distance from the player
		//reasons why we only do this about ten times a second
		
		new Float:attackerPos[3];
		GetClientAbsOrigin(client, attackerPos);
		new Float:targetPos[3];
		
		for (new target = 1; target < MaxClients; target++)
		{
			if(IsValidClient(target) && IsPlayerAlive(target) && GetClientTeam(target) != GetClientTeam(client))
			{
				GetClientAbsOrigin(target, targetPos);
				if(GetVectorDistance(attackerPos, targetPos) <= Detector_Radius[weapon])
				{
					Detected[target] = true;
					Detected_Dur[target] = GetEngineTime();
					Detected_MaxDur[target] = Detector_Duration[weapon];
					Detected_DmgVuln[target] = Detector_DmgVuln[weapon];
					SetEntProp(client, Prop_Send, "m_bGlowEnabled", 1);
				}
			}
		}
	}
	
	LastTick[client] = GetEngineTime();
}