/*

Created by: Zethax
Document created on: March 10th, 2019
Last edit made on: March 10th, 2019
Current version: v1.0

NOTE: All attributes in this pack can be applied more than once.
Attributes in this pack:
	-> "addcond on kill"
		1) Condition ID to add
		2) Duration of condition
		On kill: Gain X condition for X seconds.
	
	-> "addcond while spun up"
		1) Condition ID to add
		While spun up: Gain X condition
	
	-> "addcond while charging"
		1) Condition ID to add
		While charging: Gain X condition
	
	-> "addcond on wearer"
		1) Condition ID to add
		Wearer gains X condition
	
	-> "addcond on start drink"
		1) Condition ID to add
		2) Duration of condition
		Upon drinking: Gain X condition for X seconds
	
	-> "addcond on hit"
		1) Condition ID to add
		2) Duration of condition
		On hit: Gain X condition for X seconds

*/

#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2>
#include <sdkhooks>
#include <sdktools>
#include <cw3-attributes>
#include <zethax>

#define PLUGIN_NAME "tf_custom_addcond_attribs"
#define PLUGIN_AUTH "Zethax"
#define PLUGIN_DESC "A small pack of attributes that add conditions to the player based on certain conditions"
#define PLUGIN_VERS "v1.1"

#define MAXCONDS 255

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
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

new bool:AddcondOnKill[2049];
new AddcondOnKill_Condition[2049][MAXCONDS + 1];
new Float:AddcondOnKill_Duration[2049][MAXCONDS + 1];

new bool:AddcondSpunUp[2049];
new AddcondSpunUp_Condition[2049][MAXCONDS + 1];

new bool:AddcondCharging[MAXPLAYERS + 1][MAXSLOTS + 1];
new AddcondCharging_Condition[MAXPLAYERS + 1][MAXSLOTS + 1][MAXCONDS + 1];

new bool:AddcondOnWearer[MAXPLAYERS + 1][MAXSLOTS + 1];
new AddcondOnWearer_Condition[MAXPLAYERS + 1][MAXSLOTS + 1][MAXCONDS + 1];

new bool:AddcondOnDrink[2049];
new AddcondOnDrink_Condition[2049][MAXCONDS + 1];
new Float:AddcondOnDrink_Duration[2049][MAXCONDS + 1];

new bool:AddcondOnHit[2049];
new AddcondOnHit_Condition[2049][MAXCONDS + 1];
new Float:AddcondOnHit_Duration[2049][MAXCONDS + 1];

new Float:LastTick[MAXPLAYERS + 1];

public Action:CW3_OnAddAttribute(slot, client, const String:attrib[], const String:plugin[], const String:value[], bool:whileActive)
{
	new Action:action;
	if(!StrEqual(plugin, PLUGIN_NAME))
  		return action;
	
	new weapon = GetPlayerWeaponSlot(client, slot);
	
	if(StrEqual(attrib, "addcond on kill"))
	{
		if(weapon < 0 || weapon > 2048)
			return action;
		
		new String:values[2][10];
		ExplodeString(value, " ", values, sizeof(values), sizeof(values[]));
		
		AddcondOnKill_Condition[weapon][StringToInt(values[0])] = StringToInt(values[0]);
		AddcondOnKill_Duration[weapon][StringToInt(values[0])] = StringToFloat(values[1]);
		
		AddcondOnKill[weapon] = true;
		action = Plugin_Handled;
	}
	else if(StrEqual(attrib, "addcond while spun up"))
	{
		if(weapon < 0 || weapon > 2048)
			return action;
		
		AddcondSpunUp_Condition[weapon][StringToInt(value)] = StringToInt(value);
		
		AddcondSpunUp[weapon] = true;
		action = Plugin_Handled;
	}
	else if(StrEqual(attrib, "addcond while charging"))
	{
		AddcondCharging_Condition[client][slot][StringToInt(value)] = StringToInt(value);
		
		AddcondCharging[client][slot] = true;
		action = Plugin_Handled;
	}
	else if(StrEqual(attrib, "addcond on wearer"))
	{
		AddcondOnWearer_Condition[client][slot][StringToInt(value)] = StringToInt(value);
		
		AddcondOnWearer[client][slot] = true;
		action = Plugin_Handled;
	}
	else if(StrEqual(attrib, "addcond on start drink"))
	{
		new String:values[2][10];
		ExplodeString(value, " ", values, sizeof(values), sizeof(values[]));
		
		AddcondOnDrink_Condition[weapon][StringToInt(values[0])] = StringToInt(values[0]);
		AddcondOnDrink_Duration[weapon][StringToInt(values[0])] = StringToFloat(values[1]);
		
		AddcondOnDrink[weapon] = true;
		action = Plugin_Handled;
	}
	else if(StrEqual(attrib, "addcond on hit"))
	{
		new String:values[2][10];
		ExplodeString(value, " ", values, sizeof(values), sizeof(values[]));
		
		AddcondOnHit_Condition[weapon][StringToInt(values[0])] = StringToInt(values[0]);
		AddcondOnHit_Duration[weapon][StringToInt(values[0])] = StringToFloat(values[1]);
		
		AddcondOnHit[weapon] = true;
		action = Plugin_Handled;
	}
	
	return action;
}

public OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damageCustom)
{
	if(attacker > -1 && weapon > -1)
	{
		if(AddcondOnHit[weapon])
		{
			for (new i = 0; i <= MAXCONDS; i++)
			{
				if(AddcondOnHit_Condition[weapon][i] == 0)
					continue;
				
				TF2_AddCondition(attacker, TFCond:AddcondOnHit_Condition[weapon][i], AddcondOnHit_Duration[weapon][i]);
			}
		}
	}
}

public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(attacker)
	{
		new weapon = GetActiveWeapon(attacker);
		if(weapon > -1 && AddcondOnKill[weapon])
		{
			for (new i = 0; i <= MAXCONDS; i++)
			{
				if(AddcondOnKill_Condition[weapon][i] == 0)
					continue;
				
				TF2_AddCondition(attacker, TFCond:AddcondOnKill_Condition[weapon][i], AddcondOnKill_Duration[weapon][i]);
			}
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
	
	new slot;
	if(GetEngineTime() >= LastTick[client] + 0.1)
	{
		if(AddcondSpunUp[weapon])
			AddcondSpunUp_PreThink(client, weapon);
		
		if(AddcondOnDrink[weapon])
			AddcondOnDrink_PreThink(client, weapon);
		
		slot = GetSlotContainingAttribute(client, AddcondCharging);
		if(slot > -1 && AddcondCharging[client][slot])
			AddcondCharging_PreThink(client, slot);
		
		slot = GetSlotContainingAttribute(client, AddcondOnWearer);
		if(slot > -1 && AddcondOnWearer[client][slot])
			AddcondOnWearer_PreThink(client, slot);
		
		LastTick[client] = GetEngineTime();
	}
}

void AddcondSpunUp_PreThink(client, weapon)
{
	if(TF2_IsPlayerInCondition(client, TFCond:0)) //TFCond:0 == Revving minigun
	{
		for (new i = 0; i <= MAXCONDS; i++)
		{
			if(AddcondSpunUp_Condition[weapon][i] == 0)
				continue;
			
			TF2_AddCondition(client, TFCond:AddcondSpunUp_Condition[weapon][i], 0.2);
		}
	}
}

void AddcondOnDrink_PreThink(client, weapon)
{
	if(GetEntPropFloat(weapon, Prop_Send, "m_flEffectBarRegenTime") >= 1.0)
	{
		for (new i = 0; i <= MAXCONDS; i++)
		{
			if(AddcondOnDrink_Condition[weapon][i] == 0)
				continue;
			
			TF2_AddCondition(client, TFCond:AddcondOnDrink_Condition[weapon][i], AddcondOnDrink_Duration[weapon][i]);
		}
	}
}

void AddcondCharging_PreThink(client, slot)
{
	if(TF2_IsPlayerInCondition(client, TFCond_Charging))
	{
		for (new i = 0; i <= MAXCONDS; i++)
		{
			if(AddcondCharging_Condition[client][slot][i] == 0)
				continue;
			
			TF2_AddCondition(client, TFCond:AddcondCharging_Condition[client][slot][i], 0.2);
		}
	}
}

void AddcondOnWearer_PreThink(client, slot)
{
	for (new i = 0; i <= MAXCONDS; i++)
	{
		if(AddcondOnWearer_Condition[client][slot][i] == 0)
			continue;
		
		TF2_AddCondition(client, TFCond:AddcondOnWearer_Condition[client][slot][i], 0.2);
	}
}

public OnEntityDestroyed(ent)
{
    if(ent < 0 || ent > 2048)
        return;
	
	new ClearConds[MAXCONDS + 1] =  { 0, ... };
	new Float:ClearDur[MAXCONDS + 1] =  { 0.0, ... };
	
	AddcondOnKill[ent] = false;
	AddcondOnKill_Duration[ent] = ClearDur;
	AddcondOnKill_Condition[ent] = ClearConds;
	
	AddcondSpunUp[ent] = false;
	AddcondSpunUp_Condition[ent] = ClearConds;
	
	AddcondOnDrink[ent] = false;
	AddcondOnDrink_Duration[ent] = ClearDur;
	AddcondOnDrink_Condition[ent] = ClearConds;
	
	AddcondOnHit[ent] = false;
	AddcondOnHit_Duration[ent] = ClearDur;
	AddcondOnHit_Condition[ent] = ClearConds;
}

public CW3_OnWeaponRemoved(slot, client)
{
	new ClearConds[MAXCONDS + 1] =  { 0, ... };
	
	AddcondCharging[client][slot] = false;
	AddcondCharging_Condition[client][slot] = ClearConds;
	
	AddcondOnWearer[client][slot] = false;
	AddcondOnWearer_Condition[client][slot] = ClearConds;
}

/*
Used for finding an attribute in any given player slot.
Only works on attributes made in the new format, using [client][slot].

@param client			Client ID to check
@param attribute 		Attribute name to check for.

@return slot number containing attribute.
	Returns -1 if attribute is not found or client is not valid.
*/
stock GetSlotContainingAttribute(client, const attribute[][])
{
	if(!IsValidClient(client)) return -1;
	
	for (new i = 0; i <= MAXSLOTS; i++)
	{
		if(attribute[client][i])
			return i;
	}
	
	return -1;
}
