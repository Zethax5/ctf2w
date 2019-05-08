/*

Created by: Zethax
Document created on: March 23rd, 2019
Last edit made on: March 23rd, 2019
Current version: v1.0

Attributes in this pack:
	-> "heat decreases accuracy"
		1) Delay between each heat stack
		2) Accuracy penalty per stack
		3) Maximum amount of stacks
		4) Old accuracy

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

#define PLUGIN_NAME "tf_custom_heat_reduces_accuracy"
#define PLUGIN_AUTH "Zethax"
#define PLUGIN_DESC "Adds an attribute which reduces accuracy over time"
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
	SDKHook(client, SDKHook_PostThink, OnClientPostThink);
}

new bool:HeatAccuracy[2049];
new Float:HeatAccuracy_AccuracyPerStack[2049];
new HeatAccuracy_Stacks[2049];
new HeatAccuracy_MaxStacks[2049];
new Float:HeatAccuracy_BaseAccuracy[2049];
new Float:HeatAccuracy_Delay[2049];
new Float:HeatAccuracy_Tick[2049];

new Float:LastTick[MAXPLAYERS + 1];

public Action:CW3_OnAddAttribute(slot, client, const String:attrib[], const String:plugin[], const String:value[], bool:whileActive)
{
	new Action:action;
	if(!StrEqual(plugin, PLUGIN_NAME))
  		return action;
	
	new weapon = GetPlayerWeaponSlot(client, slot);
	if(weapon < 0 || weapon > 2048)
		return action;
	
	if(StrEqual(attrib, "heat decreases accuracy"))
	{
		new String:values[4][10];
		ExplodeString(value, " ", values, sizeof(values), sizeof(values[]));
		
		HeatAccuracy_Delay[weapon] = StringToFloat(values[0]);
		HeatAccuracy_AccuracyPerStack[weapon] = StringToFloat(values[1]);
		HeatAccuracy_MaxStacks[weapon] = StringToInt(values[2]);
		HeatAccuracy_BaseAccuracy[weapon] = StringToFloat(values[3]);
		
		HeatAccuracy[weapon] = true;
		action = Plugin_Handled;
	}
	
	return action;
}

public OnClientPostThink(client)
{
	if(!IsValidClient(client))
		return;
	
	new weapon = GetActiveWeapon(client);
	if(weapon < 0 || weapon > 2048)
		return;
	
	if(!HeatAccuracy[weapon])
		return;
	
	if(GetEngineTime() >= LastTick[client] + 0.1)
	{
		HeatAccuracy_PostThink(client, weapon);
		LastTick[client] = GetEngineTime();
	}
}

void HeatAccuracy_PostThink(client, weapon)
{
	if(TF2_IsPlayerInCondition(client, TFCond:0) && GetAmmo_Weapon(client, weapon) > 0)
	{
		new buttons = GetClientButtons(client);
		if((buttons & IN_ATTACK) == IN_ATTACK && GetEngineTime() >= HeatAccuracy_Tick[weapon] + HeatAccuracy_Delay[weapon])
		{
			HeatAccuracy_Stacks[weapon]++;
			if(HeatAccuracy_Stacks[weapon] > HeatAccuracy_MaxStacks[weapon])
				HeatAccuracy_Stacks[weapon] = HeatAccuracy_MaxStacks[weapon];
			
			new Float:baseAccuracy = HeatAccuracy_BaseAccuracy[weapon];
			new Float:newAccuracy = HeatAccuracy_AccuracyPerStack[weapon] * HeatAccuracy_Stacks[weapon];
			
			TF2Attrib_SetByName(weapon, "spread penalty", baseAccuracy + newAccuracy);
			
			HeatAccuracy_Tick[weapon] = GetEngineTime();
		}
		else if((buttons & IN_ATTACK2) == IN_ATTACK2 && GetEngineTime() >= HeatAccuracy_Tick[weapon] + (HeatAccuracy_Delay[weapon] * 2.0))
		{
			HeatAccuracy_Stacks[weapon]--;
			if(HeatAccuracy_Stacks[weapon] < 0)
				HeatAccuracy_Stacks[weapon] = 0;
			
			new Float:baseAccuracy = HeatAccuracy_BaseAccuracy[weapon];
			new Float:newAccuracy = HeatAccuracy_AccuracyPerStack[weapon] * HeatAccuracy_Stacks[weapon];
			
			TF2Attrib_SetByName(weapon, "spread penalty", baseAccuracy + newAccuracy);
			
			HeatAccuracy_Tick[weapon] = GetEngineTime();
		}
	}
	else
	{
		HeatAccuracy_Stacks[weapon] = 0;
		TF2Attrib_SetByName(weapon, "spread penalty", HeatAccuracy_BaseAccuracy[weapon]);
	}
}

public OnEntityDestroyed(ent)
{
	if(ent < 0 || ent > 2048)
		return;
	
	HeatAccuracy[ent] = false;
	HeatAccuracy_AccuracyPerStack[ent] = 0.0;
	HeatAccuracy_MaxStacks[ent] = 0;
	HeatAccuracy_Stacks[ent] = 0;
	HeatAccuracy_BaseAccuracy[ent] = 0.0;
	HeatAccuracy_Delay[ent] = 0.0;
	HeatAccuracy_Tick[ent] = 0.0;
}
