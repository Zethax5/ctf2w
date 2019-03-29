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

#define PLUGIN_NAME "tf_custom_condiment_cannon"
#define PLUGIN_AUTH "Zethax"
#define PLUGIN_DESC "Adds an attribute which applies conditions based on the amount of shots in the weapon clip."
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
	SDKHook(client, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
}

new bool:CondCannon[2049];
new Float:CondCannon_Duration[2049];
new CondCannon_Conds[2049][10];
new CondCannon_Max[2049];

public Action:CW3_OnAddAttribute(slot, client, const String:attrib[], const String:plugin[], const String:value[], bool:whileActive)
{
	new Action:action;
	if(!StrEqual(plugin, PLUGIN_NAME))
  		return action;
	
	new weapon = GetPlayerWeaponSlot(client, slot);
	if(weapon < 0 || weapon > 2048)
		return action;
	
	if(StrEqual(attrib, "condiment cannon attrib"))
	{
		new String:values[10][10];
		ExplodeString(value, " ", values, sizeof(values), sizeof(values[]));
		
		CondCannon_Duration[weapon] = StringToFloat(values[0]);
		for(new i = 1; i < 10; i++)
		{
			if(strlen(values[i]))
				CondCannon_Conds[weapon][i] = StringToInt(values[i]);
			else
			{
				CondCannon_Max[weapon] = i;
				break;
			}
		}
		
		CondCannon[weapon] = true;
		action = Plugin_Handled;
	}
	
	return action;
}

public OnTakeDamagePost(victim, attacker, inflictor, Float:damage, damagetype, weapon, const Float:damageForce[3], const Float:damagePosition[3], damageCustom)
{
	if(IsValidClient(attacker) && IsValidClient(victim))
	{
		if(weapon > -1 && CondCannon[weapon])
		{
			for(new i = 1; i <= CondCannon_Max[weapon]; i++)
			{
				if(GetClip_Weapon(weapon) == i)
				{
					TF2_AddCondition(victim, TFCond:CondCannon_Conds[weapon][i], CondCannon_Duration[weapon], attacker);
					if(CondCannon_Conds[weapon][i] == 22)
						TF2_IgnitePlayer(victim, attacker);
					if(CondCannon_Conds[weapon][i] == 25)
						TF2_MakeBleed(victim, attacker, CondCannon_Duration[weapon]);
				}
			}
		}
	}
}

public OnEntityDestroyed(ent)
{
	if(ent < 0 || ent > 2048)
		return;
	
	new ClearConds[10] = { 0, ...};
	
	CondCannon[ent] = false;
	CondCannon_Duration[ent] = 0.0;
	CondCannon_Conds[ent] = ClearConds;
}
