/*

Created by: Zethax
Document created on: March 27th, 2019
Last edit made on: March 27th, 2019
Current version: v1.0

Attributes in this pack:
	-> "increased melee range on kill"
		1) Melee range
		2) Melee bounds
		3) Maximum duration

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

#define PLUGIN_NAME "tf_custom_range_on_kill"
#define PLUGIN_AUTH "Zethax"
#define PLUGIN_DESC "Adds an attribute which increases melee range on kill."
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

new bool:RangeOnKill[2049];
new Float:RangeOnKill_Range[2049];
new Float:RangeOnKill_Bounds[2049];
new Float:RangeOnKill_Duration[2049];
new Float:RangeOnKill_Tick[2049];
new bool:Boosted[2049];

new Float:LastTick[MAXPLAYERS + 1];

public Action:CW3_OnAddAttribute(slot, client, const String:attrib[], const String:plugin[], const String:value[], bool:whileActive)
{
	new Action:action;
	if(!StrEqual(plugin, PLUGIN_NAME))
  		return action;
	
	new weapon = GetPlayerWeaponSlot(client, slot);
	if(weapon < 0 || weapon > 2048)
		return action;
	
	if(StrEqual(attrib, "increased melee range on kill"))
	{
		new String:values[3][10];
		ExplodeString(value, " ", values, sizeof(values), sizeof(values[]));
		
		RangeOnKill_Range[weapon] = StringToFloat(values[0]);
		RangeOnKill_Bounds[weapon] = StringToFloat(values[1]);
		RangeOnKill_Duration[weapon] = StringToFloat(values[2]);
		
		RangeOnKill[weapon] = true;
		action = Plugin_Handled;
	}
	
	return action;
}

public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(IsValidClient(attacker))
	{
		new weapon = GetActiveWeapon(attacker);
		if(weapon > -1 && RangeOnKill[weapon])
		{
			Boosted[weapon] = true;
			RangeOnKill_Tick[weapon] = GetEngineTime();
			TF2Attrib_SetByName(weapon, "melee range multiplier", 1.0 + RangeOnKill_Range[weapon]);
			TF2Attrib_SetByName(weapon, "melee bounds multiplier", 1.0 + RangeOnKill_Bounds[weapon]);
		}
	}
}

public OnClientPreThink(client)
{
	if(!IsValidClient(client))
		return;
		
	new weapon = GetPlayerWeaponSlot(client, 2);
	if(weapon < 0 || weapon > 2048)
		return;
	
	if(!RangeOnKill[weapon])
		return;
	
	if(GetEngineTime() >= LastTick[client] + 0.1)
	{
		if(Boosted[weapon] && GetEngineTime() >= RangeOnKill_Tick[weapon] + RangeOnKill_Duration[weapon])
		{
			Boosted[weapon] = false;
			TF2Attrib_RemoveByName(weapon, "melee range multiplier");
			TF2Attrib_RemoveByName(weapon, "melee bounds multiplier");
		}
	}
}

public OnEntityDestroyed(ent)
{
	if(ent < 0 || ent > 2048)
		return;
	
	Boosted[ent] = false;
	RangeOnKill[ent] = false;
	RangeOnKill_Range[ent] = 0.0;
	RangeOnKill_Bounds[ent] = 0.0;
	RangeOnKill_Duration[ent] = 0.0;
}
