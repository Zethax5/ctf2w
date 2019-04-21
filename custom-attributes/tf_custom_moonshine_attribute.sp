/*

Created by: Zethax
Document created on: March 23rd, 2019
Last edit made on: March 23rd, 2019
Current version: v1.0

Attributes in this pack:
	-> "health packs brew moonshine"
		1) Maximum amount of moonshine that can be accumulated
		Health restored per pint of Moonshine will be based on maximum moonshine stacks.
		Per pint of moonshine, health restored equals max hp divided by max moonshine stacks.

*/

#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2>
#include <sdkhooks>
#include <sdktools>
#include <cw3-attributes>
#include <zethax>

#define PLUGIN_NAME "tf_custom_moonshine_attribute"
#define PLUGIN_AUTH "Zethax"
#define PLUGIN_DESC "Adds an attribute which brews Moonshine out of health packs"
#define PLUGIN_VERS "v1.0"

public Plugin:my_info = {
  
	name        = PLUGIN_NAME,
	author      = PLUGIN_AUTH,
	description = PLUGIN_DESC,
	version     = PLUGIN_VERS,
	url         = ""
};

public OnPluginStart() {
 	
	HookEntityOutput("item_healthkit_small", "OnPlayerTouch", OnTouchHealthKit);
	HookEntityOutput("item_healthkit_medium", "OnPlayerTouch", OnTouchHealthKit);
	HookEntityOutput("item_healthkit_full", "OnPlayerTouch", OnTouchHealthKit);
	
	for(new i = 1 ; i < MaxClients ; i++)
	{
		if(!IsValidClient(i))
			continue;
  
		OnClientPutInServer(i);
	}
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_PostThink, OnClientPostThink);
}

new bool:Moonshine[2049];
new Moonshine_MaxStacks[2049];
new Moonshine_Stacks[2049];
new bool:Moonshine_Drinking[2049];
new Float:Moonshine_DrinkTick[2049];

new Float:LastTick[MAXPLAYERS + 1];

public Action:CW3_OnAddAttribute(slot, client, const String:attrib[], const String:plugin[], const String:value[], bool:whileActive)
{
	new Action:action;
	if(!StrEqual(plugin, PLUGIN_NAME))
  		return action;
	
	new weapon = GetPlayerWeaponSlot(client, slot);
	if(weapon < 0 || weapon > 2048)
		return action;
	
	if(StrEqual(attrib, "health packs brew moonshine"))
	{
		Moonshine_MaxStacks[weapon] = StringToInt(value);
		
		//Initializes ammo counter
		SetEntProp(weapon, Prop_Send, "m_iClip1", 0);
		SetEntProp(weapon, Prop_Data, "m_iPrimaryAmmoType", 4);
		
		Moonshine[weapon] = true;
		action = Plugin_Handled;
	}
	
	return action;
}

public OnTouchHealthKit(const String:output[], caller, activator, Float:delay)
{
	if(IsValidClient(activator))
	{
		new melee = GetPlayerWeaponSlot(activator, 2);
		if(melee > -1 && Moonshine[melee])
		{
			Moonshine_Stacks[melee]++;
			if(Moonshine_Stacks[melee] > Moonshine_MaxStacks[melee])
				Moonshine_Stacks[melee] = Moonshine_MaxStacks[melee];
		}
	}
}

public OnClientPostThink(client)
{
	if(!IsValidClient(client))
		return;
		
	new weapon = GetPlayerWeaponSlot(client, 2);
	if(weapon < 0 || weapon > 2048)
		return;
	
	if(!Moonshine[weapon])
		return;
	
	if(GetEngineTime() >= LastTick[client] + 0.05)
	{
		Moonshine_DrinkHandle(client, weapon);
		LastTick[client] = GetEngineTime();
	}
}

void Moonshine_DrinkHandle(client, weapon)
{
	if(TF2_IsPlayerInCondition(client, TFCond_Taunting) && !Moonshine_Drinking[weapon])
	{
		Moonshine_Drinking[weapon] = true;
		Moonshine_DrinkTick[weapon] = GetEngineTime();
	}
	else if(!TF2_IsPlayerInCondition(client, TFCond_Taunting) && Moonshine_Drinking[weapon])
	{
		Moonshine_Drinking[weapon] = false;
	}
	
	if(Moonshine_Stacks[weapon] > 0 && Moonshine_Drinking[weapon] && GetEngineTime() >= Moonshine_DrinkTick[weapon] + 1.75)
	{
		new maxhealth = GetClientMaxHealth(client);
		new healing = (maxhealth / Moonshine_MaxStacks[weapon]) * Moonshine_Stacks[weapon];
		new health = GetClientHealth(client);
		
		health += healing;
		if(health > maxhealth)
			health = maxhealth;
		
		SetEntityHealth(client, health);
		Moonshine_Stacks[weapon] = 0;
	}
	
	SetEntProp(weapon, Prop_Send, "m_iClip1", Moonshine_Stacks[weapon]);
}

public OnEntityDestroyed(ent)
{
	if(ent < 0 || ent > 2048)
		return;
	
	Moonshine[ent] = false;
	Moonshine_Stacks[ent] = 0;
	Moonshine_MaxStacks[ent] = 0;
}
