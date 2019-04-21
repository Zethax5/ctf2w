/*

Created by: Zethax
Document created on: March 28th, 2019
Last edit made on: March 28th, 2019
Current version: v1.0

Attributes in this pack:
	-> "stack speed bonuses on kill"
		1) Fire rate bonus per stack
		2) Reload rate bonus per stack
		3) Blast radius bonus per stack
		4) Projectile speed bonus per stack
		5) Maximum stack amount
		6) Delay before stack decay begins
		7) Amount of time to subtract from base decay time after decay begins

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

#define PLUGIN_NAME "tf_custom_projectile_speed_onkill"
#define PLUGIN_AUTH "Zethax"
#define PLUGIN_DESC "Adds an attribute which grants stacking projectile speed on kill, among other speeds."
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
}

new bool:SpeedOnKill[2049];
new Float:SpeedOnKill_FireSpd[2049];
new Float:SpeedOnKill_BlastRad[2049];
new Float:SpeedOnKill_ReloadSpd[2049];
new Float:SpeedOnKill_ProjectileSpd[2049];
new SpeedOnKill_MaxStacks[2049];
new SpeedOnKill_OldStacks[2049];
new SpeedOnKill_Stacks[2049];
new Float:SpeedOnKill_FastDecay[2049];
new Float:SpeedOnKill_Decay[2049];
new Float:SpeedOnKill_Tick[2049];

public Action:CW3_OnAddAttribute(slot, client, const String:attrib[], const String:plugin[], const String:value[], bool:whileActive)
{
	new Action:action;
	if(!StrEqual(plugin, PLUGIN_NAME))
  		return action;
	
	new weapon = GetPlayerWeaponSlot(client, slot);
	if(weapon < 0 || weapon > 2048)
		return action;
	
	if(StrEqual(attrib, "stack speed bonuses on kill"))
	{
		new String:values[7][10];
		ExplodeString(value, " ", values, sizeof(values), sizeof(values[]));
		
		SpeedOnKill_FireSpd[weapon] = StringToFloat(values[0]);
		SpeedOnKill_ReloadSpd[weapon] = StringToFloat(values[1]);
		SpeedOnKill_BlastRad[weapon] = StringToFloat(values[2]);
		SpeedOnKill_ProjectileSpd[weapon] = StringToFloat(values[3]);
		SpeedOnKill_MaxStacks[weapon] = StringToInt(values[4]);
		SpeedOnKill_Decay[weapon] = StringToFloat(values[5]);
		SpeedOnKill_FastDecay[weapon] = StringToFloat(values[6]);
		
		SpeedOnKill[weapon] = true;
		action = Plugin_Handled;
	}
	
	return action;
}

public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new assister = GetClientOfUserId(GetEventInt(event, "assister"));
	
	if(IsValidClient(attacker))
	{
		new weapon = GetActiveWeapon(attacker);
		if(weapon > -1 && SpeedOnKill[weapon])
		{
			SpeedOnKill_Stacks[weapon] += 2;
			if(SpeedOnKill_Stacks[weapon] > SpeedOnKill_MaxStacks[weapon])
				SpeedOnKill_Stacks[weapon] = SpeedOnKill_MaxStacks[weapon];
			
			SpeedOnKill_Tick[weapon] = GetEngineTime();
		}
	}
	
	if(IsValidClient(assister))
	{
		new weapon = GetActiveWeapon(assister);
		if(weapon > -1 && SpeedOnKill[weapon])
		{
			SpeedOnKill_Stacks[weapon]++;
			if(SpeedOnKill_Stacks[weapon] > SpeedOnKill_MaxStacks[weapon])
				SpeedOnKill_Stacks[weapon] = SpeedOnKill_MaxStacks[weapon];
			
			SpeedOnKill_Tick[weapon] = GetEngineTime();
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
	
	if(!SpeedOnKill[weapon])
		return;
	
	if(GetEngineTime() >= SpeedOnKill_Tick[weapon] + SpeedOnKill_Decay[weapon])
	{
		SpeedOnKill_Tick[weapon] = GetEngineTime() + SpeedOnKill_FastDecay[weapon];
		SpeedOnKill_Stacks[weapon]--;
		if(SpeedOnKill_Stacks[weapon] < 0)
			SpeedOnKill_Stacks[weapon] = 0;
	}
	
	if(SpeedOnKill_OldStacks[weapon] != SpeedOnKill_Stacks[weapon])
	{
		new Float:fireRateBoost = SpeedOnKill_FireSpd[weapon] * SpeedOnKill_Stacks[weapon];
		new Float:reloadRateBoost = SpeedOnKill_ReloadSpd[weapon] * SpeedOnKill_Stacks[weapon];
		new Float:blastRadiusBoost = SpeedOnKill_BlastRad[weapon] * SpeedOnKill_Stacks[weapon];
		new Float:projectileSpeedBoost = SpeedOnKill_ProjectileSpd[weapon] * SpeedOnKill_Stacks[weapon];
		TF2Attrib_SetByName(weapon, "fire rate bonus", 1.0 - fireRateBoost);
		TF2Attrib_SetByName(weapon, "Reload time decreased", 1.0 - reloadRateBoost);
		TF2Attrib_SetByName(weapon, "Blast radius increased", 1.0 + blastRadiusBoost);
		TF2Attrib_SetByName(weapon, "Projectile speed increased", 1.0 + projectileSpeedBoost);
		SpeedOnKill_OldStacks[weapon] = SpeedOnKill_Stacks[weapon];
	}
	
	SetHudTextParams(0.6, 0.8, 0.2, 255, 255, 255, 255);
	ShowSyncHudText(client, hudText_Client, "Stacks: %i / %i", SpeedOnKill_Stacks[weapon], SpeedOnKill_MaxStacks[weapon]);
}

public OnEntityDestroyed(ent)
{
	if(ent < 0 || ent > 2048)
		return;
	
	SpeedOnKill[ent] = false;
	SpeedOnKill_FireSpd[ent] = 0.0;
	SpeedOnKill_ReloadSpd[ent] = 0.0;
	SpeedOnKill_BlastRad[ent] = 0.0;
	SpeedOnKill_ProjectileSpd[ent] = 0.0;
	SpeedOnKill_MaxStacks[ent] = 0;
	SpeedOnKill_OldStacks[ent] = 0;
	SpeedOnKill_Decay[ent] = 0.0;
	SpeedOnKill_FastDecay[ent] = 0.0;
}
