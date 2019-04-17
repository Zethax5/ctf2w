/*

Created by: Zethax
Document created on: January 15th, 2019
Last edit made on: February 22nd, 2019
Current version: v1.0

Attributes in this pack:
	- "kills with other weapons boost this weapon"
		1) Maximum duration that can be accumulated
		2) Duration gained on kill with secondary
		3) Duration gained on kill with melee
		4) Condition gained while spinning your primary weapon
		
		On kill gain X seconds based on which weapon you used
		While spinning up with this weapon you gain X condition
		Assist kills grants half the bonus
*/

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#include <tf2>
#include <cw3-attributes>
#include <zethax>

#define PLUGIN_NAME "tf_custom_kills_boost_weapon"
#define PLUGIN_AUTH "Zethax"
#define PLUGIN_DESC "Adds custom attributes associated with minicrit boosting"
#define PLUGIN_VERS "v1.0"

new Handle:hudText_Client;

public Plugin:my_info = {
	
	name		= PLUGIN_NAME,
	author		= PLUGIN_AUTH,
	description = PLUGIN_DESC,
	version		= PLUGIN_VERS,
	url			= ""
};

public OnPluginStart() {
 
 HookEvent("player_death", OnPlayerDeath);
 
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
	SDKHook(client, SDKHook_PreThink, OnClientPreThink);
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

new bool:KillsBoost[2049];
new Float:KillsBoost_MaxDur[2049];
new Float:KillsBoost_StoredDur[2049];
new Float:KillsBoost_GainOnKill[2049];
new Float:KillsBoost_GainOnMeleeKill[2049];
new KillsBoost_Condition[2049];

new Float:LastTick[MAXPLAYERS + 1];
new Float:SpinTime[MAXPLAYERS + 1];

public Action:CW3_OnAddAttribute(slot, client, const String:attrib[], const String:plugin[], const String:value[], bool:whileActive)
{
	new Action:action;
	if(!StrEqual(plugin, "tf_custom_kills_boost_weapon"))
		return action;
	
	new weapon = GetPlayerWeaponSlot(client, slot);
	if(weapon < 0 || weapon > 2048)
		return action;
	
	if(StrEqual(attrib, "kills with other weapons boost this weapon"))
	{
		new String:values[4][10];
		ExplodeString(value, " ", values, sizeof(values), sizeof(values[]));
		
		KillsBoost_MaxDur[weapon]		   = StringToFloat(values[0]);
		KillsBoost_GainOnKill[weapon]	   = StringToFloat(values[1]);
		KillsBoost_GainOnMeleeKill[weapon] = StringToFloat(values[2]);
		KillsBoost_Condition[weapon]	   = StringToInt(values[3]);
	
		KillsBoost[weapon] = true;
		action = Plugin_Handled;
	}
	
	return action;
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damageCustom)
{
	if(attacker > -1 && weapon > -1)
		LastWeaponHurtWith[attacker] = weapon;
	
	return Plugin_Continue;
}

public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new assister = GetClientOfUserId(GetEventInt(event, "assister"));
	
	if(attacker)
	{
		new weapon = LastWeaponHurtWith[attacker];
		new primary = GetPlayerWeaponSlot(attacker, 0);
		if(primary > 0 && primary < 2049 && KillsBoost[primary])
		{
			if(weapon == GetPlayerWeaponSlot(attacker, 1))
			{
				KillsBoost_StoredDur[primary] += KillsBoost_GainOnKill[primary];
				if(KillsBoost_StoredDur[primary] > KillsBoost_MaxDur[primary])
					KillsBoost_StoredDur[primary] = KillsBoost_MaxDur[primary];
			}
			else if(weapon == GetPlayerWeaponSlot(attacker, 2))
			{
				KillsBoost_StoredDur[primary] += KillsBoost_GainOnMeleeKill[primary];
				if(KillsBoost_StoredDur[primary] > KillsBoost_MaxDur[primary])
					KillsBoost_StoredDur[primary] = KillsBoost_MaxDur[primary];
			}
		}
	}
	if(assister)
	{
		new weapon = LastWeaponHurtWith[assister];
		new primary = GetPlayerWeaponSlot(assister, 0);
		if(primary > 0 && primary < 2049 && KillsBoost[primary])
		{
			if(weapon == GetPlayerWeaponSlot(assister, 1))
			{
				KillsBoost_StoredDur[primary] += KillsBoost_GainOnKill[primary] / 2;
				if(KillsBoost_StoredDur[primary] > KillsBoost_MaxDur[primary])
					KillsBoost_StoredDur[primary] = KillsBoost_MaxDur[primary];
			}
			else if(weapon == GetPlayerWeaponSlot(assister, 2))
			{
				KillsBoost_StoredDur[primary] += KillsBoost_GainOnMeleeKill[primary] / 2;
				if(KillsBoost_StoredDur[primary] > KillsBoost_MaxDur[primary])
					KillsBoost_StoredDur[primary] = KillsBoost_MaxDur[primary];
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
	
	if(!KillsBoost[weapon])
		return;
	
	if(GetEngineTime() > LastTick[client] + 0.1)
		KillsBoost_PreThink(client, weapon);
}

static void KillsBoost_PreThink(client, weapon)
{
	if(TF2_IsPlayerInCondition(client, TFCond:0))
	{
		SpinTime[client] += 0.1;
		if(SpinTime[client] >= 1.0 && KillsBoost_StoredDur[weapon] > 0.0)
		{
			TF2_AddCondition(client, TFCond:KillsBoost_Condition[weapon], 0.2);
			KillsBoost_StoredDur[weapon] -= 0.1;
		}
	}
	else
		SpinTime[client] = 0.0;
	
	SetHudTextParams(-1.0, 0.6, 0.2, 255, 255, 255, 255);
	ShowSyncHudText(client, hudText_Client, "Boost: %is / %is", RoundFloat(KillsBoost_StoredDur[weapon]), RoundFloat(KillsBoost_MaxDur[weapon]));
	
	LastTick[client] = GetEngineTime();
}

public OnEntityDestroyed(ent)
{
	if(ent < 0 || ent > 2048)
		return;
	
	KillsBoost[ent] = false;
	KillsBoost_MaxDur[ent] = 0.0;
	KillsBoost_StoredDur[ent] = 0.0;
	KillsBoost_GainOnKill[ent] = 0.0;
	KillsBoost_GainOnMeleeKill[ent] = 0.0;
	KillsBoost_Condition[ent] = 0;
}
