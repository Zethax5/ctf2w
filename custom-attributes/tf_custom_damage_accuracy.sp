/*

Created by: Zethax
Document created on: March 12th, 2019
Last edit made on: March 12th, 2019
Current version: v1.0

Attributes in this pack:
	-> "damage builds accuracy"
		1) Maximum accuracy
		2) Max damage required to obtain max accuracy
		3) Accuracy drain per shot
		4) Sentry damage multiplier

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

#define PLUGIN_NAME "tf_custom_damage_accuracy"
#define PLUGIN_AUTH "Zethax"
#define PLUGIN_DESC "Adds an attribute which increases accuracy on one weapon for damage dealt with other weapons."
#define PLUGIN_VERS "v1.0"

new Handle:hudText_Client;

public Plugin:my_info = {
  
	name        = PLUGIN_NAME,
	author      = PLUGIN_AUTH,
	description = PLUGIN_DESC,
	version     = PLUGIN_VERS,
	url         = ""
};

public OnPluginStart() {
	
	//"15% of damage dealt by buildings contributes to accuracy"
	//ugh
	HookEvent("player_builtobject", OnPlayerBuiltObject);
	HookEvent("object_removed", OnBuildingDestroyed);
	HookEvent("object_destroyed", OnBuildingDestroyed);
	HookEvent("object_detonated", OnBuildingDestroyed);
	
	for(new i = 1 ; i < MaxClients ; i++)
	{
		if(!IsValidClient(i))
			continue;
  
		OnClientPutInServer(i);
	}
	
	hudText_Client = CreateHudSynchronizer();
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
	SDKHook(client, SDKHook_PreThink, OnClientPreThink);
}

new bool:DamageBuildsAccuracy[2049];
new Float:DamageBuildsAccuracy_MaxAccuracy[2049];
new Float:DamageBuildsAccuracy_OldCharge[2049];
new Float:DamageBuildsAccuracy_MaxCharge[2049];
new Float:DamageBuildsAccuracy_Charge[2049];
new Float:DamageBuildsAccuracy_Drain[2049];
new Float:DamageBuildsAccuracy_SentryMult[2049];

new Float:LastTick[MAXPLAYERS + 1];
new SentryOwner[MAXPLAYERS + 1];

public Action:CW3_OnAddAttribute(slot, client, const String:attrib[], const String:plugin[], const String:value[], bool:whileActive)
{
	new Action:action;
	if(!StrEqual(plugin, PLUGIN_NAME))
  		return action;
	
	new weapon = GetPlayerWeaponSlot(client, slot);
	if(weapon < 0 || weapon > 2048)
		return action;
	
	if(StrEqual(attrib, "damage builds accuracy"))
	{
		new String:values[4][10];
		ExplodeString(value, " ", values, sizeof(values), sizeof(values[]));
		
		DamageBuildsAccuracy_MaxAccuracy[weapon] = StringToFloat(values[0]);
		DamageBuildsAccuracy_MaxCharge[weapon] = StringToFloat(values[1]);
		DamageBuildsAccuracy_Drain[weapon] = StringToFloat(values[2]);
		DamageBuildsAccuracy_SentryMult[weapon] = StringToFloat(values[3]);
		
		DamageBuildsAccuracy[weapon] = true;
		action = Plugin_Handled;
	}
	
	return action;
}

public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
	if (client < 0 || client > MaxClients)return Plugin_Continue;
	if (weapon <= -1 || weapon >= 2049)return Plugin_Continue;
	
	new Action:action;
	
	if(DamageBuildsAccuracy[weapon])
	{
		DamageBuildsAccuracy_Charge[weapon] -= DamageBuildsAccuracy_Drain[weapon];
		if (DamageBuildsAccuracy_Charge[weapon] < 0.0)
			DamageBuildsAccuracy_Charge[weapon] = 0.0;
	}
	
	return action;
}

public Action:OnTakeDamageAlive(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	new Action:action = Plugin_Continue;
	
	new attribWeapon = GetPlayerWeaponSlot(attacker, 0);
	if(attribWeapon == -1 || !DamageBuildsAccuracy[attribWeapon])
		attribWeapon = GetPlayerWeaponSlot(attacker, 1);
	if(attribWeapon == -1 || !DamageBuildsAccuracy[attribWeapon])
		return action;
	
	if(inflictor == SentryOwner[attacker])
	{
		DamageBuildsAccuracy_Charge[attribWeapon] += damage * DamageBuildsAccuracy_SentryMult[attribWeapon];
		if (DamageBuildsAccuracy_Charge[attribWeapon] > DamageBuildsAccuracy_MaxCharge[attribWeapon])
			DamageBuildsAccuracy_Charge[attribWeapon] = DamageBuildsAccuracy_MaxCharge[attribWeapon];
	}
	else if(weapon > -1 && !DamageBuildsAccuracy[weapon])
	{
		DamageBuildsAccuracy_Charge[attribWeapon] += damage;
		if (DamageBuildsAccuracy_Charge[attribWeapon] > DamageBuildsAccuracy_MaxCharge[attribWeapon])
			DamageBuildsAccuracy_Charge[attribWeapon] = DamageBuildsAccuracy_MaxCharge[attribWeapon];
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
	
	if(!DamageBuildsAccuracy[weapon])
		return;
	
	if(GetEngineTime() >= LastTick[client] + 0.1)
	{
		DamageBuildsAccuracy_PreThink(client, weapon);
		LastTick[client] = GetEngineTime();
	}
}

void DamageBuildsAccuracy_PreThink(client, weapon)
{
	new Float:accuracyBonus = DamageBuildsAccuracy_MaxAccuracy[weapon] * (DamageBuildsAccuracy_Charge[weapon] / DamageBuildsAccuracy_MaxCharge[weapon]);
	if(DamageBuildsAccuracy_OldCharge[weapon] != DamageBuildsAccuracy_Charge[weapon])
	{
		TF2Attrib_SetByName(weapon, "weapon spread bonus", 1.0 - accuracyBonus);
		
		DamageBuildsAccuracy_OldCharge[weapon] = DamageBuildsAccuracy_Charge[weapon];
	}
	
	SetHudTextParams(-1.0, 0.8, 0.2, 255, 255, 255, 255);
	ShowSyncHudText(client, hudText_Client, "Accuracy: %i%% / %i%%", RoundFloat(accuracyBonus * 100.0), RoundFloat(DamageBuildsAccuracy_MaxAccuracy[weapon] * 100.0));
}

public Action:OnPlayerBuiltObject(Handle:event, const String:name[], bool:dontBroadcast)
{
	new owner = GetClientOfUserId(GetEventInt(event, "userid"));
	new ent = GetEventInt(event, "index");
	
	if(IsClassname(ent, "obj_sentrygun"))
		SentryOwner[owner] = ent;
}

public Action:OnBuildingDestroyed(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new ent = GetEventInt(event, "index");
	
	if(IsClassname(ent, "obj_sentrygun"))
	{
		SentryOwner[client] = 0;
	}
}

public OnEntityDestroyed(ent)
{
    if(ent < 0 || ent > 2048)
        return;
	
	DamageBuildsAccuracy[ent] 			  = false;
	DamageBuildsAccuracy_Drain[ent] 	  = 0.0;
	DamageBuildsAccuracy_Charge[ent] 	  = 0.0;
	DamageBuildsAccuracy_MaxCharge[ent]   = 0.0;
	DamageBuildsAccuracy_OldCharge[ent]   = 0.0;
	DamageBuildsAccuracy_MaxAccuracy[ent] = 0.0;
	DamageBuildsAccuracy_SentryMult[ent]  = 0.0;
}
