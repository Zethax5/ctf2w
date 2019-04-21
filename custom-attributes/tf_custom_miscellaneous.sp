/*

Created by: Zethax
Document created on: March 11th, 2019
Last edit made on: March 11th, 2019
Current version: v1.0

Attributes in this pack:
	-> "the bypass"
		Any value activates.
		Absolutely prevents intelligence pickup.
		
	-> "modify headshots"
		Takes one value.
		1 == minicrits on headshot
		0 == disable headshots

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

#define PLUGIN_NAME "tf_custom_miscellaneous"
#define PLUGIN_AUTH "Zethax"
#define PLUGIN_DESC "A little pack of 2 attributes"
#define PLUGIN_VERS "v1.0"

public Plugin:my_info = {
  
	name        = PLUGIN_NAME,
	author      = PLUGIN_AUTH,
	description = PLUGIN_DESC,
	version     = PLUGIN_VERS,
	url         = ""
};

public OnPluginStart()
{
	for (new i = 1; i < MaxClients; i++)
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

new bool:ModifyHeadshots[2049];
new ModifyHeadshots_Modifier[2049];
new bool:TheBypass[2049];

public Action:CW3_OnAddAttribute(slot, client, const String:attrib[], const String:plugin[], const String:value[], bool:whileActive)
{
	new Action:action;
	if(!StrEqual(plugin, PLUGIN_NAME))
  		return action;
	
	new weapon = GetPlayerWeaponSlot(client, slot);
	if(weapon < 0 || weapon > 2048)
		return action;
	
	if(StrEqual(attrib, "the bypass"))
	{
		new primary = GetPlayerWeaponSlot(client, 0);
		new secondary = GetPlayerWeaponSlot(client, 1);
		new melee = GetPlayerWeaponSlot(client, 2);
		
		if(primary > -1)
		{
			TF2Attrib_SetByName(primary, "cannot pick up intelligence", 1.0);
		}
		if(secondary > -1)
		{
			TF2Attrib_SetByName(secondary, "cannot pick up intelligence", 1.0);
		}
		if(melee > -1)
		{
			TF2Attrib_SetByName(melee, "cannot pick up intelligence", 1.0);
		}
		
		action = Plugin_Handled;
	}
	else if(StrEqual(attrib, "modify headshots"))
	{
		ModifyHeadshots_Modifier[weapon] = StringToInt(value);
		
		ModifyHeadshots[weapon] = true;
		action = Plugin_Handled;
	}
	
	return action;
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damageCustom)
{
	if(attacker && weapon > -1)
	{
		if(ModifyHeadshots[weapon] && damageCustom == TF_CUSTOM_HEADSHOT)
		{
			damagetype &= ~DMG_CRIT;
			if(ModifyHeadshots_Modifier[weapon] == 1)
				TF2_AddCondition(victim, TFCond_MarkedForDeathSilent, 0.01);
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

public OnEntityDestroyed(ent)
{
	if(ent < 0 || ent > 2048)
		return;
	
	ModifyHeadshots[ent] = false;
	ModifyHeadshots_Modifier[ent] = 0;
	
	if(TheBypass[ent])
	{
		new owner = ReturnOwner(ent);
		if(IsValidClient(owner))
		{
			TF2Attrib_RemoveByName(GetPlayerWeaponSlot(owner, 0), "cannot pick up intelligence");
			TF2Attrib_RemoveByName(GetPlayerWeaponSlot(owner, 1), "cannot pick up intelligence");
			TF2Attrib_RemoveByName(GetPlayerWeaponSlot(owner, 2), "cannot pick up intelligence");
		}
	}
}