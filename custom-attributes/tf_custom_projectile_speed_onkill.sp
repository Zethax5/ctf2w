/*

Created by: Zethax
Document created on: March 28th, 2019
Last edit made on: March 28th, 2019
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

#define PLUGIN_NAME "tf_custom_projectile_speed_onkill"
#define PLUGIN_AUTH "Zethax"
#define PLUGIN_DESC "Adds an attribute which grants stacking projectile speed on kill, among other speeds."
#define PLUGIN_VERS "v0.0"

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

new bool:SpeedOnKill[2049];
new Float:SpeedOnKill_FireSpd[2049];
new Float:SpeedOnKill_DmgPen[2049];

public Action:CW3_OnAddAttribute(slot, client, const String:attrib[], const String:plugin[], const String:value[], bool:whileActive)
{
	new Action:action;
	if(!StrEqual(plugin, PLUGIN_NAME))
  		return action;
	
	new weapon = GetPlayerWeaponSlot(client, slot);
	if(weapon < 0 || weapon > 2048)
		return action;
	
	if(StrEqual(attrib, "stack speed bonuses on kill"))
	{
		new String:values[7][10];
		ExplodeString(value, " ", values, sizeof(values), sizeof(values[]));
		
		
		
		SpeedOnKill[weapon] = true;
		action = Plugin_Handled;
	}
	
	return action;
}

public OnEntityDestroyed(ent)
{
	if(ent < 0 || ent > 2048)
		return;
	
	
}
