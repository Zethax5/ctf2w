/*

Created by: Zethax
Document created on: January 11th, 2019
Last edit made on: January 11th, 2019
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

#define PLUGIN_NAME "tf_custom_earthquake"
#define PLUGIN_AUTH "Zethax"
#define PLUGIN_DESC "Adds in 2 attributes associated with creating earthquakes."
#define PLUGIN_VERS "v0.0"

public Plugin:my_info = {
  
	name        = PLUGIN_NAME,
	author      = PLUGIN_AUTH,
	description = PLUGIN_DESC,
	version     = PLUGIN_VERS,
	url         = ""
};

public OnPluginStart() {
 	
	HookEvent("rocket_jump_landed", OnBlastJumpLanded);
	HookEvent("sticky_jump_landed", OnBlastJumpLanded);
	
	for(new i = 1 ; i < MaxClients ; i++)
	{
		if(!IsValidClient(i))
			continue;
  
		OnClientPutInServer(i);
	}
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

new bool:Earthquake[MAXPLAYERS + 1][MAXSLOTS + 1];
new Float:Earthquake_Damage[MAXPLAYERS + 1][MAXSLOTS + 1];
new Float:Earthquake_Radius[MAXPLAYERS + 1][MAXSLOTS + 1];
new Float:Earthquake_Falloff[MAXPLAYERS + 1][MAXSLOTS + 1];
new Float:Earthquake_KnockbackMult[MAXPLAYERS + 1][MAXSLOTS + 1];
new bool:Earthquake_WhileActive[MAXPLAYERS + 1][MAXSLOTS + 1];
new bool:Earthquake_TriggerFromFallDamage[MAXPLAYERS + 1][MAXSLOTS + 1];

public Action:CW3_OnAddAttribute(slot, client, const String:attrib[], const String:plugin[], const String:value[], bool:whileActive)
{
	new Action:action;
	if(!StrEqual(plugin, PLUGIN_NAME))
  		return action;
		
	if(StrEqual(attrib, "earthquake on blast jump land"))
	{
		new String:values[4][10];
		ExplodeString(value, " ", values, sizeof(values), sizeof(values[]));
		
		Earthquake_Radius[client][slot] = StringToFloat(values[0]);
		Earthquake_Damage[client][slot] = StringToFloat(values[1]);
		Earthquake_Falloff[client][slot] = StringToFloat(values[2]);
		Earthquake_KnockbackMult[client][slot] = StringToFloat(values[3]);
		Earthquake_WhileActive[client][slot] = whileActive;
		
		Earthquake[client][slot] = true;
		action = Plugin_Handled;
	}
	else if(StrEqual(attrib, "earthquake on fall damage"))
	{
		Earthquake_Radius[client][slot] = StringToFloat(values[0]);
		Earthquake_Damage[client][slot] = StringToFloat(values[1]);
		Earthquake_Falloff[client][slot] = StringToFloat(values[2]);
		Earthquake_KnockbackMult[client][slot] = StringToFloat(values[3]);
		Earthquake_WhileActive[client][slot] = whileActive;
		
		Earthquake[client][slot] = true;
		Earthquake_TriggerOnFallDamage[client][slot] = true;
		action = Plugin_Handled;
	}
	
	return action;
}

public Action:OnBlastJumpLanded(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(!IsValidClient(client))
		return Plugin_Continue;
	
	new primary = 1;
	new slot = GetClientSlot
}

public CW3_OnWeaponRemoved(slot, client)
{
	Earthquake[client][slot] = false;
	Earthquake_Radius[client][slot] = 0.0;
	Earthquake_Damage[client][slot] = 0.0;
	Earthquake_Falloff[client][slot] = 0.0;
	Earthquake_KnockbackMult[client][slot] = 0.0;
	Earthquake_WhileActive[client][slot] = false;
	Earthquake_TriggerOnFallDamage[client][slot] = false;
}

stock CreateEarthquake(client)
{
	
}

stock GetClientSlot(client)
{
	if(!Client_IsValid(client)) return -1;
	if(!IsPlayerAlive(client)) return -1;
	
	new slot = GetWeaponSlot(client, Client_GetActiveWeapon(client));
	return slot;
}
stock GetWeaponSlot(client, weapon)
{
	if(!Client_IsValid(client)) return -1;
	
	for(new i = 0; i < MAXSLOTS; i++)
	{
		if(weapon == GetPlayerWeaponSlot(client, i))
		{
			return i;
		}
	}
	return -1;
}
