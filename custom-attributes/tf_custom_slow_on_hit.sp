/*

Created by: Zethax
Document created on: March 11th, 2019
Last edit made on: March 12th, 2019
Current version: v1.0

Attributes in this pack:
	-> "slow on hit"
		1) Slow multiplier
		2) Duration of the slow

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

#define PLUGIN_NAME "tf_custom_slow_on_hit"
#define PLUGIN_AUTH "Zethax"
#define PLUGIN_DESC "Adds in custom attributes associated with slowness on hit"
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

new bool:SlowOnHit[2049];
new Float:SlowOnHit_Dur[2049];
new Float:SlowOnHit_Mult[2049];
new Float:SlowOnHit_MaxDur[2049];
new bool:Slowed[MAXPLAYERS + 1];

new Float:LastTick[MAXPLAYERS + 1];

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(client, SDKHook_PreThink, OnClientPreThink);
}

public Action:CW3_OnAddAttribute(slot, client, const String:attrib[], const String:plugin[], const String:value[], bool:whileActive)
{
	new Action:action;
	if(!StrEqual(plugin, PLUGIN_NAME))
  		return action;
	
	new weapon = GetPlayerWeaponSlot(client, slot);
	if(weapon < 0 || weapon > 2048)
		return action;
	
	if(StrEqual(attrib, "slow on hit"))
	{
		new String:values[2][10];
		ExplodeString(value, " ", values, sizeof(values), sizeof(values[]));
		
		SlowOnHit_Mult[weapon] = StringToFloat(values[0]);
		SlowOnHit_MaxDur[weapon] = StringToFloat(values[1]);
		
		SlowOnHit[weapon] = true;
		action = Plugin_Handled;
	}
	
	return action;
}

public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	if(Slowed[victim])
	{
		RemoveSlowness(victim);
	}
}

public Action:OnInventoryApplication(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(Slowed[client])
	{
		RemoveSlowness(client);
	}
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damageCustom)
{
	if(attacker && victim)
	{
		if(SlowOnHit[weapon])
		{
			Slowed[victim] = true;
			SlowOnHit_Dur[victim] = GetEngineTime();
			SlowOnHit_MaxDur[victim] = SlowOnHit_MaxDur[weapon];
			TF2Attrib_SetByName(victim, "move speed penalty", 1.0 - SlowOnHit_Mult[weapon]);
			TF2_AddCondition(victim, TFCond_SpeedBuffAlly, 0.001); //updates victim's movement speed
		}
	}
}

public OnClientPreThink(client)
{
	if(!IsValidClient(client))
		return;
	
	if(Slowed[client])
	{
		if(GetEngineTime() >= LastTick[client] + 0.1)
			Slowed_PreThink(client);
	}
}

void Slowed_PreThink(client)
{
	if(GetEngineTime() >= SlowOnHit_Dur[client] + SlowOnHit_MaxDur[client])
	{
		RemoveSlowness(client);
	}
}

public OnEntityDestroyed(ent)
{
    if(ent < 0 || ent > 2048)
        return;
	
	SlowOnHit[ent] = false;
	SlowOnHit_Dur[ent] = 0.0;
	SlowOnHit_Mult[ent] = 0.0;
	SlowOnHit_MaxDur[ent] = 0.0;
}

stock RemoveSlowness(client)
{
	Slowed[client] = false;
	SlowOnHit_Dur[client] = 0.0;
	SlowOnHit_MaxDur[client] = 0.0;
	TF2Attrib_RemoveByName(client, "move speed penalty");
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.001); //update player movement speed
}