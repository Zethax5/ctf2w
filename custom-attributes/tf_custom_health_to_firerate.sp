/*

Created by: Zethax
Document created on: March 27th, 2019
Last edit made on: March 27th, 2019
Current version: v1.0

Attributes in this pack:
	-> "fire rate increases as health decreases"
		1) Maximum fire rate at 1 hp

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

#define PLUGIN_NAME "tf_custom_health_to_firerate"
#define PLUGIN_AUTH "Zethax"
#define PLUGIN_DESC "Adds an attribute which increases fire rate as health decreases"
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
	SDKHook(client, SDKHook_PreThink, OnClientPreThink);
}

new bool:HealthToFireRate[2049];
new Float:HealthToFireRate_MaxMult[2049];

new Float:LastTick[MAXPLAYERS + 1];

public Action:CW3_OnAddAttribute(slot, client, const String:attrib[], const String:plugin[], const String:value[], bool:whileActive)
{
	new Action:action;
	if(!StrEqual(plugin, PLUGIN_NAME))
  		return action;
	
	new weapon = GetPlayerWeaponSlot(client, slot);
	if(weapon < 0 || weapon > 2048)
		return action;
	
	if(StrEqual(attrib, "fire rate increases as health decreases"))
	{
		HealthToFireRate_MaxMult[weapon] = StringToFloat(value);
		
		HealthToFireRate[weapon] = true;
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
	
	if(!HealthToFireRate[weapon])
		return;
	
	if(GetEngineTime() >= LastTick[client] + 0.1)
	{
		new Float:mult = HealthToFireRate_MaxMult[weapon] * (1.0 - (GetClientHealth(client) / GetClientMaxHealth(client)));
		TF2Attrib_SetByName(weapon, "fire rate penalty HIDDEN", 1.0 - mult);
	}
}

public OnEntityDestroyed(ent)
{
	if(ent < 0 || ent > 2048)
		return;
	
	HealthToFireRate[ent] = false;
	HealthToFireRate_MaxMult[ent] = 0.0;
}
