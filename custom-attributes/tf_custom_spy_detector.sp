/*

Created by: Zethax
Document created on: February 28th, 2019
Last edit made on: April 23rd, 2019
Current version: v1.0
Attributes in this pack:
	- "detection field while active"
		1) Radius of detection field
		2) Damage vulnerability multiplier
		3) Duration of the detection after leaving the field

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
#define PLUGIN_VERS "v1.0"

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
	SDKHook(client, SDKHook_PreThink, OnClientPreThink);
	SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
	SDKHook(client, SDKHook_SetTransmit, OnTransmit);
}

new bool:Detector[2049];
new Float:Detector_Radius[2049];
new Float:Detector_DmgVuln[2049];
new Float:Detector_Duration[2049];

new bool:Detected[MAXPLAYERS + 1];
new Float:Detected_Dur[MAXPLAYERS + 1];
new Float:Detected_DmgVuln[MAXPLAYERS + 1];
new Float:Detected_MaxDur[MAXPLAYERS + 1];
new Detected_Inflictor[MAXPLAYERS + 1];

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

public Action:OnTakeDamageAlive(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damageCustom)
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

public OnClientPreThink(client)
{
	if(!IsValidClient(client))
		return;
	
	if(Detected[client])
	{
		new detector = Detected_Inflictor[client];
		if(GetEngineTime() >= Detected_Dur[client] + Detected_MaxDur[client] || GetEntProp(detector, Prop_Data, "m_iAmmo", 4, 3) <= 0)
			RemoveDetection(client);
	}
	
	new weapon = GetActiveWeapon(client);
	if(weapon < 0 || weapon > 2048)
		return;
	
	if(!Detector[weapon])
		return;
	
	if(GetEngineTime() >= LastTick[client] + 0.1)
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

public Action:OnTransmit(entity, client)
{
	if(0 < client <= MaxClients && 0 < entity <= MaxClients && Detected[client])
	{
		SetEntProp(entity, Prop_Send, "m_bGlowEnabled", 0);
		new weapon = GetActiveWeapon(entity);
		if(weapon > -1 && weapon < 2049 && Detector[weapon])
		{
			new Float:clientPos[3];
			new Float:targetPos[3];
			GetClientAbsOrigin(client, clientPos);
			GetClientAbsOrigin(entity, targetPos);
			if(GetVectorDistance(clientPos, targetPos) <= Detector_Radius[weapon])
				SetEntProp(entity, Prop_Send, "m_bGlowEnabled", 1);
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
	if(Detector[weapon] && metal > 0)
	{
		//now begins some intense stuff
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
					Detected_Inflictor[target] = client;
					SetEntProp(target, Prop_Send, "m_bGlowEnabled", 1);
				}
			}
		}
	}
	
	LastTick[client] = GetEngineTime();
}

