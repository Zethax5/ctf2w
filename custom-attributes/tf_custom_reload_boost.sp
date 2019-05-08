/*

Created by: Zethax
Document created on: March 12th, 2019
Last edit made on: March 12th, 2019
Current version: v1.0

Attributes in this pack:
	-> "build reload boost on damage"
		1) Maximum reload boost that can be obtained
		2) Maximum damage required to obtain max reload boost
		3) Max clip size of the weapon

*/

#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2>
#include <sdkhooks>
#include <sdktools>
#include <cw3-attributes>
#include <zethax>
#include <tf2attributes>

#define PLUGIN_NAME "tf_custom_reload_boost"
#define PLUGIN_AUTH "Zethax"
#define PLUGIN_DESC "Adds an attribute which increases reload speed when dealing damage"
#define PLUGIN_VERS "v1.0"

public Plugin:my_info = {
  
	name        = PLUGIN_NAME,
	author      = PLUGIN_AUTH,
	description = PLUGIN_DESC,
	version     = PLUGIN_VERS,
	url         = ""
};

public OnPluginStart() {
 
	for(new i = 1 ; i < MaxClients ; i++)
	{
		if(!IsValidClient(i))
			continue;
  
		OnClientPutInServer(i);
	}
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
	SDKHook(client, SDKHook_PreThink, OnClientPreThink);
}

new bool:ReloadBoost[2049];
new Float:ReloadBoost_Charge[2049];
new Float:ReloadBoost_OldCharge[2049];
new Float:ReloadBoost_MaxCharge[2049];
new Float:ReloadBoost_MaxBoost[2049];
new ReloadBoost_MaxClip[2049];

new Float:LastTick[MAXPLAYERS + 1];

public Action:CW3_OnAddAttribute(slot, client, const String:attrib[], const String:plugin[], const String:value[], bool:whileActive)
{
	new Action:action;
	if(!StrEqual(plugin, PLUGIN_NAME))
  		return action;
	
	new weapon = GetPlayerWeaponSlot(client, slot);
	if(weapon < 0 || weapon > 2048)
		return action;
	
	if(StrEqual(attrib, "build reload boost on damage"))
	{
		new String:values[3][10];
		ExplodeString(value, " ", values, sizeof(values), sizeof(values[]));
		
		ReloadBoost_MaxBoost[weapon] = StringToFloat(values[0]);
		ReloadBoost_MaxCharge[weapon] = StringToFloat(values[1]);
		if(strlen(values[2]))
			ReloadBoost_MaxClip[weapon] = StringToInt(values[2]);
		else
			ReloadBoost_MaxClip[weapon] = GetClip_Weapon(weapon);
		
		ReloadBoost[weapon] = true;
		action = Plugin_Handled;
	}
	
	return action;
}

public Action:OnTakeDamageAlive(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	new Action:action = Plugin_Continue;
	
	if(weapon > -1 && ReloadBoost[weapon])
	{
		ReloadBoost_Charge[weapon] += damage;
		if (ReloadBoost_Charge[weapon] > ReloadBoost_MaxCharge[weapon])
			ReloadBoost_Charge[weapon] = ReloadBoost_MaxCharge[weapon];
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
	
	if(!ReloadBoost[weapon])
		return;
	
	if(GetEngineTime() >= LastTick[client] + 0.1)
		ReloadBoost_PreThink(client, weapon);
}

void ReloadBoost_PreThink(client, weapon)
{
	new Float:boost = ReloadBoost_MaxBoost[weapon] * (ReloadBoost_Charge[weapon] / ReloadBoost_MaxCharge[weapon]);
	
	if(ReloadBoost_OldCharge[weapon] != ReloadBoost_Charge[weapon])
	{
		TF2Attrib_SetByName(weapon, "Reload time decreased", 1.0 - boost);
		
		ReloadBoost_OldCharge[weapon] = ReloadBoost_Charge[weapon];
	}
	if(GetClip_Weapon(weapon) == ReloadBoost_MaxClip[weapon])
		ReloadBoost_Charge[weapon] = 0.0;
	
	LastTick[client] = GetEngineTime();
}

public OnEntityDestroyed(ent)
{
    if(ent < 0 || ent > 2048)
        return;
	
	ReloadBoost[ent] = false;
	ReloadBoost_Charge[ent] = 0.0;
	ReloadBoost_MaxCharge[ent] = 0.0;
	ReloadBoost_OldCharge[ent] = 0.0;
	ReloadBoost_MaxBoost[ent] = 0.0;
	ReloadBoost_MaxClip[ent] = 0;
}
