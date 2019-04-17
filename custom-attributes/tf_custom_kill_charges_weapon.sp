/*

Created by: Zethax
Document created on: March 12th, 2019
Last edit made on: March 12th, 2019
Current version: v1.0

Attributes in this pack:
	-> "melee kill charges secondary"
		Apply to your melee weapon
		1) Duration
		2..10) Conditions to add
		Condition values can be left blank.
		
	-> "secondary kill charges melee"
		Apply to your secondary weapon
		1) Duration
		2..10) Conditions to add
		Condition values can be left blank.
	
	When applying both attributes, condition values can be left blank. For example:
	"values"		"5.0 113 32"
	This adds a fire rate-reload rate bonus and a speed boost while your secondary is active for 5 seconds.
	All unneeded values can be left blank, so you could have 1 condition or 10 conditions if you so desired.
*/

#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2>
#include <sdkhooks>
#include <sdktools>
#include <cw3-attributes>
#include <zethax>

#define PLUGIN_NAME "tf_custom_kill_charges_weapon"
#define PLUGIN_AUTH "Zethax"
#define PLUGIN_DESC "Adds in 2 attributes that boost other weapons on kill"
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

new bool:MeleeKillChargesSecondary[2049];
new Float:MeleeKillChargesSecondary_MaxDur[2049];
new MeleeKillChargesSecondary_Condition[2049][10];

new bool:SecondaryKillChargesMelee[2049];
new Float:SecondaryKillChargesMelee_MaxDur[2049];
new SecondaryKillChargesMelee_Condition[2049][10];

//Used to indicate when a weapon has been charged
new bool:Charged[2049];
new Float:ChargeDur[2049];

new Float:LastTick[MAXPLAYERS + 1];

public Action:CW3_OnAddAttribute(slot, client, const String:attrib[], const String:plugin[], const String:value[], bool:whileActive)
{
	new Action:action;
	if(!StrEqual(plugin, PLUGIN_NAME))
  		return action;
	
	new weapon = GetPlayerWeaponSlot(client, slot);
	if(weapon < 0 || weapon > 2048)
		return action;
	
	if(StrEqual(attrib, "melee kill charges secondary"))
	{
		new String:values[10][10];
		ExplodeString(value, " ", values, sizeof(values), sizeof(values[]));
		
		MeleeKillChargesSecondary_MaxDur[weapon] = StringToFloat(values[0]);
		for (new i = 1; i < 10; i++)
		{
			if(strlen(values[i]))
				MeleeKillChargesSecondary_Condition[weapon][i] = StringToInt(values[i]);
			else
				break;
		}
		
		MeleeKillChargesSecondary[weapon] = true;
		action = Plugin_Handled;
	}
	else if(StrEqual(attrib, "secondary kill charges melee"))
	{
		new String:values[10][10];
		ExplodeString(value, " ", values, sizeof(values), sizeof(values[]));
		
		SecondaryKillChargesMelee_MaxDur[weapon] = StringToFloat(values[0]);
		for (new i = 1; i < 10; i++)
		{
			if(strlen(values[i]))
				SecondaryKillChargesMelee_Condition[weapon][i] = StringToInt(values[i]);
			else
				break;
		}
		
		SecondaryKillChargesMelee[weapon] = true;
		action = Plugin_Handled;
	}
	
	return action;
}

public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(attacker)
	{
		new weapon = GetActiveWeapon(attacker);
		new secondary = GetPlayerWeaponSlot(attacker, 1);
		new melee = GetPlayerWeaponSlot(attacker, 2);
		if(secondary > -1 && melee > -1 && weapon > -1)
		{
			if(SecondaryKillChargesMelee[weapon])
				Charged[melee] = true;
			if(MeleeKillChargesSecondary[weapon])
				Charged[secondary] = true;
		}
	}
}

public OnClientPreThink(client)
{
	if(!IsValidClient(client))
		return;
	
	new weapon = GetActiveWeapon(client);
	if(weapon < 0 || weapon > 2048)
		return;
	
	if(GetEngineTime() >= LastTick[client] + 0.1)
		ChargedWeapons_PreThink(client, weapon);
}

void ChargedWeapons_PreThink(client, weapon)
{
	new secondary = GetPlayerWeaponSlot(client, 1);
	new melee = GetPlayerWeaponSlot(client, 2);
	if(secondary > -1 && melee > -1)
	{
		if(weapon == secondary)
		{
			//adds effect while charged weapon is active
			if(GetEngineTime() <= ChargeDur[weapon] + MeleeKillChargesSecondary_MaxDur[melee])
			{
				for (new i = 1; i < 10; i++)
				{
					if(MeleeKillChargesSecondary_Condition[melee][i] == 0)
						continue;
					
					TF2_AddCondition(client, TFCond:MeleeKillChargesSecondary_Condition[melee][i], 0.2);
				}
			}
			
			//initializes charge
			if(Charged[weapon])
			{
				ChargeDur[secondary] = GetEngineTime();
				Charged[secondary] = false;
			}
		}
		if(weapon == melee)
		{
			//adds effect while charged weapon is active
			if(GetEngineTime() <= ChargeDur[weapon] + SecondaryKillChargesMelee_MaxDur[secondary])
			{
				for (new i = 1; i < 10; i++)
				{
					if(SecondaryKillChargesMelee_Condition[secondary][i] == 0)
						continue;
					
					TF2_AddCondition(client, TFCond:SecondaryKillChargesMelee_Condition[secondary][i], 0.2);
				}
			}
			
			//initializes charge
			if(Charged[weapon])
			{
				ChargeDur[melee] = GetEngineTime();
				Charged[melee] = false;
			}
		}
	}
	LastTick[client] = GetEngineTime();
}

public OnEntityDestroyed(ent)
{
    if(ent < 0 || ent > 2048)
        return;
	
	new ClearConds[10] =  { 0, ... };
	
	MeleeKillChargesSecondary[ent] = false;
	MeleeKillChargesSecondary_MaxDur[ent] = 0.0;
	MeleeKillChargesSecondary_Condition[ent] = ClearConds;
	
	SecondaryKillChargesMelee[ent] = false;
	SecondaryKillChargesMelee_MaxDur[ent] = 0.0;
	SecondaryKillChargesMelee_Condition[ent] = ClearConds;
	
	Charged[ent] = false;
	ChargeDur[ent] = 0.0;
}
